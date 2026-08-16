param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

function Read-ProjectFile([string]$RelativePath) {
    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing required file: $RelativePath" }
    return Get-Content -LiteralPath $path -Raw
}

function Assert-Match([string]$Content, [string]$Pattern, [string]$Message) {
    if ($Content -notmatch $Pattern) { throw $Message }
}

$clickable = Read-ProjectFile 'Server\data\npclib\npc_system\npc_clickable.lua'
$handler = Read-ProjectFile 'Server\data\npclib\npc_system\npc_handler.lua'
$keywordHandler = Read-ProjectFile 'Server\data\npclib\npc_system\keyword_handler.lua'
$load = Read-ProjectFile 'Server\data\npclib\load.lua'

Assert-Match $load 'npc_clickable\.lua[\s\S]*npc_handler\.lua' 'Clickable helper must load before NpcHandler.'
Assert-Match $handler 'NpcClickable\.format\(self, msg, npc, player, true\)' 'Greeting messages are not routed through the clickable layer.'
Assert-Match $handler 'NpcClickable\.format\(self, message, npc, player, false\)' 'Normal NPC responses are not routed through the clickable layer.'
Assert-Match $clickable 'maxKeywordLength\s*=\s*32' 'Short-keyword client safety limit is missing.'
Assert-Match $clickable 'maxLinksPerMessage\s*=\s*12' 'Per-message clickable safety limit is missing.'
Assert-Match $clickable 'Preserve malformed legacy text exactly' 'Malformed-markup client crash guard is missing.'
Assert-Match $clickable 'appendConfirmationOptions' 'Yes/No confirmation formatter is missing.'
Assert-Match $clickable '\{Yes\} / \{No\}' 'Clickable Yes/No rendering is missing.'
Assert-Match $clickable 'appendTravelPromptOptions' 'Open travel questions do not expose destination options.'
Assert-Match $clickable 'isOpenTravelQuestion' 'Open travel questions are not separated from Yes/No confirmations.'
Assert-Match $clickable 'message:lower\(\):gsub\("\[\{\}\]", ""\)' 'Linked aliases are not normalized before question classification.'
Assert-Match $clickable 'appendGreetingOptions' 'Greeting option menu is missing.'
Assert-Match $clickable 'nodeLeadsToTravel' 'Travel destination discovery is missing.'
Assert-Match $clickable 'pcall\(node\.checkMessage, node, player, normalized\)' 'Unavailable duplicate keywords are not filtered through the NPC condition.'
Assert-Match $clickable '"passage"' 'Travel submenu entry keyword is missing.'
Assert-Match $clickable 'npc:isMerchant\(\)' 'Shop detection for clickable Trade is missing.'
Assert-Match $clickable '"Balance"[\s\S]*"Deposit"[\s\S]*"Withdraw"[\s\S]*"Transfer"' 'Bank menu options are incomplete.'

# Manual typed keywords still use the original per-player KeywordHandler path.
Assert-Match $keywordHandler 'function KeywordHandler:processMessage\(npc, player, message\)' 'Manual keyword processing was removed.'
Assert-Match $keywordHandler 'self\.lastNode\[playerId\]' 'Keyword state is not isolated per player.'
Assert-Match $keywordHandler 'parameters\.cost\s*~=\s*nil\s*and\s*nodeLeadsToTravel\(node\)' 'Parent travel offers with access conditions are not bypassed safely.'
Assert-Match $keywordHandler 'do not turn[\s\S]*item-based free-travel branches' 'Item-based free-travel protection is missing.'
if ($clickable -match 'setStorageValue|addItem|removeItem|teleportTo|removeMoney') {
    throw 'Presentation helper must not alter quest, item, travel or economy state.'
}

$npcRoot = Join-Path $Root 'Server\data-global\npc'
$npcFiles = @(Get-ChildItem -LiteralPath $npcRoot -File -Filter '*.lua')
$interactiveFiles = @()
$handlerFiles = @()
foreach ($file in $npcFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match 'NpcHandler:new\s*\(') { $handlerFiles += $file.FullName }
    if ($content -match 'NpcHandler:new\s*\(|onCreatureSay|creatureSayCallback|addKeyword') { $interactiveFiles += $file.FullName }
}
if ($handlerFiles.Count -lt 1100) { throw "Unexpected NpcHandler coverage: $($handlerFiles.Count) files." }
$uncovered = @($interactiveFiles | Where-Object { $_ -notin $handlerFiles })
if ($uncovered.Count -gt 0) { throw "Interactive NPC files outside the central handler: $($uncovered -join ', ')" }

