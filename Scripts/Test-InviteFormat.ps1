Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$version = Get-TrmLocalVersion
$invite = New-TrmWorldInvite -WorldName 'FazendoTibia' -Host '192.168.0.10' -Port 7172 -Version $version -Mode remote
Assert-True ($invite -match '^TIBIA_REMASTERED_INVITE') 'Convite novo nao contem cabecalho oficial.'
Assert-True ($invite -match "version=$([regex]::Escape($version))") 'Convite novo nao contem a versao real.'
Assert-True ($invite -notmatch 'Local host mode|Host local|localhost|127\.0\.0\.1') 'Convite remoto contem texto/local host indevido.'

$parsed = ConvertFrom-TrmWorldInvite $invite
Assert-True $parsed.valid "Convite remoto oficial nao foi aceito: $($parsed.error)"
Assert-True ($parsed.host -eq '192.168.0.10') 'Parser nao extraiu host correto.'
Assert-True ([int]$parsed.port -eq 7172) 'Parser nao extraiu porta correta.'
Assert-True ($parsed.version -eq $version) 'Parser nao extraiu versao correta.'
Assert-True ($parsed.mode -eq 'remote') 'Parser nao extraiu modo remote.'

$hostLocal = New-TrmWorldInvite -WorldName 'FazendoTibia' -Host '127.0.0.1' -Port 7172 -Version $version -Mode 'host-local'
$parsedHostLocal = ConvertFrom-TrmWorldInvite $hostLocal
Assert-True (-not $parsedHostLocal.valid) 'Convite host-local foi aceito em Entrar em Mundo.'
Assert-True ($parsedHostLocal.error -match 'local do host') 'Erro de host-local nao ficou claro.'

$legacyWithDiagnostic = @"
Tibia Remastered Convite
Mundo: FazendoTibia
IP: 192.168.0.10
Porta: 7172
Versao: $version
Diagnostico: warning
Versao: Local host mode.
"@
$parsedLegacy = ConvertFrom-TrmWorldInvite $legacyWithDiagnostic
Assert-True $parsedLegacy.valid "Convite legado com diagnostico nao foi aceito: $($parsedLegacy.error)"
Assert-True ($parsedLegacy.version -eq $version) 'Parser legado sobrescreveu a versao real com texto de diagnostico.'

$missingVersion = @"
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=192.168.0.10
port=7172
mode=remote
"@
$parsedMissing = ConvertFrom-TrmWorldInvite $missingVersion
Assert-True (-not $parsedMissing.valid) 'Convite oficial sem version foi aceito.'
Assert-True ($parsedMissing.error -match 'version ausente') 'Erro de version ausente nao ficou claro.'

[pscustomobject]@{
    status = 'passed'
    version = $version
    invite = $invite
} | ConvertTo-Json -Depth 4
