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
Set-Content -Path (Join-Path $remote 'version.json') -Value '{"name":"TibiaRemastered","version":"1.0.1","channel":"dev","minimumLauncherVersion":"0.1.0"}' -Encoding UTF8

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

$oldState = Resolve-TrmLauncherUpdateState -LocalVersion '0.1.15-test' -RemoteVersion '0.1.16-test'
if ($oldState.state -ne 'UPDATE_AVAILABLE') { throw "Estado incorreto para versao antiga: $($oldState.state)" }
if (-not $oldState.canUpdate -or -not $oldState.canUpdateAndPlay -or -not $oldState.canNews) { throw 'Estado UPDATE_AVAILABLE nao habilitou botoes esperados.' }
if ([string]::IsNullOrWhiteSpace([string]$oldState.remoteVersionDisplay) -or $oldState.remoteVersionDisplay -ne '0.1.16-test') { throw 'Versao disponivel nao ficou visivel para versao antiga.' }

$equalState = Resolve-TrmLauncherUpdateState -LocalVersion '0.1.16-test' -RemoteVersion '0.1.16-test'
if ($equalState.state -ne 'UP_TO_DATE') { throw "Estado incorreto para versoes iguais: $($equalState.state)" }
if ($equalState.canUpdate) { throw 'Estado UP_TO_DATE deixou Atualizar habilitado.' }
if (-not $equalState.canUpdateAndPlay -or $equalState.updatePlayText -ne 'Jogar') { throw 'Estado UP_TO_DATE nao habilitou Jogar pelo botao Atualizar e Jogar.' }

$offlineState = Resolve-TrmLauncherUpdateState -LocalVersion '0.1.15-test' -ErrorMessage 'falha simulada'
if ($offlineState.state -ne 'OFFLINE_CHECK') { throw "Estado incorreto para falha remota: $($offlineState.state)" }
if ($offlineState.remoteVersionDisplay -ne 'Nao foi possivel verificar') { throw 'Falha remota nao exibiu mensagem de versao indisponivel.' }
if (-not $offlineState.canUpdateAndPlay -or $offlineState.updatePlayText -ne 'Jogar') { throw 'Falha remota nao manteve Jogar disponivel.' }

$checkedState = Get-TrmLauncherVersionCheckState
if ($checkedState.state -ne 'UPDATE_AVAILABLE') { throw "Verificacao real em fixture nao detectou update: $($checkedState.state)" }
if ($checkedState.remoteVersionDisplay -ne '1.0.1') { throw 'Verificacao real em fixture nao exibiu versao remota.' }

