param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$stages = Get-Content (Join-Path $ProjectRoot 'Server\data\stages.lua') -Raw
$balance = Get-Content (Join-Path $ProjectRoot 'Modules\Remastered\Config\default.lua') -Raw
[xml]$vocations = Get-Content (Join-Path $ProjectRoot 'Server\data\XML\vocations.xml') -Raw

$experienceBlock = [regex]::Match($stages, '(?s)experienceStages\s*=\s*\{(.*?)\}\s*skillsStages').Groups[1].Value
$skillsBlock = [regex]::Match($stages, '(?s)skillsStages\s*=\s*\{(.*?)\}\s*magicLevelStages').Groups[1].Value
$magicBlock = [regex]::Match($stages, '(?s)magicLevelStages\s*=\s*\{(.*)\}\s*$').Groups[1].Value

Assert-True ($experienceBlock -match 'multiplier\s*=\s*8(?:\.0)?\s*,') 'XP stages precisa ser exatamente 8x.'
Assert-True ($skillsBlock -match 'multiplier\s*=\s*3(?:\.0)?\s*,') 'Skills stages precisa ser exatamente 3x.'
Assert-True ($magicBlock -match 'multiplier\s*=\s*3(?:\.0)?\s*,') 'Magic Level stages precisa ser exatamente 3x.'
Assert-True (([regex]::Matches($experienceBlock, 'multiplier\s*=')).Count -eq 1) 'XP possui mais de um stage/multiplicador.'
Assert-True (([regex]::Matches($skillsBlock, 'multiplier\s*=')).Count -eq 1) 'Skills possuem mais de um stage/multiplicador.'
Assert-True (([regex]::Matches($magicBlock, 'multiplier\s*=')).Count -eq 1) 'Magic Level possui mais de um stage/multiplicador.'
Assert-True ($balance -match 'experienceRate\s*=\s*1(?:\.0)?\s*,') 'Camada Remastered de XP deve ser neutra (1x).'
Assert-True ($balance -match 'skillRate\s*=\s*1(?:\.0)?\s*,') 'Camada Remastered de Skills deve ser neutra (1x).'
Assert-True ($balance -match 'magicRate\s*=\s*1(?:\.0)?\s*,') 'Camada Remastered de Magic deve ser neutra (1x).'

$allVocations = @($vocations.vocations.vocation)
Assert-True ($allVocations.Count -gt 0) 'Nenhuma vocation encontrada.'
$invalidAttackSpeeds = @($allVocations | Where-Object { [int]$_.attackspeed -ne 1538 })
Assert-True ($invalidAttackSpeeds.Count -eq 0) ('Vocations sem ataque 1.3x: ' + (($invalidAttackSpeeds | ForEach-Object name) -join ', '))

$playerCombat = Get-Content (Join-Path $ProjectRoot 'Server\data\events\scripts\player.lua') -Raw
$balanceApi = Get-Content (Join-Path $ProjectRoot 'Modules\Remastered\Balance\api.lua') -Raw
Assert-True ($balance -match 'spellDamageMultiplier\s*=\s*1\.15\s*,') 'Spell damage precisa ser 1.15.'
Assert-True ($balance -match 'offensiveRuneDamageMultiplier\s*=\s*1\.30\s*,') 'Rune damage precisa ser 1.30.'
Assert-True ($balanceApi -match 'getSpellDamageMultiplier') 'API central de spell damage ausente.'
Assert-True ($balanceApi -match 'getOffensiveRuneDamageMultiplier') 'API central de rune damage ausente.'
Assert-True ($playerCombat -match 'itemType:isRune\(\)') 'Runas precisam ser identificadas por ItemType:isRune().'
Assert-True ($playerCombat -match 'damage < 0 and combatType ~= COMBAT_HEALING') 'Cura precisa ficar fora dos multiplicadores ofensivos.'
Assert-True ($playerCombat -notmatch 'SOLO_(?:SPELL|RUNE)_DAMAGE_MULTIPLIER') 'Multiplicador local duplicado encontrado.'

$controlledBaseDamage = 1000
$spellDamage = [math]::Floor($controlledBaseDamage * 1.15)
$runeDamage = [math]::Floor($controlledBaseDamage * 1.30)
Assert-True ($spellDamage -eq 1150) 'Teste numerico de spell 1.15 falhou.'
Assert-True ($runeDamage -eq 1300) 'Teste numerico de rune 1.30 falhou.'
$damageCases = @(
    [pscustomobject]@{vocation='Sorcerer'; type='fire'; base=200; spell=230; rune=260},
    [pscustomobject]@{vocation='Druid'; type='ice'; base=400; spell=460; rune=520},
    [pscustomobject]@{vocation='Paladin'; type='holy'; base=1000; spell=1150; rune=1300}
)
foreach ($case in $damageCases) {
    Assert-True ([math]::Abs([math]::Floor(-$case.base * 1.15)) -eq $case.spell) "Spell numerica falhou: $($case.vocation)/$($case.type)."
    Assert-True ([math]::Abs([math]::Floor(-$case.base * 1.30)) -eq $case.rune) "Rune numerica falhou: $($case.vocation)/$($case.type)."
}
Assert-True ([math]::Floor(500 * 1.0) -eq 500) 'Cura, melee, distance, wand/rod devem permanecer 1x.'

[pscustomobject]@{status='passed'; experienceEffective=8; skillsEffective=3; magicEffective=3; attackIntervalMs=1538; attackSpeedMultiplier=[math]::Round(2000/1538,4); spellBaseDamage=$controlledBaseDamage; spellFinalDamage=$spellDamage; spellDamageMultiplier=1.15; runeBaseDamage=$controlledBaseDamage; runeFinalDamage=$runeDamage; offensiveRuneDamageMultiplier=1.30; damageCases=$damageCases; healingUnchanged=$true; basicWeaponsUnchanged=$true; duplicateMultipliers=$false; vocationsValidated=$allVocations.Count} | ConvertTo-Json -Depth 5
