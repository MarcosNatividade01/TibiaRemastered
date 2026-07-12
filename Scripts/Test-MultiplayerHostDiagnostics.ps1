Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $root 'Launcher\Modules'
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$runtimeSource = Get-Content -Raw (Join-Path $root 'Launcher\Modules\TibiaRemastered.Runtime.psm1')
$launcherSource = Get-Content -Raw (Join-Path $root 'Launcher\Launcher.ps1')
$serverConfigSource = Get-Content -Raw (Join-Path $root 'Server\config.lua')
$firewallPs1 = Join-Path $root 'Tools\NetworkDiagnostics\Enable-TibiaRemasteredFirewall.ps1'
$firewallBat = Join-Path $root 'Tools\NetworkDiagnostics\Enable-TibiaRemasteredFirewall.bat'

$serverConfig = Get-TrmServerConfigNetwork
Assert-True $serverConfig.exists 'Server/config.lua nao foi encontrado.'
Assert-True ($serverConfig.ip -eq '0.0.0.0') "Servidor nao esta configurado para bind externo: ip=$($serverConfig.ip)"
Assert-True ([int]$serverConfig.loginProtocolPort -eq 7171) 'Porta real de login deveria ser 7171.'
Assert-True ([int]$serverConfig.gameProtocolPort -eq 7172) 'Porta real de game deveria ser 7172.'
Assert-True ($serverConfigSource -match 'bindOnlyGlobalAddress\s*=\s*false') 'bindOnlyGlobalAddress foi alterado inesperadamente.'

Assert-True ($runtimeSource -match 'function New-TrmMultiplayerHostDiagnosticReport') 'Diagnostico multiplayer host nao existe.'
Assert-True ($runtimeSource -match 'Get-NetTCPConnection') 'Diagnostico nao consulta LISTENING/netstat.'
Assert-True ($runtimeSource -match 'Get-NetFirewallPortFilter') 'Diagnostico nao consulta regras de Firewall.'
Assert-True ($runtimeSource -match 'relay = \[pscustomobject\]@\{') 'Relatorio nao registra status do relay.'
Assert-True ($runtimeSource -match "status = 'unavailable'") 'Relay nao esta marcado claramente como indisponivel.'
Assert-True ($runtimeSource -match 'cgnatSuspected') 'Relatorio nao registra suspeita de CGNAT.'
Assert-True ($runtimeSource -match 'TimeoutMs = 8000') 'Timeout TCP padrao nao foi aumentado para 8000ms.'
Assert-True ($runtimeSource -match 'inviteAllowedForInternet') 'Diagnostico nao diferencia convite LAN de convite Internet.'
Assert-True ($runtimeSource -match 'nao pertencem a esta instalacao') 'Inicializacao nao protege contra portas ocupadas por outra copia do servidor.'

Assert-True ($launcherSource -match 'Format-MultiplayerDiagnosticText') 'Tela de hospedagem nao exibe diagnostico multiplayer.'
Assert-True ($launcherSource -match 'Format-MultiplayerDiagnosticForUser') 'Tela Diagnostico nao formata diagnostico multiplayer.'
Assert-True ($launcherSource -match 'New-TrmMultiplayerHostDiagnosticReport') 'Botao Diagnostico Host nao usa diagnostico multiplayer completo.'
Assert-True ($launcherSource -match 'Liberar Firewall') 'Tela Diagnostico nao oferece opcao administrativa para Firewall.'
Assert-True ($launcherSource -match 'Enable-TibiaRemasteredFirewall\.ps1') 'Botao Firewall nao chama o script oficial.'
Assert-True ($launcherSource -match 'inviteAllowedForLan') 'Copiar Convite nao consulta permissao do diagnostico.'
Assert-True ($launcherSource -match 'Relay.*indisponivel|relay reverso') 'Ajuda nao esclarece ausencia de relay.'

Assert-True (Test-Path $firewallPs1) 'Script PowerShell de Firewall nao existe.'
Assert-True (Test-Path $firewallBat) 'Script BAT de Firewall nao existe.'
$firewallSource = Get-Content -Raw $firewallPs1
Assert-True ($firewallSource -match 'Administrator') 'Script de Firewall nao exige administrador explicitamente.'
Assert-True ($firewallSource -match 'New-NetFirewallRule') 'Script de Firewall nao cria regras.'
Assert-True ($firewallSource -match '7171,7172,80') 'Script de Firewall nao cobre 7171/7172/80.'

$tcpClosed = Test-TrmTcpConnectionDirect -Host '127.0.0.1' -Port 1
Assert-True ([int]$tcpClosed.timeoutMs -eq 8000) 'Resultado TCP nao registra timeoutMs=8000.'

$report = New-TrmConnectionTestReport -Mode remote -RawInvite '' -Host '127.0.0.1' -Port 1 -WebPort 9 -ClientWorldAddress '127.0.0.1' -Phase 'diagnostic-field-test'
Assert-True ($report.PSObject.Properties.Name -contains 'localIPv4') 'Relatorio de convidado nao registra IPv4 local.'
Assert-True ($report.PSObject.Properties.Name -contains 'publicIPv4') 'Relatorio de convidado nao registra IPv4 publico.'
Assert-True ($report.PSObject.Properties.Name -contains 'relay') 'Relatorio de convidado nao registra relay.'
Assert-True ($report.relay.status -eq 'unavailable') 'Relatorio de convidado nao marca relay como indisponivel.'
Assert-True ($report.PSObject.Properties.Name -contains 'cgnatSuspected') 'Relatorio de convidado nao registra CGNAT suspeito.'
Assert-True ($report.failureStage -eq 'remote-loopback') 'Relatorio remoto com localhost nao falha na etapa correta.'

[pscustomobject]@{
    status = 'passed'
    serverBind = $serverConfig.ip
    loginPort = [int]$serverConfig.loginProtocolPort
    gamePort = [int]$serverConfig.gameProtocolPort
    tcpTimeoutMs = [int]$tcpClosed.timeoutMs
    relayStatus = [string]$report.relay.status
    reportPath = [string]$report.reportPath
} | ConvertTo-Json -Depth 8
