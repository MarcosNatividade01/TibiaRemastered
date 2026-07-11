Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$version = GetCurrentVersion
$invite = New-TrmWorldInvite -WorldName 'FazendoTibia' -Host '192.168.0.10' -PublicHost '177.192.12.76' -Port 7172 -Version $version -Mode remote
$badModePattern = ('Local host ' + 'mode|Host local|localhost|127\.0\.0\.1')
Assert-True ($invite -match '^TIBIA_REMASTERED_INVITE') 'Convite novo nao contem cabecalho oficial.'
Assert-True ($invite -match "version=$([regex]::Escape($version))") 'Convite novo nao contem a versao real.'
Assert-True ($invite -match 'publicHost=177\.192\.12\.76') 'Convite novo nao contem publicHost.'
Assert-True ($invite -notmatch $badModePattern) 'Convite remoto contem texto/local host indevido.'

$parsed = ConvertFrom-TrmWorldInvite $invite
Assert-True $parsed.valid "Convite remoto oficial nao foi aceito: $($parsed.error)"
Assert-True ($parsed.host -eq '192.168.0.10') 'Parser nao extraiu host correto.'
Assert-True ($parsed.publicHost -eq '177.192.12.76') 'Parser nao extraiu publicHost correto.'
Assert-True ([int]$parsed.port -eq 7172) 'Parser nao extraiu porta correta.'
Assert-True ($parsed.version -eq $version) 'Parser nao extraiu versao correta.'
Assert-True ($parsed.mode -eq 'remote') 'Parser nao extraiu modo remote.'

$copyText = Get-TrmCopyableWorldInvite -InviteText $invite
Assert-True ($copyText -eq $invite) 'Fonte do botao Copiar Convite alterou o convite oficial.'
Assert-True ($copyText -notmatch 'CHANGELOG|Novidades|Atualizacoes|Diagnostico|Status:') 'Fonte do clipboard contem changelog, novidades ou diagnostico.'

$remoteLoopbackRejected = $false
try { New-TrmWorldInvite -WorldName 'FazendoTibia' -Host 'localhost' -Port 7172 -Version $version -Mode remote | Out-Null } catch { $remoteLoopbackRejected = $true }
Assert-True $remoteLoopbackRejected 'Gerador aceitou localhost em convite remoto.'

$parsedRemoteLoopback = ConvertFrom-TrmWorldInvite @"
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=127.0.0.1
publicHost=127.0.0.1
port=7172
version=$version
mode=remote
"@
Assert-True (-not $parsedRemoteLoopback.valid) 'Parser aceitou localhost em convite remoto.'

$hostLocal = New-TrmWorldInvite -WorldName 'FazendoTibia' -Host '127.0.0.1' -Port 7172 -Version $version -Mode 'host-local'
$parsedHostLocal = ConvertFrom-TrmWorldInvite $hostLocal
Assert-True (-not $parsedHostLocal.valid) 'Convite host-local foi aceito em Entrar em Mundo.'
Assert-True ($parsedHostLocal.error -match 'local do host') 'Erro de host-local nao ficou claro.'

$badModeText = 'Local host ' + 'mode.'
$legacyHeader = 'Tibia Remastered ' + 'Convite'
$legacyVersionLabel = 'Versao' + ':'
$legacyWithDiagnostic = @"
$legacyHeader
Mundo: FazendoTibia
IP: 192.168.0.10
Porta: 7172
$legacyVersionLabel $version
Diagnostico: warning
$legacyVersionLabel $badModeText
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

$outOfOrder = @"
TIBIA_REMASTERED_INVITE
mode=remote
version=$version
publicHost=177.192.12.76
port=7172
host=192.168.0.10
world=FazendoTibia
"@
$parsedOutOfOrder = ConvertFrom-TrmWorldInvite $outOfOrder
Assert-True $parsedOutOfOrder.valid "Convite fora de ordem nao foi aceito: $($parsedOutOfOrder.error)"
Assert-True ($parsedOutOfOrder.version -eq $version -and $parsedOutOfOrder.mode -eq 'remote') 'Parser dependeu da ordem das linhas.'

$diagnostic = New-TrmNetworkDiagnosticReport -Mode host -Port 7172 -WebPort 80
Assert-True ($diagnostic.currentVersion -eq $version) 'Diagnostico nao usa a versao atual real.'
Assert-True ($diagnostic.connectionMode -eq 'host-local') 'Diagnostico nao separa mode=host-local.'
Assert-True ($diagnostic.version.localVersion -eq $version) 'Diagnostico colocou versao incorreta no objeto version.'
Assert-True ($diagnostic.version.message -notmatch ('Local host ' + 'mode|host-local|remote|offline')) 'Diagnostico misturou modo dentro da mensagem de versao.'

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse('127.0.0.1'), 0)
try {
    $listener.Start()
    $tcpPort = [int]$listener.LocalEndpoint.Port
    $report = New-TrmConnectionTestReport -Mode host-local -Host '127.0.0.1' -Port $tcpPort -WebPort 9 -WorldName 'FazendoTibia' -ExpectedVersion $version -ClientWorldAddress '127.0.0.1' -Phase 'tcp-only-test'
    Assert-True $report.tcpTest.succeeded 'Teste de conexao nao validou a porta Tibia TCP.'
    Assert-True (-not $report.loginServer.responded) 'Web/login opcional respondeu inesperadamente no teste.'
    Assert-True ($report.status -eq 'passed') "Web/login opcional bloqueou o teste TCP: $($report.failureReason)"
} finally {
    $listener.Stop()
}

[pscustomobject]@{
    status = 'passed'
    version = $version
    invite = $invite
} | ConvertTo-Json -Depth 4
