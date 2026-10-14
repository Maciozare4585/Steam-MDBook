<#
.SYNOPSIS
    Genera o actualiza la metadata base V6.6.
.DESCRIPTION
    Asegura que cada juego del registry tenga entrada en `data/games-metadata.json` con estructura para
    Steam metadata, modos, features, DLC, estado personal, recomendaciones, perfiles y calidad de datos.
.EXAMPLE
    .\scripts\14-generate-games-metadata-base.ps1
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$MetadataPath = ".\data\games-metadata.json",
    [switch]$OverwriteMissingOnly
)

$ErrorActionPreference = "Stop"

function New-DefaultGameMetadata($game) {
    $appId = [int]$game.steamAppId
    return [ordered]@{
        canonicalId = "steam:$appId"
        steamAppId = $appId
        title = $game.title
        officialName = $game.officialName
        slug = $game.slug
        type = $game.steamType
        steamMetadata = [ordered]@{
            releaseDate = $null; developers = @(); publishers = @(); genres = @(); categories = @(); tags = @(); shortDescription = $null; sourceNotes = @()
        }
        playModes = [ordered]@{
            singlePlayer = $null; localMultiplayer = $null; onlineMultiplayer = $null; localCoop = $null; onlineCoop = $null; pvp = $null; pve = $null; mmo = $null; crossPlatform = $null
        }
        steamFeatures = [ordered]@{
            achievements = $null; cloudSaves = $null; fullControllerSupport = $null; partialControllerSupport = $null; remotePlayTogether = $null; workshop = $null; tradingCards = $null; vrSupported = $null
        }
        dlcInfo = [ordered]@{
            hasDlc = $false; totalDlcCount = 0; ownedDlcCount = 0; missingDlcCount = 0; dlcs = @(); ownershipStatus = "unknown"; ownershipSummary = $null; missingNotes = @(); manualSource = $null; lastManualUpdateAt = $null
        }
        playerState = [ordered]@{
            mainStatus = "sin_empezar"
            checkboxes = [ordered]@{
                tried = $false; started = $false; finishedMainStory = $false; finishedPostGame = $false; completed100Percent = $false; abandoned = $false; discarded = $false; installed = $false; favorite = $false; wantsToPlay = $false; wantsToFinish = $false; wantsToReplay = $false; wantsToPlatinum = $false; needsRestart = $false; needsPreviousGame = $false; goodForCoop = $false; comfortGame = $false; riskOfAutopilot = $false
            }
        }
        recommendationMetadata = [ordered]@{
            playRole = $null; energyRequired = $null; sessionLength = $null; friction = $null; reentryCost = $null; storyDependency = $null; focusRequired = $null; difficulty = $null; pacing = $null; moodTags = @(); goodFor = @(); avoidWhen = @(); recommendedAs = @()
        }
        profileMetadata = [ordered]@{
            daniel = [ordered]@{ importanceLevel = "normal"; meaningType = @(); personalSummary = $null; whyItMatters = $null; memories = @(); profileTags = @(); profileCollections = @(); visibility = "normal"; recommendationBias = [ordered]@{ boostWhenMood = @(); avoidWhenMood = @() } }
            jesse = [ordered]@{ importanceLevel = "normal"; meaningType = @(); personalSummary = $null; whyItMatters = $null; memories = @(); profileTags = @(); profileCollections = @(); visibility = "normal"; recommendationBias = [ordered]@{ boostWhenMood = @(); avoidWhenMood = @() } }
            jovan = [ordered]@{ importanceLevel = "normal"; meaningType = @(); personalSummary = $null; whyItMatters = $null; memories = @(); profileTags = @(); profileCollections = @(); visibility = "normal"; recommendationBias = [ordered]@{ boostWhenMood = @(); avoidWhenMood = @() } }
        }
        libraryPlacement = [ordered]@{ collections = @(); states = @(); profiles = @(); technicalCollections = @(); quarantineSource = $null; duplicateReason = $null; manualCollections = @(); autoCollections = @(); suggestedCollections = @(); excludedCollections = @() }
        platforms = [ordered]@{ steam = [ordered]@{ owned = $true; appId = $appId; storeUrl = "https://store.steampowered.com/app/$appId"; launchUrl = "steam://run/$appId"; installUrl = "steam://install/$appId" } }
        dataQuality = [ordered]@{ metadataStatus = "missing"; idConfidence = $game.matchType; needsReview = $false; warnings = @(); lastSyncedAt = (Get-Date).ToString("o") }
    }
}

$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$existing = if (Test-Path $MetadataPath) { Get-Content $MetadataPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{ version = "6.6.0"; games = @() } }
$existingById = @{}
foreach ($g in @($existing.games)) { $existingById[[int]$g.steamAppId] = $g }

$games = @()
foreach ($game in $registry) {
    $appId = [int]$game.steamAppId
    if ($existingById.ContainsKey($appId)) { $games += $existingById[$appId] }
    else { $games += (New-DefaultGameMetadata $game) }
}

$out = [ordered]@{ version = "6.6.0"; updatedAt = (Get-Date).ToString("o"); games = $games }
$out | ConvertTo-Json -Depth 30 | Set-Content $MetadataPath -Encoding UTF8
Write-Host "Metadata base generada: $($games.Count) juegos."
