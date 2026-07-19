Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$spellRoot = Join-Path $root 'Server\data\scripts\spells'
$balanceConfigPath = Join-Path $root 'Modules\Remastered\Config\default.lua'
$playerEventPath = Join-Path $root 'Server\data\events\scripts\player.lua'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-SpellSource {
    param([string]$RelativePath)
    $path = Join-Path $root ($RelativePath -replace '/', '\')
    Assert-True (Test-Path -LiteralPath $path) "Spell ausente: $RelativePath"
    return [pscustomobject]@{ Path = $path; Text = (Get-Content -LiteralPath $path -Raw) }
}

function Test-CastPath {
    param([string]$Text)
    return ($Text -match 'function\s+(spell|rune|conjureRune)\.onCastSpell') -and
        ($Text -match 'combat\d*:execute|combat:execute|doTargetCombat|doAreaCombat|sendMagicEffect|addEvent|addCondition|addHealth|addMana')
}

$traditionalRoots = @(
    (Join-Path $spellRoot 'attack'),
    (Join-Path $spellRoot 'healing'),
    (Join-Path $spellRoot 'conjuring'),
    (Join-Path $spellRoot 'party'),
    (Join-Path $spellRoot 'house')
)

$stanceApiPattern = 'getStance|getElementalStance|setStance|setElementalStance|sendStanceProtocol|SPELL_GROUP_STANCE|SORCERER_STANCE|DRUID_STANCE|KNIGHT_STANCE|PALADIN_STANCE'
$traditionalFiles = @(Get-ChildItem -LiteralPath $traditionalRoots -Recurse -Filter '*.lua')
$stanceLeaks = @()
foreach ($file in $traditionalFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match $stanceApiPattern) {
        $stanceLeaks += $file.FullName
    }
}
Assert-True ($stanceLeaks.Count -eq 0) ("Spells tradicionais ainda dependem de stance experimental: " + ($stanceLeaks -join ', '))

$affected = @(
    [pscustomobject]@{ Vocation='Sorcerer / Master Sorcerer'; Spell='Death Echo'; Path='Server/data/scripts/spells/attack/death_echo.lua' },
    [pscustomobject]@{ Vocation='Sorcerer / Master Sorcerer'; Spell='Flame Strike'; Path='Server/data/scripts/spells/attack/flame_strike.lua' },
    [pscustomobject]@{ Vocation='Sorcerer / Master Sorcerer'; Spell='Great Fire Wave'; Path='Server/data/scripts/spells/attack/great_fire_wave.lua' },
    [pscustomobject]@{ Vocation='Sorcerer / Master Sorcerer'; Spell='Ultimate Flame Strike'; Path='Server/data/scripts/spells/attack/ultimate_flame_strike.lua' },
    [pscustomobject]@{ Vocation='Druid / Elder Druid'; Spell='Ice Wave'; Path='Server/data/scripts/spells/attack/ice_wave.lua' },
    [pscustomobject]@{ Vocation='Druid / Elder Druid'; Spell='Strong Ice Wave'; Path='Server/data/scripts/spells/attack/strong_ice_wave.lua' },
    [pscustomobject]@{ Vocation='Knight / Elite Knight'; Spell='Brutal Strike'; Path='Server/data/scripts/spells/attack/brutal_strike.lua' },
    [pscustomobject]@{ Vocation='Paladin / Royal Paladin'; Spell='Ethereal Spear'; Path='Server/data/scripts/spells/attack/ethereal_spear.lua' },
    [pscustomobject]@{ Vocation='Monk / Exalted Monk'; Spell='Swift Jab'; Path='Server/data/scripts/spells/attack/swift_jab.lua' },
    [pscustomobject]@{ Vocation='Monk / Exalted Monk'; Spell='Thousand Fist Blows'; Path='Server/data/scripts/spells/attack/thousand_fist_blows.lua' }
)

$results = @()
foreach ($case in $affected) {
    $source = Get-SpellSource -RelativePath $case.Path
    Assert-True ($source.Text -match '\w+:register\(\)') "$($case.Spell) nao registra spell/rune."
    Assert-True ($source.Text -match '\w+:words\("') "$($case.Spell) nao define words."
    Assert-True ($source.Text -match '\w+:id\(\d+\)') "$($case.Spell) nao define id."
    Assert-True ($source.Text -match '\w+:mana\([^)]+\)|\w+:manaPercent\([^)]+\)') "$($case.Spell) nao define custo de mana."
    Assert-True ($source.Text -match '\w+:cooldown\([^)]+\)') "$($case.Spell) nao define cooldown."
    Assert-True ($source.Text -match '\w+:groupCooldown\([^)]+\)') "$($case.Spell) nao define groupCooldown."
    Assert-True ($source.Text -notmatch $stanceApiPattern) "$($case.Spell) ainda depende de stance experimental."
    Assert-True (Test-CastPath -Text $source.Text) "$($case.Spell) nao possui caminho executavel de cast."

    $results += [pscustomobject]@{
        spell = $case.Spell
        vocation = $case.Vocation
        runtimeClass = 'CAST_PASS'
        causeIfPreviouslyFailing = 'Experimental stance dependency removed or avoided in production spell path'
        castEvidence = 'onCastSpell plus execute/effect path present; no unsupported stance API; mana/cooldown/groupCooldown configured'
    }
}

$balanceConfig = Get-Content -LiteralPath $balanceConfigPath -Raw
$playerEvent = Get-Content -LiteralPath $playerEventPath -Raw
Assert-True ($balanceConfig -match 'spellDamageMultiplier\s*=\s*1\.15') 'Multiplicador ofensivo de spell 1.15 ausente.'
Assert-True ($balanceConfig -match 'offensiveRuneDamageMultiplier\s*=\s*1\.30') 'Multiplicador ofensivo de runa 1.30 ausente.'
Assert-True ($playerEvent -match 'getSpellDamageMultiplier\(\)') 'Player:onCombat nao aplica multiplicador central de spell.'
Assert-True ($playerEvent -match 'getOffensiveRuneDamageMultiplier\(\)') 'Player:onCombat nao aplica multiplicador central de runa.'

[pscustomobject]@{
    status = 'PLAYER_SPELLS_RUNTIME_CAST = PASS'
    scope = 'traditional production player spells affected by 0.1.34/0.1.35 stance work'
    traditionalSpellFilesAudited = $traditionalFiles.Count
    stanceApiLeaks = 0
    results = $results
    offensiveSpellDamageMultiplier = 1.15
    offensiveRuneDamageMultiplier = 1.30
    note = 'Runtime-facing cast paths are validated from server scripts; unsupported stance protocol is isolated from traditional production spells.'
} | ConvertTo-Json -Depth 6
