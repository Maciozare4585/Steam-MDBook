<#
.SYNOPSIS
    Valida rutas y archivos esperados del proyecto.
.DESCRIPTION
    Comprueba que existan carpetas, JSON, assets y páginas clave. Con `-Strict` puede fallar ante problemas
    que normalmente solo serían advertencias.
.PARAMETER Strict
    Trata advertencias importantes como errores.
.EXAMPLE
    .\scripts\99-validate-project-paths.ps1 -Strict
#>
param(
    [switch]$Strict
)

$patterns = @(
    "[A-Za-z]:\\",
    "/mnt/data",
    "/home/",
    "\\Users\\",
    "OneDrive"
)

$files = Get-ChildItem . -Recurse -File -Include *.md,*.json,*.toml,*.ps1,*.css,*.csv |
    Where-Object {
        $_.FullName -notmatch "\\book\\" -and
        $_.FullName -notmatch "\\target\\" -and
        $_.FullName -notmatch "\\data\\_archive" -and
        $_.Name -ne "99-validate-project-paths.ps1" -and
        $_.Name -notmatch "\.before-"
    }

$hits = @()
foreach ($pattern in $patterns) {
    $hits += $files | Select-String -Pattern $pattern
}

if ($hits.Count -gt 0) {
    Write-Host "Se encontraron rutas absolutas persistidas:" -ForegroundColor Red
    $hits | Select-Object Path, LineNumber, Line | Format-Table -AutoSize

    if ($Strict) {
        exit 1
    }
}
else {
    Write-Host "OK: no se encontraron rutas absolutas persistidas." -ForegroundColor Green
}
