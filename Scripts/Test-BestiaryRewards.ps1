param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$balance = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Config/default.lua')
Assert-True ($balance -match 'bestiaryCompletionRewardMultiplier\s*=\s*4\.0') 'Central Bestiary reward multiplier is not 4.0.'
$bad = @()
Get-ChildItem -Path (Join-Path $Root 'Server/data-global/monster'), (Join-Path $Root 'Server/data-crystal/monster') -Recurse -Filter *.lua -File | ForEach-Object {
    $matches = [regex]::Matches((Get-Content -LiteralPath $_.FullName -Raw), 'CharmsPoints\s*=\s*(\d+)\s*,')
    foreach ($m in $matches) {
        $value = [int]$m.Groups[1].Value
        if ($value -lt 4 -or ($value % 4) -ne 0) {
            $bad += "$($_.FullName): CharmsPoints=$value"
        }
    }
}
if ($bad.Count -gt 0) { throw "Bestiary CharmsPoints values are not consistent with x4:`n$($bad -join "`n")" }
Write-Host 'MANUAL_REQUIRED: Bestiary reward data checks passed; runtime completion grant requires in-game validation.'
exit 2
