param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$MetadataPath = ".\data\games-metadata.json",
    [string]$OutputPath = ".\src\assets\data\games-index.json"
)

$ErrorActionPreference = "Stop"
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$metadata = Get-Content $MetadataPath -Raw | ConvertFrom-Json
$metaById = @{}
foreach ($m in @($metadata.games)) { $metaById[[int]$m.steamAppId] = $m }

$index = @()
foreach ($g in $registry) {
    $appId = [int]$g.steamAppId
    $m = $metaById[$appId]
    $images = $g.images
    $index += [ordered]@{
        title = $g.title; slug = $g.slug; aliases = @($g.aliases); steamAppId = $appId; officialName = $g.officialName; steamType = $g.steamType; matchType = $g.matchType; preferredImageSource = $g.preferredImageSource
        steamUrl = "https://store.steampowered.com/app/$appId"; playUrl = "steam://run/$appId"; installUrl = "steam://install/$appId"
        assets = [ordered]@{ steamHeader = $images.steamHeader; steamCapsule = $images.steamCapsule; steamBackground = $images.steamBackground; sgdbHero = $images.sgdbHero; sgdbGrid = $images.sgdbGrid; sgdbLogo = $images.sgdbLogo; sgdbIcon = $images.sgdbIcon }
        metadata = $m.steamMetadata
        steamMetadata = $m.steamMetadata; playModes = $m.playModes; steamFeatures = $m.steamFeatures; dlcInfo = $m.dlcInfo; playerState = $m.playerState; recommendationMetadata = $m.recommendationMetadata; profileMetadata = $m.profileMetadata; libraryPlacement = $m.libraryPlacement; platforms = $m.platforms; dataQuality = $m.dataQuality
    }
}
$index = $index | Sort-Object title, steamAppId
New-Item -ItemType Directory -Force (Split-Path $OutputPath) | Out-Null
$index | ConvertTo-Json -Depth 30 | Set-Content $OutputPath -Encoding UTF8
Write-Host "games-index generado con metadata extendida: $($index.Count) juegos."
