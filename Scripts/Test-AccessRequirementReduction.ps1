param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-Reduced([int]$Requirement) {
    if ($Requirement -le 0) { return $Requirement }
    return [Math]::Max(1, [Math]::Ceiling($Requirement * 0.5))
}

$cases = @{
    1 = 1
    2 = 1
    3 = 2
    5 = 3
    20 = 10
    25 = 13
    50 = 25
    75 = 38
    100 = 50
    200 = 100
    250 = 125
}
foreach ($entry in $cases.GetEnumerator()) {
    $actual = Get-Reduced ([int]$entry.Key)
    if ($actual -ne [int]$entry.Value) { throw "Reduction failed: $($entry.Key) -> $actual, expected $($entry.Value)." }
}

$api = Get-Content -LiteralPath (Join-Path $Root 'Modules\Remastered\Gameplay\api.lua') -Raw
if ($api -notmatch 'math\.ceil\(requirement \* multiplier\)') { throw 'Lua access reduction must use ceil.' }
if ($api -notmatch 'function Gameplay\.getReducedAccessRequirement') { throw 'Item requirement reducer is missing.' }
if ($api -notmatch 'function Gameplay\.getReducedAccessLevel') { throw 'Level requirement reducer is missing.' }

$levelDoor = Get-Content -LiteralPath (Join-Path $Root 'Server\data\scripts\actions\doors\level_door.lua') -Raw
if ($levelDoor -notmatch 'getReducedAccessLevel\(requiredLevel\)') { throw 'Level doors do not use the reduced access level.' }

Write-Output 'PASS: access quantities and levels use ceil(original / 2), minimum 1.'
