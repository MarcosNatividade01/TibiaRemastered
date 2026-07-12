Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $root 'Launcher\Modules'
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$existingClientIds = @(Get-Process -Name client-local -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$preexistingUserDataFiles = @()
if (Test-Path (Join-Path $root 'UserData')) {
    $preexistingUserDataFiles = @(Get-ChildItem (Join-Path $root 'UserData') -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
}

try {
    $hostResult = Start-TrmHostedWorld
    $valid = New-TrmConnectionTestReport -Mode remote -RawInvite $hostResult.remoteInvite -Host $hostResult.localIp -Port $hostResult.port -WebPort $hostResult.webPort -WorldName $hostResult.worldName -ExpectedVersion $hostResult.version -ClientWorldAddress $hostResult.localIp -Phase 'test-valid-invite'
    Assert-True ($valid.status -eq 'passed') "Convite valido falhou: $($valid.failureReason)"
    Assert-True ($valid.tcpTest.succeeded) 'TCP do convite valido nao passou.'
    Assert-True ($valid.loginServer.responded) 'Login server do convite valido nao respondeu.'
    Assert-True ($valid.clientWorldAddress -eq $hostResult.localIp) 'Client nao usaria o mesmo IP do convite valido.'
    $parsedHostedInvite = ParseRemoteInvite -InviteText $hostResult.remoteInvite
    Assert-True ($parsedHostedInvite.valid -and $parsedHostedInvite.mode -eq 'remote') 'Convite real do host nao passou no parser remoto.'

    $invalidIp = New-TrmConnectionTestReport -Mode remote -RawInvite 'IP: 203.0.113.250' -Host '203.0.113.250' -Port 7172 -WebPort 80 -ClientWorldAddress '203.0.113.250' -Phase 'test-invalid-ip'
    Assert-True (-not $invalidIp.tcpTest.succeeded) 'IP invalido respondeu TCP inesperadamente.'
    Assert-True ($invalidIp.status -eq 'failed') 'IP invalido nao falhou.'

    $wrongPort = New-TrmConnectionTestReport -Mode remote -RawInvite "IP: $($hostResult.localIp)`nPorta: 1" -Host $hostResult.localIp -Port 1 -WebPort $hostResult.webPort -ClientWorldAddress $hostResult.localIp -Phase 'test-wrong-port'
    Assert-True (-not $wrongPort.tcpTest.succeeded) 'Porta errada respondeu TCP inesperadamente.'
    Assert-True ($wrongPort.status -eq 'failed') 'Porta errada nao falhou.'

    $loopback = New-TrmConnectionTestReport -Mode remote -RawInvite "IP: 127.0.0.1`nPorta: 7172" -Host '127.0.0.1' -Port 7172 -WebPort 80 -ClientWorldAddress '127.0.0.1' -Phase 'test-loopback-remote'
    Assert-True $loopback.isLoopbackHost '127.0.0.1 nao foi identificado como loopback.'
    Assert-True ($loopback.status -eq 'failed') 'Convite remoto com localhost nao falhou.'
    Assert-True ($loopback.failureReason -match 'localhost') 'Falha de localhost nao ficou clara.'

    $inviteBeforeOwnJoin = [string]$hostResult.remoteInvite
    $own = JoinOwnHostedWorld -Port $hostResult.port -WorldName $hostResult.worldName
    Assert-True ($own.clientWorldAddress -eq '127.0.0.1') 'Host local nao usou 127.0.0.1.'
    Assert-True ($own.mode -eq 'own-hosted') 'Entrar no Meu Mundo nao preservou o modo local.'
    $inviteAfterOwnJoin = BuildRemoteInvite -WorldName $hostResult.worldName -Host $hostResult.localIp -PublicHost $hostResult.publicIp -Port $hostResult.port -Version $hostResult.version
    Assert-True ($inviteBeforeOwnJoin -eq $inviteAfterOwnJoin) 'Entrar no Meu Mundo contaminou o convite remoto.'
    Assert-True ((ParseRemoteInvite $inviteAfterOwnJoin).mode -eq 'remote') 'Convite apos Entrar no Meu Mundo deixou de ser remote.'
    foreach ($path in $preexistingUserDataFiles) { Assert-True (Test-Path -LiteralPath $path) "Arquivo preexistente de UserData foi removido: $path" }

    [pscustomobject]@{
        status = 'passed'
        remoteInviteMode = $parsedHostedInvite.mode
        ownHostAddress = $own.clientWorldAddress
        postOwnHostInviteMode = (ParseRemoteInvite $inviteAfterOwnJoin).mode
        preexistingUserDataFilesPreserved = $preexistingUserDataFiles.Count
        validInviteReport = $valid.reportPath
        invalidIpReport = $invalidIp.reportPath
        wrongPortReport = $wrongPort.reportPath
        loopbackReport = $loopback.reportPath
        ownHostReport = $own.connectionReport.reportPath
    } | ConvertTo-Json -Depth 8
} finally {
    Start-Sleep -Seconds 2
    Get-Process -Name client-local -ErrorAction SilentlyContinue | Where-Object { $existingClientIds -notcontains $_.Id } | Stop-Process -Force -ErrorAction SilentlyContinue
    Stop-TrmHostedWorld | Out-Null
}
