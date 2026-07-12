param(
    [int[]]$Ports = @(7171,7172,80),
    [string]$RulePrefix = 'Tibia Remastered'
)

$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Este script precisa ser executado como Administrador para criar regras do Firewall do Windows.'
}

$created = @()
foreach ($port in $Ports) {
    if ($port -lt 1 -or $port -gt 65535) { throw "Porta invalida: $port" }
    $name = "$RulePrefix TCP $port"
    $existing = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
    if ($existing) {
        Set-NetFirewallRule -DisplayName $name -Enabled True -Direction Inbound -Action Allow -Profile Any | Out-Null
        $created += [pscustomobject]@{port=$port; displayName=$name; action='updated'}
        continue
    }
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -Profile Any | Out-Null
    $created += [pscustomobject]@{port=$port; displayName=$name; action='created'}
}

$created | Format-Table -AutoSize
Write-Host ''
Write-Host 'Regras de firewall criadas/atualizadas. Volte ao Launcher e rode Diagnostico Multiplayer novamente.'
