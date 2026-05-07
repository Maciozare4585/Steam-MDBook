param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$SteamGridDbApiKey = $env:STEAMGRIDDB_API_KEY,
    [switch]$PreferAnimated = $true,
    [switch]$UpdateMarkdownPages,
    [switch]$WhatIfMode,
    [switch]$RefreshSteamGridDb,
    [int]$DelayMs = 350
)

. "$PSScriptRoot\_registry-lib.ps1"
$script:RefreshAssetsGlobal = $RefreshSteamGridDb.IsPresent

if ([string]::IsNullOrWhiteSpace($SteamGridDbApiKey)) {
    throw "Falta SteamGridDB API key. Usa -SteamGridDbApiKey o `$env:STEAMGRIDDB_API_KEY."
}

function Invoke-SgdbApi($Url, $ApiKey) {
    $headers = @{ Authorization = "Bearer $ApiKey" }
    try { return Invoke-RestMethod -Uri $Url -Headers $headers -Method Get }
    catch {
        Write-Warn "SteamGridDB falló: $Url -> $($_.Exception.Message)"
        return $null
    }
}

function Get-ExtFromAsset($Asset, [string]$Fallback) {
    if ($Asset.mime) {
        switch -Regex ($Asset.mime) {
            "webp" { return ".webp" }
            "gif" { return ".gif" }
            "png" { return ".png" }
            "jpeg|jpg" { return ".jpg" }
        }
    }
    if ($Asset.url -match "\.([a-zA-Z0-9]+)(\?|$)") { return "." + $matches[1].ToLowerInvariant() }
    return $Fallback
}

function Select-SgdbAsset($Items, [switch]$PreferAnimated) {
    if (-not $Items -or $Items.Count -eq 0) { return $null }

    if ($PreferAnimated) {
        $animated = $Items | Where-Object {
            ($_.type -eq "animated") -or ($_.mime -match "webp|gif|apng")
        } | Select-Object -First 1
        if ($animated) { return $animated }
    }

    return ($Items | Select-Object -First 1)
}

$registry = @(Load-JsonFile $RegistryPath @())

foreach ($game in $registry) {
    $appid = [int]$game.steamAppId
    $title = [string]$game.title
    $slug = [string]$game.slug

    if ((-not $RefreshSteamGridDb) -and $game.preferredImageSource -like "steamgriddb*" -and $game.preferredImageForMdBook) {
        $localPath = $game.preferredImageForMdBook -replace "^\.\./", "src/"
        if (Test-Path ".\$localPath") {
            Write-Ok "SGDB existente, skip: $title"
            continue
        }
    }

    Start-Sleep -Milliseconds $DelayMs
    $sgdbGame = Invoke-SgdbApi "https://www.steamgriddb.com/api/v2/games/steam/$appid" $SteamGridDbApiKey

    if (-not ($sgdbGame -and $sgdbGame.success -and $sgdbGame.data)) {
        Write-Warn "Sin juego SGDB: $title / $appid"
        continue
    }

    $sgdbId = [int]$sgdbGame.data.id
    $game.sgdbGameId = $sgdbId

    $requests = @(
        @{ key="hero"; prop="sgdbHero"; endpoint="heroes"; fallback=".webp"; query="types=animated,static&mimes=image/webp,image/gif,image/png,image/jpeg" },
        @{ key="grid"; prop="sgdbGrid"; endpoint="grids"; fallback=".webp"; query="types=animated,static&mimes=image/webp,image/gif,image/png,image/jpeg" },
        @{ key="logo"; prop="sgdbLogo"; endpoint="logos"; fallback=".png"; query="types=animated,static&mimes=image/webp,image/gif,image/png" },
        @{ key="icon"; prop="sgdbIcon"; endpoint="icons"; fallback=".png"; query="mimes=image/png,image/jpeg,image/vnd.microsoft.icon" }
    )

    $preferred = $null
    $preferredSource = ""

    foreach ($req in $requests) {
        Start-Sleep -Milliseconds 250
        $url = "https://www.steamgriddb.com/api/v2/$($req.endpoint)/game/$sgdbId?$($req.query)"
        $res = Invoke-SgdbApi $url $SteamGridDbApiKey
        if (-not ($res -and $res.success -and $res.data)) { continue }

        $asset = Select-SgdbAsset @($res.data) -PreferAnimated:$PreferAnimated
        if (-not $asset) { continue }

        $ext = Get-ExtFromAsset $asset $req.fallback
        $local = "src/assets/games/$appid/$($req.prop)$ext"
        Download-FileSafe -Url $asset.url -OutFile ".\$local" -WhatIfMode:$WhatIfMode | Out-Null
        $game.images.$($req.prop) = $local

        if (-not $preferred -and ($req.key -eq "hero" -or $req.key -eq "grid")) {
            $preferred = "../assets/games/$appid/$($req.prop)$ext"
            $preferredSource = "steamgriddb-$($req.key)"
        }
    }

    if ($preferred) {
        $game.preferredImageSource = $preferredSource
        $game.preferredImageForMdBook = $preferred

        if ($UpdateMarkdownPages -and (-not $WhatIfMode)) {
            Update-GamePageImageById -Slug $slug -SteamAppId $appid -Title $title -RelativeImage $preferred
        }

        Write-Ok "$title -> $preferredSource"
    }
    else {
        Write-Warn "Sin assets SGDB útiles: $title"
    }

    $game.updatedAt = (Get-Date).ToString("s")
}

if (-not $WhatIfMode) {
    Save-JsonFile $RegistryPath ($registry | Sort-Object title) 12
}

Write-Step "SteamGridDB procesado."
