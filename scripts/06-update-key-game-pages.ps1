<#
.SYNOPSIS
    Actualiza fichas compactas de juegos clave de Daniel.
.DESCRIPTION
    Lee data de juegos clave y registry para regenerar páginas base dentro del perfil de Daniel.
    Se conserva para compatibilidad con la capa anterior de fichas.
.EXAMPLE
    .\scripts\06-update-key-game-pages.ps1
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$GamesKeyPath = ".\data\games-key.json",
    [string]$KeyDir = ".\src\05-perfiles\daniel\fichas"
)

. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @())
$gamesKey = @(Load-JsonFile $GamesKeyPath @())

$bySlug = @{}
$byTitle = @{}
$byAppId = @{}

foreach ($g in $registry) {
    if ($g.steamAppId) { $byAppId[[string]$g.steamAppId] = $g }
    if ($g.slug) { $bySlug[[string]$g.slug] = $g }
    if ($g.title) { $byTitle[(Normalize-Title $g.title)] = $g }
    if ($g.officialName) { $byTitle[(Normalize-Title $g.officialName)] = $g }
}

foreach ($item in $gamesKey) {
    if (-not $item.slug) { continue }
    $file = Join-Path $KeyDir "$($item.slug).md"
    if (-not (Test-Path $file)) { continue }

    $entry = $null
    if ($item.steamAppId -and $byAppId.ContainsKey([string]$item.steamAppId)) {
        $entry = $byAppId[[string]$item.steamAppId]
    }
    elseif ($bySlug.ContainsKey([string]$item.slug)) {
        $entry = $bySlug[[string]$item.slug]
    }
    elseif ($item.title -and $byTitle.ContainsKey((Normalize-Title $item.title))) {
        $entry = $byTitle[(Normalize-Title $item.title)]
    }

    if (-not $entry) { continue }

    $appid = [int]$entry.steamAppId
    $mdProjectRel = "src/05-perfiles/daniel/fichas/$($item.slug).md"
    $assetProjectRel = "src/assets/games/$appid/steam-header.jpg"
    $imgRel = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath $assetProjectRel

    $content = Get-Content $file -Raw -Encoding UTF8
    $title = if ($item.title) { [string]$item.title } else { [string]$entry.title }
    $imgTag = "<img src=`"$imgRel`" alt=`"$title`" class=`"game-hero`" loading=`"lazy`" />"

    if ($content -match '<div class="game-cover-placeholder">[\s\S]*?</div>') {
        $content = [regex]::Replace($content, '<div class="game-cover-placeholder">[\s\S]*?</div>', $imgTag, 1)
    }

    $content = [regex]::Replace(
        $content,
        "\n# Imagen\s+Cuando tengas imagen, puedes reemplazar el placeholder por:[\s\S]*?```md\s+!\[[^\]]+\]\([^)]+\)\s+```\s*$",
        "",
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    Set-Content $file $content -Encoding UTF8
}

Write-Step "Fichas clave actualizadas con rutas por Steam App ID."
