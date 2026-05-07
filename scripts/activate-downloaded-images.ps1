<#
Activa imágenes en fichas de juegos clave si existe src/assets/games/<slug>/header.jpg.
#>

$gamePages = Get-ChildItem ".\src\05-perfiles\daniel\fichas" -Filter "*.md"

foreach ($page in $gamePages) {
    $content = Get-Content $page.FullName -Raw -Encoding UTF8
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($page.Name)
    $header = ".\src\assets\games\$slug\header.jpg"

    if (-not (Test-Path $header)) {
        continue
    }

    if ($content -match "<img src=`"../../../assets/games/$slug/header.jpg`"") {
        continue
    }

    $titleMatch = [regex]::Match($content, "(?m)^#\s+(.+)$")
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $slug }

    $img = "<img src=`"../../../assets/games/$slug/header.jpg`" alt=`"$title`" />"

    if ($content -match '<div class="game-cover-placeholder">[\s\S]*?</div>') {
        $content = [regex]::Replace($content, '<div class="game-cover-placeholder">[\s\S]*?</div>', $img, 1)
        Set-Content $page.FullName $content -Encoding UTF8
        Write-Host "Imagen activada: $($page.Name)"
    }
}
