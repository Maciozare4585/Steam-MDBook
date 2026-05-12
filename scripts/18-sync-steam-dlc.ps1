<#
.SYNOPSIS
    Sincroniza el catálogo de DLC disponibles en Steam para cada juego.

.DESCRIPTION
    Lee data/games-metadata.json, consulta Steam Store API appdetails y llena dlcInfo.dlcs
    con una fila por DLC detectado.

    Ahora también puede conservar o inicializar un campo manual `marker` para la UI del mdBook.
    Valores sugeridos: owned, missing, skip, soundtrack, artbook, cosmetic, currency, pass, free.

    El script respeta ownership manual ya existente cuando puede empatar por appId o nombre.
    Si un juego ya estaba marcado como ownershipStatus = "full", marca todos los DLC detectados como propios.

.PARAMETER DelayMs
    Milisegundos de espera entre llamadas a Steam. Default: 1500.

.PARAMETER MaxGames
    Máximo de juegos a procesar. 0 = todos.

.PARAMETER OnlyAppIds
    Lista opcional de Steam AppIDs de juegos base a procesar.

.PARAMETER Force
    Vuelve a consultar aunque dlcInfo ya tenga catalogSource = steam-store-api.

.PARAMETER DryRun
    Muestra qué cambiaría sin escribir archivos.

.PARAMETER BuildIndexAfter
    Regenera src/assets/data/games-index.json al terminar.

.EXAMPLE
    .\scripts\18-sync-steam-dlc.ps1 -MaxGames 50 -DelayMs 2000 -BuildIndexAfter

.EXAMPLE
    .\scripts\18-sync-steam-dlc.ps1 -OnlyAppIds 1245620,292030 -DelayMs 2000 -BuildIndexAfter
#>

