<#
.SYNOPSIS
    Genera páginas de juegos y `games-index.json`.
.DESCRIPTION
    Crea el índice alfabético de `src/07-juegos/por-letra/` desde el registry y mezcla metadata extendida
    desde `data/games-metadata.json` cuando existe. También genera `src/assets/data/games-index.json`.
.PARAMETER IncludeIndividualPages
    Genera páginas individuales antiguas. Normalmente no se recomienda porque satura el sidebar.
.EXAMPLE
    .\scripts\04-generate-game-pages.ps1
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$MetadataPath = ".\data\games-metadata.json",
    [string]$CatalogPath = ".\data\library-catalog.json",
    [string]$OutDir = ".\src\07-juegos",
    [string]$DataOutDir = ".\src\assets\data",
    [switch]$IncludeIndividualPages
)

. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @()) | Where-Object { $_.steamAppId }
$registry = @($registry | Sort-Object title)

# V6.6.12: La navegación general usa library-catalog.json si existe.
# Ese catálogo incluye juegos sin Steam App ID, externos, demos y pendientes.
$catalog = @()
if (Test-Path $CatalogPath) {
    $catalog = @(Load-JsonFile $CatalogPath @())
}
if (-not $catalog -or $catalog.Count -eq 0) {
    $catalog = @($registry | ForEach-Object {
        [pscustomobject]@{
            canonicalId = "steam:$($_.steamAppId)"
            title = $_.title
            slug = $_.slug
            steamAppId = $_.steamAppId
            officialName = $_.officialName
            steamType = $_.steamType
            isResolvedSteam = $true
            sourceType = "steam-registry"
            priority = "registry-approved"
            sourceFiles = @("data/steam-games-registry.json")
            externalType = $null
        }
    })
}
$catalog = @($catalog | Sort-Object title)

$metadataById = @{}
if (Test-Path $MetadataPath) {
    $metadataFile = Load-JsonFile $MetadataPath ([pscustomobject]@{ games = @() })
    foreach ($m in @($metadataFile.games)) {
        if ($m.steamAppId) { $metadataById[[int]$m.steamAppId] = $m }
    }
    Write-Step "Metadata extendida detectada para $($metadataById.Count) juegos."
}
else {
    Write-Warn "No se encontró $MetadataPath. Se generará games-index.json con metadata mínima de registry."
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
if (-not (Test-Path $DataOutDir)) { New-Item -ItemType Directory -Path $DataOutDir -Force | Out-Null }

$LetterDir = Join-Path $OutDir "por-letra"
if (-not (Test-Path $LetterDir)) { New-Item -ItemType Directory -Path $LetterDir -Force | Out-Null }

function Escape-Md([string]$Text) {
    if ($null -eq $Text) { return "" }
    return ($Text -replace "\|", "/")
}

function Escape-Html([string]$Text) {
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-GameLetterKey {
    param([string]$Title)
    if ([string]::IsNullOrWhiteSpace($Title)) { return "OTROS" }
    foreach ($ch in $Title.Trim().ToCharArray()) {
        if ([char]::IsDigit($ch)) { return "0-9" }
        if ([char]::IsLetter($ch)) {
            $normalized = $ch.ToString().Normalize([System.Text.NormalizationForm]::FormD)
            $base = $normalized.Substring(0, 1).ToUpperInvariant()
            if ($base -match "^[A-Z]$") { return $base }
            return "OTROS"
        }
    }
    return "OTROS"
}

function Get-LetterSlug {
    param([string]$Key)
    if ($Key -eq "0-9") { return "0-9" }
    if ($Key -eq "OTROS") { return "otros" }
    return $Key.ToLowerInvariant()
}

function New-SteamActionsHtml {
    param(
        [int]$AppId,
        [switch]$Compact,
        [string]$Indent = ""
    )

    $className = if ($Compact) { "steam-actions steam-actions--compact" } else { "steam-actions" }

    return @(
        "$Indent<div class=`"$className`" data-steam-appid=`"$AppId`">",
        "$Indent  <a class=`"steam-action steam-play`" href=`"steam://run/$AppId`" title=`"Abrir o lanzar este juego con Steam`">▶ Jugar</a>",
        "$Indent  <a class=`"steam-action steam-install`" href=`"steam://install/$AppId`" title=`"Abrir el flujo de instalación de Steam`">⬇ Instalar</a>",
        "$Indent  <a class=`"steam-action steam-store`" href=`"https://store.steampowered.com/app/$AppId`" title=`"Abrir la página del juego en Steam`">Tienda</a>",
        "$Indent</div>"
    ) -join "`n"
}

function Get-StringArray($Value) {
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value | Where-Object { $_ } | ForEach-Object { [string]$_ }) }
    return @([string]$Value)
}

