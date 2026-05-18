<#
.SYNOPSIS
    Descarga imágenes oficiales de Steam para los juegos registrados.
.DESCRIPTION
    Usa `data/steam-games-registry.json` para descargar headers/capsules/backgrounds hacia
    `src/assets/games/<steamAppId>/`. Puede actualizar páginas Markdown para apuntar a assets locales.
.PARAMETER UpdateMarkdownPages
    Actualiza referencias de imagen dentro de páginas Markdown generadas.
.PARAMETER RefreshAssets
    Redescarga assets aunque ya existan localmente.
.PARAMETER WhatIfMode
    Simula la corrida sin escribir archivos.
.EXAMPLE
    .\scripts\02-download-steam-images.ps1 -UpdateMarkdownPages -DelayMs 2500
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$ReportCsvPath = ".\data\steam-assets-report.csv",
    [string]$ReportJsonPath = ".\data\steam-assets-report.json",
    [string]$RetryPath = ".\data\steam-games-retry-needed.json",
    [string]$ReviewPath = ".\data\steam-games-review-needed.json",
    [switch]$UpdateMarkdownPages,
    [switch]$WhatIfMode,
    [switch]$RefreshAssets,
    [int]$DelayMs = 1200,
    [string]$Language = "english"
)

. "$PSScriptRoot\_registry-lib.ps1"
$script:RefreshAssetsGlobal = $RefreshAssets.IsPresent

$registry = @(Load-JsonFile $RegistryPath @())
$report = @()
$retry = @(Load-JsonFile $RetryPath @())
$review = @(Load-JsonFile $ReviewPath @())
$cleanRegistry = @()

foreach ($game in $registry) {
    $rawAppId = $game.steamAppId
    $appid = 0
    [int]::TryParse([string]$rawAppId, [ref]$appid) | Out-Null

    $title = [string]$game.title
    $slug = [string]$game.slug

    if ($appid -le 0) {
        Write-Warn "AppId inválido, se manda a revisión: $title / $rawAppId"

        $review += [pscustomobject]@{
            title = $title
            slug = $slug
            detectedSteamAppId = $rawAppId
            detectedName = $game.officialName
            matchType = if ($game.matchType) { $game.matchType } else { "invalid-appid" }
            steamType = $game.steamType
            reason = "steamAppId inválido o 0; no se consulta Steam con appids=0"
            updatedAt = (Get-Date).ToString("s")
        }

        $report += [pscustomobject]@{
            title = $title
            slug = $slug
            steamAppId = $rawAppId
            officialName = $game.officialName
            preferredImageSource = $game.preferredImageSource
            preferredImage = ""
            success = $false
            notes = "SKIP invalid appid"
        }

        continue
    }

    $cleanRegistry += $game

    $header = "src/assets/games/$appid/steam-header.jpg"
    $capsule = "src/assets/games/$appid/steam-capsule.jpg"
    $background = "src/assets/games/$appid/steam-background.jpg"

    if ((-not $RefreshAssets) -and (Test-Path ".\$header") -and (Test-Path ".\$capsule") -and (Test-Path ".\$background")) {
        Write-Ok "Assets existentes, skip: $title"
        $report += [pscustomobject]@{
            title = $title
            slug = $slug
            steamAppId = $appid
            officialName = $game.officialName
            preferredImageSource = $game.preferredImageSource
            preferredImage = $header
            success = $true
            notes = "SKIP existing assets"
        }
        continue
    }

    try {
        Start-Sleep -Milliseconds $DelayMs
        $details = Get-AppDetails -AppId $appid -Language $Language
        $node = $details."$appid"

        if (-not $node.success) {
            Write-Warn "No appdetails: $title / $appid"

            $review += [pscustomobject]@{
                title = $title
                slug = $slug
                detectedSteamAppId = $appid
                detectedName = $game.officialName
                matchType = $game.matchType
                steamType = $game.steamType
                reason = "appdetails success=false"
                updatedAt = (Get-Date).ToString("s")
            }

            continue
        }

        $data = $node.data

        Download-FileSafe -Url $data.header_image -OutFile ".\$header" -WhatIfMode:$WhatIfMode | Out-Null
        Download-FileSafe -Url $data.capsule_image -OutFile ".\$capsule" -WhatIfMode:$WhatIfMode | Out-Null

        $bgUrl = $data.background_raw
        if (-not $bgUrl) { $bgUrl = $data.background }
        Download-FileSafe -Url $bgUrl -OutFile ".\$background" -WhatIfMode:$WhatIfMode | Out-Null

        $game.officialName = $data.name
        $game.steamType = $data.type
        $game.preferredImageSource = "steam"
        $game.preferredImageForMdBook = "../assets/games/$appid/steam-header.jpg"
        $game.images.steamHeader = $header
        $game.images.steamCapsule = $capsule
        $game.images.steamBackground = $background
        $game.updatedAt = (Get-Date).ToString("s")

        if ($UpdateMarkdownPages -and (-not $WhatIfMode)) {
            Update-GamePageImageById -Slug $slug -SteamAppId $appid -Title $title -RelativeImage "../assets/games/$appid/steam-header.jpg"
        }

        $report += [pscustomobject]@{
            title = $title
            slug = $slug
            steamAppId = $appid
            officialName = $data.name
            preferredImageSource = "steam"
            preferredImage = $header
            success = $true
            notes = "OK"
        }

        Write-Ok "$title -> assets oficiales"
    }
    catch {
        $msg = $_.Exception.Message

        $report += [pscustomobject]@{
            title = $title
            slug = $slug
            steamAppId = $appid
            officialName = $game.officialName
            preferredImageSource = "steam"
            preferredImage = ""
            success = $false
            notes = $msg
        }

        if (Test-RateLimit429 $msg) {
            $retry += [pscustomobject]@{
                title = $title
                slug = $slug
                detectedSteamAppId = $appid
                detectedName = $game.officialName
                matchType = $game.matchType
                reason = $msg
                retryReason = "Rate limit al descargar imágenes oficiales"
                updatedAt = (Get-Date).ToString("s")
            }
        }
        else {
            $review += [pscustomobject]@{
                title = $title
                slug = $slug
                detectedSteamAppId = $appid
                detectedName = $game.officialName
                matchType = $game.matchType
                steamType = $game.steamType
                reason = $msg
                updatedAt = (Get-Date).ToString("s")
            }
        }

        Write-Warn "$title / ${appid}: $msg"
    }
}

if (-not $WhatIfMode) {
    Save-JsonFile $RegistryPath ($cleanRegistry | Sort-Object title) 12
    $report | Export-Csv -Path $ReportCsvPath -NoTypeInformation -Encoding UTF8
    Save-JsonFile $ReportJsonPath $report 8
    Save-JsonFile $RetryPath ($retry | Sort-Object title) 8
    Save-JsonFile $ReviewPath ($review | Sort-Object title) 8
}

Write-Step "Assets Steam procesados."