param(
    [int]$DelayMs = 1500,
    [int]$MaxGames = 0,
    [int[]]$OnlyAppIds = @(),
    [switch]$Force,
    [switch]$DryRun,
    [switch]$BuildIndexAfter
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$metadataPath = Join-Path $projectRoot "data\games-metadata.json"
$reportPath = Join-Path $projectRoot "data\dlc-sync-report.json"
$buildIndexScript = Join-Path $PSScriptRoot "15-build-games-index-with-metadata.ps1"

if (-not (Test-Path $metadataPath)) {
    Write-Error "No se encontró $metadataPath. Ejecuta primero .\scripts\14-generate-games-metadata-base.ps1"
    exit 1
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

function Get-Array($Value) {
    if ($null -eq $Value) { return @() }
    return @($Value)
}

function Normalize-Key([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    return ($Value.ToLowerInvariant() -replace '[^a-z0-9áéíóúüñ]+', ' ').Trim()
}

function Test-TitleMatch([string]$ExistingTitle, [string]$IncomingTitle) {
    $a = Normalize-Key $ExistingTitle
    $b = Normalize-Key $IncomingTitle
    if ([string]::IsNullOrWhiteSpace($a) -or [string]::IsNullOrWhiteSpace($b)) { return $false }
    return ($a -eq $b -or $a.Contains($b) -or $b.Contains($a))
}

function Get-ManualOwnedFromExisting($ExistingDlcs, $IncomingAppId, [string]$IncomingTitle, [bool]$FullOwnership) {
    if ($FullOwnership) { return $true }

    foreach ($existing in (Get-Array $ExistingDlcs)) {
        $existingAppId = $null
        if ($existing.PSObject.Properties['appId'] -and $null -ne $existing.appId) {
            try { $existingAppId = [int]$existing.appId } catch { $existingAppId = $null }
        }

        if ($existingAppId -and $IncomingAppId -and $existingAppId -eq $IncomingAppId) {
            if ($null -ne $existing.owned) { return [bool]$existing.owned }
        }

        if (Test-TitleMatch ([string]$existing.title) $IncomingTitle) {
            if ($null -ne $existing.owned) { return [bool]$existing.owned }
        }
    }

    return $false
}

function Get-ManualStatusFromExisting($ExistingDlcs, $IncomingAppId, [string]$IncomingTitle, [bool]$Owned) {
    foreach ($existing in (Get-Array $ExistingDlcs)) {
        $existingAppId = $null
        if ($existing.PSObject.Properties['appId'] -and $null -ne $existing.appId) {
            try { $existingAppId = [int]$existing.appId } catch { $existingAppId = $null }
        }

        $matches = ($existingAppId -and $IncomingAppId -and $existingAppId -eq $IncomingAppId) -or (Test-TitleMatch ([string]$existing.title) $IncomingTitle)
        if ($matches -and $existing.PSObject.Properties['status'] -and -not [string]::IsNullOrWhiteSpace([string]$existing.status)) {
            return [string]$existing.status
        }
    }

    if ($Owned) { return "propio" }
    return "pendiente_manual"
}



function Normalize-DlcMarker([string]$Marker) {
    if ([string]::IsNullOrWhiteSpace($Marker)) { return $null }

    $key = $Marker.Trim().ToLowerInvariant() -replace '[\s-]+', '_'
    $map = @{
        yes = 'owned'; owned = 'owned'; propio = 'owned'; lo_tenemos = 'owned'
        no = 'missing'; missing = 'missing'; faltante = 'missing'; pendiente = 'missing'
        skip = 'skip'; no_comprar = 'skip'; descartado = 'skip'; not_buying = 'skip'
        soundtrack = 'soundtrack'; ost = 'soundtrack'; banda_sonora = 'soundtrack'
        artbook = 'artbook'; bookart = 'artbook'; book_art = 'artbook'; digital_artbook = 'artbook'
        cosmetic = 'cosmetic'; skin = 'cosmetic'; outfit = 'cosmetic'
        currency = 'currency'; moneda = 'currency'; coins = 'currency'; gems = 'currency'
        pass = 'pass'; season_pass = 'pass'; expansion_pass = 'pass'
        free = 'free'; gratis = 'free'
    }

    if ($map.ContainsKey($key)) { return $map[$key] }
    return $key
}

function Get-ManualMarkerFromExisting($ExistingDlcs, $IncomingAppId, [string]$IncomingTitle, [bool]$Owned) {
    foreach ($existing in (Get-Array $ExistingDlcs)) {
        $existingAppId = $null
        if ($existing.PSObject.Properties['appId'] -and $null -ne $existing.appId) {
            try { $existingAppId = [int]$existing.appId } catch { $existingAppId = $null }
        }

        $matches = ($existingAppId -and $IncomingAppId -and $existingAppId -eq $IncomingAppId) -or (Test-TitleMatch ([string]$existing.title) $IncomingTitle)
        if ($matches) {
            foreach ($name in @('marker', 'iconMarker', 'icon')) {
                if ($existing.PSObject.Properties[$name] -and -not [string]::IsNullOrWhiteSpace([string]$existing.$name)) {
                    return (Normalize-DlcMarker ([string]$existing.$name))
                }
            }
        }
    }

    if ($Owned) { return 'owned' }
    return $null
}

function Get-DefaultMarker([string]$Title, [string]$Status, [bool]$Owned, [bool]$IsFree) {
    $titleNorm = ([string]$Title).ToLowerInvariant()
    $statusNorm = ([string]$Status).ToLowerInvariant()

    if ($statusNorm -in @('skip', 'no_comprar', 'no-comprar', 'no comprar', 'not_buying', 'descartado')) { return 'skip' }
    if ($titleNorm -match 'soundtrack|ost|original soundtrack|banda sonora|music pack') { return 'soundtrack' }
    if ($titleNorm -match 'artbook|art book|digital artbook|booklet|art collection') { return 'artbook' }
    if ($titleNorm -match 'skin|costume|cosmetic|outfit|wardrobe|character pack') { return 'cosmetic' }
    if ($titleNorm -match 'coin|coins|gem|gems|point|points|credit|credits|currency') { return 'currency' }
    if ($titleNorm -match 'season pass|expansion pass|upgrade pack|supporter pack') { return 'pass' }
    if ($IsFree) { return 'free' }
    if ($Owned) { return 'owned' }
    return 'missing'
}

function Get-SteamAppData([int]$AppId) {
    $url = "https://store.steampowered.com/api/appdetails?appids=$AppId&l=spanish&cc=mx"
    $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 25 -ErrorAction Stop
    $appData = $resp."$AppId"
    if (-not $appData -or $appData.success -ne $true -or -not $appData.data) { return $null }
    return $appData.data
}

function Get-PriceText($Data) {
    if ($null -eq $Data -or -not $Data.PSObject.Properties['price_overview'] -or $null -eq $Data.price_overview) { return $null }
    if ($Data.price_overview.PSObject.Properties['final_formatted']) { return [string]$Data.price_overview.final_formatted }
    return $null
}

function New-DlcRecord($DlcData, [int]$DlcAppId, $ExistingDlcs, [bool]$FullOwnership, [string]$SyncTimestamp) {
    $name = if ($DlcData -and -not [string]::IsNullOrWhiteSpace([string]$DlcData.name)) { [string]$DlcData.name } else { "DLC $DlcAppId" }
    $owned = Get-ManualOwnedFromExisting $ExistingDlcs $DlcAppId $name $FullOwnership
    $status = Get-ManualStatusFromExisting $ExistingDlcs $DlcAppId $name $owned
    $isFree = if ($DlcData -and $null -ne $DlcData.is_free) { [bool]$DlcData.is_free } else { $false }
    $marker = Get-ManualMarkerFromExisting $ExistingDlcs $DlcAppId $name $owned
    if ([string]::IsNullOrWhiteSpace([string]$marker)) {
        $marker = Normalize-DlcMarker (Get-DefaultMarker $name $status $owned $isFree)
    }
    $releaseDate = $null
    if ($DlcData -and $DlcData.release_date -and -not $DlcData.release_date.coming_soon) { $releaseDate = [string]$DlcData.release_date.date }

    return [ordered]@{
        appId = $DlcAppId
        title = $name
        type = if ($DlcData -and -not [string]::IsNullOrWhiteSpace([string]$DlcData.type)) { [string]$DlcData.type } else { "dlc" }
        owned = $owned
        marker = $marker
        important = $null
        status = $status
        isFree = if ($DlcData -and $null -ne $DlcData.is_free) { [bool]$DlcData.is_free } else { $null }
        price = Get-PriceText $DlcData
        releaseDate = $releaseDate
        storeUrl = "https://store.steampowered.com/app/$DlcAppId"
        source = "steam-store-api"
        lastSyncedAt = $SyncTimestamp
    }
}

Write-Host "Leyendo $metadataPath..."
$metadataFile = Get-Content $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$games = @($metadataFile.games)
$onlySet = @{}
foreach ($id in $OnlyAppIds) { $onlySet[[int]$id] = $true }

$candidates = @($games | Where-Object {
    $include = $true

    if ($null -eq $_.steamAppId) {
        $include = $false
    }

    if ($include -and $OnlyAppIds.Count -gt 0 -and -not $onlySet.ContainsKey([int]$_.steamAppId)) {
        $include = $false
    }

    $alreadyCatalogSynced = $false
    if ($include) {
        $dlcInfo = $_.dlcInfo
        if ($dlcInfo -and $dlcInfo.PSObject.Properties['catalogSource']) {
            $alreadyCatalogSynced = ([string]$dlcInfo.catalogSource -eq "steam-store-api")
        }
    }

    $include -and ($Force -or -not $alreadyCatalogSynced)
})

if ($MaxGames -gt 0 -and $MaxGames -lt $candidates.Count) {
    $candidates = @($candidates | Select-Object -First $MaxGames)
}

Write-Host "Juegos a revisar para catálogo DLC: $($candidates.Count)"
if ($DryRun) { Write-Host "[DRY RUN] No se escribirán cambios." }

$processed = 0
$updated = 0
$failed = 0
$withoutDlc = 0
$reportItems = @()
$syncTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($game in $candidates) {
    $processed++
    $appId = [int]$game.steamAppId
    $title = [string]$game.title
    Write-Host "[$processed/$($candidates.Count)] AppID $appId — $title"

    try {
        $data = Get-SteamAppData $appId
        if ($null -eq $data) {
            Write-Host "  ⚠ Sin datos en Steam Store API"
            $failed++
            $reportItems += [ordered]@{ steamAppId = $appId; title = $title; status = "no-store-data"; dlcCount = 0 }
            continue
        }

        $dlcIds = @()
        if ($data.PSObject.Properties['dlc'] -and $null -ne $data.dlc) {
            $dlcIds = @(Get-Array $data.dlc | ForEach-Object { try { [int]$_ } catch { $null } } | Where-Object { $_ })
        }

        $dlcIds = @($dlcIds | Sort-Object -Unique)
        $dlcInfo = Ensure-ObjectProperty $game "dlcInfo"
        $existingDlcs = if ($dlcInfo -and $dlcInfo.PSObject.Properties['dlcs']) { @(Get-Array $dlcInfo.dlcs) } else { @() }
        $existingOwnership = if ($dlcInfo -and $dlcInfo.PSObject.Properties['ownershipStatus']) { [string]$dlcInfo.ownershipStatus } else { "unknown" }
        $fullOwnership = $existingOwnership -eq "full"

        if ($dlcIds.Count -eq 0) {
            if (-not $DryRun) {
                Set-ObjectProperty $dlcInfo "hasDlc" $false
                Set-ObjectProperty $dlcInfo "totalDlcCount" 0
                Set-ObjectProperty $dlcInfo "ownedDlcCount" 0
                Set-ObjectProperty $dlcInfo "missingDlcCount" 0
                Set-ObjectProperty $dlcInfo "dlcs" @()
                Set-ObjectProperty $dlcInfo "ownershipStatus" "no_dlc_detected"
                Set-ObjectProperty $dlcInfo "ownershipSummary" "Steam Store no reportó DLC para este juego."
                Set-ObjectProperty $dlcInfo "catalogSource" "steam-store-api"
                Set-ObjectProperty $dlcInfo "lastCatalogSyncAt" $syncTimestamp
            }
            Write-Host "  → Sin DLC detectado"
            $withoutDlc++
            $updated++
            $reportItems += [ordered]@{ steamAppId = $appId; title = $title; status = "no-dlc-detected"; dlcCount = 0 }
        }
        else {
            $newDlcs = @()
            $dlcIndex = 0
            foreach ($dlcId in $dlcIds) {
                $dlcIndex++
                Write-Host "  [$dlcIndex/$($dlcIds.Count)] DLC AppID $dlcId"
                $dlcData = $null
                try {
                    $dlcData = Get-SteamAppData $dlcId
                }
                catch {
                    Write-Host "    ⚠ No se pudo leer detalle de DLC: $($_.Exception.Message)"
                }
                $newDlcs += (New-DlcRecord $dlcData $dlcId $existingDlcs $fullOwnership $syncTimestamp)
                if ($DelayMs -gt 0 -and $dlcIndex -lt $dlcIds.Count) { Start-Sleep -Milliseconds $DelayMs }
            }

            $ownedCount = @($newDlcs | Where-Object { $_.owned -eq $true }).Count
            $missingCount = $newDlcs.Count - $ownedCount
            $newOwnershipStatus = if ($newDlcs.Count -eq 0) {
                "no_dlc_detected"
            }
            elseif ($ownedCount -eq 0) {
                "catalog_only"
            }
            elseif ($ownedCount -eq $newDlcs.Count) {
                "full"
            }
            elseif ($ownedCount -gt 0) {
                "partial"
            }
            else {
                "unknown"
            }

            $summary = if ($newDlcs.Count -eq 1) {
                "Steam detectó 1 DLC. Marca owned=true si lo tenemos."
            }
            else {
                "Steam detectó $($newDlcs.Count) DLC. Marca owned=true en cada fila confirmada."
            }

            if (-not $DryRun) {
                Set-ObjectProperty $dlcInfo "hasDlc" $true
                Set-ObjectProperty $dlcInfo "totalDlcCount" $newDlcs.Count
                Set-ObjectProperty $dlcInfo "ownedDlcCount" $ownedCount
                Set-ObjectProperty $dlcInfo "missingDlcCount" $missingCount
                Set-ObjectProperty $dlcInfo "dlcs" $newDlcs
                Set-ObjectProperty $dlcInfo "ownershipStatus" $newOwnershipStatus
                Set-ObjectProperty $dlcInfo "ownershipSummary" $summary
                Set-ObjectProperty $dlcInfo "catalogSource" "steam-store-api"
                Set-ObjectProperty $dlcInfo "lastCatalogSyncAt" $syncTimestamp
                if (-not $dlcInfo.PSObject.Properties['manualSource']) { Set-ObjectProperty $dlcInfo "manualSource" $null }
                if (-not $dlcInfo.PSObject.Properties['lastManualUpdateAt']) { Set-ObjectProperty $dlcInfo "lastManualUpdateAt" $null }
            }

            Write-Host "  ✅ DLC detectados: $($newDlcs.Count) | propios marcados: $ownedCount"
            $updated++
            $reportItems += [ordered]@{ steamAppId = $appId; title = $title; status = "dlc-found"; dlcCount = $newDlcs.Count; ownedCount = $ownedCount }
        }
    }
    catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)"
        $failed++
        $reportItems += [ordered]@{ steamAppId = $appId; title = $title; status = "error"; error = $_.Exception.Message; dlcCount = 0 }
    }

    if ($DelayMs -gt 0 -and $processed -lt $candidates.Count) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

if (-not $DryRun) {
    Set-ObjectProperty $metadataFile "version" "6.6.6"
    Set-ObjectProperty $metadataFile "updatedAt" $syncTimestamp
    $metadataFile | ConvertTo-Json -Depth 40 | Set-Content $metadataPath -Encoding UTF8

    $report = [ordered]@{
        version = "6.6.6"
        generatedAt = $syncTimestamp
        processed = $processed
        updated = $updated
        withoutDlc = $withoutDlc
        failed = $failed
        items = $reportItems
    }
    $report | ConvertTo-Json -Depth 20 | Set-Content $reportPath -Encoding UTF8

    Write-Host ""
    Write-Host "✅ Catálogo DLC guardado en $metadataPath"
    Write-Host "🧾 Reporte: $reportPath"

    if ($BuildIndexAfter) {
        Write-Host ""
        Write-Host "Regenerando games-index con DLC..."
        & $buildIndexScript
    }
}
else {
    Write-Host ""
    Write-Host "[DRY RUN] Procesados: $processed | Actualizaría: $updated | Sin DLC: $withoutDlc | Fallidos: $failed"
}
