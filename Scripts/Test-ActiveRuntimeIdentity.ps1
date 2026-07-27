param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$config = Get-Content -Raw (Join-Path $Root 'Config/launcher-config.json') | ConvertFrom-Json
$clientServerScript = Get-Content -Raw (Join-Path $Root 'Client/ligar_servidor.ps1')
$remasteredConfig = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Config/default.lua')
$balanceModule = Get-Content -Raw (Join-Path $Root 'Modules/Remastered/Balance/BalanceModule/main.lua')

Assert-True ($config.serverExe -eq 'Server\crystalserver.exe') 'Launcher serverExe does not point to the package Server directory.'
Assert-True ($config.serverWorkingDirectory -eq 'Server') 'Launcher serverWorkingDirectory does not point to Server.'
Assert-True ($config.clientExe -eq 'Client\bin\client-local.exe') 'Launcher clientExe does not point to Client/bin/client-local.exe.'
Assert-True ($clientServerScript -notmatch 'C:\\otserv') 'Client/ligar_servidor.ps1 still references C:\otserv.'
Assert-True ($clientServerScript -match 'Split-Path -Parent \$PSScriptRoot') 'Client/ligar_servidor.ps1 does not resolve the project root from its own location.'
Assert-True ($remasteredConfig -match 'version\s*=\s*"0\.1\.38-test"') 'Remastered runtime version is not 0.1.38-test.'
Assert-True ($remasteredConfig -match 'label\s*=\s*"0\.1\.38-runtime-fix"') 'Remastered runtime build label is missing.'
Assert-True ($balanceModule -match 'datapack=%s') 'Balance module does not log the active datapack.'
Assert-True ($balanceModule -match 'spellCooldown x%s') 'Balance module does not log spell cooldown multiplier.'

Write-Host 'PASS: active runtime identity and launcher/server path checks passed.'
exit 0
