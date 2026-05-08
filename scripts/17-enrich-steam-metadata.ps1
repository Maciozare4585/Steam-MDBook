<#
.SYNOPSIS
    Enriquece games-metadata.json con datos reales de la Steam Store API.

.DESCRIPTION
    Lee games-metadata.json y para cada juego que tenga steamMetadata vacío
    (sin genres, tags, developers, etc.) consulta la API pública de Steam:
        https://store.steampowered.com/api/appdetails?appids=APPID&l=spanish

    Escribe los campos recuperados de vuelta en games-metadata.json.
    Respeta un delay configurable para no saturar la API.

.PARAMETER DelayMs
    Milisegundos de espera entre llamadas a la API. Default: 1500.

.PARAMETER MaxGames
    Límite de juegos a procesar en esta ejecución. Útil para runs parciales.
    Default: 0 (sin límite).

.PARAMETER Force
    Si se especifica, sobreescribe metadata aunque ya exista.

.PARAMETER DryRun
    Imprime qué haría sin escribir nada.

.EXAMPLE
    # Enriquecer los primeros 50 juegos sin metadata
    .\scripts\17-enrich-steam-metadata.ps1 -MaxGames 50

    # Ver qué haría sin tocar nada
    .\scripts\17-enrich-steam-metadata.ps1 -DryRun -MaxGames 10

    # Forzar refresco de todos los juegos (lento)
    .\scripts\17-enrich-steam-metadata.ps1 -Force -DelayMs 2000
#>

