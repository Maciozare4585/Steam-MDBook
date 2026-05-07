param(
    [string]$SummaryPath = ".\src\SUMMARY.md",
    [string]$RegistryPath = ".\data\steam-games-registry.json"
)

. "$PSScriptRoot\_registry-lib.ps1"

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

$registry = @(Load-JsonFile $RegistryPath @()) | Where-Object { $_.steamAppId } | Sort-Object title
$groups = @{}
foreach ($g in $registry) {
    $key = Get-GameLetterKey ([string]$g.title)
    if (-not $groups.ContainsKey($key)) { $groups[$key] = 0 }
    $groups[$key]++
}

$keys = New-Object System.Collections.Generic.List[string]
if ($groups.ContainsKey("0-9")) { $keys.Add("0-9") }
foreach ($code in ([int][char]'A')..([int][char]'Z')) {
    $letter = [string][char]$code
    if ($groups.ContainsKey($letter)) { $keys.Add($letter) }
}
if ($groups.ContainsKey("OTROS")) { $keys.Add("OTROS") }

$letterLines = New-Object System.Collections.Generic.List[string]
$letterLines.Add("  - [Índice alfabético](07-juegos/index.md)")
foreach ($key in $keys) {
    $slug = Get-LetterSlug $key
    $letterLines.Add("  - [Juegos — $key](07-juegos/por-letra/$slug.md)")
}
$letterLines.Add("  - [Galería global de assets](07-juegos/galeria-assets-generada.md)")
$letterLines.Add("  - [Juegos por revisar](07-juegos/review-needed.md)")
$letterLines.Add("  - [Reintentos pendientes](07-juegos/retry-needed.md)")
$letterLines.Add("  - [Entradas ignoradas](07-juegos/ignored.md)")

$summary = Get-Content $SummaryPath -Raw -Encoding UTF8
$newBlock = "- [VII. Juegos / Metadatos](07-juegos/index.md)`n" + (($letterLines.ToArray()) -join "`n") + "`n"
$summary = [regex]::Replace($summary, '- \[VII\. Juegos / Metadatos\]\(07-juegos/index\.md\)[\s\S]*$', $newBlock)
Set-Content $SummaryPath $summary -Encoding UTF8

Write-Step "SUMMARY saneado: VII. Juegos / Metadatos compacto por letras."
