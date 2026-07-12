$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path $repo 'tmp\remote-account-proxy-tests'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force -Path $work | Out-Null
$env:TRM_ROOT = $work
Set-Content -Path (Join-Path $work 'version.json') -Value '{"name":"TibiaRemastered","version":"0.1.23-test","channel":"dev","minimumLauncherVersion":"0.1.0"}' -Encoding UTF8
Import-Module (Join-Path $repo 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return [int]$listener.LocalEndpoint.Port
    } finally {
        $listener.Stop()
    }
}

function Wait-Port {
    param([int]$Port, [int]$TimeoutSeconds = 10)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
            if ($async.AsyncWaitHandle.WaitOne(300, $false)) {
                $client.EndConnect($async)
                return $true
            }
        } catch {
        } finally {
            $client.Close()
        }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

$hostPort = Get-FreeTcpPort
$guestPort = Get-FreeTcpPort
$worldAddress = '192.168.0.61'
$gamePort = 7172
$fakeHostLog = Join-Path $work 'fake-host-requests.jsonl'
$fakeHostScript = Join-Path $work 'fake-host-endpoint.ps1'
$guestScript = Join-Path $work 'guest-portable-web-endpoint.ps1'

@'
param(
    [int]$Port,
    [string]$WorldAddress,
    [int]$GamePort,
    [string]$LogPath
)
$ErrorActionPreference = 'Stop'
function Send-Json($Stream, [object]$Value) {
    $json = $Value | ConvertTo-Json -Depth 16 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    $headBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headBytes, 0, $headBytes.Length)
    $Stream.Write($bytes, 0, $bytes.Length)
}
function Read-Request($Stream) {
    $reader = New-Object IO.StreamReader($Stream, [Text.Encoding]::UTF8, $false, 1024, $true)
    $requestLine = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($requestLine)) { return $null }
    $headers = @{}
    while ($true) {
        $line = $reader.ReadLine()
        if ($line -eq $null -or $line -eq '') { break }
        $idx = $line.IndexOf(':')
        if ($idx -gt 0) { $headers[$line.Substring(0,$idx).Trim().ToLowerInvariant()] = $line.Substring($idx+1).Trim() }
    }
    $length = 0
    if ($headers.ContainsKey('content-length')) { [void][int]::TryParse($headers['content-length'], [ref]$length) }
    $body = ''
    if ($length -gt 0) {
        $buffer = New-Object char[] $length
        $read = $reader.ReadBlock($buffer, 0, $length)
        $body = -join $buffer[0..([Math]::Max(0,$read-1))]
    }
    $parts = $requestLine.Split(' ')
    return [pscustomobject]@{Method=$parts[0]; Path=$parts[1]; Body=$body}
}
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()
while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $request = Read-Request $stream
        if ($null -eq $request) { continue }
        $payload = if ([string]::IsNullOrWhiteSpace($request.Body)) { [pscustomobject]@{} } else { $request.Body | ConvertFrom-Json }
        $type = if ($payload.PSObject.Properties.Name -contains 'type') { [string]$payload.type } else { '' }
        $email = if ($payload.PSObject.Properties.Name -contains 'email') { [string]$payload.email } elseif ($payload.PSObject.Properties.Name -contains 'EMail') { [string]$payload.EMail } else { '' }
        $hasPassword = (($payload.PSObject.Properties.Name -contains 'password') -or ($payload.PSObject.Properties.Name -contains 'Password') -or ($payload.PSObject.Properties.Name -contains 'Password1'))
        ([pscustomobject]@{path=$request.Path; type=$type; email=$email; hasPassword=$hasPassword; receivedAt=(Get-Date).ToString('s')} | ConvertTo-Json -Compress) | Add-Content -Path $LogPath -Encoding UTF8
        if ($request.Path -like '/clientcreateaccount.php*') {
            if ($type -eq 'GetAccountCreationStatus') {
                Send-Json $stream ([pscustomobject]@{RecommendedWorld='FazendoTibia'; IsCaptchaDeactivated=$true; Worlds=@([pscustomobject]@{Name='FazendoTibia'})})
            } else {
                Send-Json $stream ([pscustomobject]@{Success=$true; AccountID='remoteaccount'; AccountName='remoteaccount'; EMail=$email; CharacterName='Proxy Test'})
            }
        } elseif ($request.Path -like '/login.php*') {
            $password = if ($payload.PSObject.Properties.Name -contains 'password') { [string]$payload.password } else { 'Redacted1234' }
            Send-Json $stream ([pscustomobject]@{
                session=[pscustomobject]@{sessionkey=($email+"`n"+$password); status='active'}
                playdata=[pscustomobject]@{
                    worlds=@([pscustomobject]@{id=0; name='FazendoTibia'; externaladdress=$WorldAddress; externaladdressprotected=$WorldAddress; externaladdressunprotected=$WorldAddress; externalport=$GamePort; externalportprotected=$GamePort; externalportunprotected=$GamePort})
                    characters=@([pscustomobject]@{worldid=0; name='Proxy Test'; level=8; vocation='None'; ismale=$true; outfitid=128; headcolor=78; torsocolor=68; legscolor=58; detailcolor=76; addonsflags=0; dailyrewardstate=0})
                }
            })
        } elseif ($request.Path -like '/version.json*') {
            Send-Json $stream ([pscustomobject]@{version='0.1.23-test'; channel='dev'})
        } else {
            Send-Json $stream ([pscustomobject]@{ok=$true})
        }
    } finally {
        $client.Close()
    }
}
'@ | Set-Content -Path $fakeHostScript -Encoding UTF8

