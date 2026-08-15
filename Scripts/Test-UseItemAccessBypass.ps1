param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Read-Relative([string]$Path) {
    return Get-Content -LiteralPath (Join-Path $Root $Path) -Raw
}

$desert = Read-Relative 'Server\data-global\scripts\quests\desert_dungeon_quest\actions_desert_dungeon_lever.lua'
if ($desert -notmatch 'canBypassAccess\("useItem"\)') { throw 'Desert Dungeon altar bypass is missing.' }
if ($desert -notmatch 'if not itemAccessUnlocked and not sacrificeItem') { throw 'Desert Dungeon still requires altar sacrifices in exploration mode.' }
if ($desert -notmatch 'if not itemAccessUnlocked and sacrificeItem') { throw 'Desert Dungeon may consume sacrifices in exploration mode.' }

$explorerFiles = @(
    'Server\data-global\scripts\quests\the_explorer_society\movements_carving_teleport_liberty_bay.lua',
    'Server\data-global\scripts\quests\the_explorer_society\movements_carvingteleport_port_hope.lua'
)
foreach ($file in $explorerFiles) {
    $content = Read-Relative $file
    if ($content -notmatch 'if questAccessUnlocked or \(.*removeItem\(5021, 1\)\) then') {
        throw "Explorer Society carving does not short-circuit item consumption in $file"
    }
}

$dreamKey = Read-Relative 'Server\data-global\scripts\quests\the_dream_courts\actions_key_check.lua'
if ($dreamKey -notmatch 'if not doorAccessUnlocked then(?s:.*?)setStorageValue') {
    throw 'Dream Courts item mechanism does not protect quest storage during bypass.'
}

$chayenne = Read-Relative 'Server\data-global\scripts\quests\chayenne_realm\actions_lever.lua'
if ($chayenne -notmatch 'not itemAccessUnlocked and player:getItemCount\(14682\) < 1') {
    throw 'Chayenne passage still requires the magical key.'
}

Write-Output 'PASS: real item, altar, key and carving access gates bypass items without rewards or progress.'
