param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Text([string]$Path, [string]$Pattern, [string]$Message) {
    $content = Get-Content -LiteralPath (Join-Path $Root $Path) -Raw
    if ($content -notmatch $Pattern) { throw $Message }
}

Assert-Text 'Modules\Remastered\Config\default.lua' 'freeExploration\s*=\s*\{' 'Central free exploration configuration is missing.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'enabled\s*=\s*true' 'Free exploration is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreQuestAccess\s*=\s*true' 'Quest access bypass is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreQuestKeys\s*=\s*true' 'Key bypass is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreQuestItems\s*=\s*true' 'Quest item bypass is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreNpcAccess\s*=\s*true' 'NPC access bypass is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreTeleportAccess\s*=\s*true' 'Teleport access bypass is not enabled.'
Assert-Text 'Modules\Remastered\Config\default.lua' 'ignoreUseItemAccess\s*=\s*true' 'Use-item access bypass is not enabled.'
Assert-Text 'Server\config.lua' '(?m)^toggleFreeQuest\s*=\s*false\s*$' 'Legacy FreeQuests storage writer must be disabled.'
Assert-Text 'Server\data-global\scripts\creaturescripts\customs\freequests.lua' 'isFreeExplorationEnabled\(\)' 'FreeQuests lacks the exploration-mode safety guard.'
Assert-Text 'Modules\Remastered\Gameplay\api.lua' 'function Gameplay\.canBypassAccess' 'Central access API is missing.'

$api = Get-Content -LiteralPath (Join-Path $Root 'Modules\Remastered\Gameplay\api.lua') -Raw
if ($api -match 'setStorageValue|addItem|removeItem|addExperience|addAchievement') {
    throw 'Central access API must not change quest progress or rewards.'
}

$chayenneReward = Get-Content -LiteralPath (Join-Path $Root 'Server\data-global\scripts\quests\chayenne_realm\actions_reward.lua') -Raw
if ($chayenneReward -notmatch 'getStorageValue\(Storage\.ChayenneReward\) < 1' -or $chayenneReward -notmatch 'setStorageValue\(Storage\.ChayenneReward, 1\)') {
    throw 'Chayenne reward anti-duplication guard is not intact.'
}

$soulWarReward = Get-Content -LiteralPath (Join-Path $Root 'Server\data-global\scripts\quests\soul_war\action-reward_soul_war.lua') -Raw
if ($soulWarReward -notmatch 'soulWarQuest:get\("final-reward"\)') {
    throw 'Soul War final reward anti-duplication guard is not intact.'
}

$exerciseConfig = Get-Content -LiteralPath (Join-Path $Root 'Modules\Remastered\Config\default.lua') -Raw
$exerciseScript = Get-Content -LiteralPath (Join-Path $Root 'Server\data\scripts\actions\items\exercise_training_weapons.lua') -Raw
if ($exerciseConfig -notmatch 'exerciseWeaponSkillMultiplier\s*=\s*3\.0' -or
    $exerciseScript -notmatch 'dummies\[dummyId\] / 100\) \* getExerciseWeaponSkillMultiplier\(\)') {
    throw 'Exercise weapons are not configured to grant triple skill progress per charge.'
}

Write-Output 'PASS: free exploration is enabled; automatic completion and duplicate rewards remain blocked.'