function New-GameIndexEntry {
    param($Game)

    $appid = [int]$Game.steamAppId
    $extended = $null
    if ($metadataById.ContainsKey($appid)) { $extended = $metadataById[$appid] }

    $steamMetadata = @{}
    if ($extended -and $extended.steamMetadata) { $steamMetadata = $extended.steamMetadata }
    elseif ($Game.metadata) { $steamMetadata = $Game.metadata }

    $images = $Game.images
    $steamHeader = if ($images -and $images.steamHeader) { [string]$images.steamHeader } else { "src/assets/games/$appid/steam-header.jpg" }
    $steamCapsule = if ($images -and $images.steamCapsule) { [string]$images.steamCapsule } else { "src/assets/games/$appid/steam-capsule.jpg" }
    $steamBackground = if ($images -and $images.steamBackground) { [string]$images.steamBackground } else { "src/assets/games/$appid/steam-background.jpg" }
    $sgdbHero = if ($images) { [string]$images.sgdbHero } else { "" }
    $sgdbGrid = if ($images) { [string]$images.sgdbGrid } else { "" }
    $sgdbLogo = if ($images) { [string]$images.sgdbLogo } else { "" }
    $sgdbIcon = if ($images) { [string]$images.sgdbIcon } else { "" }

    $playModes = if ($extended) { $extended.playModes } else { $null }
    $steamFeatures = if ($extended) { $extended.steamFeatures } else { $null }
    $dlcInfo = if ($extended) { $extended.dlcInfo } else { $null }
    $playerState = if ($extended) { $extended.playerState } else { $null }
    $recommendationMetadata = if ($extended) { $extended.recommendationMetadata } else { $null }
    $profileMetadata = if ($extended) { $extended.profileMetadata } else { $null }
    $libraryPlacement = if ($extended) { $extended.libraryPlacement } else { $null }
    $platforms = if ($extended) { $extended.platforms } else { $null }
    $dataQuality = if ($extended) { $extended.dataQuality } else { $null }

    return [pscustomobject]@{
        title = [string]$Game.title
        slug = [string]$Game.slug
        aliases = @(Get-StringArray $Game.aliases)
        steamAppId = $appid
        officialName = [string]$Game.officialName
        steamType = [string]$Game.steamType
        matchType = [string]$Game.matchType
        preferredImageSource = [string]$Game.preferredImageSource
        steamUrl = "https://store.steampowered.com/app/$appid"
        playUrl = "steam://run/$appid"
        installUrl = "steam://install/$appid"
        assets = [pscustomobject]@{
            steamHeader = $steamHeader
            steamCapsule = $steamCapsule
            steamBackground = $steamBackground
            sgdbHero = $sgdbHero
            sgdbGrid = $sgdbGrid
            sgdbLogo = $sgdbLogo
            sgdbIcon = $sgdbIcon
        }
        metadata = $steamMetadata
        steamMetadata = $steamMetadata
        playModes = $playModes
        steamFeatures = $steamFeatures
        dlcInfo = $dlcInfo
        playerState = $playerState
        recommendationMetadata = $recommendationMetadata
        profileMetadata = $profileMetadata
        libraryPlacement = $libraryPlacement
        platforms = $platforms
        dataQuality = $dataQuality
    }
}

