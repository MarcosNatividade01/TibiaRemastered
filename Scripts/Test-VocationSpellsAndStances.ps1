Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$currentRoot = Join-Path $root 'Server\data\scripts\spells'
$upstreamRoot = Join-Path $root 'Upstream\CrystalLatest\data\scripts\spells'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-SpellEntries {
    param([Parameter(Mandatory=$true)][string]$BasePath)

    Get-ChildItem -LiteralPath $BasePath -Recurse -Filter *.lua | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw
        $relative = $_.FullName.Substring($BasePath.Length).TrimStart('\','/') -replace '\\','/'
        $name = if ($text -match 'spell:name\("([^"]+)"\)') { $Matches[1] } else { '' }
        $words = if ($text -match 'spell:words\("([^"]+)"\)') { $Matches[1] } else { '' }
        $id = if ($text -match 'spell:id\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $level = if ($text -match 'spell:level\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $mana = if ($text -match 'spell:mana\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $cooldown = if ($text -match 'spell:cooldown\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $groupCooldown = if ($text -match 'spell:groupCooldown\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $group = if ($text -match 'spell:group\(([^\)]+)\)') { $Matches[1].Trim() } else { '' }
        $vocations = @()
        if ($text -match 'spell:vocation\(([^\)]+)\)') {
            $vocations = [regex]::Matches($Matches[1], '"([^";]+)(?:;true)?"') | ForEach-Object { $_.Groups[1].Value }
        }

        [pscustomobject]@{
            Relative = $relative
            File = $_.Name
            Name = $name
            Words = $words
            Id = $id
            Level = $level
            Mana = $mana
            Cooldown = $cooldown
            GroupCooldown = $groupCooldown
            Group = $group
            Vocations = @($vocations)
            HasRegister = ($text -match 'spell:register\(\)')
            HasElementalStance = ($text -match 'getElementalStance')
            Text = $text
        }
    }
}

$current = @(Get-SpellEntries $currentRoot)
$upstream = @(Get-SpellEntries $upstreamRoot)
$currentRegistered = @($current | Where-Object { $_.Name -and $_.Words -and $_.HasRegister })
$upstreamRegistered = @($upstream | Where-Object { $_.Name -and $_.Words -and $_.HasRegister })

$missing = @($upstreamRegistered | Where-Object {
    $u = $_
    -not ($currentRegistered | Where-Object { $_.Name -eq $u.Name -and $_.Words -eq $u.Words })
})

$clientCompatibleSharpshooter = $currentRegistered | Where-Object {
    $_.Name -eq 'Sharpshooter' -and $_.Words -eq 'utito tempo san' -and $_.Id -eq '135'
} | Select-Object -First 1
if ($clientCompatibleSharpshooter) {
    $missing = @($missing | Where-Object { $_.Name -ne 'Sharpshooter' })
}

$stanceNames = @(
    'Master of Flames',
    'Master of Thunder',
    'Master of Decay',
    'Shared Conservation',
    'Elemental Synthesis',
    'Blood Rage',
    'Protector',
    'Sharpshooter',
    'Divine Defiance'
)

$stanceEntries = @($currentRegistered | Where-Object { $stanceNames -contains $_.Name })
foreach ($stance in $stanceNames) {
    $entry = $stanceEntries | Where-Object { $_.Name -eq $stance } | Select-Object -First 1
    Assert-True ($null -ne $entry) "Postura ausente: $stance"
    Assert-True ($entry.Text -match 'setStance|setElementalStance') "Postura sem runtime de stance: $stance"
    if ($entry.Text -match 'getElementalStance|setElementalStance') {
        Assert-True ($entry.Text -match 'player\.getElementalStance and player:getElementalStance\(\)') "Postura elemental sem guarda de compatibilidade com o binario atual: $stance"
        Assert-True ($entry.Text -match 'player\.setElementalStance and') "Postura elemental chama setElementalStance sem guarda: $stance"
    } else {
        Assert-True ($entry.Text -match 'player\.getStance and player:getStance\(\)') "Postura sem guarda de compatibilidade com o binario atual: $stance"
        Assert-True ($entry.Text -match 'player\.setStance and') "Postura chama setStance sem guarda: $stance"
    }
    Assert-True ($entry.Group -notmatch '(^|,\s*)11($|\s*,)') "Postura publicada com secondary group 11; risco de regressao de login no client atual: $stance"
}

$sorcererStanceAttackFiles = @(
    'buzz.lua','curse.lua','death_strike.lua','electrify.lua','energy_beam.lua','energy_wave.lua','fire_wave.lua','flame_strike.lua',
    'great_death_beam.lua','great_energy_beam.lua','great_fire_wave.lua','hells_core.lua','ignite.lua','rage_of_the_skies.lua',
    'scorch.lua','strong_energy_strike.lua','strong_flame_strike.lua','ultimate_energy_strike.lua','ultimate_flame_strike.lua',
    'death_echo.lua'
)
foreach ($file in $sorcererStanceAttackFiles) {
    $entry = $current | Where-Object { $_.Relative -eq "attack/$file" } | Select-Object -First 1
    Assert-True ($null -ne $entry) "Spell ofensiva de Sorcerer ausente: $file"
    Assert-True $entry.HasElementalStance "Spell ofensiva de Sorcerer sem variante por postura: $file"
    Assert-True ($entry.Text -match 'player\.getElementalStance and player:getElementalStance\(\)') "Spell ofensiva de Sorcerer chama getElementalStance sem guarda: $file"
}

$localMultipliers = @(Select-String -Path (Join-Path $currentRoot 'attack\*.lua') -Pattern 'OFFENSIVE_SPELL_DAMAGE_MULTIPLIER' -ErrorAction SilentlyContinue)
Assert-True ($localMultipliers.Count -eq 0) 'Multiplicador local de spell ofensiva encontrado; risco de +15% duplicado.'

$playerEvent = Get-Content -LiteralPath (Join-Path $root 'Server\data\events\scripts\player.lua') -Raw
Assert-True ($playerEvent -match 'Remastered\.Balance\.getSpellDamageMultiplier\(\)') 'Multiplicador central de spells ausente.'
Assert-True ($playerEvent -match 'Remastered\.Balance\.getOffensiveRuneDamageMultiplier\(\)') 'Multiplicador central de runas ausente.'

$vocations = @(
    'sorcerer',
    'master sorcerer',
    'druid',
    'elder druid',
    'knight',
    'elite knight',
    'paladin',
    'royal paladin',
    'monk',
    'exalted monk'
)

$summary = foreach ($vocation in $vocations) {
    $reference = @($upstreamRegistered | Where-Object { $_.Vocations -contains $vocation })
    $present = @($currentRegistered | Where-Object { $_.Vocations -contains $vocation })
    $stance = @($present | Where-Object { ($_.Name -in $stanceNames) -and ($_.Text -match 'setStance|setElementalStance') })
    $attack = @($present | Where-Object { $_.Relative -like 'attack/*' })
    $support = @($present | Where-Object { $_.Relative -like 'support/*' })
    $healing = @($present | Where-Object { $_.Relative -like 'healing/*' })

    Assert-True ($present.Count -gt 0) "Sem spells registradas para vocacao: $vocation"
    Assert-True (($attack.Count -gt 0 -or $vocation -like '*druid*')) "Sem amostra ofensiva para vocacao: $vocation"
    Assert-True (($support.Count -gt 0 -or $healing.Count -gt 0)) "Sem amostra suporte/heal para vocacao: $vocation"

    [pscustomobject]@{
        Vocation = $vocation
        Reference = $reference.Count
        Present = $present.Count
        Stances = $stance.Count
        Attack = $attack.Count
        Support = $support.Count
        Healing = $healing.Count
    }
}

$duplicatedNameWords = @($currentRegistered | Group-Object Name,Words | Where-Object { $_.Count -gt 1 })
Assert-True ($missing.Count -eq 0) ("Spells ausentes em relacao ao upstream: " + (($missing | ForEach-Object { $_.Name }) -join ', '))
Assert-True ($duplicatedNameWords.Count -eq 0) ("Spells duplicadas por nome/palavras: " + (($duplicatedNameWords | ForEach-Object { $_.Name }) -join ', '))

$report = [pscustomobject]@{
    status = 'passed'
    currentRegistered = $currentRegistered.Count
    upstreamRegistered = $upstreamRegistered.Count
    missing = $missing.Count
    stances = @($stanceEntries | Select-Object Name,Words,Vocations,Level,Mana,Cooldown,GroupCooldown)
    vocationSummary = @($summary)
}

$summary | Format-Table -AutoSize
$report | ConvertTo-Json -Depth 8
