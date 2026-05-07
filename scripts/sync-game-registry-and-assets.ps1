param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

& "$PSScriptRoot\05-run-full-sync.ps1" @Args
