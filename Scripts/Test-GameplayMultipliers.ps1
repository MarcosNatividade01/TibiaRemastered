param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$balance = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Config/default.lua')
$api = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Balance/api.lua')
$server = Get-Content -Raw (Join-Path $Root 'Server/config.lua')
Assert-True ($balance -match 'spellDamageMultiplier\s*=\s*1\.65') 'PLAYER_SPELL_DAMAGE_MULTIPLIER is not 1.65.'
Assert-True ($balance -match 'offensiveRuneDamageMultiplier\s*=\s*1\.45') 'PLAYER_RUNE_DAMAGE_MULTIPLIER is not 1.45.'
Assert-True ($balance -match 'playerSpellCooldownMultiplier\s*=\s*0\.50') 'PLAYER_SPELL_COOLDOWN_MULTIPLIER is not 0.50.'
Assert-True ($balance -match 'bountyRewardMultiplier\s*=\s*5\.00') 'BOUNTY_REWARD_MULTIPLIER is not 5.00.'
Assert-True ($balance -match 'bestiaryCompletionRewardMultiplier\s*=\s*4\.0') 'BESTIARY_REWARD_MULTIPLIER is not 4.0.'
Assert-True ($balance -match 'charmCostMultiplier\s*=\s*0\.50') 'CHARM_COST_MULTIPLIER is not 0.50.'
Assert-True ($balance -match 'huntingTaskShopPriceMultiplier\s*=\s*0\.40') 'HUNTING_TASK_SHOP_PRICE_MULTIPLIER is not 0.40.'
Assert-True ($balance -match 'weak\s*=\s*\{\s*difficultyMultiplier\s*=\s*0\.65') 'WEAK_BOSS_MULTIPLIER is not 0.65.'
Assert-True ($balance -match 'medium\s*=\s*\{\s*difficultyMultiplier\s*=\s*0\.50') 'MEDIUM_BOSS_MULTIPLIER is not 0.50.'
Assert-True ($balance -match 'strong\s*=\s*\{\s*difficultyMultiplier\s*=\s*0\.25') 'STRONG_BOSS_MULTIPLIER is not 0.25.'
Assert-True ($api -match 'installGameCreateMonsterHook') 'Game.createMonster boss hook is missing.'
Assert-True ($server -match 'bountyTasksExpMultiplier\s*=\s*5\.0') 'Server bounty EXP multiplier is not 5.0.'
Assert-True ($server -match 'bountyTasksPointsMultiplier\s*=\s*5\.0') 'Server bounty points multiplier is not 5.0.'
Write-Host 'PASS: gameplay multipliers and Lua integration checks passed.'
exit 0
