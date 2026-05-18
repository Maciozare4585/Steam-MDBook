<#
.SYNOPSIS
    Reinicia el estado de discovery y reconstruye targets desde colecciones Markdown.
.DESCRIPTION
    Hace backup de archivos de estado, limpia review/retry/ignored y reconstruye `steam-image-targets.json`
    preservando los Steam App IDs ya conocidos en `steam-games-registry.json`.

    Este script NO borra el registry aprobado. Su objetivo es que la lista general vuelva a detectar
    todos los juegos/elementos presentes en las colecciones activas del mdBook.
.EXAMPLE
    .\scripts\00-reset-discovery-state.ps1
.EXAMPLE
    .\scripts\00-reset-discovery-state.ps1 -AllMarkdownFiles -GenerateExternalGames
#>
param(
    [string]$TargetsPath = ".\data\steam-image-targets.json",
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$ReviewPath = ".\data\steam-games-review-needed.json",
    [string]$RetryPath = ".\data\steam-games-retry-needed.json",
    [string]$IgnoredPath = ".\data\steam-games-ignored.json",
    [string]$DiscoveredPath = ".\data\library-discovered-targets.json",
    [string]$ReportPath = ".\data\discovery-reset-report.json",
    [switch]$AllMarkdownFiles,
    [switch]$GenerateExternalGames,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_registry-lib.ps1"

function Copy-IfExists($Path, $BackupDir) {
    if (Test-Path $Path) {
        Copy-Item $Path (Join-Path $BackupDir (Split-Path $Path -Leaf)) -Force
    }
}

$backupDir = $null
if (-not $NoBackup) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = ".\data\_backup_discovery_reset_$stamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-IfExists $TargetsPath $backupDir
    Copy-IfExists $ReviewPath $backupDir
    Copy-IfExists $RetryPath $backupDir
    Copy-IfExists $IgnoredPath $backupDir
    Copy-IfExists $DiscoveredPath $backupDir
    Write-Step "Backup creado: $backupDir"
}

$registry = @(Load-JsonFile $RegistryPath @())
$existingTargets = @(Load-JsonFile $TargetsPath @())
$markdownTargets = @(Get-MarkdownTargets -AllMarkdownFiles:$AllMarkdownFiles)

$registryByTitle = @{}
$registryBySlug = @{}
foreach ($r in $registry) {
    if ($r.title) { $registryByTitle[(Normalize-Title $r.title)] = $r }
    if ($r.aliases) {
        foreach ($alias in @($r.aliases)) {
            if ($alias) { $registryByTitle[(Normalize-Title $alias)] = $r }
        }
    }
    if ($r.slug) { $registryBySlug[[string]$r.slug] = $r }
}

$targetMap = @{}
function Add-ResetTarget($Target, [string]$DefaultPriority) {
    if (-not $Target -or -not $Target.title) { return }

    $title = Clean-DisplayTitle ([string]$Target.title)
    if ([string]::IsNullOrWhiteSpace($title)) { return }
    if (Test-HeadingNoise $title) { return }

    $key = Normalize-Title $title
    if ([string]::IsNullOrWhiteSpace($key)) { return }

    $slug = [string]$Target.slug
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = New-Slug $title }

    $known = $null
    if ($registryByTitle.ContainsKey($key)) { $known = $registryByTitle[$key] }
    elseif ($registryBySlug.ContainsKey($slug)) { $known = $registryBySlug[$slug] }

    $appid = ""
    $priority = if ($Target.priority) { [string]$Target.priority } else { $DefaultPriority }

    if ($known -and $known.steamAppId) {
        $appid = $known.steamAppId
        $priority = "registry-approved"
        $slug = if ($known.slug) { [string]$known.slug } else { $slug }
    }
    elseif ($Target.steamAppId) { $appid = $Target.steamAppId }

    $source = if ($Target.source) { [string]$Target.source } else { "" }

    if (-not $targetMap.ContainsKey($key)) {
        $targetMap[$key] = [pscustomobject]@{
            title = $title
            slug = $slug
            steamAppId = $appid
            priority = $priority
            source = $source
        }
    }
    else {
        $existing = $targetMap[$key]
        if ((-not $existing.steamAppId) -and $appid) { $existing.steamAppId = $appid }
        if (($existing.priority -ne "registry-approved") -and $priority) { $existing.priority = $priority }
        if ((-not $existing.source) -and $source) { $existing.source = $source }
    }
}

foreach ($t in $existingTargets) { Add-ResetTarget $t "existing-target" }
foreach ($t in $markdownTargets) { Add-ResetTarget $t "discovered-markdown" }

$allTargets = @($targetMap.Values | Sort-Object title)
Save-JsonFile $TargetsPath $allTargets 8
Save-JsonFile $DiscoveredPath (@($markdownTargets | Sort-Object title)) 8

# Reset explícito de colas. El backup conserva el estado anterior.
Save-JsonFile $ReviewPath @() 4
Save-JsonFile $RetryPath @() 4
Save-JsonFile $IgnoredPath @() 4

if ($GenerateExternalGames) {
    $external = @()
    foreach ($t in $markdownTargets) {
        if ($t.source -and ([string]$t.source -match '02-colecciones/tecnicas/01-0-externos')) {
            $title = Clean-DisplayTitle ([string]$t.title)
            if ($title -and -not (Test-HeadingNoise $title)) {
                $kind = "external"
                if ($title -match 'Launcher|Client|Connect|Galaxy|EA|Epic|Rockstar|Ubisoft|Hytale|Habbo') { $kind = "launcher" }
                elseif ($title -match 'citra|yuzu|Fightcade|NeoRAGEx|WinDS|WinKawaks') { $kind = "emulator" }
                elseif ($title -match 'Recovery|Joyxoff|Organizer') { $kind = "tool" }
                else { $kind = "game" }

                $external += [pscustomobject]@{
                    title = $title
                    slug = New-Slug $title
                    source = "external"
                    type = $kind
                    sourceFile = [string]$t.source
                }
            }
        }
    }
    Save-JsonFile ".\data\external-games.json" (@($external | Sort-Object title)) 8
}

$resolved = @($allTargets | Where-Object { $_.steamAppId }).Count
$unresolved = $allTargets.Count - $resolved
$report = [ordered]@{
    version = "6.6.12"
    updatedAt = (Get-Date).ToString("o")
    backupDir = $backupDir
    markdownTargets = $markdownTargets.Count
    previousTargets = $existingTargets.Count
    registryEntries = $registry.Count
    rebuiltTargets = $allTargets.Count
    targetsWithSteamAppId = $resolved
    targetsWithoutSteamAppId = $unresolved
    resetFiles = @($ReviewPath, $RetryPath, $IgnoredPath)
    notes = @(
        "steam-games-registry.json no se borra; conserva IDs aprobados.",
        "steam-image-targets.json ahora conserva títulos descubiertos aunque aún no tengan Steam App ID.",
        "La lista general debe generarse con scripts/19-build-library-catalog.ps1 y scripts/04-generate-game-pages.ps1."
    )
}
Save-JsonFile $ReportPath $report 8

Write-Step "Targets reconstruidos: $($allTargets.Count)"
Write-Step "Con Steam App ID: $resolved"
Write-Step "Sin Steam App ID todavía: $unresolved"
Write-Step "Review/retry/ignored reiniciados."
Write-Step "Reporte: $ReportPath"
