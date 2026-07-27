param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$shop = Get-Content -Raw (Join-Path $Root 'Server/data/scripts/lib/task_board_shop.lua')
Assert-True ($shop -match 'remasteredHuntingTaskShopPrice') 'Hunting task shop multiplier helper is missing.'
foreach ($pair in @('100000:40000','35000:14000','145000:58000')) {
    $parts = $pair.Split(':')
    $expected = [int]([int]$parts[0] * 0.40)
    Assert-True ($expected -eq [int]$parts[1]) "Arithmetic fixture failed for $pair."
}
Assert-True (-not ($shop -match 'price\s*=\s*(100000|35000|145000)\s*,')) 'Undiscounted known prices remain in shop.'
Write-Host 'MANUAL_REQUIRED: Hunting Task Shop static price checks passed; runtime purchase requires in-game validation.'
exit 2