$result = Invoke-TrmUpdateOrRepair
$updatedContent = (Get-Content -Raw (Join-Path $install 'Assets\update-test.txt')).Trim()
$protectedContent = (Get-Content -Raw (Join-Path $install 'UserData\Database\player.db')).Trim()
$updatedVersion = (Get-Content -Raw (Join-Path $install 'version.json') | ConvertFrom-Json).version
if ($updatedContent -ne 'new') { throw 'Arquivo normal nao foi atualizado.' }
if ($protectedContent -ne 'private-local') { throw 'Arquivo protegido foi sobrescrito.' }
if ($updatedVersion -ne '1.0.1') { throw 'version.json local nao foi atualizado.' }
$postUpdateState = Get-TrmLauncherVersionCheckState
if ($postUpdateState.state -ne 'UP_TO_DATE') { throw "Estado apos update nao ficou atualizado: $($postUpdateState.state)" }
if ($postUpdateState.canUpdate) { throw 'Apos update, botao Atualizar continuaria habilitado.' }
if (-not $postUpdateState.canUpdateAndPlay) { throw 'Apos update, Atualizar e Jogar/Jogar nao ficou disponivel.' }
if (-not (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.16' -RemoteVersion '0.1.17-test')) { throw 'Comparacao nao liberou 0.1.16 -> 0.1.17-test.' }
if (-not (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.17-test' -RemoteVersion '0.1.17-rc1')) { throw 'Comparacao nao liberou test -> rc1.' }
if (-not (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.17-rc1' -RemoteVersion '0.1.17')) { throw 'Comparacao nao liberou rc1 -> stable.' }
if (-not (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.15-test' -RemoteVersion '0.1.16-test')) { throw 'Comparacao nao liberou 0.1.15-test -> 0.1.16-test.' }
if (-not (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.16-test' -RemoteVersion '0.1.16')) { throw 'Comparacao nao tratou 0.1.16-test -> 0.1.16.' }
if (Test-TrmVersionNeedsUpdate -LocalVersion '0.1.17-test' -RemoteVersion '0.1.17-test') { throw 'Comparacao liberou update com versoes iguais.' }

Remove-Item -Path (Join-Path $install 'version.json') -Force
if ($null -ne (Read-TrmJsonFile -Path (Join-Path $install 'version.json') -Default $null)) { throw 'version.json local ausente nao resultou em fallback.' }
Set-Content -Path (Join-Path $install 'version.json') -Value '{"name":"TibiaRemastered","version":"1.0.1","channel":"dev"}' -Encoding UTF8
$sameVersionResult = Invoke-TrmUpdateOrRepair
if ($sameVersionResult.downloaded -ne 0) { throw 'Versao local igual a remota baixou arquivos indevidamente.' }

$badVersionPath = Join-Path $remote 'bad-version.json'
Set-Content -Path $badVersionPath -Value '{ invalid json' -Encoding UTF8
$config.remoteVersionUrl = $badVersionPath
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config
$badVersionBlocked = $false
try { Invoke-TrmUpdateOrRepair | Out-Null } catch { $badVersionBlocked = ($_.Exception.Message -match 'version\.json remoto') }
if (-not $badVersionBlocked) { throw 'version.json remoto invalido nao gerou erro claro.' }

$config.remoteVersionUrl = Join-Path $remote 'version.json'
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config
$badManifest = $manifest | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$badManifest.files[0].sha256 = '0000000000000000000000000000000000000000000000000000000000000000'
$badManifest.version = '1.0.2'
$badManifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $remote 'manifest.json') -Encoding UTF8
Set-Content -Path (Join-Path $remote 'version.json') -Value '{"name":"TibiaRemastered","version":"1.0.2","channel":"dev","minimumLauncherVersion":"0.1.0"}' -Encoding UTF8
Set-Content -Path $asset -Value 'bad-hash-content' -Encoding UTF8
$hashBlocked = $false
try { Invoke-TrmUpdateOrRepair | Out-Null } catch { $hashBlocked = ($_.Exception.Message -match 'Hash mismatch') }
if (-not $hashBlocked) { throw 'Hash invalido nao bloqueou update.' }

$config.remoteManifestUrl = Join-Path $remote 'missing-manifest.json'
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config
$missingManifestBlocked = $false
try { Invoke-TrmUpdateOrRepair | Out-Null } catch { $missingManifestBlocked = ($_.Exception.Message -match 'manifest(\.json)? remoto|internet') }
if (-not $missingManifestBlocked) { throw 'Manifest indisponivel nao gerou erro claro.' }

$config.remoteVersionUrl = Join-Path $remote 'missing-version.json'
Save-TrmJsonFile -Path (Join-Path $install 'Config\launcher-config.json') -Value $config
$failedCheckState = Get-TrmLauncherVersionCheckState
if ($failedCheckState.state -ne 'OFFLINE_CHECK') { throw "Falha de consulta remota nao virou OFFLINE_CHECK: $($failedCheckState.state)" }

[pscustomobject]@{
    status = 'passed'
    downloaded = $result.downloaded
    sameVersionDownloaded = $sameVersionResult.downloaded
    protected = $result.protected
    version = $updatedVersion
    hashInvalidBlocked = $hashBlocked
    badVersionBlocked = $badVersionBlocked
    missingManifestBlocked = $missingManifestBlocked
    stateOldVersion = $oldState.state
    stateEqualVersion = $equalState.state
    stateOfflineCheck = $offlineState.state
    stateAfterUpdate = $postUpdateState.state
    failedRemoteCheckState = $failedCheckState.state
} | ConvertTo-Json -Depth 8
