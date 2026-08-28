param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $Root 'Server\data-global\scripts\custom\movement_god_room_portal.lua'
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw 'GOD room portal runtime fallback is missing.'
}

$content = Get-Content -LiteralPath $scriptPath -Raw
$requiredPatterns = @(
    'Position\(32821, 31533, 10\)',
    'Position\(32823, 31533, 10\)',
    'Position\(32369, 32241, 7\)',
    'player:getTown\(\)',
    'town:getTemplePosition\(\)',
    'godRoomPortalMovement\.onStepIn',
    'godRoomPortalAction\.onUse',
    'godRoomPortalMovement:position\(position\)',
    'godRoomPortalAction:position\(position\)'
)

foreach ($pattern in $requiredPatterns) {
    if ($content -notmatch $pattern) {
        throw "GOD room portal fallback is incomplete: $pattern"
    }
}

Write-Output 'PASS: both broken GOD room portals support step-in and click fallback to the player temple.'
