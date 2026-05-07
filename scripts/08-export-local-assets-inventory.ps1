param(
    [string]$AssetsRoot = ".\src\assets\games",
    [string]$OutPath = ".\data\local-assets-existing.csv"
)

. "$PSScriptRoot\_registry-lib.ps1"

$ProjectRoot = Get-ProjectRoot

$rows = Get-ChildItem $AssetsRoot -Recurse -File | ForEach-Object {
    [pscustomobject]@{
        ProjectRelativePath = ConvertTo-ProjectRelativePath $_.FullName
        Name = $_.Name
        Length = $_.Length
    }
}

$rows | Export-Csv $OutPath -NoTypeInformation -Encoding UTF8
Write-Step "Inventario relativo generado: $OutPath"
