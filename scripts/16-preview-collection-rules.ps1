param(
    [string]$MetadataPath = ".\data\games-metadata.json",
    [string]$RulesPath = ".\data\collection-rules.json",
    [string]$OutputPath = ".\data\generated\collection-suggestions.json"
)

$ErrorActionPreference = "Stop"
$metadata = Get-Content $MetadataPath -Raw | ConvertFrom-Json
$rules = Get-Content $RulesPath -Raw | ConvertFrom-Json
$suggestions = @()

function Get-FieldValue($obj, [string]$path) {
    $cur = $obj
    foreach ($part in $path.Split('.')) {
        if ($null -eq $cur) { return $null }
        $cur = $cur.$part
    }
    return $cur
}

foreach ($game in @($metadata.games)) {
    foreach ($rule in @($rules.rules)) {
        $ok = $false
        $conditions = $rule.conditions
        foreach ($prop in $conditions.PSObject.Properties) {
            $field = $prop.Name
            $expected = $prop.Value
            if ($field -eq 'anyTags') {
                $tags = @($game.steamMetadata.tags) + @($game.recommendationMetadata.moodTags)
                foreach ($tag in $expected) { if ($tags -contains $tag) { $ok = $true } }
            }
            elseif ($field -eq 'anyGenres') {
                foreach ($genre in $expected) { if (@($game.steamMetadata.genres) -contains $genre) { $ok = $true } }
            }
            else {
                $value = Get-FieldValue $game $field
                if ($value -eq $expected) { $ok = $true }
            }
        }
        if ($ok) {
            $suggestions += [ordered]@{ steamAppId = $game.steamAppId; title = $game.title; ruleId = $rule.id; collection = $rule.collection; mode = $rule.mode; priority = $rule.priority }
        }
    }
}
New-Item -ItemType Directory -Force (Split-Path $OutputPath) | Out-Null
[ordered]@{ version = "6.6.0"; updatedAt = (Get-Date).ToString("o"); suggestions = $suggestions } | ConvertTo-Json -Depth 20 | Set-Content $OutputPath -Encoding UTF8
Write-Host "Sugerencias generadas: $($suggestions.Count)."
