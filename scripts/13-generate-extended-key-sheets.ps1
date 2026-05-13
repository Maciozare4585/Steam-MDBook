<#
.SYNOPSIS
    Genera fichas extendidas de juegos clave de Daniel.
.DESCRIPTION
    Lee `data/key-game-extended.json` y produce `src/05-perfiles/daniel/fichas-extendidas.md`.
    Los enlaces de metadata apuntan directamente a `../../07-juegos/detalle.html?id=<steamAppId>`.
.EXAMPLE
    .\scripts\13-generate-extended-key-sheets.ps1
#>
param(
    [string]$DataPath = ".\data\key-game-extended.json",
    [string]$OutPath = ".\src\05-perfiles\daniel\fichas-extendidas.md",
    [string]$IndexPath = ".\src\05-perfiles\daniel\juegos-clave.md"
)

. "$PSScriptRoot\_registry-lib.ps1"

$items = @(Load-JsonFile $DataPath @())

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

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# Fichas extendidas de Daniel")
$lines.Add("")
$lines.Add("> Estas fichas pertenecen al perfil de Daniel. No son colecciones de Steam ni criterio global familiar; son explicación personal y práctica para juegos con peso, estado mixto o decisión pendiente de Daniel.")
$lines.Add("")
$lines.Add("Úsalas cuando un juego necesita más contexto que una sola fila de colección: por ejemplo, juegos favoritos con avance pendiente, juegos terminados con postgame, o casos donde el estado personal no debe romper la taxonomía.")
$lines.Add("")
$lines.Add('<div class="extended-key-grid">')

foreach ($item in $items) {
    $appid = [int]$item.steamAppId
    $slug = [string]$item.slug
    $title = [string]$item.title
    $emoji = if ($item.emoji) { [string]$item.emoji } else { "🎮" }

    $mdProjectRel = ConvertTo-ProjectRelativePath $OutPath
    $img = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath "src/assets/games/$appid/steam-header.jpg"
    $letterSlug = Get-LetterSlug (Get-GameLetterKey $title)
    $meta = "../../07-juegos/detalle.html?id=$appid"

    $safeTitle = Escape-Html $title
    $safeSlug = Escape-Html $slug

    $lines.Add("<section class=`"extended-key-card`" id=`"key-$safeSlug`">")
    $lines.Add("  <img src=`"$img`" alt=`"$safeTitle`" loading=`"lazy`" />")
    $lines.Add("  <div class=`"extended-key-card__body`">")
    $lines.Add("    <h2>$emoji $safeTitle</h2>")
    $lines.Add("    <div class=`"extended-key-meta`">")
    $lines.Add("      <span class=`"extended-key-pill`">$(Escape-Html $item.house)</span>")
    $lines.Add("      <span class=`"extended-key-pill`">$(Escape-Html $item.state)</span>")
    $lines.Add("      <span class=`"extended-key-pill`">Energía: $(Escape-Html $item.energy)</span>")
    $lines.Add("    </div>")
    $lines.Add("    <dl>")
    $lines.Add("      <dt>Por qué importa</dt><dd>$(Escape-Html $item.whyItMatters)</dd>")
    $lines.Add("      <dt>Lectura actual</dt><dd>$(Escape-Html $item.currentReading)</dd>")
    $lines.Add("      <dt>Siguiente paso</dt><dd>$(Escape-Html $item.nextStep)</dd>")
    $lines.Add("      <dt>Evitar</dt><dd>$(Escape-Html $item.avoid)</dd>")
    $lines.Add("    </dl>")
    $lines.Add("    <div class=`"extended-key-actions`">")
    $lines.Add("      <a href=`"$meta`">Ver metadata</a>")
    $lines.Add("      <a class=`"steam-action steam-play`" href=`"steam://run/$appid`">▶ Jugar</a>")
    $lines.Add("      <a class=`"steam-action steam-install`" href=`"steam://install/$appid`">⬇ Instalar</a>")
    $lines.Add("      <a class=`"steam-action steam-store`" href=`"https://store.steampowered.com/app/$appid`">Tienda</a>")
    $lines.Add("      <a href=`"#key-$safeSlug`">Ancla</a>")
    $lines.Add("    </div>")
    $lines.Add("  </div>")
    $lines.Add("</section>")
    $lines.Add("")
}

$lines.Add("</div>")

Set-Content $OutPath ($lines -join "`n") -Encoding UTF8

if (Test-Path $IndexPath) {
    $index = Get-Content $IndexPath -Raw -Encoding UTF8

    foreach ($item in $items) {
        $slug = [string]$item.slug
        $index = $index.Replace("href=`"$slug.html`"", "href=`"fichas-extendidas.html#key-$slug`"")
    }

    Set-Content $IndexPath $index -Encoding UTF8
}

Write-Step "Fichas extendidas generadas: $OutPath"