param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$tool = Join-Path $Root 'Tools\MapPatch\Invoke-MapPatch.ps1'
$patchRoot = Join-Path $Root 'MapPatches\TestRoom'
$invalidRoot = Join-Path $Root 'UpstreamTesting\MapPatches\InvalidCases'
New-Item -ItemType Directory -Force -Path $invalidRoot | Out-Null

function Invoke-PatchTool {
    param([string]$Mode, [string]$PatchPath, [bool]$ExpectSuccess)
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tool -Mode $Mode -PatchPath $PatchPath -Root $Root 2>&1
    $code = $LASTEXITCODE
    if ($ExpectSuccess -and $code -ne 0) { throw "$Mode expected success for $PatchPath but failed:`n$output" }
    if (-not $ExpectSuccess -and $code -eq 0) { throw "$Mode expected failure for $PatchPath but passed." }
    return [pscustomobject]@{mode=$Mode; patch=$PatchPath; exitCode=$code; expectedSuccess=$ExpectSuccess}
}

function New-InvalidPatch {
    param([string]$Name, [scriptblock]$Mutate)
    $dir = Join-Path $invalidRoot $Name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $patch = Get-Content -Raw (Join-Path $patchRoot 'patch.json') | ConvertFrom-Json
    & $Mutate $patch
    $patch | ConvertTo-Json -Depth 12 | Set-Content -Path (Join-Path $dir 'patch.json') -Encoding UTF8
    return $dir
}

$results = @()
$results += Invoke-PatchTool -Mode Validate -PatchPath $patchRoot -ExpectSuccess $true
$results += Invoke-PatchTool -Mode ApplySandbox -PatchPath $patchRoot -ExpectSuccess $true
$results += Invoke-PatchTool -Mode ApplySandbox -PatchPath $patchRoot -ExpectSuccess $true
$results += Invoke-PatchTool -Mode Rollback -PatchPath $patchRoot -ExpectSuccess $true

$conflict = New-InvalidPatch 'coordinate-conflict' {
    param($p)
    $p.area.from.x = 32152; $p.area.from.y = 31123; $p.area.from.z = 0
    $p.area.to.x = 32155; $p.area.to.y = 31126; $p.area.to.z = 0
    $p.spawns[0].x = 32153; $p.spawns[0].y = 31125; $p.spawns[0].z = 0
}
$results += Invoke-PatchTool -Mode Validate -PatchPath $conflict -ExpectSuccess $false

$missingMonster = New-InvalidPatch 'missing-monster' {
    param($p)
    $p.spawns[0].name = 'Definitely Missing Monster'
}
$results += Invoke-PatchTool -Mode Validate -PatchPath $missingMonster -ExpectSuccess $false

$missingNpc = New-InvalidPatch 'missing-npc' {
    param($p)
    $p.npcs = @(
        [pscustomobject]@{
            name = 'Definitely Missing Npc'
            x = 10004
            y = 10004
            z = 7
            direction = 'south'
        }
    )
}
$results += Invoke-PatchTool -Mode Validate -PatchPath $missingNpc -ExpectSuccess $false

$badTeleport = New-InvalidPatch 'invalid-teleport' {
    param($p)
    $p.teleports[0].to.x = $p.teleports[0].from.x
    $p.teleports[0].to.y = $p.teleports[0].from.y
    $p.teleports[0].to.z = $p.teleports[0].from.z
}
$results += Invoke-PatchTool -Mode Validate -PatchPath $badTeleport -ExpectSuccess $false

$featureText = Get-Content -Raw (Join-Path $Root 'Modules\Remastered\Config\features.lua')
if ($featureText -notmatch [regex]::Escape('enable_map_patch_test_room = false')) {
    throw 'Feature flag enable_map_patch_test_room must remain false.'
}
$results += [pscustomobject]@{mode='FeatureFlag'; patch='enable_map_patch_test_room'; exitCode=0; expectedSuccess=$true}

$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    status = 'passed'
    results = $results
}
$reportPath = Join-Path $Root 'UpstreamTesting\MapPatches\pipeline-test-report.json'
$report | ConvertTo-Json -Depth 12 | Set-Content -Path $reportPath -Encoding UTF8
$report | ConvertTo-Json -Depth 12
