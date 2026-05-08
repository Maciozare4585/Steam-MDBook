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
    [switch]$ValidatePaths
)

$ErrorActionPreference = "Stop"

Write-Host "==> 0/10 Reparando páginas auxiliares y registry..."
& "$PSScriptRoot\09-repair-mdbook-pages.ps1"

Write-Host "==> 1/10 Sincronizando IDs..."
$idArgs = @("-UpdateTargets")
if ($DiscoverFromMarkdown) { $idArgs += "-DiscoverFromMarkdown" }
if ($RefreshMetadata) { $idArgs += "-RefreshMetadata" }
if ($ForceSearch) { $idArgs += "-ForceSearch" }
if ($AllowFuzzy) { $idArgs += "-AllowFuzzy" }
if ($AcceptFuzzyMatches) { $idArgs += "-AcceptFuzzyMatches" }
& "$PSScriptRoot\01-sync-steam-ids.ps1" @idArgs

Write-Host "==> 2/10 Descargando imágenes oficiales de Steam..."
$steamAssetArgs = @("-UpdateMarkdownPages")
if ($RefreshAssets) { $steamAssetArgs += "-RefreshAssets" }
& "$PSScriptRoot\02-download-steam-images.ps1" @steamAssetArgs

if ($UseSteamGridDb) {
    Write-Host "==> 3/10 Descargando assets de SteamGridDB..."
    $sgdbArgs = @("-SteamGridDbApiKey", $SteamGridDbApiKey, "-UpdateMarkdownPages")
    if ($RefreshSteamGridDb) { $sgdbArgs += "-RefreshSteamGridDb" }
    & "$PSScriptRoot\03-sync-steamgriddb-assets.ps1" @sgdbArgs
}
else {
    Write-Host "==> 3/10 SteamGridDB omitido."
}

Write-Host "==> 4/10 Generando páginas genéricas..."
& "$PSScriptRoot\04-generate-game-pages.ps1"

Write-Host "==> 5/10 Generando metadata base V6.6..."
& "$PSScriptRoot\14-generate-games-metadata-base.ps1"

Write-Host "==> 6/10 Generando games-index con metadata extendida..."
& "$PSScriptRoot\15-build-games-index-with-metadata.ps1"

Write-Host "==> 7/10 Generando preview de reglas de colección..."
& "$PSScriptRoot\16-preview-collection-rules.ps1"

Write-Host "==> 8/10 Actualizando fichas clave..."
& "$PSScriptRoot\06-update-key-game-pages.ps1"

if (-not $SkipCollectionTooltips) {
    Write-Host "==> 9/10 Actualizando tooltips de tablas..."
    & "$PSScriptRoot\07-generate-collection-tooltips.ps1"
}
else {
    Write-Host "==> 9/10 Tooltips de tablas omitidos."
}

Write-Host "==> 10/10 Reparando páginas auxiliares finales..."
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