Write-TrmPortableWebEndpointScript -Path $guestScript
$fakeHost = $null
$guestEndpoint = $null
try {
    $fakeHost = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$fakeHostScript,'-Port',[string]$hostPort,'-WorldAddress',$worldAddress,'-GamePort',[string]$gamePort,'-LogPath',$fakeHostLog) -WorkingDirectory $work -WindowStyle Hidden -PassThru
    Assert-True (Wait-Port -Port $hostPort -TimeoutSeconds 10) 'Fake host endpoint nao abriu.'

    $remoteBase = "http://127.0.0.1:$hostPort"
    $guestEndpoint = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$guestScript,'-Root',$work,'-MysqlExe',(Get-Command powershell.exe).Source,'-DbPort','3306','-HttpPort',[string]$guestPort,'-Database','otserv','-BindAddress','127.0.0.1','-WorldAddress',$worldAddress,'-GamePort',[string]$gamePort,'-RemoteAccountBaseUrl',$remoteBase) -WorkingDirectory $work -WindowStyle Hidden -PassThru
    Assert-True (Wait-Port -Port $guestPort -TimeoutSeconds 10) 'Guest endpoint proxy nao abriu.'

    $status = Invoke-RestMethod -Uri "http://127.0.0.1:$guestPort/clientcreateaccount.php" -Method Post -ContentType 'application/json' -Body '{"type":"GetAccountCreationStatus"}' -TimeoutSec 10
    Assert-True ($status.RecommendedWorld -eq 'FazendoTibia') 'Status de criacao nao veio do host remoto.'

    $createBody = @{type='CreateAccountAndCharacter'; EMail='proxy-test@example.com'; Password='StrongPass123'; CharacterName='Proxy Test'} | ConvertTo-Json -Compress
    $create = Invoke-RestMethod -Uri "http://127.0.0.1:$guestPort/clientcreateaccount.php" -Method Post -ContentType 'application/json' -Body $createBody -TimeoutSec 10
    Assert-True ([bool]$create.Success) 'Criacao remota via proxy nao retornou sucesso.'

    $loginBody = @{type='login'; email='proxy-test@example.com'; password='StrongPass123'} | ConvertTo-Json -Compress
    $login = Invoke-RestMethod -Uri "http://127.0.0.1:$guestPort/login.php" -Method Post -ContentType 'application/json' -Body $loginBody -TimeoutSec 10
    $world = @($login.playdata.worlds)[0]
    $character = @($login.playdata.characters)[0]
    Assert-True ($world.externaladdress -eq $worldAddress) 'Login remoto nao anunciou o IP real do host.'
    Assert-True ([int]$world.externalport -eq $gamePort) 'Login remoto nao anunciou a porta real do game server.'
    Assert-True ($character.name -eq 'Proxy Test') 'Lista de personagens nao veio do host remoto.'

    $events = @(Get-Content $fakeHostLog | ForEach-Object { $_ | ConvertFrom-Json })
    Assert-True (@($events | Where-Object path -like '/clientcreateaccount.php*').Count -ge 2) 'Host remoto nao recebeu chamadas de criacao/status.'
    Assert-True (@($events | Where-Object path -like '/login.php*').Count -ge 1) 'Host remoto nao recebeu chamada de login.'
    Assert-True (@($events | Where-Object { $_.PSObject.Properties.Name -contains 'password' }).Count -eq 0) 'Log tecnico registrou campo de senha.'

    [pscustomobject]@{
        status = 'passed'
        guestEndpoint = "127.0.0.1:$guestPort"
        remoteAccountBaseUrl = $remoteBase
        advertisedGameHost = $world.externaladdress
        advertisedGamePort = [int]$world.externalport
        character = $character.name
        hostRequests = $events.Count
    } | ConvertTo-Json -Depth 6
} finally {
    if ($guestEndpoint -and -not $guestEndpoint.HasExited) { Stop-Process -Id $guestEndpoint.Id -Force -ErrorAction SilentlyContinue }
    if ($fakeHost -and -not $fakeHost.HasExited) { Stop-Process -Id $fakeHost.Id -Force -ErrorAction SilentlyContinue }
}