function New-GamePageContent {
    param($Game)

    $appid = [int]$Game.steamAppId
    $title = [string]$Game.title
    $official = [string]$Game.officialName
    $steamType = Escape-Md ([string]$Game.steamType)
    $slug = Escape-Md ([string]$Game.slug)
    $matchType = Escape-Md ([string]$Game.matchType)
    $imageSource = Escape-Md ([string]$Game.preferredImageSource)

    $mdProjectRel = "src/07-juegos/$appid.md"
    $assetProjectRel = "src/assets/games/$appid/steam-header.jpg"
    $img = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath $assetProjectRel

    $letterKey = Get-GameLetterKey $title
    $letterSlug = Get-LetterSlug $letterKey

    $lines = @(
        "# 🎮 $title",
        "",
        "> Nota: Esta ficha individual se conserva como archivo auxiliar. La navegación pública recomendada usa [`detalle.html?id=$appid`](detalle.html?id=$appid).",
        "",
        "<a href=`"https://store.steampowered.com/app/$appid`">",
        "  <img src=`"$img`" alt=`"$title`" class=`"game-hero`" loading=`"lazy`" />",
        "</a>",
        "",
        "## Acciones rápidas",
        "",
        (New-SteamActionsHtml -AppId $appid),
        "",
        "## Metadatos",
        "",
        "| Campo | Valor |",
        "|---|---|",
        "| Título local | $(Escape-Md $title) |",
        "| Nombre oficial | $(Escape-Md $official) |",
        "| Steam App ID | ``$appid`` |",
        "| Tipo Steam | ``$steamType`` |",
        "| Slug | ``$slug`` |",
        "| Match | ``$matchType`` |",
        "| Fuente de imagen | ``$imageSource`` |",
        "| Ficha dinámica | [Abrir](detalle.html?id=$appid) |",
        "| Página alfabética | [Abrir](por-letra/$letterSlug.md#game-meta-$appid) |",
        "| Steam | [Abrir en Steam](https://store.steampowered.com/app/$appid) |"
    )

    return ($lines -join "`n") + "`n"
}

function New-CompactGameCard {
    param($Game)

    $appid = [int]$Game.steamAppId
    $title = Escape-Html ([string]$Game.title)
    $official = Escape-Html ([string]$Game.officialName)
    $steamType = Escape-Html ([string]$Game.steamType)
    $matchType = Escape-Html ([string]$Game.matchType)
    $imageSource = Escape-Html ([string]$Game.preferredImageSource)

@"
<article id="game-meta-$appid" class="compact-game-card">
  <a class="compact-game-card__cover" href="../detalle.html?id=$appid">
    <img src="../../assets/games/$appid/steam-header.jpg" alt="$title" loading="lazy" />
  </a>
  <div class="compact-game-card__body">
    <div class="compact-game-card__title"><a href="../detalle.html?id=$appid">🎮 $title</a></div>
    <div class="compact-game-card__meta">
      <span><strong>App ID:</strong> <code>$appid</code></span>
      <span><strong>Oficial:</strong> $official</span>
      <span><strong>Tipo:</strong> <code>$steamType</code></span>
      <span><strong>Match:</strong> <code>$matchType</code></span>
      <span><strong>Imagen:</strong> <code>$imageSource</code></span>
    </div>
    $(New-SteamActionsHtml -AppId $appid -Compact)
  </div>
</article>
"@
}


function New-CompactCatalogCard {
    param($Item)

    $title = Escape-Html ([string]$Item.title)
    $official = Escape-Html ([string]$Item.officialName)
    $sourceType = Escape-Html ([string]$Item.sourceType)
    $priority = Escape-Html ([string]$Item.priority)
    $externalType = Escape-Html ([string]$Item.externalType)
    $slug = Escape-Html ([string]$Item.slug)

    $appid = 0
    $hasAppId = $false
    if ($Item.steamAppId) { $hasAppId = [int]::TryParse([string]$Item.steamAppId, [ref]$appid) -and $appid -gt 0 }

    if ($hasAppId) {
@"
<article id="game-meta-$appid" class="compact-game-card">
  <a class="compact-game-card__cover" href="../detalle.html?id=$appid">
    <img src="../../assets/games/$appid/steam-header.jpg" alt="$title" loading="lazy" />
  </a>
  <div class="compact-game-card__body">
    <div class="compact-game-card__title"><a href="../detalle.html?id=$appid">🎮 $title</a></div>
    <div class="compact-game-card__meta">
      <span><strong>App ID:</strong> <code>$appid</code></span>
      <span><strong>Oficial:</strong> $official</span>
      <span><strong>Origen catálogo:</strong> <code>$sourceType</code></span>
    </div>
    $(New-SteamActionsHtml -AppId $appid -Compact)
  </div>
</article>
"@
    }
    else {
        $label = if ($externalType) { $externalType } elseif ($priority) { $priority } else { "catalog-only" }
@"
<article id="game-meta-$slug" class="compact-game-card compact-game-card--catalog-only">
  <div class="compact-game-card__cover compact-game-card__cover--placeholder">📦</div>
  <div class="compact-game-card__body">
    <div class="compact-game-card__title">📦 $title</div>
    <div class="compact-game-card__meta">
      <span><strong>Estado:</strong> <code>sin Steam App ID</code></span>
      <span><strong>Origen catálogo:</strong> <code>$sourceType</code></span>
      <span><strong>Tipo:</strong> <code>$label</code></span>
    </div>
  </div>
</article>
"@
    }
}

function Write-DetailPage {
    $content = @'
# 🎮 Ficha dinámica de juego

> Esta página usa `src/assets/data/games-index.json` y se rellena en el navegador según el parámetro `id` de la URL.

Ejemplo:

```text
detalle.html?id=3404260
```

<div id="game-detail-root" class="game-detail-root">
  <p>Cargando ficha del juego...</p>
</div>
'@
    Set-Content (Join-Path $OutDir "detalle.md") $content -Encoding UTF8
}

# Limpia páginas alfabéticas previas.
Get-ChildItem $LetterDir -Filter "*.md" -ErrorAction SilentlyContinue | Remove-Item -Force

# Si no se solicitan fichas individuales, se eliminan las páginas numéricas viejas para evitar ruido.
if (-not $IncludeIndividualPages) {
    Get-ChildItem $OutDir -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -match "^\d+$" } | Remove-Item -Force
}

if ($IncludeIndividualPages) {
    foreach ($g in $registry) {
        if (-not $g.steamAppId) { continue }
        $appid = [int]$g.steamAppId
        Set-Content (Join-Path $OutDir "$appid.md") (New-GamePageContent $g) -Encoding UTF8
    }
}

Write-DetailPage

$gameIndex = @($registry | ForEach-Object { New-GameIndexEntry $_ })
Save-JsonFile (Join-Path $DataOutDir "games-index.json") $gameIndex 14

$groups = @{}
foreach ($g in $catalog) {
    $key = Get-GameLetterKey ([string]$g.title)
    if (-not $groups.ContainsKey($key)) { $groups[$key] = New-Object System.Collections.Generic.List[object] }
    $groups[$key].Add($g)
}

$keys = New-Object System.Collections.Generic.List[string]
if ($groups.ContainsKey("0-9")) { $keys.Add("0-9") }
foreach ($code in ([int][char]'A')..([int][char]'Z')) {
    $letter = [char]$code
    if ($groups.ContainsKey([string]$letter)) { $keys.Add([string]$letter) }
}
if ($groups.ContainsKey("OTROS")) { $keys.Add("OTROS") }

foreach ($key in $keys) {
    $slug = Get-LetterSlug $key
    $items = @($groups[$key] | Sort-Object title)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Juegos — $key")
    $lines.Add("")
    $lines.Add("> Página alfabética compacta. Contiene **$($items.Count)** entradas generadas desde ``data/library-catalog.json``.")
    $lines.Add("")
    $lines.Add("[← Volver al índice de juegos](../index.md) · [Ficha dinámica](../detalle.md)")
    $lines.Add("")
    $lines.Add('<div class="compact-game-list">')

    foreach ($g in $items) {
        $lines.Add((New-CompactCatalogCard $g))
        $lines.Add("")
    }

    $lines.Add('</div>')
    Set-Content (Join-Path $LetterDir "$slug.md") ($lines -join "`n") -Encoding UTF8
}

$index = New-Object System.Collections.Generic.List[string]
$index.Add("# 🎮 Juegos / Metadatos")
$index.Add("")
$index.Add("> Índice global compacto generado desde ``data/library-catalog.json``. Incluye entradas con Steam App ID y entradas de catálogo sin resolver.")
$index.Add("")
$index.Add("Esta sección ya no lista todos los juegos individuales en el sidebar. Los detalles se dividen por letra y cada juego puede abrirse en una ficha dinámica única.")
$index.Add("")
$index.Add("**Total en catálogo general:** ``$($catalog.Count)`` entradas.  ")
$index.Add("**Con Steam App ID:** ``$($registry.Count)`` entradas.")
$index.Add("")
$index.Add("## Ficha dinámica")
$index.Add("")
$index.Add("- [Abrir ficha dinámica vacía](detalle.md)")
$index.Add("")
$index.Add("## Navegación rápida")
$index.Add("")
$index.Add('<div class="letter-nav">')
foreach ($key in $keys) {
    $slug = Get-LetterSlug $key
    $count = $groups[$key].Count
    $index.Add("  <a href=`"por-letra/$slug.html`">$key <small>$count</small></a>")
}
$index.Add('</div>')
$index.Add("")
$index.Add("## Índice compacto")
$index.Add("")
$index.Add("Cada enlace abre la ficha dinámica del juego correspondiente.")
$index.Add("")
$index.Add('<div class="compact-registry-index">')
foreach ($g in $catalog) {
    $title = Escape-Html ([string]$g.title)
    $appid = 0
    $hasAppId = $false
    if ($g.steamAppId) { $hasAppId = [int]::TryParse([string]$g.steamAppId, [ref]$appid) -and $appid -gt 0 }

    if ($hasAppId) {
        $index.Add("  <a id=`"game-meta-$appid`" class=`"compact-registry-link`" href=`"detalle.html?id=$appid`">🎮 $title</a>")
    }
    else {
        $slug = Escape-Html ([string]$g.slug)
        $index.Add("  <span id=`"game-meta-$slug`" class=`"compact-registry-link compact-registry-link--catalog-only`">📦 $title</span>")
    }
}
$index.Add('</div>')

Set-Content (Join-Path $OutDir "index.md") ($index -join "`n") -Encoding UTF8

Write-Step "Páginas de juegos, catálogo general y games-index.json generados en $OutDir."
