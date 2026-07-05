Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $repo 'Launcher\Modules'
$work = Join-Path $repo 'tmp\update-ux-tests'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
$install = Join-Path $work 'install'
$remote = Join-Path $work 'remote'
New-Item -ItemType Directory -Force -Path $install,$remote | Out-Null

$env:TRM_ROOT = $install
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

Ensure-TrmProjectStructure
Set-Content -Path (Join-Path $install 'version.json') -Value '{"name":"TibiaRemastered","version":"1.0.0","channel":"dev"}' -Encoding UTF8
$config = Get-TrmConfig
$config.remoteVersionUrl = Join-Path $remote 'version.json'
$config.remoteManifestUrl = Join-Path $remote 'manifest.json'
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config

New-Item -ItemType Directory -Force -Path (Join-Path $remote 'Assets'),(Join-Path $remote 'UserData\Database'),(Join-Path $install 'Assets'),(Join-Path $install 'UserData\Database') | Out-Null
Set-Content -Path (Join-Path $install 'Assets\update-test.txt') -Value 'old' -Encoding UTF8
Set-Content -Path (Join-Path $install 'UserData\Database\player.db') -Value 'private-local' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'Assets\update-test.txt') -Value 'new' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'UserData\Database\player.db') -Value 'remote-private' -Encoding UTF8
Set-Content -Path (Join-Path $remote 'version.json') -Value '{"name":"TibiaRemastered","version":"1.0.1","channel":"dev"}' -Encoding UTF8

$asset = Join-Path $remote 'Assets\update-test.txt'
$protected = Join-Path $remote 'UserData\Database\player.db'
$manifest = [pscustomobject]@{
    version = '1.0.1'
    generatedAt = (Get-Date).ToString('s')
    hashAlgorithm = 'SHA256'
    files = @(
        [pscustomobject]@{ path='Assets/update-test.txt'; sha256=(Get-FileHash $asset -Algorithm SHA256).Hash.ToLowerInvariant(); size=(Get-Item $asset).Length; url=$asset; overwrite=$true; category='Assets' },
        [pscustomobject]@{ path='UserData/Database/player.db'; sha256=(Get-FileHash $protected -Algorithm SHA256).Hash.ToLowerInvariant(); size=(Get-Item $protected).Length; url=$protected; overwrite=$true; category='UserData' }
    )
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $remote 'manifest.json') -Encoding UTF8

$result = Invoke-TrmUpdateOrRepair
$updatedContent = (Get-Content -Raw (Join-Path $install 'Assets\update-test.txt')).Trim()
$protectedContent = (Get-Content -Raw (Join-Path $install 'UserData\Database\player.db')).Trim()
$updatedVersion = (Get-Content -Raw (Join-Path $install 'version.json') | ConvertFrom-Json).version
if ($updatedContent -ne 'new') { throw 'Arquivo normal nao foi atualizado.' }
if ($protectedContent -ne 'private-local') { throw 'Arquivo protegido foi sobrescrito.' }
if ($updatedVersion -ne '1.0.1') { throw 'version.json local nao foi atualizado.' }
$sameVersionResult = Invoke-TrmUpdateOrRepair
if ($sameVersionResult.downloaded -ne 0) { throw 'Versao local igual a remota baixou arquivos indevidamente.' }

$badManifest = $manifest | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$badManifest.files[0].sha256 = '0000000000000000000000000000000000000000000000000000000000000000'
$badManifest.version = '1.0.2'
$badManifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $remote 'manifest.json') -Encoding UTF8
Set-Content -Path $asset -Value 'bad-hash-content' -Encoding UTF8
$hashBlocked = $false
try { Invoke-TrmUpdateOrRepair | Out-Null } catch { $hashBlocked = ($_.Exception.Message -match 'Hash mismatch') }
if (-not $hashBlocked) { throw 'Hash invalido nao bloqueou update.' }

$config.remoteManifestUrl = Join-Path $remote 'missing-manifest.json'
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config
$missingManifestBlocked = $false
try { Invoke-TrmUpdateOrRepair | Out-Null } catch { $missingManifestBlocked = ($_.Exception.Message -match 'manifest remoto|internet') }
if (-not $missingManifestBlocked) { throw 'Manifest indisponivel nao gerou erro claro.' }

[pscustomobject]@{
    status = 'passed'
    downloaded = $result.downloaded
    sameVersionDownloaded = $sameVersionResult.downloaded
    protected = $result.protected
    version = $updatedVersion
    hashInvalidBlocked = $hashBlocked
    missingManifestBlocked = $missingManifestBlocked
} | ConvertTo-Json -Depth 8
