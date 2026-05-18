<#
.SYNOPSIS
    Enriquece games-metadata.json con datos reales de la Steam Store API.

.DESCRIPTION
    Lee data/games-metadata.json y consulta la API pública de Steam Store:
        https://store.steampowered.com/api/appdetails?appids=APPID&l=spanish

    Actualiza descripción, fecha, desarrolladores, publishers, géneros, categorías,
    modos de juego y features de Steam. Después debe regenerarse games-index.json
    para que la ficha dinámica lo muestre en mdBook.

.PARAMETER DelayMs
    Milisegundos de espera entre llamadas a la API. Default: 1500.

.PARAMETER MaxGames
    Límite de juegos a procesar en esta ejecución. Default: 0 = todos los pendientes.

.PARAMETER Force
    Fuerza refresco aunque ya exista metadata.

.PARAMETER DryRun
    Muestra qué procesaría sin escribir cambios.

.PARAMETER BuildIndexAfter
    Ejecuta scripts/15-build-games-index-with-metadata.ps1 al terminar si hubo cambios.

.EXAMPLE
    .\scripts\17-enrich-steam-metadata.ps1 -MaxGames 100 -DelayMs 2000 -BuildIndexAfter

.EXAMPLE
    .\scripts\17-enrich-steam-metadata.ps1 -DryRun -MaxGames 20
#>

