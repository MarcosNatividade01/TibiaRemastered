Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path $repo 'tmp\invite-flow-tests'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force -Path $work | Out-Null
$env:TRM_ROOT = $work
Set-Content -Path (Join-Path $work 'version.json') -Value '{"name":"TibiaRemastered","version":"0.1.19-test","channel":"dev","minimumLauncherVersion":"0.1.0"}' -Encoding UTF8
Import-Module (Join-Path $repo 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Normalize-ClipboardText([string]$Text) {
    return (($Text -replace "`r`n", "`n").Trim())
}

$version = GetCurrentVersion
$launcherSource = Get-Content -Raw (Join-Path $repo 'Launcher\Launcher.ps1')
$runtimeSource = Get-Content -Raw (Join-Path $repo 'Launcher\Modules\TibiaRemastered.Runtime.psm1')
Assert-True ($launcherSource -match 'Set-TrmRemoteInviteClipboard\s+-InviteText\s+\(\[string\]\$hostSession\.RemoteInvite\)') 'Handler Copiar Convite nao esta ligado ao convite remoto validado.'
Assert-True ($launcherSource -notmatch 'Clipboard\]\:\:SetText') 'Launcher ainda grava o clipboard diretamente sem validacao/leitura de retorno.'
Assert-True ($runtimeSource -match '(?s)function JoinOwnHostedWorld.*?BuildHostLocalConnection.*?Start-TrmClientForWorld') 'Entrar no Meu Mundo nao usa a estrutura host-local isolada.'
Assert-True ($runtimeSource -match '(?s)function JoinRemoteWorld.*?ParseRemoteInvite.*?Resolve-TrmRemoteInviteTarget') 'Entrar em Mundo nao usa parser/target remoto isolado.'
Assert-True ($runtimeSource -notmatch '(?s)if \(-not \$preflight\.loginServer\.responded\).*?throw \(Format-TrmConnectionFailure \$preflight\)') 'Fluxo remoto ainda trata web/login remoto indisponivel como falha apos TCP OK.'
Assert-True ($runtimeSource -match '(?s)Test-TrmLocalClientLoginEndpoint.*?advertisedGameHost.*?advertisedGamePort') 'Fluxo nao valida o endpoint local que anuncia host/porta ao client.'
$invite = BuildRemoteInvite -WorldName 'FazendoTibia' -Host '192.168.0.10' -PublicHost '203.0.113.10' -Port 7172 -Version $version
$badRemotePattern = 'github\.com|githubusercontent\.com|localhost|127\.0\.0\.1|mode=host-local'
Assert-True ($invite -match '^TIBIA_REMASTERED_INVITE') 'Convite remoto nao contem cabecalho oficial.'
Assert-True ($invite -match "version=$([regex]::Escape($version))") 'Convite remoto nao contem a versao real.'
Assert-True ($invite -match 'publicHost=203\.0\.113\.10') 'Convite remoto nao contem publicHost.'
Assert-True ($invite -match 'loginPort=7171') 'Convite remoto nao contem loginPort.'
Assert-True ($invite -match 'gamePort=7172') 'Convite remoto nao contem gamePort.'
Assert-True ($invite -notmatch $badRemotePattern) 'Convite remoto contem GitHub, loopback ou host-local.'

$parsed = ParseRemoteInvite $invite
Assert-True $parsed.valid "Convite remoto oficial nao foi aceito: $($parsed.error)"
Assert-True ($parsed.worldName -eq 'FazendoTibia') 'Parser nao extraiu world correto.'
Assert-True ($parsed.host -eq '192.168.0.10') 'Parser nao extraiu host correto.'
Assert-True ($parsed.publicHost -eq '203.0.113.10') 'Parser nao extraiu publicHost correto.'
Assert-True ([int]$parsed.port -eq 7172) 'Parser nao extraiu porta correta.'
Assert-True ([int]$parsed.loginPort -eq 7171) 'Parser nao extraiu loginPort correto.'
Assert-True ([int]$parsed.gamePort -eq 7172) 'Parser nao extraiu gamePort correto.'
Assert-True ($parsed.version -eq $version) 'Parser nao extraiu versao correta.'
Assert-True ($parsed.mode -eq 'remote') 'Parser nao extraiu mode=remote.'

$copyText = Get-TrmCopyableWorldInvite -InviteText $invite
Assert-True ((Normalize-ClipboardText $copyText) -eq (Normalize-ClipboardText $invite)) 'Fonte do botao Copiar Convite alterou o convite oficial.'
Assert-True ($copyText -notmatch 'CHANGELOG|Novidades|Atualizacoes|Diagnostico|Status:') 'Fonte do clipboard contem dados de outra funcionalidade.'

Add-Type -AssemblyName System.Windows.Forms
$previousClipboard = [System.Windows.Forms.Clipboard]::GetText()
$clipboardRestored = $false
try {
    [System.Windows.Forms.Clipboard]::SetText('https://github.com/MarcosNatividade01/TibiaRemastered')
    $clipboardResult = Set-TrmRemoteInviteClipboard -InviteText $invite
    $actualClipboard = [System.Windows.Forms.Clipboard]::GetText()
    Assert-True ((Normalize-ClipboardText $actualClipboard) -eq (Normalize-ClipboardText $invite)) 'Clipboard real nao recebeu o convite remoto.'
    Assert-True ($actualClipboard -notmatch $badRemotePattern) 'Clipboard real manteve GitHub, loopback ou host-local.'
    Assert-True ((Normalize-ClipboardText $clipboardResult) -eq (Normalize-ClipboardText $actualClipboard)) 'Retorno do handler difere do clipboard real.'

    [System.Windows.Forms.Clipboard]::SetText('https://github.com/MarcosNatividade01/TibiaRemastered')
    $invalidCopyRejected = $false
    try { Set-TrmRemoteInviteClipboard -InviteText 'convite invalido' | Out-Null } catch { $invalidCopyRejected = $true }
    Assert-True $invalidCopyRejected 'Handler aceitou convite invalido.'
    Assert-True ([string]::IsNullOrEmpty([System.Windows.Forms.Clipboard]::GetText())) 'Falha de copia deixou URL antiga do GitHub no clipboard.'
} finally {
    [System.Windows.Forms.Clipboard]::Clear()
    if (-not [string]::IsNullOrEmpty($previousClipboard)) { [System.Windows.Forms.Clipboard]::SetText($previousClipboard) }
    $clipboardRestored = $true
}

$hostLocalConnection = BuildHostLocalConnection -WorldName 'FazendoTibia' -Port 7172 -Version $version
Assert-True ($hostLocalConnection.host -eq '127.0.0.1') 'Conexao do proprio host nao usa 127.0.0.1.'
Assert-True ($hostLocalConnection.mode -eq 'host-local') 'Conexao do proprio host nao usa mode=host-local.'
Assert-True ((Normalize-ClipboardText $invite) -eq (Normalize-ClipboardText $copyText)) 'Criar conexao host-local alterou o convite remoto.'

$postLocalPreviousClipboard = [System.Windows.Forms.Clipboard]::GetText()
try {
    $postLocalCopy = Set-TrmRemoteInviteClipboard -InviteText $invite
    $postLocalParsed = ParseRemoteInvite -InviteText ([System.Windows.Forms.Clipboard]::GetText())
    Assert-True $postLocalParsed.valid "Convite remoto deixou de ser valido depois do fluxo host-local: $($postLocalParsed.error)"
    Assert-True ($postLocalParsed.mode -eq 'remote') 'Fluxo host-local contaminou o convite remoto no clipboard.'
    Assert-True ($postLocalParsed.host -eq $parsed.host -and [int]$postLocalParsed.port -eq [int]$parsed.port -and [int]$postLocalParsed.gamePort -eq [int]$parsed.gamePort -and $postLocalParsed.version -eq $parsed.version) 'Fluxo host-local alterou host, porta ou versao do convite remoto.'
    Assert-True ((Normalize-ClipboardText $postLocalCopy) -eq (Normalize-ClipboardText $invite)) 'Segunda copia remota divergiu do convite original.'
} finally {
    [System.Windows.Forms.Clipboard]::Clear()
    if (-not [string]::IsNullOrEmpty($postLocalPreviousClipboard)) { [System.Windows.Forms.Clipboard]::SetText($postLocalPreviousClipboard) }
}

$hostLocalInvite = New-TrmWorldInvite -WorldName 'FazendoTibia' -Host '127.0.0.1' -Port 7172 -Version $version -Mode 'host-local'
$parsedHostLocal = ParseRemoteInvite $hostLocalInvite
Assert-True (-not $parsedHostLocal.valid) 'Parser remoto aceitou convite host-local.'
Assert-True ($parsedHostLocal.error -match 'local do host|somente mode=remote') 'Erro de host-local nao ficou claro.'

$remoteLoopback = @"
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=127.0.0.1
publicHost=
port=7172
loginPort=7171
gamePort=7172
version=$version
mode=remote
"@
$parsedRemoteLoopback = ParseRemoteInvite $remoteLoopback
Assert-True (-not $parsedRemoteLoopback.valid) 'Parser aceitou localhost em convite remoto.'

$githubInvite = @"
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=github.com
publicHost=
port=7172
loginPort=7171
gamePort=7172
version=$version
mode=remote
"@
Assert-True (-not (ParseRemoteInvite $githubInvite).valid) 'Parser aceitou GitHub como host do convite.'

$missingWorld = @"
TIBIA_REMASTERED_INVITE
host=192.168.0.10
publicHost=
port=7172
version=$version
mode=remote
"@
$parsedMissingWorld = ParseRemoteInvite $missingWorld
Assert-True (-not $parsedMissingWorld.valid -and $parsedMissingWorld.error -match 'world ausente') 'Parser nao rejeitou world ausente com erro claro.'

$missingVersion = @"
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=192.168.0.10
publicHost=
port=7172
loginPort=7171
gamePort=7172
mode=remote
"@
$parsedMissingVersion = ParseRemoteInvite $missingVersion
Assert-True (-not $parsedMissingVersion.valid -and $parsedMissingVersion.error -match 'version ausente') 'Parser nao rejeitou version ausente com erro claro.'

$outOfOrder = @"
TIBIA_REMASTERED_INVITE
mode=remote
version=$version
publicHost=203.0.113.10
port=7172
loginPort=7171
gamePort=7172
host=192.168.0.10
world=FazendoTibia
"@
$parsedOutOfOrder = ParseRemoteInvite $outOfOrder
Assert-True $parsedOutOfOrder.valid "Parser dependeu da ordem das chaves: $($parsedOutOfOrder.error)"

$localIp = Get-TrmLocalIPv4Address
Assert-True (-not (Test-TrmLoopbackHost -Host $localIp)) 'Teste remoto local exige um IP LAN real.'
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 0)
try {
    $listener.Start()
    $tcpPort = [int]$listener.LocalEndpoint.Port
    $simulatedInvite = BuildRemoteInvite -WorldName 'FazendoTibia' -Host $localIp -Port $tcpPort -Version $version
    $simulatedParsed = ParseRemoteInvite $simulatedInvite
    $target = Resolve-TrmRemoteInviteTarget -ParsedInvite $simulatedParsed -RequestedHost $simulatedParsed.host
    $report = New-TrmConnectionTestReport -Mode remote -RawInvite $simulatedInvite -Host $target.host -Port $target.port -LoginPort $target.loginPort -WebPort 9 -WorldName $target.worldName -ExpectedVersion $target.version -ClientWorldAddress $target.host -Phase 'remote-local-simulated'
    Assert-True $report.tcpTest.succeeded 'Teste TCP remoto local nao alcancou o host:port do convite.'
    Assert-True ($report.status -eq 'passed') 'TCP=True com web/login remoto indisponivel foi tratado como falha.'
    Assert-True (-not $report.loginServer.responded) 'Cenario de teste esperava web/login remoto indisponivel.'
    Assert-True ([string]::IsNullOrWhiteSpace([string]$report.failureReason)) 'Relatorio gerou falha com TCP=True e erro vazio.'
    Assert-True ($report.finalHost -eq $localIp -and $report.clientWorldAddress -eq $localIp) 'Host remoto foi trocado antes de chegar ao client.'
    Assert-True ([int]$report.finalPort -eq $tcpPort -and $report.clientUsesSameHostAndPort) 'Porta/host do client divergem do teste TCP.'
    Assert-True ([int]$target.gamePort -eq $tcpPort -and [int]$target.loginPort -eq 7171) 'Target remoto nao preservou loginPort/gamePort.'
} finally {
    $listener.Stop()
}

$localListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
try {
    $localListener.Start()
    $localPort = [int]$localListener.LocalEndpoint.Port
    $localReport = New-TrmConnectionTestReport -Mode host-local -Host '127.0.0.1' -Port $localPort -WebPort 9 -WorldName 'FazendoTibia' -ExpectedVersion $version -ClientWorldAddress '127.0.0.1' -Phase 'host-local-simulated'
    Assert-True $localReport.tcpTest.succeeded 'Teste host-local nao validou 127.0.0.1.'
    Assert-True ($localReport.mode -eq 'host-local' -and $localReport.clientWorldAddress -eq '127.0.0.1') 'Fluxo host-local perdeu o modo ou o loopback.'
} finally {
    $localListener.Stop()
}

$logCount = @(Get-ChildItem (Join-Path $work 'Logs\ConnectionTests') -File -ErrorAction SilentlyContinue).Count
Assert-True ($logCount -gt 0) 'Logs detalhados nao foram criados em Logs/ConnectionTests.'

[pscustomobject]@{
    status = 'passed'
    version = $version
    remoteInvite = $invite
    clipboardVerified = $true
    clipboardRestored = $clipboardRestored
    hostLocalHost = $hostLocalConnection.host
    hostLocalMode = $hostLocalConnection.mode
    postHostLocalRemoteMode = $postLocalParsed.mode
    roundTripHost = $parsed.host
    roundTripPort = $parsed.port
    roundTripLoginPort = $parsed.loginPort
    roundTripGamePort = $parsed.gamePort
    roundTripVersion = $parsed.version
    roundTripMode = $parsed.mode
    simulatedRemoteHost = $localIp
    connectionLogs = $logCount
} | ConvertTo-Json -Depth 6
