<#
.SYNOPSIS
    Genera la galería global de assets.
.DESCRIPTION
    Crea `src/07-juegos/galeria-assets-generada.md` desde el registry. Cada tarjeta apunta a la ficha dinámica
    `detalle.html?id=<steamAppId>` para evitar navegación intermedia por letra.
.EXAMPLE
    .\scripts\10-generate-assets-gallery.ps1
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$OutPath = ".\src\07-juegos\galeria-assets-generada.md"
)

. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @()) | Where-Object { $_.steamAppId }

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

$lines.Add("# 🖼️ Galería global de assets")
$lines.Add("")
$lines.Add("> Página generada desde ``data/steam-games-registry.json``.")
$lines.Add("")
$lines.Add("Total de juegos con metadata: **$($registry.Count)**.")
$lines.Add("")
$lines.Add("Esta página es una galería técnica/global. No pertenece a ningún perfil personal. Para navegar con contexto, usa las colecciones; para ver metadatos, haz click en una tarjeta.")
$lines.Add("")
$lines.Add('<div class="assets-gallery-grid">')

foreach ($g in ($registry | Sort-Object title)) {
    $appid = [int]$g.steamAppId
    $title = [string]$g.title
    $source = if ($g.preferredImageSource) { [string]$g.preferredImageSource } else { "steam" }

    $mdProjectRel = ConvertTo-ProjectRelativePath $OutPath
    $img = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath "src/assets/games/$appid/steam-header.jpg"
    $letterSlug = Get-LetterSlug (Get-GameLetterKey $title)
    $link = "detalle.html?id=$appid"

    $safeTitle = Escape-Html $title
    $safeSource = Escape-Html $source

    $lines.Add("<a class=`"assets-gallery-card`" href=`"$link`" title=`"$safeTitle`">")
    $lines.Add("  <img src=`"$img`" alt=`"$safeTitle`" loading=`"lazy`" />")
    $lines.Add("  <span>$safeTitle</span>")
    $lines.Add("  <small>$appid · $safeSource</small>")
    $lines.Add("</a>")
}

$lines.Add("</div>")

Set-Content $OutPath ($lines -join "`n") -Encoding UTF8

Write-Step "Galería automática generada: $OutPath"
