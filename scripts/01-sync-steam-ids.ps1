param(
    [string]$TargetsPath = ".\data\steam-image-targets.json",
    [string]$OverridesPath = ".\data\steam-appid-overrides.json",
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$ReviewPath = ".\data\steam-games-review-needed.json",
    [string]$RetryPath = ".\data\steam-games-retry-needed.json",
    [switch]$DiscoverFromMarkdown,
    [switch]$UpdateTargets = $true,
    [switch]$AllowFuzzy,
    [switch]$AcceptFuzzyMatches,
    [switch]$OnlyMissing = $true,
    [switch]$RefreshMetadata,
    [switch]$ForceSearch,
    [int]$DelayMs = 1200,
    [string]$CountryCode = "us",
    [string]$Language = "english"
)

. "$PSScriptRoot\_registry-lib.ps1"

$targets = @()
$loadedTargets = Load-JsonFile $TargetsPath @()
if ($loadedTargets -is [System.Array]) { $targets += $loadedTargets } else { $targets += @($loadedTargets) }

if ($DiscoverFromMarkdown) {
    Write-Step "Descubriendo títulos desde Markdown con filtros estrictos..."
    $targets += Get-MarkdownTargets
}

$overrides = Convert-ObjectToHashtable (Load-JsonFile $OverridesPath $null)
$registry = @(Load-JsonFile $RegistryPath @())
$review = @(Load-JsonFile $ReviewPath @())
$retry = @(Load-JsonFile $RetryPath @())

$registryMap = @{}
$registryBySlug = @{}
$registryByTitle = @{}
foreach ($r in $registry) {
    if ($r.steamAppId) { $registryMap[[string]$r.steamAppId] = $r }
    if ($r.slug) { $registryBySlug[[string]$r.slug] = $r }
    if ($r.title) { $registryByTitle[(Normalize-Title $r.title)] = $r }
    if ($r.aliases) {
        foreach ($alias in @($r.aliases)) {
            if ($alias) { $registryByTitle[(Normalize-Title $alias)] = $r }
        }
    }
}

$targetMap = @{}
foreach ($t in $targets) {
    if (-not $t.title) { continue }
    $t.title = Clean-DisplayTitle $t.title
    if (Test-HeadingNoise $t.title) { continue }

    $slug = $t.slug
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = New-Slug $t.title }
    $key = Normalize-Title $t.title

    if (-not $targetMap.ContainsKey($key)) {
        $t | Add-Member -NotePropertyName slug -NotePropertyValue $slug -Force
        $targetMap[$key] = $t
    }
}
$targets = @($targetMap.Values)
Write-Step "Targets útiles: $($targets.Count)"

