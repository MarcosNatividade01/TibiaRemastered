param(
    [Parameter(Mandatory=$true)][string]$HostName,
    [Parameter(Mandatory=$true)][int]$Port,
    [int]$TimeoutMs = 3000,
    [string]$OutputDirectory = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    $current = Split-Path -Parent $PSScriptRoot
    while ($current -and -not (Test-Path (Join-Path $current 'version.json'))) {
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $current
}

function Read-LocalVersion([string]$Root) {
    $path = Join-Path $Root 'version.json'
    if (-not (Test-Path $path)) { return 'unknown' }
    try {
        $json = (Get-Content -Raw -Encoding UTF8 $path).TrimStart([char]0xFEFF) | ConvertFrom-Json
        return [string]$json.version
    } catch {
        return 'invalid'
    }
}

function Test-Tcp([string]$TargetHost, [int]$TargetPort, [int]$Timeout) {
    $client = New-Object System.Net.Sockets.TcpClient
    $started = Get-Date
    try {
        $async = $client.BeginConnect($TargetHost, $TargetPort, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($Timeout, $false)) {
            return [pscustomobject]@{ succeeded=$false; error="timeout apos ${Timeout}ms"; socketError='timeout'; elapsedMs=[int]((Get-Date) - $started).TotalMilliseconds }
        }
        $client.EndConnect($async)
        return [pscustomobject]@{ succeeded=$true; error=''; socketError=''; elapsedMs=[int]((Get-Date) - $started).TotalMilliseconds }
    } catch {
        $socketError = ''
        $current = $_.Exception
        while ($current) {
            if ($current -is [System.Net.Sockets.SocketException]) {
                $socketError = $current.SocketErrorCode.ToString()
                break
            }
            $current = $current.InnerException
        }
        return [pscustomobject]@{ succeeded=$false; error=$_.Exception.Message; socketError=$socketError; elapsedMs=[int]((Get-Date) - $started).TotalMilliseconds }
    } finally {
        $client.Close()
    }
}

$root = Get-ProjectRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'Logs\ConnectionTests'
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$addresses = @()
$resolveError = ''
try {
    $addresses = @([System.Net.Dns]::GetHostAddresses($HostName) | ForEach-Object { $_.IPAddressToString })
} catch {
    $resolveError = $_.Exception.Message
}

$pingResult = $null
try {
    $pingResult = @(Test-Connection -ComputerName $HostName -Count 2 -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{
            address = [string]$_.Address
            ipv4Address = if ($_.IPV4Address) { [string]$_.IPV4Address.IPAddressToString } else { '' }
            responseTimeMs = [int]$_.ResponseTime
        }
    })
} catch {
    $pingResult = [pscustomobject]@{ error = $_.Exception.Message }
}

$route = $null
try {
    $route = Test-NetConnection -ComputerName $HostName -Port $Port -InformationLevel Detailed -WarningAction SilentlyContinue
} catch {
    $route = [pscustomobject]@{ error = $_.Exception.Message }
}

$tcp = Test-Tcp -TargetHost $HostName -TargetPort $Port -Timeout $TimeoutMs
$localVersion = Read-LocalVersion -Root $root
$routeError = ''
if ($route -and ($route.PSObject.Properties.Name -contains 'error')) {
    $routeError = [string]$route.error
}
$routeSourceAddress = ''
if ($route -and $route.SourceAddress) {
    if ($route.SourceAddress.PSObject.Properties.Name -contains 'IPAddress') {
        $routeSourceAddress = [string]$route.SourceAddress.IPAddress
    } else {
        $routeSourceAddress = [string]$route.SourceAddress
    }
}
$routeRemoteAddress = ''
if ($route -and $route.RemoteAddress) {
    if ($route.RemoteAddress.PSObject.Properties.Name -contains 'IPAddressToString') {
        $routeRemoteAddress = [string]$route.RemoteAddress.IPAddressToString
    } else {
        $routeRemoteAddress = [string]$route.RemoteAddress
    }
}
$isLoopbackHost = ($HostName.Trim().Trim('[',']').ToLowerInvariant() -in @('127.0.0.1','localhost','::1'))
$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    host = $HostName
    port = $Port
    timeoutMs = $TimeoutMs
    localVersion = $localVersion
    resolvedAddresses = $addresses
    resolveError = $resolveError
    ping = $pingResult
    tcp = $tcp
    testNetConnection = if ($route) {
        [pscustomobject]@{
            computerName = $route.ComputerName
            remoteAddress = $routeRemoteAddress
            remotePort = $route.RemotePort
            interfaceAlias = $route.InterfaceAlias
            sourceAddress = $routeSourceAddress
            pingSucceeded = $route.PingSucceeded
            tcpTestSucceeded = $route.TcpTestSucceeded
            error = $routeError
        }
    } else { $null }
    recommendation = if ($isLoopbackHost) {
        'Host local usado no convidado. Para multiplayer remoto, use o convite oficial mode=remote com IP LAN do host.'
    } elseif ($tcp.succeeded) {
        "TCP OK. O Launcher deve usar exatamente ${HostName}:$Port."
    } elseif ($HostName -match '^(10\.|172\.(1[6-9]|2\d|3[0-1])\.|192\.168\.)') {
        'TCP falhou para IP privado. Confirme mesma LAN, servidor ligado e firewall liberado.'
    } else {
        'TCP falhou para IP publico. Confirme port forwarding, firewall, bloqueio do provedor e CGNAT.'
    }
}

$path = Join-Path $OutputDirectory ('remote-host-diagnostic-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding UTF8
$report | Add-Member -NotePropertyName reportPath -NotePropertyValue $path -Force
$report | ConvertTo-Json -Depth 8

if (-not $tcp.succeeded) { exit 2 }
