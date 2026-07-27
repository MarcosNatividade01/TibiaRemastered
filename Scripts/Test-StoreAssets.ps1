param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$assetsPath = Join-Path $Root 'Client/assets.json'
$assets = Get-Content -Raw $assetsPath | ConvertFrom-Json
$missing = @()
foreach ($entry in @($assets.files)) {
    $local = Join-Path $Root ('Client/' + [string]$entry.localfile)
    if (-not (Test-Path -LiteralPath $local)) { $missing += [string]$entry.localfile }
}
Assert-True ($missing.Count -eq 0) ("Client/assets.json has missing files:`n" + ($missing -join "`n"))
$store = Get-Content -Raw (Join-Path $Root 'Server/data/modules/scripts/gamestore/gamestore.lua')
$icons = [regex]::Matches($store, 'icons\s*=\s*\{([^}]*)\}') | ForEach-Object {
    [regex]::Matches($_.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
}
$reportDir = Join-Path $env:TEMP 'TibiaRemastered'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report = Join-Path $reportDir 'STORE_ASSETS_INVENTORY.csv'
"STORE_ENTRY,TYPE,SERVER_ID,CLIENT_APPEARANCE,IMAGE,STATUS" | Set-Content -LiteralPath $report
foreach ($icon in ($icons | Sort-Object -Unique)) {
    $status = if (Test-Path -LiteralPath (Join-Path $Root "Client/storeimages/$icon")) { 'FOUND_STOREIMAGE' } else { 'SERVER_ICON_REFERENCE_ONLY' }
    ('"{0}","","","","{0}","{1}"' -f $icon,$status) | Add-Content -LiteralPath $report
}
Write-Host "Store asset inventory generated: $report"
Write-Host 'MANUAL_REQUIRED: Store asset inventory generated; visual Store opening requires in-game validation.'
exit 2
