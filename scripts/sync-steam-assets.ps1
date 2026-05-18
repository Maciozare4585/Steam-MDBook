<#
.SYNOPSIS
    Wrapper de compatibilidad para sincronizar assets Steam.
.DESCRIPTION
    Reenvía argumentos a `sync-game-registry-and-assets.ps1` para mantener comandos antiguos funcionando.
.EXAMPLE
    .\scripts\sync-steam-assets.ps1 -DiscoverFromMarkdown
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

& "$PSScriptRoot\sync-game-registry-and-assets.ps1" @Args
