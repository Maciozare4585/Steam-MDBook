<#
.SYNOPSIS
    Orquestador principal del pipeline mdBook/Steam.
.DESCRIPTION
    Ejecuta reparación, sync de IDs, descarga de imágenes, generación de páginas, metadata base,
    enriquecimiento Steam opcional, catálogo DLC opcional, tooltips, galería, sanitización y validación.
.PARAMETER DiscoverFromMarkdown
    Descubre juegos desde tablas Markdown.
.PARAMETER EnrichSteamMetadata
    Consulta Steam Store API para metadata extendida.
.PARAMETER SyncSteamDlc
    Consulta catálogo DLC desde Steam y actualiza `dlcInfo.dlcs`.
.PARAMETER ValidatePaths
    Ejecuta validación de rutas al final.
.EXAMPLE
    .\scripts\05-run-full-sync.ps1 -DiscoverFromMarkdown -AllowFuzzy -EnrichSteamMetadata -SyncSteamDlc -ValidatePaths
#>
param(
    [switch]$DiscoverFromMarkdown,
    [switch]$UseSteamGridDb,
    [string]$SteamGridDbApiKey = $env:STEAMGRIDDB_API_KEY,
    [switch]$RefreshMetadata,
    [switch]$RefreshAssets,
    [switch]$RefreshSteamGridDb,
    [switch]$ForceSearch,
    [switch]$AllowFuzzy,
    [switch]$AcceptFuzzyMatches,
    [switch]$SkipCollectionTooltips,
    [switch]$ValidatePaths,
    [switch]$EnrichSteamMetadata,
    [int]$MetadataMaxGames = 0,
    [int]$MetadataDelayMs = 1500,
    [switch]$ForceSteamMetadata,
    [switch]$SyncSteamDlc,
    [int]$DlcMaxGames = 0,
    [int]$DlcDelayMs = 1500,
    [switch]$ForceSteamDlc
)

$ErrorActionPreference = "Stop"

Write-Host "==> 0/12 Reparando páginas auxiliares y registry..."
& "$PSScriptRoot\09-repair-mdbook-pages.ps1"

Write-Host "==> 1/12 Sincronizando IDs..."
$idArgs = @("-UpdateTargets")
if ($DiscoverFromMarkdown) { $idArgs += "-DiscoverFromMarkdown" }
if ($RefreshMetadata) { $idArgs += "-RefreshMetadata" }
if ($ForceSearch) { $idArgs += "-ForceSearch" }
if ($AllowFuzzy) { $idArgs += "-AllowFuzzy" }
if ($AcceptFuzzyMatches) { $idArgs += "-AcceptFuzzyMatches" }
& "$PSScriptRoot\01-sync-steam-ids.ps1" @idArgs

Write-Host "==> 2/12 Descargando imágenes oficiales de Steam..."
$steamAssetArgs = @("-UpdateMarkdownPages")
if ($RefreshAssets) { $steamAssetArgs += "-RefreshAssets" }
& "$PSScriptRoot\02-download-steam-images.ps1" @steamAssetArgs

if ($UseSteamGridDb) {
    Write-Host "==> 3/12 Descargando assets de SteamGridDB..."
    $sgdbArgs = @("-SteamGridDbApiKey", $SteamGridDbApiKey, "-UpdateMarkdownPages")
    if ($RefreshSteamGridDb) { $sgdbArgs += "-RefreshSteamGridDb" }
    & "$PSScriptRoot\03-sync-steamgriddb-assets.ps1" @sgdbArgs
}
else {
    Write-Host "==> 3/12 SteamGridDB omitido."
}

Write-Host "==> 4/12 Generando páginas genéricas..."
& "$PSScriptRoot\04-generate-game-pages.ps1"

Write-Host "==> 5/12 Generando metadata base V6.6..."
& "$PSScriptRoot\14-generate-games-metadata-base.ps1"

if ($EnrichSteamMetadata) {
    Write-Host "==> 6/12 Enriqueciendo metadata desde Steam Store API..."

    # Hotfix V6.6.4:
    # Usar Join-Path evita que PowerShell interprete mal rutas tipo $PSScriptRoot\17...
    # y evita caracteres de control cuando el script se genera/edita automáticamente.
    $enrichScript = Join-Path $PSScriptRoot "17-enrich-steam-metadata.ps1"

    if (-not (Test-Path $enrichScript)) {
        throw "No se encontró el script de enriquecimiento: $enrichScript"
    }

    if ($MetadataMaxGames -gt 0 -and $ForceSteamMetadata) {
        & $enrichScript -DelayMs $MetadataDelayMs -MaxGames $MetadataMaxGames -Force
    }
    elseif ($MetadataMaxGames -gt 0) {
        & $enrichScript -DelayMs $MetadataDelayMs -MaxGames $MetadataMaxGames
    }
    elseif ($ForceSteamMetadata) {
        & $enrichScript -DelayMs $MetadataDelayMs -Force
    }
    else {
        & $enrichScript -DelayMs $MetadataDelayMs
    }
}
else {
    Write-Host "==> 6/12 Enriquecimiento Steam omitido. Usa -EnrichSteamMetadata para traer descripciones, géneros, modos y features."
}

if ($SyncSteamDlc) {
    Write-Host "==> 7/12 Sincronizando catálogo DLC desde Steam Store API..."
    $dlcScript = Join-Path $PSScriptRoot "18-sync-steam-dlc.ps1"

    if (-not (Test-Path $dlcScript)) {
        throw "No se encontró el script de DLC: $dlcScript"
    }

    if ($DlcMaxGames -gt 0 -and $ForceSteamDlc) {
        & $dlcScript -DelayMs $DlcDelayMs -MaxGames $DlcMaxGames -Force
    }
    elseif ($DlcMaxGames -gt 0) {
        & $dlcScript -DelayMs $DlcDelayMs -MaxGames $DlcMaxGames
    }
    elseif ($ForceSteamDlc) {
        & $dlcScript -DelayMs $DlcDelayMs -Force
    }
    else {
        & $dlcScript -DelayMs $DlcDelayMs
    }
}
else {
    Write-Host "==> 7/12 Sincronización DLC omitida. Usa -SyncSteamDlc para traer catálogo de DLC por juego."
}

Write-Host "==> 8/12 Generando games-index con metadata extendida..."
& "$PSScriptRoot\15-build-games-index-with-metadata.ps1"

Write-Host "==> 9/12 Generando preview de reglas de colección..."
& "$PSScriptRoot\16-preview-collection-rules.ps1"

Write-Host "==> 10/12 Actualizando fichas clave..."
& "$PSScriptRoot\06-update-key-game-pages.ps1"

if (-not $SkipCollectionTooltips) {
    Write-Host "==> 11/12 Actualizando tooltips de tablas..."
    & "$PSScriptRoot\07-generate-collection-tooltips.ps1"
}
else {
    Write-Host "==> 11/12 Tooltips de tablas omitidos."
}

Write-Host "==> 12/12 Reparando páginas auxiliares finales..."
& "$PSScriptRoot\09-repair-mdbook-pages.ps1"

if ($ValidatePaths) {
    & "$PSScriptRoot\08-export-local-assets-inventory.ps1"
    & "$PSScriptRoot\99-validate-project-paths.ps1" -Strict
}


Write-Host "==> Generando galería automática de assets..."
& "$PSScriptRoot\10-generate-assets-gallery.ps1"

Write-Host "==> Saneando SUMMARY de juegos..."
& "$PSScriptRoot\11-sanitize-games-summary.ps1"

Write-Host "Listo."
