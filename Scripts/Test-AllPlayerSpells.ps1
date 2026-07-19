Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$spellRoot = Join-Path $root 'Server\data\scripts\spells'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$files = @(Get-ChildItem -LiteralPath $spellRoot -Recurse -Filter '*.lua')
Assert-True ($files.Count -gt 0) 'Nenhuma spell Lua encontrada.'

$ids = @{}
$words = @{}
$unsafe = @()
$registered = 0
$vocations = @('sorcerer','master sorcerer','druid','elder druid','knight','elite knight','paladin','royal paladin','monk','exalted monk')
$vocationHits = @{}
foreach ($vocation in $vocations) { $vocationHits[$vocation] = 0 }

foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match 'spell:register\(\)|rune:register\(\)|conjureRune:register\(\)') {
        $registered++
    }
    foreach ($match in [regex]::Matches($text, '(?m)^\s*\w+:id\((\d+)\)')) {
        $id = $match.Groups[1].Value
        if (-not $ids.ContainsKey($id)) { $ids[$id] = @() }
        $ids[$id] += $file.FullName
    }
    foreach ($match in [regex]::Matches($text, '(?m)^\s*\w+:words\("([^"]+)"\)')) {
        $word = $match.Groups[1].Value.ToLowerInvariant()
        if (-not $words.ContainsKey($word)) { $words[$word] = @() }
        $words[$word] += $file.FullName
    }
    if ($text -match 'player:getElementalStance\(\)' -and $text -notmatch 'player\.getElementalStance and player:getElementalStance\(\)') {
        $unsafe += $file.FullName
    }
    if ($text -match 'player:getStance\(\)' -and $text -notmatch 'player\.getStance and player:getStance\(\)') {
        $unsafe += $file.FullName
    }
    foreach ($vocation in $vocations) {
        if ($text.ToLowerInvariant().Contains('"' + $vocation + ';true"')) {
            $vocationHits[$vocation]++
        }
    }
}

$duplicateWords = @($words.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 -and $_.Key -notmatch '^###' })

Assert-True ($registered -gt 100) 'Quantidade de spells registradas abaixo do esperado.'
Assert-True ($unsafe.Count -eq 0) ("Chamadas stance sem guarda: " + ($unsafe -join ', '))
foreach ($vocation in $vocations) {
    Assert-True ($vocationHits[$vocation] -gt 0) "Nenhuma spell registrada para $vocation."
}
Assert-True ($duplicateWords.Count -eq 0) ("Words duplicadas: " + (($duplicateWords | ForEach-Object { $_.Key }) -join ', '))

[pscustomobject]@{
    status = 'PLAYER_SPELLS_REGRESSION = PASS'
    files = $files.Count
    registered = $registered
    sharedIds = @($ids.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }).Count
    vocations = $vocationHits
} | ConvertTo-Json -Depth 4