param(
    [int]$DelayMs = 1500,
    [int]$MaxGames = 0,
    [switch]$Force,
    [switch]$DryRun,
    [switch]$BuildIndexAfter
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$metadataPath = Join-Path $projectRoot "data\games-metadata.json"
$buildIndexScript = Join-Path $PSScriptRoot "15-build-games-index-with-metadata.ps1"

if (-not (Test-Path $metadataPath)) {
    Write-Error "No se encontró $metadataPath. Ejecuta primero .\scripts\14-generate-games-metadata-base.ps1"
    exit 1
}

function Get-ArrayCount($Value) {
    if ($null -eq $Value) { return 0 }
    return @($Value).Count
}

function Test-NeedsEnrichment($Game) {
    if ($Force) { return $true }
    if ($null -eq $Game.steamAppId) { return $false }

    $sm = $Game.steamMetadata
    if ($null -eq $sm) { return $true }

    $hasDescription = -not [string]::IsNullOrWhiteSpace([string]$sm.shortDescription)
    $hasGenres = (Get-ArrayCount $sm.genres) -gt 0
    $hasCategories = (Get-ArrayCount $sm.categories) -gt 0
    $hasDevelopers = (Get-ArrayCount $sm.developers) -gt 0
    $status = if ($Game.dataQuality) { [string]$Game.dataQuality.metadataStatus } else { "" }

    return (-not $hasDescription -or -not $hasGenres -or -not $hasCategories -or -not $hasDevelopers -or $status -eq "missing")
}

function Get-TextArray($Value) {
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-AnyPattern($Values, [string[]]$Patterns) {
    foreach ($v in (Get-TextArray $Values)) {
        $text = $v.ToLowerInvariant()
        foreach ($p in $Patterns) {
            if ($text -match $p) { return $true }
        }
    }
    return $false
}

function Set-ObjectProperty($Object, [string]$Name, $Value) {
    if ($null -eq $Object) { return }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
    else {
        $prop.Value = $Value
    }
}

function Set-ExistingPropertyIfNull($Object, [string]$Name, $Value) {
    if ($null -eq $Object) { return }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
    elseif ($null -eq $prop.Value) {
        $prop.Value = $Value
    }
}

function Ensure-ObjectProperty($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop -or $null -eq $prop.Value) {
        $newObject = [pscustomobject]@{}
        Set-ObjectProperty $Object $Name $newObject
        return $newObject
    }

    return $prop.Value
}

Write-Host "Leyendo $metadataPath..."
$metadataFile = Get-Content $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$games = @($metadataFile.games)

$needsEnrichment = @($games | Where-Object { Test-NeedsEnrichment $_ })
$totalPending = $needsEnrichment.Count
$totalToProcess = $totalPending
if ($MaxGames -gt 0 -and $MaxGames -lt $totalToProcess) { $totalToProcess = $MaxGames }

Write-Host "Juegos pendientes de enriquecer: $totalPending (de $($games.Count) totales)"
Write-Host "Juegos a procesar en esta corrida: $totalToProcess"
if ($DryRun) { Write-Host "[DRY RUN] No se escribirán cambios." }

$processed = 0
$success = 0
$failed = 0
$skipped = 0

foreach ($game in ($needsEnrichment | Select-Object -First $totalToProcess)) {
    $appId = [int]$game.steamAppId
    $title = [string]$game.title
    $processed++

    Write-Host "[$processed/$totalToProcess] AppID $appId — $title"

    try {
        $url = "https://store.steampowered.com/api/appdetails?appids=$appId&l=spanish"
        $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 20 -ErrorAction Stop
        $appData = $resp."$appId"

        if (-not $appData -or $appData.success -ne $true -or -not $appData.data) {
            Write-Host "  ⚠ Sin datos en Steam Store API"
            $skipped++
        }
        else {
            $data = $appData.data

            $genres = @($data.genres | ForEach-Object { $_.description } | Where-Object { $_ })
            $categories = @($data.categories | ForEach-Object { $_.description } | Where-Object { $_ })
            $developers = @($data.developers | Where-Object { $_ })
            $publishers = @($data.publishers | Where-Object { $_ })
            $releaseDate = if ($data.release_date -and -not $data.release_date.coming_soon) { $data.release_date.date } else { $null }
            $shortDesc = [string]$data.short_description
            $type = [string]$data.type

            $allCategoryText = @($categories + $genres)
            $singlePlayer = Test-AnyPattern $allCategoryText @("single[- ]player", "un jugador")
            $localMulti = Test-AnyPattern $allCategoryText @("local multiplayer", "multijugador local", "pantalla compartida", "shared/split")
            $onlineMulti = Test-AnyPattern $allCategoryText @("multi[- ]player", "multijugador", "online pvp", "jcj en línea", "jcj online")
            $localCoop = Test-AnyPattern $allCategoryText @("local co[- ]op", "cooperativo local", "shared/split.*co[- ]op", "cooperativo en pantalla")
            $onlineCoop = Test-AnyPattern $allCategoryText @("online co[- ]op", "cooperativo en línea", "cooperativo online")
            $pvp = Test-AnyPattern $allCategoryText @("pvp", "jcj")
            $pve = Test-AnyPattern $allCategoryText @("pve", "jce", "cooperativo")
            $mmo = Test-AnyPattern $allCategoryText @("massively multiplayer", "multijugador masivo", "mmo")

            $achievements = Test-AnyPattern $categories @("steam achievements", "logros de steam")
            $cloud = Test-AnyPattern $categories @("steam cloud", "guardado en la nube")
            $fullController = Test-AnyPattern $categories @("full controller support", "compatibilidad total con mandos", "mando completo")
            $partialController = Test-AnyPattern $categories @("partial controller support", "compatibilidad parcial con mando", "mando parcial")
            $remotePlay = Test-AnyPattern $categories @("remote play together")
            $workshop = Test-AnyPattern $categories @("steam workshop", "workshop")
            $tradingCards = Test-AnyPattern $categories @("steam trading cards", "cromos de steam", "trading cards")
            $vrSupported = Test-AnyPattern $categories @("vr supported", "compatible con vr", "solo RV", "realidad virtual")

            if ($DryRun) {
                Write-Host "  → Géneros: $($genres -join ', ')"
                Write-Host "  → Categorías: $($categories -join ', ')"
                Write-Host "  → Descripción: $([bool]$shortDesc) | Single: $singlePlayer | Online: $onlineMulti | VR: $vrSupported"
            }
            else {
                $steamMetadata = Ensure-ObjectProperty $game "steamMetadata"
                $playModes = Ensure-ObjectProperty $game "playModes"
                $steamFeatures = Ensure-ObjectProperty $game "steamFeatures"
                $dataQuality = Ensure-ObjectProperty $game "dataQuality"

                Set-ObjectProperty $steamMetadata "releaseDate" $releaseDate
                Set-ObjectProperty $steamMetadata "developers" $developers
                Set-ObjectProperty $steamMetadata "publishers" $publishers
                Set-ObjectProperty $steamMetadata "genres" $genres
                Set-ObjectProperty $steamMetadata "categories" $categories
                Set-ObjectProperty $steamMetadata "tags" @()
                Set-ObjectProperty $steamMetadata "shortDescription" $shortDesc
                Set-ObjectProperty $steamMetadata "sourceNotes" @("Steam Store API appdetails; tags populares no disponibles por esta API pública.")
                if (-not [string]::IsNullOrWhiteSpace($type)) { Set-ObjectProperty $game "type" $type }

                Set-ExistingPropertyIfNull $playModes "singlePlayer" $singlePlayer
                Set-ExistingPropertyIfNull $playModes "localMultiplayer" $localMulti
                Set-ExistingPropertyIfNull $playModes "onlineMultiplayer" $onlineMulti
                Set-ExistingPropertyIfNull $playModes "localCoop" $localCoop
                Set-ExistingPropertyIfNull $playModes "onlineCoop" $onlineCoop
                Set-ExistingPropertyIfNull $playModes "pvp" $pvp
                Set-ExistingPropertyIfNull $playModes "pve" $pve
                Set-ExistingPropertyIfNull $playModes "mmo" $mmo

                Set-ExistingPropertyIfNull $steamFeatures "achievements" $achievements
                Set-ExistingPropertyIfNull $steamFeatures "cloudSaves" $cloud
                Set-ExistingPropertyIfNull $steamFeatures "fullControllerSupport" $fullController
                Set-ExistingPropertyIfNull $steamFeatures "partialControllerSupport" $partialController
                Set-ExistingPropertyIfNull $steamFeatures "remotePlayTogether" $remotePlay
                Set-ExistingPropertyIfNull $steamFeatures "workshop" $workshop
                Set-ExistingPropertyIfNull $steamFeatures "tradingCards" $tradingCards
                Set-ExistingPropertyIfNull $steamFeatures "vrSupported" $vrSupported

                Set-ObjectProperty $dataQuality "metadataStatus" "steam-api"
                Set-ObjectProperty $dataQuality "lastEnrichedAt" (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }

            Write-Host "  ✅ OK"
            $success++
        }
    }
    catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)"
        $failed++
    }

    if ($processed -lt $totalToProcess -and $DelayMs -gt 0) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

if (-not $DryRun -and $success -gt 0) {
    $metadataFile.updatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $metadataFile | ConvertTo-Json -Depth 30 | Set-Content $metadataPath -Encoding UTF8
    Write-Host ""
    Write-Host "✅ Guardado en $metadataPath"
    Write-Host "   Actualizados: $success | Fallidos: $failed | Sin datos: $skipped"

    if ($BuildIndexAfter) {
        Write-Host ""
        Write-Host "Regenerando games-index con metadata extendida..."
        & $buildIndexScript
    }
    else {
        Write-Host ""
        Write-Host "Siguiente paso obligatorio para verlo en mdBook:"
        Write-Host "  .\scripts\15-build-games-index-with-metadata.ps1"
    }
}
elseif ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Sin cambios escritos. Procesados: $processed | OK simulados: $success | Fallidos: $failed | Sin datos: $skipped"
}
else {
    Write-Host "Sin cambios que guardar. OK: $success | Fallidos: $failed | Sin datos: $skipped"
}
