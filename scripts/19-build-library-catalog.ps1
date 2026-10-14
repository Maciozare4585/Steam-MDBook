<#
.SYNOPSIS
    Construye el catálogo general desde Markdown + registry + externos.
.DESCRIPTION
    Genera una fuente canónica de lista general que incluye entradas con Steam App ID y entradas sin resolver.
    No depende únicamente de `steam-games-registry.json`, por lo que no oculta juegos raros, externos,
    demos, herramientas o elementos pendientes de AppID.
.EXAMPLE
    .\scripts\19-build-library-catalog.ps1
#>
param(
    [string]$TargetsPath = ".\data\steam-image-targets.json",
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$ExternalPath = ".\data\external-games.json",
    [string]$OutputPath = ".\data\library-catalog.json",
    [string]$PublicOutputPath = ".\src\assets\data\library-catalog.json",
    [string]$ReportPath = ".\data\library-catalog-report.json",
    [switch]$AllMarkdownFiles
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @())
$targets = @(Load-JsonFile $TargetsPath @())
$markdownTargets = @(Get-MarkdownTargets -AllMarkdownFiles:$AllMarkdownFiles)
$external = @(Load-JsonFile $ExternalPath @())

$registryByTitle = @{}
$registryById = @{}
foreach ($r in $registry) {
    if ($r.steamAppId) { $registryById[[string]$r.steamAppId] = $r }
    if ($r.title) { $registryByTitle[(Normalize-Title $r.title)] = $r }
    if ($r.aliases) {
        foreach ($alias in @($r.aliases)) {
            if ($alias) { $registryByTitle[(Normalize-Title $alias)] = $r }
        }
    }
}

$catalogMap = @{}
function Add-CatalogItem {
    param(
        [string]$Title,
        [string]$Slug,
        $SteamAppId,
        [string]$SourceType,
        [string]$Priority,
        [string]$SourceFile,
        [string]$ExternalType
    )

    $titleClean = Clean-DisplayTitle $Title
    if ([string]::IsNullOrWhiteSpace($titleClean)) { return }
    if (Test-HeadingNoise $titleClean) { return }

    $norm = Normalize-Title $titleClean
    if ([string]::IsNullOrWhiteSpace($norm)) { return }

    $known = $null
    if ($SteamAppId -and $registryById.ContainsKey([string]$SteamAppId)) { $known = $registryById[[string]$SteamAppId] }
    elseif ($registryByTitle.ContainsKey($norm)) { $known = $registryByTitle[$norm] }

    $appid = $null
    $resolved = $false
    $steamType = $null
    $officialName = $null

    if ($known) {
        $appid = [int]$known.steamAppId
        $resolved = $true
        $steamType = [string]$known.steamType
        $officialName = [string]$known.officialName
        if ($known.slug) { $Slug = [string]$known.slug }
    }
    elseif ($SteamAppId) {
        $parsed = 0
        if ([int]::TryParse([string]$SteamAppId, [ref]$parsed) -and $parsed -gt 0) {
            $appid = $parsed
            $resolved = $true
        }
    }

    if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = New-Slug $titleClean }
    $key = if ($appid) { "steam:$appid" } else { "title:$norm" }

    if (-not $catalogMap.ContainsKey($key)) {
        $catalogMap[$key] = [pscustomobject]@{
            canonicalId = if ($appid) { "steam:$appid" } else { "catalog:$Slug" }
            title = $titleClean
            slug = $Slug
            steamAppId = $appid
            officialName = $officialName
            steamType = $steamType
            isResolvedSteam = $resolved
            sourceType = $SourceType
            priority = $Priority
            sourceFiles = @($SourceFile | Where-Object { $_ })
            externalType = $ExternalType
        }
    }
    else {
        $item = $catalogMap[$key]
        if ((-not $item.steamAppId) -and $appid) {
            $item.steamAppId = $appid
            $item.canonicalId = "steam:$appid"
            $item.isResolvedSteam = $true
        }
        if ((-not $item.officialName) -and $officialName) { $item.officialName = $officialName }
        if ((-not $item.steamType) -and $steamType) { $item.steamType = $steamType }
        if ((-not $item.externalType) -and $ExternalType) { $item.externalType = $ExternalType }

        $sources = @($item.sourceFiles)
        if ($SourceFile) { $sources += $SourceFile }
        $item.sourceFiles = @($sources | Where-Object { $_ } | Select-Object -Unique)
    }
}

foreach ($r in $registry) {
    Add-CatalogItem -Title $r.title -Slug $r.slug -SteamAppId $r.steamAppId -SourceType "steam-registry" -Priority "registry-approved" -SourceFile "data/steam-games-registry.json"
}
foreach ($t in $targets) {
    $src = if ($t.source) { [string]$t.source } else { "data/steam-image-targets.json" }
    $priority = if ($t.priority) { [string]$t.priority } else { "target" }
    Add-CatalogItem -Title $t.title -Slug $t.slug -SteamAppId $t.steamAppId -SourceType "target" -Priority $priority -SourceFile $src
}
foreach ($t in $markdownTargets) {
    Add-CatalogItem -Title $t.title -Slug $t.slug -SteamAppId $t.steamAppId -SourceType "markdown" -Priority "discovered-markdown" -SourceFile $t.source
}
foreach ($e in $external) {
    Add-CatalogItem -Title $e.title -Slug $e.slug -SteamAppId $null -SourceType "external" -Priority "external" -SourceFile $e.sourceFile -ExternalType $e.type
}

$catalog = @($catalogMap.Values | Sort-Object title)
Save-JsonFile $OutputPath $catalog 12
$publicDir = Split-Path $PublicOutputPath -Parent
if ($publicDir -and -not (Test-Path $publicDir)) { New-Item -ItemType Directory -Path $publicDir -Force | Out-Null }
Save-JsonFile $PublicOutputPath $catalog 12

$resolved = @($catalog | Where-Object { $_.isResolvedSteam }).Count
$externalCount = @($catalog | Where-Object { $_.sourceType -eq "external" -or $_.externalType }).Count
$report = [ordered]@{
    version = "6.6.12"
    updatedAt = (Get-Date).ToString("o")
    registryEntries = $registry.Count
    targetEntries = $targets.Count
    markdownEntries = $markdownTargets.Count
    externalEntries = $external.Count
    catalogTotal = $catalog.Count
    resolvedSteam = $resolved
    unresolvedOrCatalogOnly = $catalog.Count - $resolved
    externalOrNoSteam = $externalCount
    output = $OutputPath
    publicOutput = $PublicOutputPath
}
Save-JsonFile $ReportPath $report 8

Write-Step "Catálogo general generado: $($catalog.Count) entradas."
Write-Step "Resueltas con Steam App ID: $resolved"
Write-Step "Sin App ID / externas / catálogo: $($catalog.Count - $resolved)"
Write-Step "Salida pública: $PublicOutputPath"
