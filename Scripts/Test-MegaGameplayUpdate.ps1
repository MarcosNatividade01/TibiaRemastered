Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$serverConfig = Get-Content -LiteralPath (Join-Path $root 'Server\config.lua') -Raw
$balanceConfig = Get-Content -LiteralPath (Join-Path $root 'Modules\Remastered\Config\default.lua') -Raw
$balanceApi = Get-Content -LiteralPath (Join-Path $root 'Modules\Remastered\Balance\api.lua') -Raw
$bossLever = Get-Content -LiteralPath (Join-Path $root 'Server\data\libs\functions\boss_lever.lua') -Raw
$creatureEvent = Get-Content -LiteralPath (Join-Path $root 'Server\data\events\scripts\creature.lua') -Raw
$npcPath = Join-Path $root 'Server\data-global\npc\gold_token_broker.lua'
$npcSpawnPath = Join-Path $root 'Server\data-global\world\world-npc.xml'
$assetsAuditPath = Join-Path $root 'Docs\MISSING_ASSETS_AUDIT.md'

Assert-True ($serverConfig -match 'bountyTasksExpMultiplier\s*=\s*1\.4') 'Bounty XP nao esta em +40%.'
Assert-True ($serverConfig -match 'bountyTasksPointsMultiplier\s*=\s*1\.4') 'Bounty points nao esta em +40%.'
Assert-True ($balanceConfig -match 'bountyRewardMultiplier\s*=\s*1\.40') 'Multiplicador central de bounty ausente.'

Assert-True ($serverConfig -match 'bestiaryKillMultiplier\s*=\s*2') 'Bestiary nao esta configurado para 50% das kills.'
Assert-True ($serverConfig -match 'bestiaryRateCharmShopPrice\s*=\s*0\.5') 'Charm shop nao esta configurado para -50%.'
Assert-True ($balanceConfig -match 'bestiaryCompletionRewardMultiplier\s*=\s*4\.0') 'Bestiary reward 4x ausente.'
Assert-True ($balanceConfig -match 'charmCostMultiplier\s*=\s*0\.50') 'Charm cost -50% ausente.'

Assert-True ($balanceConfig -match 'weak\s*=\s*{\s*difficultyMultiplier\s*=\s*0\.85') 'Boss tier weak -15% ausente.'
Assert-True ($balanceConfig -match 'medium\s*=\s*{\s*difficultyMultiplier\s*=\s*0\.80') 'Boss tier medium -20% ausente.'
Assert-True ($balanceConfig -match 'strong\s*=\s*{\s*difficultyMultiplier\s*=\s*0\.70') 'Boss tier strong -30% ausente.'
Assert-True ($balanceConfig -match 'endgame\s*=\s*{\s*difficultyMultiplier\s*=\s*0\.50') 'Boss tier endgame -50% ausente.'
Assert-True ($balanceApi -match 'applyBossHealth') 'Aplicacao central de HP de boss ausente.'
Assert-True ($balanceApi -match 'scaleBossDamage') 'Aplicacao central de dano de boss ausente.'
Assert-True ($balanceApi -match 'isRewardBoss') 'Dano de boss nao verifica reward/bosstiary.'
Assert-True ($bossLever -match 'Remastered\.Balance\.applyBossHealth') 'BossLever nao aplica reducao central de HP.'
Assert-True ($creatureEvent -match 'Remastered\.Balance\.scaleBossDamage') 'Creature:onDrainHealth nao aplica reducao central de dano de boss.'

$desertLever = Get-Content -LiteralPath (Join-Path $root 'Server\data-global\scripts\quests\desert_dungeon_quest\actions_desert_dungeon_lever.lua') -Raw
$elementalLever = Get-Content -LiteralPath (Join-Path $root 'Server\data-global\scripts\quests\elemental_spheres\actions_lever.lua') -Raw
Assert-True ($desertLever -notmatch 'one player of each vocation') 'Desert Dungeon ainda exige composicao fixa.'
Assert-True ($elementalLever -notmatch 'one player of each vocation') 'Elemental Spheres ainda exige composicao fixa.'

Assert-True (Test-Path -LiteralPath $npcPath) 'NPC Gold Token Broker ausente.'
$npc = Get-Content -LiteralPath $npcPath -Raw
$npcSpawn = Get-Content -LiteralPath $npcSpawnPath -Raw
Assert-True ($npc -match 'lookType\s*=\s*146') 'NPC nao usa visual do Rashid.'
Assert-True ($npc -match 'clientId\s*=\s*22721') 'Gold Token ID incorreto.'
Assert-True ($npc -match 'buy\s*=\s*200000') 'Preco do Gold Token incorreto.'
Assert-True ($npcSpawn -match 'Gold Token Broker') 'Spawn do NPC nao registrado.'

Assert-True (Test-Path -LiteralPath $assetsAuditPath) 'Auditoria de assets ausente.'
$assetsAudit = Get-Content -LiteralPath $assetsAuditPath -Raw
Assert-True ($assetsAudit -match 'BLOCKED_BY_CLIENT_VERSION') 'Assets bloqueados por versao nao documentados.'

[pscustomobject]@{
    status = 'MEGA_GAMEPLAY_STATIC = PASS'
    bountyRewardMultiplier = 1.40
    bestiaryRequiredKillsMultiplier = 0.50
    bestiaryCompletionRewardMultiplier = 4.0
    charmCostMultiplier = 0.50
    goldTokenId = 22721
    goldTokenPrice = 200000
} | ConvertTo-Json -Depth 4
