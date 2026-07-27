param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$server = Get-Content -Raw (Join-Path $Root 'Server/config.lua')
$balance = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Config/default.lua')
Assert-True ($server -match 'bestiaryRateCharmShopPrice\s*=\s*0\.5') 'Server charm shop rate is not 0.5.'
Assert-True ($balance -match 'charmCostMultiplier\s*=\s*0\.50') 'Central charm cost multiplier is not 0.50.'
Write-Host 'MANUAL_REQUIRED: Major/Minor charm cost configuration checks passed; runtime display and purchase require in-game validation.'
exit 2
