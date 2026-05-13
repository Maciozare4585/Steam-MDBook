<#
.SYNOPSIS
    Repara páginas auxiliares y archivos técnicos del mdBook.
.DESCRIPTION
    Asegura la existencia de páginas de revisión, reintentos, ignorados y otras páginas esperadas por SUMMARY.
    Ayuda a evitar errores de `mdbook build` por archivos faltantes.
.EXAMPLE
    .\scripts\09-repair-mdbook-pages.ps1
#>
param(
    [string]$RegistryPath = ".\data\steam-games-registry.json",
    [string]$TargetsPath = ".\data\steam-image-targets.json",
    [string]$ReviewPath = ".\data\steam-games-review-needed.json",
    [string]$RetryPath = ".\data\steam-games-retry-needed.json",
    [string]$IgnoredPath = ".\data\steam-games-ignored.json",
    [string]$GamesOutDir = ".\src\07-juegos"
)

. "$PSScriptRoot\_registry-lib.ps1"

if (-not (Test-Path $GamesOutDir)) {
    New-Item -ItemType Directory -Path $GamesOutDir | Out-Null
}

$registry = @(Load-JsonFile $RegistryPath @())
$targets = @(Load-JsonFile $TargetsPath @())
$review = @(Load-JsonFile $ReviewPath @())
$retry = @(Load-JsonFile $RetryPath @())
$ignored = @(Load-JsonFile $IgnoredPath @())

$cleanRegistry = @()

foreach ($game in $registry) {
    $appid = 0
    [int]::TryParse([string]$game.steamAppId, [ref]$appid) | Out-Null

    if ($appid -le 0) {
        $review += [pscustomobject]@{
            title = $game.title
            slug = $game.slug
            detectedSteamAppId = $game.steamAppId
            detectedName = $game.officialName
            matchType = if ($game.matchType) { $game.matchType } else { "invalid-appid" }
            steamType = $game.steamType
            reason = "steamAppId inválido o 0; removido del registry por repair"
            updatedAt = (Get-Date).ToString("s")
        }
        continue
    }

    $cleanRegistry += $game
}

foreach ($target in $targets) {
    $appid = 0
    [int]::TryParse([string]$target.steamAppId, [ref]$appid) | Out-Null

    if ($appid -le 0) {
        $target.steamAppId = ""
        if ($target.priority -eq "registry-approved") {
            $target.priority = "pending-invalid-appid"
        }
    }
}

function Escape-Cell([string]$Text) {
    if ($null -eq $Text) { return "" }
    return ($Text -replace "\|", "/")
}

function Write-ReviewPage {
    param([array]$Rows)

    $lines = @(
        "# ⚠️ Juegos por revisar",
        "",
        "> Elementos reales que requieren override/manual review. Esta página se regenera con ``scripts/09-repair-mdbook-pages.ps1``.",
        "",
        "| Título | App ID detectado | Nombre detectado | Match | Motivo |",
        "|---|---:|---|---|---|"
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        $lines += "| — | — | — | — | Sin pendientes |"
    }
    else {
        foreach ($r in ($Rows | Sort-Object title)) {
            $lines += "| $(Escape-Cell $r.title) | $(Escape-Cell $r.detectedSteamAppId) | $(Escape-Cell $r.detectedName) | $(Escape-Cell $r.matchType) | $(Escape-Cell $r.reason) |"
        }
    }

    Set-Content (Join-Path $GamesOutDir "review-needed.md") ($lines -join "`n") -Encoding UTF8
}

function Write-RetryPage {
    param([array]$Rows)

    $lines = @(
        "# 🔁 Reintentos pendientes",
        "",
        "> Errores temporales, principalmente ``429 Too Many Requests`` o fallos transitorios de red/API.",
        "",
        "| Título | App ID | Match | Motivo |",
        "|---|---:|---|---|"
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        $lines += "| — | — | — | Sin reintentos pendientes |"
    }
    else {
        foreach ($r in ($Rows | Sort-Object title)) {
            $lines += "| $(Escape-Cell $r.title) | $(Escape-Cell $r.detectedSteamAppId) | $(Escape-Cell $r.matchType) | $(Escape-Cell $r.reason) |"
        }
    }

    Set-Content (Join-Path $GamesOutDir "retry-needed.md") ($lines -join "`n") -Encoding UTF8
}

function Write-IgnoredPage {
    param([array]$Rows)

    $lines = @(
        "# 🧹 Entradas ignoradas",
        "",
        "> Encabezados, placeholders o basura detectada desde Markdown que no deben entrar al registry.",
        "",
        "| Título | Slug | Motivo |",
        "|---|---|---|"
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        $lines += "| — | — | Sin entradas ignoradas |"
    }
    else {
        foreach ($r in ($Rows | Sort-Object title)) {
            $lines += "| $(Escape-Cell $r.title) | ``$(Escape-Cell $r.slug)`` | $(Escape-Cell $r.reason) |"
        }
    }

    Set-Content (Join-Path $GamesOutDir "ignored.md") ($lines -join "`n") -Encoding UTF8
}

Save-JsonFile $RegistryPath ($cleanRegistry | Sort-Object title) 12
Save-JsonFile $TargetsPath ($targets | Sort-Object title) 8
Save-JsonFile $ReviewPath ($review | Sort-Object title) 8

Write-ReviewPage $review
Write-RetryPage $retry
Write-IgnoredPage $ignored

Write-Step "Repair listo: registry limpio y páginas review/retry/ignored generadas."
