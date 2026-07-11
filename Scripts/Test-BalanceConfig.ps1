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
$invalidAttackSpeeds = @($allVocations | Where-Object { [int]$_.attackspeed -ne 1000 })
Assert-True ($invalidAttackSpeeds.Count -eq 0) ('Vocations sem ataque 2x: ' + (($invalidAttackSpeeds | ForEach-Object name) -join ', '))

[pscustomobject]@{status='passed'; experienceEffective=8; skillsEffective=3; magicEffective=3; attackIntervalMs=1000; attackSpeedMultiplier=2; duplicateMultipliers=$false; vocationsValidated=$allVocations.Count} | ConvertTo-Json
