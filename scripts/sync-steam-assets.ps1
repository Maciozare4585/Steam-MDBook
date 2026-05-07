param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

& "$PSScriptRoot\sync-game-registry-and-assets.ps1" @Args
