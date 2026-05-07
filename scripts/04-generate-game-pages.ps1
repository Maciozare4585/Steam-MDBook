param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$OutDir = ".\src\07-juegos",
    [string]$DataOutDir = ".\src\assets\data",
    [switch]$IncludeIndividualPages
)

. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @()) | Where-Object { $_.steamAppId }
$registry = @($registry | Sort-Object title)

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
    $metadata = @{}
    if ($Game.metadata) { $metadata = $Game.metadata }

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
            steamHeader = "src/assets/games/$appid/steam-header.jpg"
            steamCapsule = "src/assets/games/$appid/steam-capsule.jpg"
            steamBackground = "src/assets/games/$appid/steam-background.jpg"
            sgdbHero = [string]$Game.images.sgdbHero
            sgdbGrid = [string]$Game.images.sgdbGrid
            sgdbLogo = [string]$Game.images.sgdbLogo
            sgdbIcon = [string]$Game.images.sgdbIcon
        }
        metadata = $metadata
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
foreach ($g in $registry) {
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
    $lines.Add("> Página alfabética compacta. Contiene **$($items.Count)** entradas generadas desde ``data/steam-games-registry.json``.")
    $lines.Add("")
    $lines.Add("[← Volver al índice de juegos](../index.md) · [Ficha dinámica](../detalle.md)")
    $lines.Add("")
    $lines.Add('<div class="compact-game-list">')

    foreach ($g in $items) {
        $lines.Add((New-CompactGameCard $g))
        $lines.Add("")
    }

    $lines.Add('</div>')
    Set-Content (Join-Path $LetterDir "$slug.md") ($lines -join "`n") -Encoding UTF8
}

$index = New-Object System.Collections.Generic.List[string]
$index.Add("# 🎮 Juegos / Metadatos")
$index.Add("")
$index.Add("> Índice global compacto generado desde ``data/steam-games-registry.json``.")
$index.Add("")
$index.Add("Esta sección ya no lista todos los juegos individuales en el sidebar. Los detalles se dividen por letra y cada juego puede abrirse en una ficha dinámica única.")
$index.Add("")
$index.Add("**Total registrado:** ``$($registry.Count)`` juegos/apps con ``steamAppId``.")
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
foreach ($g in $registry) {
    $appid = [int]$g.steamAppId
    $title = Escape-Html ([string]$g.title)
    $index.Add("  <a id=`"game-meta-$appid`" class=`"compact-registry-link`" href=`"detalle.html?id=$appid`">🎮 $title</a>")
}
$index.Add('</div>')

Set-Content (Join-Path $OutDir "index.md") ($index -join "`n") -Encoding UTF8

Write-Step "Páginas de juegos, ficha dinámica y games-index.json generados en $OutDir."
