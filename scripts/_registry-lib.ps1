<#
.SYNOPSIS
    Biblioteca compartida para scripts de registry, assets y Markdown.
.DESCRIPTION
    Contiene helpers de rutas, normalización de títulos, carga/escritura JSON, limpieza de nombres,
    discovery de tablas Markdown y utilidades comunes de salida.
.NOTES
    Este archivo se usa por dot-sourcing desde otros scripts; no está pensado para ejecutarse directo.
#>

function Get-ProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function ConvertTo-ProjectRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    $fullPath = [System.IO.Path]::GetFullPath($Path)

    $relative = [System.IO.Path]::GetRelativePath($fullProjectRoot, $fullPath)
    return ($relative -replace "\\", "/")
}

function Get-MdBookRelativeAssetPath {
    param(
        [Parameter(Mandatory)]
        [string]$MarkdownFile,

        [Parameter(Mandatory)]
        [string]$ProjectRelativeAssetPath,

        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $mdFullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $MarkdownFile))
    $mdDir = Split-Path $mdFullPath -Parent
    $assetFullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $ProjectRelativeAssetPath))
    $relative = [System.IO.Path]::GetRelativePath($mdDir, $assetFullPath)
    return ($relative -replace "\\", "/")
}

# Shared helpers for Steam registry scripts. V6.4.2

