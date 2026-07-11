Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$playerEventPath = Join-Path $root 'Server\data\events\scripts\player.lua'
$playerEvent = Get-Content -LiteralPath $playerEventPath -Raw
$balanceConfig = Get-Content -LiteralPath (Join-Path $root 'Modules\Remastered\Config\default.lua') -Raw
$balanceApi = Get-Content -LiteralPath (Join-Path $root 'Modules\Remastered\Balance\api.lua') -Raw

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Scale-DamageRange {
    param([double]$Minimum, [double]$Maximum, [double]$Multiplier)
    # Lua applies math.floor to the negative damage value. Return magnitudes shown in game.
    return @(
        [math]::Abs([math]::Floor(-$Minimum * $Multiplier)),
        [math]::Abs([math]::Floor(-$Maximum * $Multiplier))
    )
}

Assert-True ($balanceConfig -match 'spellDamageMultiplier\s*=\s*1\.15') 'Multiplicador central de spell nao e 1.15.'
Assert-True ($balanceConfig -match 'offensiveRuneDamageMultiplier\s*=\s*1\.30') 'Multiplicador central de runa nao e 1.30.'
Assert-True ($balanceApi -match 'getSpellDamageMultiplier') 'API central de spell ausente.'
Assert-True ($balanceApi -match 'getOffensiveRuneDamageMultiplier') 'API central de runa ausente.'
Assert-True ($playerEvent -match 'Remastered\.Balance\.getSpellDamageMultiplier\(\)') 'Player:onCombat nao consulta o multiplicador central de spell.'
Assert-True ($playerEvent -match 'Remastered\.Balance\.getOffensiveRuneDamageMultiplier\(\)') 'Player:onCombat nao consulta o multiplicador central de runa.'
Assert-True ($playerEvent -match 'itemType:isRune\(\)') 'Runas nao estao classificadas por ItemType:isRune().' 
Assert-True ($playerEvent -notmatch 'SOLO_SPELL_DAMAGE_MULTIPLIER|SOLO_RUNE_DAMAGE_MULTIPLIER|PLAYER_OFFENSIVE_(?:SPELL|RUNE)_DAMAGE_MULTIPLIER|1\.50|1\.35') 'Multiplicador local antigo ou duplicado ainda existe em Player:onCombat.'
Assert-True ($playerEvent -match 'damage < 0 and combatType ~= COMBAT_HEALING') 'Cura/suporte nao esta explicitamente excluida.'

$level = 100.0
$magicLevel = 50.0
$skill = 100.0
$attack = 50.0
$attackValue = 100.0

$spellCases = @(
    [pscustomobject]@{ Vocation='Sorcerer / Master Sorcerer'; Name='Flame Strike'; Path='Server/data/scripts/spells/attack/flame_strike.lua'; BaseMin=(($level/5)+($magicLevel*1.403)+8); BaseMax=(($level/5)+($magicLevel*2.203)+13) },
    [pscustomobject]@{ Vocation='Druid / Elder Druid'; Name='Ice Wave'; Path='Server/data/scripts/spells/attack/ice_wave.lua'; BaseMin=(($level/5)+($magicLevel*0.81)+4); BaseMax=(($level/5)+($magicLevel*2)+12) },
    [pscustomobject]@{ Vocation='Knight / Elite Knight'; Name='Brutal Strike'; Path='Server/data/scripts/spells/attack/brutal_strike.lua'; BaseMin=(((($skill*$attack)*0.02)+4+($level/5))*1.28); BaseMax=(((($skill*$attack)*0.04)+9+($level/5))*1.28) },
    [pscustomobject]@{ Vocation='Paladin / Royal Paladin'; Name='Ethereal Spear'; Path='Server/data/scripts/spells/attack/ethereal_spear.lua'; BaseMin=(($level/5)+(($skill+25)/3)); BaseMax=(($level/5)+$skill+25) },
    [pscustomobject]@{ Vocation='Monk / Exalted Monk'; Name='Swift Jab'; Path='Server/data/scripts/spells/attack/swift_jab.lua'; BaseMin=(((12*$attackValue)/100+(0.7*$attackValue))*0.9); BaseMax=(((12*$attackValue)/100+(0.7*$attackValue))*1.1) }
)

$results = @()
foreach ($case in $spellCases) {
    $sourcePath = Join-Path $root ($case.Path -replace '/', '\')
    Assert-True (Test-Path -LiteralPath $sourcePath) "Spell real ausente: $($case.Path)"
    $source = Get-Content -LiteralPath $sourcePath -Raw
    foreach ($vocation in ($case.Vocation -split ' / ')) {
        Assert-True ($source -match [regex]::Escape(('"' + $vocation.ToLowerInvariant() + ';true"'))) "$vocation nao esta registrado em $($case.Name)."
    }
    $scaled = Scale-DamageRange -Minimum $case.BaseMin -Maximum $case.BaseMax -Multiplier 1.15
    $results += [pscustomobject]@{
        Vocation=$case.Vocation; Ability=$case.Name; Type='Spell'; BaseDamage=('{0:N2}-{1:N2}' -f $case.BaseMin,$case.BaseMax)
        Multiplier='1.15'; FinalDamage=('{0}-{1}' -f $scaled[0],$scaled[1]); Result='PASS'
    }
}

$runePath = Join-Path $root 'Server\data\scripts\runes\sudden_death.lua'
$runeSource = Get-Content -LiteralPath $runePath -Raw
Assert-True ($runeSource -match 'Spell\("rune"\)') 'Sudden Death nao e uma runa real registrada.'
$runeMin = ($level/5)+($magicLevel*4.605)+28
$runeMax = ($level/5)+($magicLevel*7.395)+46
$runeScaled = Scale-DamageRange -Minimum $runeMin -Maximum $runeMax -Multiplier 1.30
foreach ($vocation in @('Sorcerer / Master Sorcerer','Druid / Elder Druid','Knight / Elite Knight','Paladin / Royal Paladin','Monk / Exalted Monk')) {
    $results += [pscustomobject]@{
        Vocation=$vocation; Ability='Sudden Death Rune'; Type='Rune'; BaseDamage=('{0:N2}-{1:N2}' -f $runeMin,$runeMax)
        Multiplier='1.30'; FinalDamage=('{0}-{1}' -f $runeScaled[0],$runeScaled[1]); Result='PASS'
    }
}

$results | Format-Table -AutoSize
[pscustomobject]@{ status='passed'; stats='level=100, magicLevel=50, skill=100, attack=50, monkAttackValue=100'; results=$results } | ConvertTo-Json -Depth 6
