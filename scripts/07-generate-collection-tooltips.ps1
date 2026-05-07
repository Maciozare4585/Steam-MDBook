param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string[]]$MarkdownRoots = @(
        ".\src\02-colecciones",
        ".\src\03-estados",
        ".\src\04-decision",
        ".\src\05-perfiles"
    )
)

. "$PSScriptRoot\_registry-lib.ps1"

$registry = @(Load-JsonFile $RegistryPath @()) | Where-Object { $_.steamAppId }

$byTitle = @{}
foreach ($g in $registry) {
    if ($g.title) { $byTitle[(Normalize-Title $g.title)] = $g }
    if ($g.officialName) { $byTitle[(Normalize-Title $g.officialName)] = $g }
    if ($g.aliases) {
        foreach ($alias in @($g.aliases)) {
            if ($alias) { $byTitle[(Normalize-Title $alias)] = $g }
        }
    }
}

function Get-GameHoverHtml {
    param(
        [string]$Title,
        [string]$MarkdownFile
    )

    $key = Normalize-Title $Title
    if (-not $byTitle.ContainsKey($key)) { return $null }

    $g = $byTitle[$key]
    $appid = [int]$g.steamAppId

    $mdProjectRel = ConvertTo-ProjectRelativePath $MarkdownFile
    $imgRel = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath "src/assets/games/$appid/steam-header.jpg"
    $detailRel = Get-MdBookRelativeAssetPath -MarkdownFile $mdProjectRel -ProjectRelativeAssetPath "src/07-juegos/detalle.md"
    $detailRel = ($detailRel -replace "\.md$", ".html") + "?id=$appid"

    $safeDisplay = [System.Net.WebUtility]::HtmlEncode($Title)
    $safeDataTitle = [System.Net.WebUtility]::HtmlEncode([string]$g.title)

    return "<span class=`"game-hover`" data-preview-src=`"$imgRel`" data-game-title=`"$safeDataTitle`"><a href=`"$detailRel`">$safeDisplay</a><span class=`"game-hover-card`"><img src=`"$imgRel`" alt=`"$safeDisplay`" loading=`"lazy`" /><strong>$safeDisplay</strong></span></span>"
}

$changed = 0
$scanned = 0

foreach ($rootPath in $MarkdownRoots) {
    if (-not (Test-Path $rootPath)) { continue }

    Get-ChildItem $rootPath -Recurse -Filter "*.md" | ForEach-Object {
        $file = $_.FullName
        $lines = Get-Content $file -Encoding UTF8
        $out = New-Object System.Collections.Generic.List[string]
        $inGameTable = $false
        $gameColumn = -1
        $localChanged = $false
        $scanned++

        foreach ($line in $lines) {
            $cells = Split-MarkdownTableRow $line
            if ($cells) {
                $headerGameColumn = -1
                for ($i = 0; $i -lt $cells.Count; $i++) {
                    if ((Normalize-Title (Clean-DisplayTitle $cells[$i])) -eq "juego") {
                        $headerGameColumn = $i
                        break
                    }
                }

                if ($headerGameColumn -ge 0) {
                    $inGameTable = $true
                    $gameColumn = $headerGameColumn
                    $out.Add($line)
                    continue
                }

                if ($inGameTable) {
                    if (Test-MarkdownSeparatorRow $cells) {
                        $out.Add($line)
                        continue
                    }

                    if ($gameColumn -lt $cells.Count) {
                        $cleanTitle = Clean-DisplayTitle $cells[$gameColumn]
                        $hover = Get-GameHoverHtml -Title $cleanTitle -MarkdownFile $file
                        if ($hover) {
                            $cells[$gameColumn] = $hover
                            $out.Add("| " + ($cells -join " | ") + " |")
                            $localChanged = $true
                            continue
                        }
                    }
                }

                $out.Add($line)
                continue
            }

            $inGameTable = $false
            $gameColumn = -1
            $out.Add($line)
        }

        if ($localChanged) {
            Set-Content $file ($out -join "`n") -Encoding UTF8
            $changed++
        }
    }
}

Write-Step "Archivos Markdown escaneados para tooltips: $scanned"
Write-Step "Archivos con tooltip actualizados: $changed"
