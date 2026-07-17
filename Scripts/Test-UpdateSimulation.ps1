Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$sandbox = Join-Path $root 'tmp\update-simulation'
$remote = Join-Path $sandbox 'remote'
$install = Join-Path $sandbox 'install'
if (Test-Path $sandbox) { Remove-Item -Path $sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $remote,$install | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $remote 'Client'),(Join-Path $remote 'Server'),(Join-Path $remote 'Config') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $remote 'Server\data-global\world\map-parts') | Out-Null

$env:TRM_ROOT = $install
$moduleRoot = Join-Path $root 'Launcher\Modules'
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

Set-Content -Path (Join-Path $remote 'Client\client.txt') -Value 'client-v1' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'Server\server.txt') -Value 'server-v1' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'Config\default.json') -Value '{"ok":true}' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'Server\data-global\world\map-parts\world.otbm.part001') -Value 'world-' -NoNewline -Encoding ASCII
Set-Content -Path (Join-Path $remote 'Server\data-global\world\map-parts\world.otbm.part002') -Value 'v1' -NoNewline -Encoding ASCII

function New-SimManifest([string]$RemoteRoot, [string]$Version) {
    $files = @()
    Get-ChildItem -Path $RemoteRoot -File -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($RemoteRoot.Length).TrimStart('\','/') -replace '\\','/'
        $files += [pscustomobject]@{
            path = $rel
            sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            size = $_.Length
            url = $_.FullName
            overwrite = -not $rel.StartsWith('Config/')
            category = $rel.Split('/')[0]
        }
    }
    $worldBytes = [System.Text.Encoding]::ASCII.GetBytes('world-v1')
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $worldHash = ([BitConverter]::ToString($sha.ComputeHash($worldBytes))).Replace('-','').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    $largeFiles = @(
        [pscustomobject]@{
            path = 'Server/data-global/world/world.otbm'
            sha256 = $worldHash
            size = $worldBytes.Length
            parts = @(
                'Server/data-global/world/map-parts/world.otbm.part001',
                'Server/data-global/world/map-parts/world.otbm.part002'
            )
        }
    )
    return [pscustomobject]@{version=$Version; generatedAt=(Get-Date).ToString('s'); hashAlgorithm='SHA256'; files=$files; largeFiles=$largeFiles}
}

$manifest = New-SimManifest $remote '9.9.9'
$result1 = Sync-TrmFromManifest -Manifest $manifest -ForceRepair

Set-Content -Path (Join-Path $install 'Client\client.txt') -Value 'corrupted' -Encoding UTF8
$result2 = Sync-TrmFromManifest -Manifest $manifest -ForceRepair

New-Item -ItemType Directory -Force -Path (Join-Path $install 'UserData\Database') | Out-Null
Set-Content -Path (Join-Path $install 'UserData\Database\player.db') -Value 'private' -Encoding UTF8
$protected = Test-TrmProtectedPath 'UserData/Database/player.db'

[pscustomobject]@{
    cleanInstallDownloaded = $result1.downloaded
    repairDownloaded = $result2.downloaded
    protectedPathProtected = $protected
    largeFileAssembled = (Test-Path (Join-Path $install 'Server\data-global\world\world.otbm'))
    status = if ($result1.downloaded -gt 0 -and $result2.downloaded -gt 0 -and $protected -and (Test-Path (Join-Path $install 'Server\data-global\world\world.otbm'))) { 'passed' } else { 'failed' }
} | ConvertTo-Json -Depth 8
