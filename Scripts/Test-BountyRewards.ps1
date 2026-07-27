param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$server = Get-Content -Raw (Join-Path $Root 'Server/config.lua')
$balance = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Config/default.lua')
Assert-True ($server -match 'bountyTasksExpMultiplier\s*=\s*5\.0') 'Server Bounty EXP multiplier is not 5.0.'
Assert-True ($server -match 'bountyTasksPointsMultiplier\s*=\s*5\.0') 'Server Bounty points multiplier is not 5.0.'
Assert-True ($balance -match 'bountyRewardMultiplier\s*=\s*5\.00') 'Central Bounty multiplier is not 5.00.'
Write-Host 'MANUAL_REQUIRED: Bounty reward configuration checks passed; runtime claim requires in-game validation.'
exit 2
