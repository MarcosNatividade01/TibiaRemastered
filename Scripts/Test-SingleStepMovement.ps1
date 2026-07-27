param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$clientSources = @(rg --files (Join-Path $Root 'Client') -g '*.lua' -g '*.cpp' -g '*.hpp' -g '*.h' 2>$null)
if ($clientSources.Count -eq 0) {
    Write-Host 'BLOCKED: client movement code is in the precompiled client binary; no editable operational movement source exists in this repository.'
    exit 3
}
Write-Host 'MANUAL_REQUIRED: editable client movement source detected; behavioral movement validation requires manual client input testing.'
exit 2