$boat = Read-ProjectFile 'Server\data-global\npc\captain_bluebear.lua'
Assert-Match $boat 'addTravelKeyword[\s\S]*destination' 'Boat sample has no travel destination flow.'
Assert-Match $boat 'addChildKeyword\(\{\s*"yes"' 'Boat confirmation keyword is missing.'

$carpet = Read-ProjectFile 'Server\data-global\npc\uzon.lua'
Assert-Match $carpet 'addTravelKeyword[\s\S]*destination' 'Carpet sample has no travel destination flow.'
Assert-Match $carpet 'addChildKeyword\(\{\s*"yes"' 'Carpet confirmation keyword is missing.'

$shop = Read-ProjectFile 'Server\data-global\npc\ahmet.lua'
Assert-Match $shop 'npcConfig\.shop' 'Shop sample is not registered as a merchant.'

$bank = Read-ProjectFile 'Server\data-global\npc\adrian.lua'
Assert-Match $bank 'parseBank\(' 'Bank sample does not route typed/clicked messages through the bank parser.'
Assert-Match $bank 'deposit[\s\S]*withdraw[\s\S]*bank account' 'Bank greeting does not expose enough context for clickable options.'

$quest = Read-ProjectFile 'Server\data-global\npc\amanda.lua'
Assert-Match $quest 'addKeyword\(\{\s*"mission"' 'Quest NPC sample is missing its mission keyword.'
Assert-Match $quest 'addChildKeyword\(\{\s*"yes"' 'Quest NPC sample is missing explicit acceptance.'

$task = Read-ProjectFile 'Server\data-global\npc\grizzly_adams.lua'
Assert-Match $task '\{tasks\}|\{task\}' 'Task NPC sample has no clickable entry point.'
Assert-Match $task '\[[Pp]layerId\]' 'Task NPC conversation state is not isolated per player.'

$yana = Read-ProjectFile 'Server\data-global\npc\yana.lua'
Assert-Match $yana '\{Skills\}[\s\S]*\{Elemental Damage\}[\s\S]*\{Support\}' 'Yana category menu is not clickable.'
Assert-Match $yana '\{Yes\}[\s\S]*\{No\}[\s\S]*\{Back\}' 'Yana confirmation/back flow is incomplete.'
Assert-Match $yana 'playerState\[playerId\]' 'Yana state is not isolated per player.'

$blessing = Read-ProjectFile 'Server\data-global\npc\alia.lua'
Assert-Match $blessing '\{blessings\}|\{twist of fate\}' 'Blessing NPC sample has no clickable service keyword.'

$cassino = Read-ProjectFile 'Server\data-global\npc\cassino.lua'
Assert-Match $cassino '\{High\}\s*/\s*\{Low\}' 'Cassino high/low choices are not independently clickable.'
Assert-Match $cassino '\{1\}.*\{2\}.*\{3\}.*\{4\}.*\{5\}.*\{6\}' 'Cassino number choices are not independently clickable.'

foreach ($buddelFile in @('buddel.lua', 'buddel_tyrsung.lua', 'buddel_helheim.lua', 'buddel_okolnir.lua', 'buddel_raider_camp.lua')) {
    $buddel = Read-ProjectFile "Server\data-global\npc\$buddelFile"
    Assert-Match $buddel 'condition, ringCheck, helheimAccess = function\(\) return true end, nil, nil' "$buddelFile still requires quest storage for travel dialogue."
    Assert-Match $buddel 'Do you want to travel\?' "$buddelFile does not expose a clickable Yes/No confirmation."
    if ($buddel -match 'destination = randomDestination \}, randomNumber') {
        throw "$buddelFile can still ignore Yes when the random fallback condition fails."
    }
}

Write-Output "PASS: $($npcFiles.Count) NPC files audited; $($handlerFiles.Count) interactive NPCs use the click-first central layer with manual keyword compatibility."