param(
    [int]$DelayMs = 1500,
    [int]$MaxGames = 0,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$metadataPath = Join-Path $PSScriptRoot "..\data\games-metadata.json"
$metadataPath = Resolve-Path $metadataPath

if (-not (Test-Path $metadataPath)) {
    Write-Error "No se encontró $metadataPath. Ejecuta primero 14-generate-games-metadata-base.ps1"
    exit 1
}

Write-Host "Leyendo $metadataPath..."
$metadataFile = Get-Content $metadataPath -Raw | ConvertFrom-Json
$games = $metadataFile.games

# Filtrar juegos que necesitan enriquecimiento
$needsEnrichment = if ($Force) {
    $games
} else {
    $games | Where-Object {
        $_.steamMetadata -and
        (
            ($null -eq $_.steamMetadata.genres -or $_.steamMetadata.genres.Count -eq 0) -and
            ($null -eq $_.steamMetadata.tags   -or $_.steamMetadata.tags.Count   -eq 0)
        )
    }
}

$total = $needsEnrichment.Count
if ($MaxGames -gt 0 -and $MaxGames -lt $total) { $total = $MaxGames }

Write-Host "Juegos a enriquecer: $total (de $($games.Count) totales)"
if ($DryRun) { Write-Host "[DRY RUN] No se escribirán cambios." }

$processed = 0
$success   = 0
$failed    = 0
$skipped   = 0

foreach ($game in ($needsEnrichment | Select-Object -First $total)) {
    $appId = $game.steamAppId
    $title = $game.title

    Write-Host "[$($processed + 1)/$total] AppID $appId — $title"

    try {
        $url = "https://store.steampowered.com/api/appdetails?appids=$appId&l=spanish"
        $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 12 -ErrorAction Stop
        $appData = $resp."$appId"

        if (-not $appData -or $appData.success -ne $true) {
            Write-Host "  ⚠ Sin datos en Steam (success=false o vacío)"
            $skipped++
        } else {
            $data = $appData.data

            # Extraer campos relevantes
            $genres     = @($data.genres | ForEach-Object { $_.description } | Where-Object { $_ })
            $categories = @($data.categories | ForEach-Object { $_.description } | Where-Object { $_ })
            $tags       = @($data.genres | ForEach-Object { $_.description })  # Steam no expone tags populares en esta API sin auth
            $developers = @($data.developers | Where-Object { $_ })
            $publishers = @($data.publishers | Where-Object { $_ })
            $releaseDate = if ($data.release_date -and -not $data.release_date.coming_soon) { $data.release_date.date } else { $null }
            $shortDesc  = $data.short_description
            $isFree     = $data.is_free -eq $true
            $type       = $data.type

            # Modos de juego desde categorías
            $catNames = $categories | ForEach-Object { $_.ToLower() }
            $singlePlayer     = ($catNames -contains "single-player") -or ($catNames -contains "un jugador")
            $localMulti       = ($catNames -contains "local multiplayer") -or ($catNames -contains "multi-jugador local")
            $onlineMulti      = ($catNames -contains "multi-player") -or ($catNames -contains "online pvp") -or ($catNames -contains "multijugador en línea")
            $localCoop        = ($catNames -contains "local co-op")
            $onlineCoop       = ($catNames -contains "online co-op")
            $achievements     = ($catNames -contains "steam achievements") -or ($catNames -contains "logros de steam")
            $cloud            = ($catNames -contains "steam cloud")
            $fullController   = ($catNames -contains "full controller support") -or ($catNames -contains "compatibilidad total con mandos")
            $partialController = ($catNames -contains "partial controller support")
            $remotePlay       = ($catNames -contains "remote play together")
            $workshop         = ($catNames -contains "steam workshop")
            $tradingCards     = ($catNames -contains "steam trading cards")
            $vrSupported      = ($catNames -contains "vr supported") -or ($catNames -contains "compatible con vr")

            if ($DryRun) {
                Write-Host "  → Géneros: $($genres -join ', ')"
                Write-Host "  → Devs: $($developers -join ', ')"
                Write-Host "  → Single: $singlePlayer | Online: $onlineMulti | VR: $vrSupported"
            } else {
                # Actualizar steamMetadata
                $game.steamMetadata.genres           = $genres
                $game.steamMetadata.categories       = $categories
                $game.steamMetadata.developers       = $developers
                $game.steamMetadata.publishers       = $publishers
                $game.steamMetadata.releaseDate      = $releaseDate
                $game.steamMetadata.shortDescription = $shortDesc
                if ($type) { $game.type = $type }

                # Actualizar playModes (solo si todavía son null)
                if ($null -eq $game.playModes.singlePlayer)      { $game.playModes.singlePlayer      = $singlePlayer }
                if ($null -eq $game.playModes.localMultiplayer)  { $game.playModes.localMultiplayer  = $localMulti }
                if ($null -eq $game.playModes.onlineMultiplayer) { $game.playModes.onlineMultiplayer = $onlineMulti }
                if ($null -eq $game.playModes.localCoop)         { $game.playModes.localCoop         = $localCoop }
                if ($null -eq $game.playModes.onlineCoop)        { $game.playModes.onlineCoop        = $onlineCoop }

                # Actualizar steamFeatures
                if ($null -eq $game.steamFeatures.achievements)           { $game.steamFeatures.achievements           = $achievements }
                if ($null -eq $game.steamFeatures.cloudSaves)             { $game.steamFeatures.cloudSaves             = $cloud }
                if ($null -eq $game.steamFeatures.fullControllerSupport)  { $game.steamFeatures.fullControllerSupport  = $fullController }
                if ($null -eq $game.steamFeatures.partialControllerSupport){ $game.steamFeatures.partialControllerSupport = $partialController }
                if ($null -eq $game.steamFeatures.remotePlayTogether)     { $game.steamFeatures.remotePlayTogether     = $remotePlay }
                if ($null -eq $game.steamFeatures.workshop)               { $game.steamFeatures.workshop               = $workshop }
                if ($null -eq $game.steamFeatures.tradingCards)           { $game.steamFeatures.tradingCards           = $tradingCards }
                if ($null -eq $game.steamFeatures.vrSupported)            { $game.steamFeatures.vrSupported            = $vrSupported }

                # Marcar calidad del dato
                if ($game.dataQuality) {
                    $game.dataQuality.metadataStatus = "steam-api"
                    $game.dataQuality.lastEnrichedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                }
            }

            Write-Host "  ✅ OK"
            $success++
        }
    } catch {
        Write-Host "  ❌ Error: $_"
        $failed++
    }

    $processed++
    Start-Sleep -Milliseconds $DelayMs
}

# Guardar si no es DryRun y hubo éxitos
if (-not $DryRun -and $success -gt 0) {
    $metadataFile.updatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    $metadataFile | ConvertTo-Json -Depth 20 | Set-Content $metadataPath -Encoding UTF8
    Write-Host ""
    Write-Host "✅ Guardado en $metadataPath"
    Write-Host "   Actualizados: $success | Fallidos: $failed | Sin datos: $skipped"
    Write-Host ""
    Write-Host "Siguiente paso: regenerar games-index con metadata extendida"
    Write-Host "  .\scripts\15-build-games-index-with-metadata.ps1"
} elseif ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Sin cambios escritos. Procesados: $processed"
} else {
    Write-Host "Sin cambios que guardar."
}
