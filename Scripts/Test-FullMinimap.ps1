param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$minimap = Join-Path $Root 'Client/minimap'
$files = @(Get-ChildItem -LiteralPath $minimap -File -ErrorAction Stop)
Assert-True ($files.Count -ge 273) "Expected at least 273 minimap files, found $($files.Count)."
$prep = Get-Content -Raw (Join-Path $Root 'Client/preparar_cliente.ps1')
Assert-True ($prep -match 'Tibia\\packages\\Tibia\\minimap') 'Client preparation does not sync to local Tibia minimap path.'
Assert-True ($prep -match 'minimapmarkers\.bin') 'Client preparation does not handle minimap markers preservation.'
$manifestTool = Get-Content -Raw (Join-Path $Root 'Launcher/Tools/Generate-Manifest.ps1')
Assert-True (-not ($manifestTool -match "'Client/minimap'")) 'Manifest generator still excludes Client/minimap.'
Write-Host 'MANUAL_REQUIRED: full minimap install/update checks passed; visual client map validation remains manual.'
exit 2
