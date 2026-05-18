<#
.SYNOPSIS
    Wrapper de compatibilidad para sincronizar registry y assets.
.DESCRIPTION
    Redirige argumentos hacia el pipeline principal o scripts equivalentes. Útil para comandos antiguos.
.EXAMPLE
    .\scripts\sync-game-registry-and-assets.ps1 -DiscoverFromMarkdown
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

& "$PSScriptRoot\05-run-full-sync.ps1" @Args