function Write-Step($Message) { Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Warn($Message) { Write-Host "WARN: $Message" -ForegroundColor Yellow }
function Write-Ok($Message) { Write-Host "OK: $Message" -ForegroundColor Green }

function Normalize-Title([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }

    $normalized = $Text.Replace([string][char]0xFE0F, "")
    $normalized = [regex]::Replace($normalized, "^[^\p{L}\p{N}\[]+", "")
    $normalized = $normalized.ToLowerInvariant()
    $normalized = $normalized -replace "™|®|©", ""
    $normalized = $normalized -replace "[’'`]", ""
    $normalized = $normalized -replace "&", "and"
    $normalized = $normalized -replace "[:\.\,\!\?\(\)\[\]\{\}/\\\-–—|]", " "
    $normalized = $normalized -replace "\s+", " "
    $normalized = $normalized.Trim()
    $normalized = $normalized -replace "\bgoty\b", "game of the year"
    $normalized = $normalized -replace "\bgame of the year edition\b", "game of the year"
    $normalized = $normalized -replace "\bdefinitive edition\b", "definitive"
    $normalized = $normalized -replace "\bcomplete edition\b", "complete"
    return $normalized
}

function Repair-DuplicatedTitle([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $clean = $Text.Trim()
    if (($clean.Length % 2) -eq 0) {
        $half = [int]($clean.Length / 2)
        $left = $clean.Substring(0, $half)
        $right = $clean.Substring($half)
        if ($left -ceq $right) { return $left.Trim() }
    }
    return $clean
}

function Clean-DisplayTitle([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }

    $clean = [System.Net.WebUtility]::HtmlDecode($Text).Trim()
    $clean = $clean.Replace([string][char]0xFE0F, "")

    $dataTitle = [regex]::Match($clean, 'data-game-title=(["''])(.*?)\1', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($dataTitle.Success) {
        return Repair-DuplicatedTitle ([System.Net.WebUtility]::HtmlDecode($dataTitle.Groups[2].Value).Trim())
    }

    $anchor = [regex]::Match($clean, '<a\b[^>]*>(.*?)</a>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($anchor.Success) { $clean = $anchor.Groups[1].Value }

    $clean = [regex]::Replace($clean, '<span\b[^>]*class=["''][^"'']*game-hover-card[^"'']*["''][\s\S]*?</span>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $clean = [regex]::Replace($clean, '<[^>]+>', '')
    $clean = $clean -replace '\*\*|`', ''
    $clean = [regex]::Replace($clean, "^[^\p{L}\p{N}\[]+", "")
    $clean = [regex]::Replace($clean, "\s+", " ").Trim()
    return Repair-DuplicatedTitle $clean
}

function New-Slug([string]$Text) {
    $s = Normalize-Title $Text
    $s = $s -replace "[^a-z0-9]+", "-"
    $s = $s.Trim("-")
    if ([string]::IsNullOrWhiteSpace($s)) { return "game" }
    return $s
}

function Test-HeadingNoise([string]$Title) {
    $t = Normalize-Title $Title
    if ([string]::IsNullOrWhiteSpace($t)) { return $true }

    $noise = @(
        "v juegos clave",
        "15 fichas independientes de juegos clave",
        "fichas extendidas",
        "indice de juegos clave",
        "juegos clave",
        "fichas independientes",
        "imagen",
        "imagenes",
        "juegos",
        "juego",
        "juego 1",
        "juego 2",
        "juego 3",
        "paginas base",
        "paginas incluidas",
        "templates copiables",
        "galeria automatica de assets",
        "automatizacion de imagenes",
        "automatizacion imagenes registry sgdb",
        "steam high family"
    )

    if ($noise -contains $t) { return $true }

    # Importante:
    # Antes usábamos ^[ivxlcdm]+\s+ y eso rompía juegos reales:
    # - DmC Devil May Cry
    # - I'm not a Monster
    # Ahora solo detectamos numerales romanos si traen punto de sección: "V. ..."
    if ($t -match "^[ivxlcdm]+\.\s+") { return $true }

    return $false
}

function Test-RateLimit429([string]$Message) {
    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
    $m = $Message.ToLowerInvariant()
    return ($m.Contains("429") -or $m.Contains("too many requests"))
}

function Load-JsonFile($Path, $Default) {
    if (-not (Test-Path $Path)) { return $Default }
    $raw = Get-Content $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    return $raw | ConvertFrom-Json
}

function Save-JsonFile($Path, $Data, [int]$Depth = 12) {
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    # ConvertTo-Json por pipeline puede dejar archivos vacíos cuando el input es @().
    # Usar -InputObject conserva correctamente [] para arrays vacíos.
    if ($null -eq $Data) { $json = "null" }
    else { $json = ConvertTo-Json -InputObject $Data -Depth $Depth }

    if ([string]::IsNullOrWhiteSpace($json)) { $json = "[]" }
    Set-Content $Path -Value $json -Encoding UTF8
}

function Convert-ObjectToHashtable($Obj) {
    $hash = @{}
    if ($null -eq $Obj) { return $hash }
    $Obj.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
    return $hash
}

function Split-MarkdownTableRow([string]$Line) {
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    $trimmed = $Line.Trim()
    if (-not $trimmed.StartsWith("|")) { return $null }
    return @($trimmed.Trim("|").Split("|") | ForEach-Object { $_.Trim() })
}

function Test-MarkdownSeparatorRow($Cells) {
    if (-not $Cells -or $Cells.Count -eq 0) { return $false }
    foreach ($c in $Cells) {
        if (($c -replace " ", "") -notmatch "^:?-{3,}:?$") { return $false }
    }
    return $true
}

function Get-SummaryMarkdownFiles {
    param(
        [string]$SummaryPath = ".\src\SUMMARY.md",
        [switch]$AllMarkdownFiles
    )

    if ($AllMarkdownFiles -or -not (Test-Path $SummaryPath)) {
        return @(Get-ChildItem ".\src" -Recurse -Filter "*.md" | Where-Object {
            $_.FullName -notmatch "\\assets\\" -and
            $_.FullName -notmatch "\\07-juegos\\" -and
            $_.FullName -notmatch "\\06-mantenimiento\\"
        })
    }

    $summaryDir = Split-Path (Resolve-Path $SummaryPath).Path -Parent
    $summary = Get-Content $SummaryPath -Raw -Encoding UTF8
    $matches = [regex]::Matches($summary, '\[[^\]]+\]\(([^)]+\.md)\)')
    $files = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($m in $matches) {
        $rel = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
        if ([string]::IsNullOrWhiteSpace($rel)) { continue }
        if ($rel -match '^(https?:|mailto:|#)') { continue }
        if ($rel -match '^07-juegos/' -or $rel -match '^06-mantenimiento/' -or $rel -match '/assets/') { continue }

        $candidate = Join-Path $summaryDir $rel
        if (-not (Test-Path $candidate)) { continue }

        $item = Get-Item $candidate
        $full = $item.FullName
        if ($full -match "\\assets\\" -or $full -match "\\07-juegos\\" -or $full -match "\\06-mantenimiento\\") { continue }
        if (-not $seen.ContainsKey($full)) {
            $seen[$full] = $true
            $files.Add($item)
        }
    }

    if ($files.Count -gt 0) { return @($files.ToArray()) }

    return @(Get-ChildItem ".\src" -Recurse -Filter "*.md" | Where-Object {
        $_.FullName -notmatch "\\assets\\" -and
        $_.FullName -notmatch "\\07-juegos\\" -and
        $_.FullName -notmatch "\\06-mantenimiento\\"
    })
}

function Get-MarkdownTargets {
    param(
        [switch]$AllMarkdownFiles,
        [string]$SummaryPath = ".\src\SUMMARY.md"
    )

    $targets = @()
    $files = Get-SummaryMarkdownFiles -SummaryPath $SummaryPath -AllMarkdownFiles:$AllMarkdownFiles

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $headerCells = Split-MarkdownTableRow $lines[$i]
            if (-not $headerCells) { continue }

            $gameColumn = -1
            for ($c = 0; $c -lt $headerCells.Count; $c++) {
                $headerName = Normalize-Title (Clean-DisplayTitle $headerCells[$c])
                if ($headerName -in @("juego", "elemento")) {
                    $gameColumn = $c
                    break
                }
            }
            if ($gameColumn -lt 0) { continue }

            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $cells = Split-MarkdownTableRow $lines[$j]
                if (-not $cells) { break }
                if (Test-MarkdownSeparatorRow $cells) { continue }
                if ($gameColumn -ge $cells.Count) { continue }

                $title = Clean-DisplayTitle $cells[$gameColumn]
                if ($title -and -not (Test-HeadingNoise $title) -and $title -notmatch "COMPLETAR|Variable|Casa principal") {
                    $targets += [pscustomobject]@{
                        title = $title
                        slug = New-Slug $title
                        steamAppId = ""
                        priority = "discovered-markdown"
                        source = (ConvertTo-ProjectRelativePath $file.FullName)
                    }
                }
            }
        }
    }

    $dedup = @{}
    foreach ($t in $targets) {
        $key = Normalize-Title $t.title
        if ([string]::IsNullOrWhiteSpace($key)) { continue }
        if (-not $dedup.ContainsKey($key)) { $dedup[$key] = $t }
        else {
            $existing = $dedup[$key]
            $sources = @()
            if ($existing.source) { $sources += @($existing.source) }
            if ($existing.sources) { $sources += @($existing.sources) }
            if ($t.source) { $sources += @($t.source) }
            $sources = @($sources | Where-Object { $_ } | Select-Object -Unique)
            $existing | Add-Member -NotePropertyName sources -NotePropertyValue $sources -Force
        }
    }
    return @($dedup.Values)
}

function Find-AppIdByStoreSearch {
    param(
        [string]$Title,
        [string]$CountryCode = "us",
        [string]$Language = "english",
        [switch]$AllowFuzzy
    )

    $encoded = [uri]::EscapeDataString($Title)
    $url = "https://store.steampowered.com/api/storesearch/?term=$encoded&cc=$CountryCode&l=$Language"

    try {
        $result = Invoke-RestMethod -Uri $url -Method Get
        if (-not $result.items -or $result.items.Count -eq 0) { return $null }

        $targetNorm = Normalize-Title $Title

        $exact = $result.items | Where-Object { (Normalize-Title $_.name) -eq $targetNorm } | Select-Object -First 1
        if ($exact) {
            return [pscustomobject]@{ appid = [int]$exact.id; name = $exact.name; matchType = "storesearch-exact" }
        }

        if ($AllowFuzzy) {
            $contains = $result.items | Where-Object {
                $candidate = Normalize-Title $_.name
                ($candidate.Contains($targetNorm)) -or ($targetNorm.Contains($candidate) -and $candidate.Length -ge 5)
            } | Sort-Object { $_.name.Length } | Select-Object -First 1

            if ($contains) {
                return [pscustomobject]@{ appid = [int]$contains.id; name = $contains.name; matchType = "storesearch-contains" }
            }

            $first = $result.items | Select-Object -First 1
            if ($first) {
                return [pscustomobject]@{ appid = [int]$first.id; name = $first.name; matchType = "storesearch-first" }
            }
        }

        return [pscustomobject]@{ appid = ""; name = ""; matchType = "review-no-exact-match" }
    }
    catch {
        Write-Warn "StoreSearch falló con '${Title}': $($_.Exception.Message)"
        return $null
    }
}

function Get-AppDetails {
    param([int]$AppId, [string]$Language = "english")
    $url = "https://store.steampowered.com/api/appdetails?appids=$AppId&l=$Language"
    return Invoke-RestMethod -Uri $url -Method Get
}

function New-RegistryEntry {
    param(
        [string]$Title,
        [string]$Slug,
        [int]$SteamAppId,
        [string]$OfficialName,
        [string]$SteamType,
        [string]$MatchName,
        [string]$MatchType
    )

    return [pscustomobject]@{
        title = (Clean-DisplayTitle $Title)
        slug = $Slug
        aliases = @()
        steamAppId = $SteamAppId
        officialName = $OfficialName
        steamType = $SteamType
        matchName = $MatchName
        matchType = $MatchType
        sgdbGameId = $null
        preferredImageSource = "steam"
        preferredImageForMdBook = "../assets/games/$SteamAppId/steam-header.jpg"
        images = [pscustomobject]@{
            steamHeader = "src/assets/games/$SteamAppId/steam-header.jpg"
            steamCapsule = "src/assets/games/$SteamAppId/steam-capsule.jpg"
            steamBackground = "src/assets/games/$SteamAppId/steam-background.jpg"
            sgdbHero = ""
            sgdbGrid = ""
            sgdbLogo = ""
            sgdbIcon = ""
        }
        updatedAt = (Get-Date).ToString("s")
    }
}

function Update-GamePageImageById {
    param(
        [string]$Slug,
        [int]$SteamAppId,
        [string]$Title,
        [string]$RelativeImage = "../../../assets/games/$SteamAppId/steam-header.jpg"
    )

    $mdFile = ".\src\05-perfiles\daniel\fichas\$Slug.md"
    if (-not (Test-Path $mdFile)) { return }

    $content = Get-Content $mdFile -Raw -Encoding UTF8
    $imgTag = "<img src=`"$RelativeImage`" alt=`"$Title`" />"

    if ($content -match [regex]::Escape($RelativeImage)) { return }

    if ($content -match '<div class="game-cover-placeholder">[\s\S]*?</div>') {
        $content = [regex]::Replace($content, '<div class="game-cover-placeholder">[\s\S]*?</div>', $imgTag, 1)
    }
    elseif ($content -match '<div class="game-card">') {
        $content = $content -replace '<div class="game-card">\s*', "<div class=`"game-card`">`n`n$imgTag`n`n"
    }
    else {
        $content = $content -replace "(?m)^#\s+(.+)$", "# `$1`n`n$imgTag"
    }

    Set-Content $mdFile $content -Encoding UTF8
}

function Download-FileSafe {
    param(
        [string]$Url,
        [string]$OutFile,
        [switch]$WhatIfMode
    )

    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }

    # V6.4.2: por default NO redescarga archivos existentes.
    # Para refrescar assets explícitamente, el script puede poner:
    # $script:RefreshAssetsGlobal = $true
    if ((Test-Path $OutFile) -and (-not $script:RefreshAssetsGlobal)) {
        try {
            $item = Get-Item $OutFile
            if ($item.Length -gt 0) {
                Write-Host "SKIP existing: $OutFile" -ForegroundColor DarkGray
                return $true
            }
        } catch {}
    }

    $dir = Split-Path $OutFile -Parent
    if (-not (Test-Path $dir)) {
        if (-not $WhatIfMode) { New-Item -ItemType Directory -Path $dir | Out-Null }
    }

    if ($WhatIfMode) {
        Write-Host "WHATIF download: $Url -> $OutFile"
        return $true
    }

    Invoke-WebRequest -Uri $Url -OutFile $OutFile
    return Test-Path $OutFile
}