foreach ($game in $targets) {
    $title = Clean-DisplayTitle ([string]$game.title)
    $slug = [string]$game.slug
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = New-Slug $title }

    # V6.4.2: reusar registry cuando ya existe y no se pidió refresh/force.
    $existingRegistryEntry = $null
    if ($registryBySlug.ContainsKey($slug)) { $existingRegistryEntry = $registryBySlug[$slug] }
    elseif ($registryByTitle.ContainsKey((Normalize-Title $title))) { $existingRegistryEntry = $registryByTitle[(Normalize-Title $title)] }

    if ($OnlyMissing -and $existingRegistryEntry -and (-not $ForceSearch) -and (-not $RefreshMetadata)) {
        if ($existingRegistryEntry.steamAppId -and $existingRegistryEntry.officialName -and $existingRegistryEntry.steamType) {
            Write-Ok "Reusado registry: $title -> $($existingRegistryEntry.steamAppId)"
            $registryMap[[string]$existingRegistryEntry.steamAppId] = $existingRegistryEntry
            continue
        }
    }

    $appid = $null
    $matchName = ""
    $matchType = ""

    if ($game.steamAppId) {
        try {
            $appid = [int]$game.steamAppId
            $matchName = $title
            $matchType = "provided"
        } catch {}
    }

    if (-not $appid -and $overrides.ContainsKey($slug) -and $overrides[$slug]) {
        $appid = [int]$overrides[$slug]
        $matchName = $title
        $matchType = "override"
    }

    if (-not $appid) {
        Start-Sleep -Milliseconds $DelayMs
        $match = Find-AppIdByStoreSearch -Title $title -CountryCode $CountryCode -Language $Language -AllowFuzzy:$AllowFuzzy
        if ($match -and $match.appid) {
            if (($match.matchType -in @("storesearch-contains", "storesearch-first")) -and (-not $AcceptFuzzyMatches)) {
                $review += [pscustomobject]@{
                    title = $title
                    slug = $slug
                    detectedSteamAppId = $match.appid
                    detectedName = $match.name
                    matchType = $match.matchType
                    reason = "Candidato fuzzy detectado; no se escribe al registry sin -AcceptFuzzyMatches"
                    updatedAt = (Get-Date).ToString("s")
                }
                Write-Warn "Candidato fuzzy enviado a revisión: $title -> $($match.name) / $($match.appid)"
                continue
            }
            $appid = [int]$match.appid
            $matchName = $match.name
            $matchType = $match.matchType
        }
        else {
            $review += [pscustomobject]@{
                title = $title
                slug = $slug
                detectedSteamAppId = ""
                detectedName = if ($match) { $match.name } else { "" }
                matchType = if ($match) { $match.matchType } else { "not-found" }
                reason = "No hubo match exacto; requiere override manual"
                updatedAt = (Get-Date).ToString("s")
            }
            Write-Warn "Revisión requerida: $title"
            continue
        }
    }

    # Si ya tenemos metadata válida para ese ID, no llamar appdetails salvo RefreshMetadata.
    if ($appid -and $registryMap.ContainsKey([string]$appid) -and (-not $RefreshMetadata)) {
        $existingById = $registryMap[[string]$appid]
        if ($existingById.officialName -and $existingById.steamType) {
            Write-Ok "Reusado ID existente: $title -> $appid"
            continue
        }
    }

    try {
        Start-Sleep -Milliseconds $DelayMs
        $details = Get-AppDetails -AppId $appid -Language $Language
        $node = $details."$appid"

        if (-not $node.success) {
            $review += [pscustomobject]@{
                title = $title; slug = $slug; detectedSteamAppId = $appid; detectedName = $matchName
                matchType = $matchType; reason = "appdetails success=false"; updatedAt = (Get-Date).ToString("s")
            }
            continue
        }

        $data = $node.data
        $steamType = [string]$data.type

        if (($matchType -eq "storesearch-contains" -or $matchType -eq "storesearch-first") -and -not $AllowFuzzy) {
            $review += [pscustomobject]@{
                title = $title; slug = $slug; detectedSteamAppId = $appid; detectedName = $data.name
                matchType = $matchType; steamType = $steamType
                reason = "Match fuzzy bloqueado por política estricta"
                updatedAt = (Get-Date).ToString("s")
            }
            continue
        }

        if ($steamType -notin @("game", "dlc", "application")) {
            $review += [pscustomobject]@{
                title = $title; slug = $slug; detectedSteamAppId = $appid; detectedName = $data.name
                matchType = $matchType; steamType = $steamType
                reason = "steamType no aceptado automáticamente"
                updatedAt = (Get-Date).ToString("s")
            }
            continue
        }

        $entry = New-RegistryEntry -Title $title -Slug $slug -SteamAppId $appid -OfficialName $data.name -SteamType $steamType -MatchName $matchName -MatchType $matchType
        $registryMap[[string]$appid] = $entry

        Write-Ok "$title -> $($data.name) / $appid / $matchType"
    }
    catch {
        $msg = $_.Exception.Message
        $target = [pscustomobject]@{
            title = $title; slug = $slug; detectedSteamAppId = $appid; detectedName = $matchName
            matchType = $matchType; reason = $msg; updatedAt = (Get-Date).ToString("s")
        }

        if (Test-RateLimit429 $msg) {
            $target | Add-Member -NotePropertyName retryReason -NotePropertyValue "Rate limit de Steam/API; reintentar después" -Force
            $retry += $target
            Write-Warn "Retry por rate limit: $title"
        }
        else {
            $review += $target
        }
    }
}

$cleanRegistry = @($registryMap.Values | Sort-Object title)
Save-JsonFile $RegistryPath $cleanRegistry 12

# Dedup review/retry and strip noise.
$dedupReview = @{}
foreach ($r in $review) {
    if (Test-HeadingNoise $r.title) { continue }
    if (Test-RateLimit429 $r.reason) { 
        $r | Add-Member -NotePropertyName retryReason -NotePropertyValue "Rate limit de Steam/API; reintentar después" -Force
        $retry += $r
        continue
    }
    $key = "$(Normalize-Title $r.title)|$($r.detectedSteamAppId)|$($r.reason)"
    if (-not $dedupReview.ContainsKey($key)) { $dedupReview[$key] = $r }
}
Save-JsonFile $ReviewPath @($dedupReview.Values | Sort-Object title) 8

$dedupRetry = @{}
foreach ($r in $retry) {
    if (Test-HeadingNoise $r.title) { continue }
    $key = "$(Normalize-Title $r.title)|$($r.detectedSteamAppId)|$($r.reason)"
    if (-not $dedupRetry.ContainsKey($key)) { $dedupRetry[$key] = $r }
}
Save-JsonFile $RetryPath @($dedupRetry.Values | Sort-Object title) 8

if ($UpdateTargets) {
    $newTargets = @()
    foreach ($r in $cleanRegistry) {
        if (Test-HeadingNoise $r.title) { continue }
        $newTargets += [pscustomobject]@{
            title = $r.title
            slug = $r.slug
            steamAppId = $r.steamAppId
            priority = "registry-approved"
        }
    }
    Save-JsonFile $TargetsPath ($newTargets | Sort-Object title) 6
}

Write-Step "Registry actualizado: $RegistryPath"
Write-Step "Revisión pendiente: $ReviewPath"
Write-Step "Retry pendiente: $RetryPath"
