param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$player = Get-Content -Raw (Join-Path $Root 'Server/data/libs/functions/player.lua')
$lever = Get-Content -Raw (Join-Path $Root 'Server/data/libs/functions/lever.lua')
$bossLever = Get-Content -Raw (Join-Path $Root 'Server/data/libs/functions/boss_lever.lua')
Assert-True ($player -match 'isBossCooldownDisabled') 'Player boss cooldown API is not neutralized.'
Assert-True ($lever -match 'isBossCooldownDisabled') 'Lever boss cooldown helper is not neutralized.'
Assert-True ($bossLever -match 'timeToFightAgain\s*=\s*0') 'BossLever still stores nonzero fight-again time.'
Write-Host 'MANUAL_REQUIRED: boss cooldown central neutralization checks passed; real re-entry requires in-game validation after server boot.'
exit 2
