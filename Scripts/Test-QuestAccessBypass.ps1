param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Contains([string]$RelativePath, [string]$Pattern) {
    $path = Join-Path $Root $RelativePath
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -notmatch $Pattern) { throw "Missing access bypass in $RelativePath" }
}

$centralFiles = @(
    'Server\data\scripts\actions\doors\quest_door.lua',
    'Server\data\scripts\actions\doors\key_door.lua',
    'Server\data\libs\functions\boss_lever.lua',
    'Server\data\npclib\npc_system\keyword_handler.lua',
    'Server\data\scripts\movements\special_tiles.lua',
    'Server\data\scripts\movements\closing_door.lua'
)
foreach ($file in $centralFiles) { Assert-Contains $file 'is(Quest|Boss|Door)AccessUnlocked|canBypassAccess' }

$physicalAccessFiles = @(
    'Server\data-global\scripts\quests\blood_brothers_quest\movements_castle_entrace.lua',
    'Server\data-global\scripts\quests\children_of_the_revolution\movements_teleport.lua',
    'Server\data-global\scripts\quests\dangerous_depth\movements_energy_entrance.lua',
    'Server\data-global\scripts\quests\the_dream_courts\movements_access_teleports.lua',
    'Server\data-global\scripts\quests\the_dream_courts\movements_courts_entrance.lua',
    'Server\data-global\scripts\quests\the_inquisition_quest\movements_teleport_main.lua',
    'Server\data-global\scripts\quests\the_hidden_city_of_beregar\moviments_elevator.lua',
    'Server\data-global\scripts\quests\the_pits_of_inferno_quest\movements_pumin_teleport.lua',
    'Server\data-global\scripts\quests\wrath_of_the_emperor\movements_teleports_access.lua',
    'Server\data-global\npc\bounac_guard.lua',
    'Server\data-global\npc\gate_guardian.lua',
    'Server\data-global\npc\iskan.lua',
    'Server\data-global\npc\zurak.lua'
)
foreach ($file in $physicalAccessFiles) { Assert-Contains $file 'isQuestAccessUnlocked|canBypassAccess' }

$drume = Get-Content -LiteralPath (Join-Path $Root 'Server\data-global\scripts\quests\the_order_of_lion_quest\creaturescripts_drume_kill.lua') -Raw
if ($drume -match 'questAccessUnlocked') { throw 'Drume kill must not advance quest because access was bypassed.' }

$demonOak = Get-Content -LiteralPath (Join-Path $Root 'Server\data-global\scripts\quests\demon_oak\movements_entrance.lua') -Raw
$earlyBranch = [regex]::Match($demonOak, 'if questAccessUnlocked then(?s:.*?)return true\s*end').Value
if (-not $earlyBranch -or $earlyBranch -match 'setStorageValue|removeItem|addItem') {
    throw 'Demon Oak bypass must teleport only, without progress or item mutation.'
}

Write-Output 'PASS: quest, door, teleport and NPC access bypasses preserve progress branches.'
