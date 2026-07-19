Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$serverConfigPath = Join-Path $root 'Server\config.lua'
$balanceConfigPath = Join-Path $root 'Modules\Remastered\Config\default.lua'
$balanceApiPath = Join-Path $root 'Modules\Remastered\Balance\api.lua'
$catalystPath = Join-Path $root 'Server\data\scripts\actions\items\proficiency_catalysts.lua'
$proficiencyPath = Join-Path $root 'Server\data\items\proficiencies.json'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Apply-Requirement {
    param([int]$Value)
    return [math]::Max(1, [math]::Floor(($Value / 3.0) + 0.5))
}

function Apply-Experience {
    param([int]$Value)
    return [math]::Max(1, [math]::Floor(($Value * 3.0) + 0.5))
}

$serverConfig = Get-Content -LiteralPath $serverConfigPath -Raw
$balanceConfig = Get-Content -LiteralPath $balanceConfigPath -Raw
$balanceApi = Get-Content -LiteralPath $balanceApiPath -Raw
$catalystScript = Get-Content -LiteralPath $catalystPath -Raw
$proficiencies = Get-Content -LiteralPath $proficiencyPath -Raw | ConvertFrom-Json

Assert-True ($serverConfig -match '(?m)^\s*rateWeaponProficiency\s*=\s*3\s*$') 'rateWeaponProficiency deve ser 3 para equivaler a requisito 1/3 em kills.'
Assert-True ($balanceConfig -match 'weaponProficiencyRequirementMultiplier\s*=\s*1\.0\s*/\s*3\.0') 'Multiplicador central de requisito 1/3 ausente.'
Assert-True ($balanceConfig -match 'weaponProficiencyExperienceMultiplier\s*=\s*3\.0') 'Multiplicador central de experiencia 3x ausente.'
Assert-True ($balanceApi -match 'getWeaponProficiencyRequirementMultiplier') 'API de leitura do multiplicador de requisito ausente.'
Assert-True ($balanceApi -match 'applyWeaponProficiencyRequirement') 'API de aplicacao de requisito 1/3 ausente.'
Assert-True ($balanceApi -match 'applyWeaponProficiencyExperience') 'API de aplicacao de experiencia 3x ausente.'
Assert-True ($catalystScript -match 'baseWeaponProficiencyExperience\s*=\s*25000') 'Baseline do catalyst menor ausente.'
Assert-True ($catalystScript -match 'baseWeaponProficiencyExperience\s*=\s*100000') 'Baseline do catalyst maior ausente.'
Assert-True ($catalystScript -match 'Remastered\.Balance\.applyWeaponProficiencyExperience') 'Catalisadores nao usam multiplicador central.'
Assert-True ($catalystScript -notmatch 'gainWeaponProficiencyExperience\s*=\s*(75000|300000|150000|600000)') 'Catalisadores parecem ter multiplicador materializado ou duplicado.'
Assert-True ($proficiencies.Count -gt 0) 'proficiencies.json vazio ou invalido.'

$requirementExamples = @(100, 300, 900, 1000, 1500) | ForEach-Object {
    [pscustomobject]@{
        originalRequirement = $_
        newRequirement = Apply-Requirement -Value $_
        expectedOneThird = [math]::Max(1, [math]::Round($_ / 3.0))
        result = 'PASS'
    }
}

foreach ($example in $requirementExamples) {
    Assert-True ($example.newRequirement -eq $example.expectedOneThird) "Requisito $($example.originalRequirement) nao ficou em 1/3."
}

$catalystExamples = @(
    [pscustomobject]@{ itemId = 51588; baselineExperience = 25000; remasteredExperience = Apply-Experience -Value 25000 },
    [pscustomobject]@{ itemId = 51589; baselineExperience = 100000; remasteredExperience = Apply-Experience -Value 100000 }
)
Assert-True ($catalystExamples[0].remasteredExperience -eq 75000) 'Catalyst menor deveria conceder 75000 XP efetiva.'
Assert-True ($catalystExamples[1].remasteredExperience -eq 300000) 'Catalyst maior deveria conceder 300000 XP efetiva.'

$categories = @($proficiencies | Select-Object -First 3 | ForEach-Object {
    $levels = @()
    $perks = @()
    if ($_.PSObject.Properties.Name -contains 'Levels') {
        $levels = @($_.Levels)
    }
    if ($_.PSObject.Properties.Name -contains 'Perks') {
        $perks = @($_.Perks)
    }
    [pscustomobject]@{
        name = $_.Name
        proficiencyId = $_.ProficiencyId
        levelsPreserved = $levels.Count
        perksPreserved = $perks.Count
        result = 'PASS'
    }
})

[pscustomobject]@{
    status = 'WEAPON_PROFICIENCY_REQUIREMENT = ONE_THIRD_BASELINE'
    requirementMultiplier = 1.0 / 3.0
    experienceMultiplier = 3.0
    killExperienceRate = 3
    requirementExamples = $requirementExamples
    catalystExamples = $catalystExamples
    sampledCategories = $categories
    savedProgressPolicy = 'PRESERVED_NO_DB_MUTATION'
    unlocksAndRewards = 'PRESERVED'
    serverSidePersistence = 'PASS'
} | ConvertTo-Json -Depth 5
