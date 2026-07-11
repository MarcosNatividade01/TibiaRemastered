Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

function Test-TrmLocalPortListening {
    param([int]$Port)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(800, $false)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Wait-TrmServerPorts {
    param([int[]]$Ports, [int]$TimeoutSeconds)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $stableChecks = 0
    while ((Get-Date) -lt $deadline) {
        $allOpen = $true
        foreach ($port in $Ports) {
            if (-not (Test-TrmLocalPortListening -Port $port)) { $allOpen = $false; break }
        }
        if ($allOpen) {
            $stableChecks++
            if ($stableChecks -ge 2) { return $true }
        } else {
            $stableChecks = 0
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Ensure-TrmDatabaseServer {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = [int]$Config.databasePort
    if (Test-TrmLocalPortListening -Port $port) { return }
    $databaseExe = Resolve-TrmRuntimePath ([string]$Config.databaseExe)
    if ([string]::IsNullOrWhiteSpace($databaseExe) -or -not (Test-Path $databaseExe)) {
        Write-TrmLog "Database exe not found or not configured: $databaseExe" 'WARN'
        return
    }
    $root = Get-TrmRoot
    $mysqlRoot = Split-Path -Parent (Split-Path -Parent $databaseExe)
    $dataDir = Join-Path $root 'UserData\Database\mysql-data'
    $tmpDir = Join-Path $root 'UserData\Database\mysql-tmp'
    $configFile = Join-Path $root 'UserData\Database\mysql-runtime.ini'
    $mysqlExe = Join-Path (Split-Path -Parent $databaseExe) 'mysql.exe'
    $installDbExe = Join-Path (Split-Path -Parent $databaseExe) 'mysql_install_db.exe'
    if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null }
    if (-not (Test-Path $dataDir)) {
        if ($ProgressCallback) { & $ProgressCallback 'Inicializando banco local...' 0 0 0 }
        New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
        if (Test-Path $installDbExe) {
            $install = Start-Process -FilePath $installDbExe -ArgumentList @('--datadir', $dataDir, '--password=') -WorkingDirectory (Split-Path -Parent $databaseExe) -NoNewWindow -Wait -PassThru
            if ($install.ExitCode -ne 0) { throw "Database initialization failed with exit code $($install.ExitCode)." }
        }
    }
    @"
[client]
port=$port
host=127.0.0.1

[mysqld]
port=$port
bind-address=127.0.0.1
basedir="$($mysqlRoot -replace '\\','/')"
datadir="$($dataDir -replace '\\','/')"
tmpdir="$($tmpDir -replace '\\','/')"
pid_file="mysql.pid"
character-set-server=utf8mb4
collation-server=utf8mb4_general_ci
default-storage-engine=InnoDB
max_allowed_packet=16M
innodb_buffer_pool_size=16M
innodb_log_file_size=5M
sql_mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION
log_bin_trust_function_creators=1
"@ | Set-Content -Path $configFile -Encoding ASCII

    if ($ProgressCallback) { & $ProgressCallback 'Iniciando banco local...' 0 0 0 }
    Start-Process -FilePath $databaseExe -ArgumentList @("--defaults-file=$configFile") -WorkingDirectory (Split-Path -Parent $databaseExe) -WindowStyle Hidden | Out-Null
    $deadline = (Get-Date).AddSeconds([int]$Config.databaseStartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-TrmLocalPortListening -Port $port) {
            Ensure-TrmDatabaseSchema -Config $Config -MysqlExe $mysqlExe -Port $port -ProgressCallback $ProgressCallback
            return
        }
        Start-Sleep -Seconds 1
    }
    throw "Database did not open port $port before timeout."
}

function Invoke-TrmMysql {
    param(
        [string]$MysqlExe,
        [int]$Port,
        [string]$Database,
        [string]$InputSql
    )
    $args = @('-h', '127.0.0.1', '-P', [string]$Port, '-u', 'root')
    if (-not [string]::IsNullOrWhiteSpace($Database)) { $args += $Database }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $MysqlExe
    $psi.Arguments = ($args | ForEach-Object { if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.WriteLine($InputSql)
    $p.StandardInput.Close()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw "mysql.exe failed: $stderr $stdout" }
    return $stdout
}

function Ensure-TrmDatabaseSchema {
    param([object]$Config, [string]$MysqlExe, [int]$Port, [scriptblock]$ProgressCallback)
    if (-not (Test-Path $MysqlExe)) { throw "mysql.exe not found: $MysqlExe" }
    $root = Get-TrmRoot
    $databaseName = 'otserv'
    if ($Config.PSObject.Properties.Name -contains 'databaseName' -and -not [string]::IsNullOrWhiteSpace([string]$Config.databaseName)) {
        $databaseName = [string]$Config.databaseName
    }
    $seedSql = Join-Path $root 'Server\schema.sql'
    if ($Config.PSObject.Properties.Name -contains 'databaseSeedSql' -and -not [string]::IsNullOrWhiteSpace([string]$Config.databaseSeedSql)) {
        $seedSql = Resolve-TrmRuntimePath ([string]$Config.databaseSeedSql)
    }
    Invoke-TrmMysql -MysqlExe $MysqlExe -Port $Port -Database '' -InputSql "CREATE DATABASE IF NOT EXISTS ``$databaseName`` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" | Out-Null
    $tables = Invoke-TrmMysql -MysqlExe $MysqlExe -Port $Port -Database $databaseName -InputSql 'SHOW TABLES;'
    if ([string]::IsNullOrWhiteSpace($tables) -and (Test-Path $seedSql)) {
        if ($ProgressCallback) { & $ProgressCallback 'Importando banco inicial...' 0 0 0 }
        $seedPath = ($seedSql -replace '\\','/')
        Invoke-TrmMysql -MysqlExe $MysqlExe -Port $Port -Database $databaseName -InputSql "SOURCE $seedPath;" | Out-Null
    }
}

function Test-TrmWebEndpointHealthy {
    param([int]$Port)
    try {
        $body = '{"type":"GetAccountCreationStatus"}'
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/clientcreateaccount.php" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 3
        return ($response -and ($response.PSObject.Properties.Name -contains 'RecommendedWorld'))
    } catch {
        return $false
    }
}

function Write-TrmPortableWebEndpointScript {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
@'
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$MysqlExe,
    [int]$DbPort = 3306,
    [int]$HttpPort = 80,
    [string]$Database = 'otserv',
    [string]$BindAddress = '127.0.0.1',
    [string]$WorldAddress = '127.0.0.1',
    [int]$GamePort = 7172
)

$ErrorActionPreference = 'Stop'

function Write-EndpointLog([string]$Message) {
    $logDir = Join-Path $Root 'Logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    Add-Content -Path (Join-Path $logDir 'portable-web-endpoint.log') -Value ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message) -Encoding UTF8
}

function Invoke-Db([string]$Sql, [string]$Db = $Database) {
    $args = @('-h','127.0.0.1','-P',[string]$DbPort,'-u','root','--batch','--raw','--skip-column-names')
    if (-not [string]::IsNullOrWhiteSpace($Db)) { $args += $Db }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $MysqlExe
    $psi.Arguments = ($args | ForEach-Object { if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.WriteLine($Sql)
    $p.StandardInput.Close()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw "mysql failed: $stderr $stdout" }
    $lines = @($stdout -split "`r?`n" | Where-Object { $_ -ne '' })
    Write-Output -NoEnumerate $lines
}

function Sql-Escape([string]$Value) {
    return "'" + (($Value -replace "\\","\\") -replace "'","''") + "'"
}

function New-Sha1([string]$Value) {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
}

function Normalize-CharacterName([string]$Name) {
    $normalized = $Name.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$builder.Append($ch) }
    }
    $ascii = $builder.ToString()
    $ascii = [regex]::Replace($ascii, '[^A-Za-z]+', ' ')
    $ascii = [regex]::Replace($ascii.Trim(), '\s+', ' ')
    if ([string]::IsNullOrWhiteSpace($ascii)) { return '' }
    return ((Get-Culture).TextInfo.ToTitleCase($ascii.ToLowerInvariant()))
}

function Test-NameAvailable([string]$Name) {
    $rows = Invoke-Db ("SELECT 1 FROM players WHERE name = {0} LIMIT 1;" -f (Sql-Escape $Name))
    return ($rows.Count -eq 0)
}

function New-CharacterName {
    param([string]$Requested)
    $name = Normalize-CharacterName $Requested
    if ($name.Length -ge 3 -and $name.Length -le 29 -and (Test-NameAvailable $name)) { return $name }
    $first = @('Arin','Borin','Kael','Luna','Mira','Nolan','Rayan','Tarin','Jafar','Marcos')
    $last = @('Storm','Vale','Dawn','Forge','River','Light','Stone','Ash','Hero','Mage')
    for ($i = 0; $i -lt 100; $i++) {
        $candidate = $first[(Get-Random -Maximum $first.Count)] + ' ' + $last[(Get-Random -Maximum $last.Count)]
        if (Test-NameAvailable $candidate) { return $candidate }
    }
    throw 'Could not generate an available character name.'
}

function New-AccountName([string]$Email) {
    $base = (($Email.Split('@')[0]) -replace '[^A-Za-z0-9]','').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($base)) { $base = 'account' }
    if ($base.Length -gt 18) { $base = $base.Substring(0, 18) }
    for ($i = 0; $i -lt 100; $i++) {
        $suffix = (Get-Date -Format 'HHmmss') + ($(if ($i -eq 0) { '' } else { [string]$i }))
        $name = ($base + $suffix)
        if ($name.Length -gt 32) { $name = $name.Substring(0, 32) }
        $rows = Invoke-Db ("SELECT 1 FROM accounts WHERE name = {0} LIMIT 1;" -f (Sql-Escape $name))
        if ($rows.Count -eq 0) { return $name }
    }
    throw 'Could not generate account name.'
}

function Send-Json($Stream, [object]$Value, [int]$Status = 200) {
    $json = $Value | ConvertTo-Json -Depth 16 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $header = "HTTP/1.1 $Status OK`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    $headBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headBytes, 0, $headBytes.Length)
    $Stream.Write($bytes, 0, $bytes.Length)
}

function Send-Error($Stream, [string]$Message, [int]$Code = 101) {
    Send-Json $Stream ([pscustomobject]@{errorCode=$Code; errorMessage=$Message; Success=$false; IsRecaptcha2Requested=$false})
}

function Get-Request($Stream) {
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
    $parts = $requestLine.Split(' ')
    $length = 0
    if ($headers.ContainsKey('content-length')) { [void][int]::TryParse($headers['content-length'], [ref]$length) }
    $body = ''
    if ($length -gt 0) {
        $buffer = New-Object char[] $length
        $read = $reader.ReadBlock($buffer, 0, $length)
        $body = -join $buffer[0..([Math]::Max(0,$read-1))]
    }
    return [pscustomobject]@{Method=$parts[0]; Path=$parts[1]; Body=$body}
}

function Handle-ClientCreate($Stream, $Payload) {
    $typeValue = if ($Payload.PSObject.Properties.Name -contains 'type') { $Payload.type } else { $Payload.Type }
    $type = ([string]$typeValue).ToLowerInvariant()
    switch ($type) {
        'getaccountcreationstatus' {
            Send-Json $Stream ([pscustomobject]@{
                Worlds=@([pscustomobject]@{Name='FazendoTibia';PlayersOnline=0;CreationDate=1781730544;Region='America';PvPType='Open PVP';PremiumOnly=$false;TransferType='Blocked';BattlEyeActivationTimestamp=0;BattlEyeInitiallyActive=0})
                RecommendedWorld='FazendoTibia'
                IsCaptchaDeactivated=$true
            })
        }
        'checkemail' {
            $emailValue = if ($Payload.PSObject.Properties.Name -contains 'EMail') { $Payload.EMail } else { $Payload.Email }
            $email = ([string]$emailValue).Trim().ToLowerInvariant()
            $valid = $email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'
            $rows = if ($valid) { Invoke-Db ("SELECT 1 FROM accounts WHERE email = {0} LIMIT 1;" -f (Sql-Escape $email)) } else { @('x') }
            if ($valid -and $rows.Count -eq 0) { Send-Json $Stream ([pscustomobject]@{IsValid=$true; EMail=$email}) }
            else { Send-Json $Stream ([pscustomobject]@{IsValid=$false; errorCode=59; errorMessage='Email address is invalid or already used.'; EMail=$email}) }
        }
        'checkpassword' {
            $passwordValue = if ($Payload.PSObject.Properties.Name -contains 'Password1') { $Payload.Password1 } else { $Payload.Password }
            $password = [string]$passwordValue
            $ok = ($password.Length -ge 10 -and $password -match '[a-z]' -and $password -match '[A-Z]' -and $password -match '[0-9]' -and $password -notmatch '[\s''"\\/]' )
            Send-Json $Stream ([pscustomobject]@{PasswordValid=$ok; PasswordStrength=$(if($ok){4}else{1}); PasswordStrengthColor=$(if($ok){'#20a000'}else{'#ec644b'}); Password1=$password; PasswordRequirements=[pscustomobject]@{PasswordLength=$password.Length -ge 10; InvalidCharacters=$password -notmatch '[\s''"\\/]'; HasLowerCase=$password -match '[a-z]'; HasUpperCase=$password -match '[A-Z]'; HasNumber=$password -match '[0-9]'}})
        }
        'checkcharactername' {
            $name = Normalize-CharacterName ([string]$Payload.CharacterName)
            $available = ($name.Length -ge 3 -and $name.Length -le 29 -and (Test-NameAvailable $name))
            Send-Json $Stream ([pscustomobject]@{CharacterName=$name; IsAvailable=$available; errorMessage=$(if($available){$null}else{'Character name is invalid or already exists.'})})
        }
        'generatecharactername' {
            Send-Json $Stream ([pscustomobject]@{GeneratedName=(New-CharacterName '')})
        }
        'createaccountandcharacter' {
            $emailValue = if ($Payload.PSObject.Properties.Name -contains 'EMail') { $Payload.EMail } else { $Payload.Email }
            $passwordValue = if ($Payload.PSObject.Properties.Name -contains 'Password') { $Payload.Password } else { $Payload.Password1 }
            $email = ([string]$emailValue).Trim().ToLowerInvariant()
            $password = [string]$passwordValue
            if ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw 'Invalid email format.' }
            if ($password.Length -lt 10) { throw 'Password does not meet the requirements.' }
            $exists = Invoke-Db ("SELECT 1 FROM accounts WHERE email = {0} LIMIT 1;" -f (Sql-Escape $email))
            if ($exists.Count -gt 0) { throw 'Email already exists.' }
            $accountName = New-AccountName $email
            $characterName = New-CharacterName ([string]$Payload.CharacterName)
            $sexRaw = if ($Payload.PSObject.Properties.Name -contains 'CharacterSex') { $Payload.CharacterSex } else { 'male' }
            $sexValue = ([string]$sexRaw).ToLowerInvariant()
            $sex = if ($sexValue -eq 'female' -or $sexValue -eq '0') { 0 } else { 1 }
            $lookType = if ($sex -eq 1) { 128 } else { 136 }
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $hash = New-Sha1 $password
            Invoke-Db ("INSERT INTO accounts (name,password,email,creation,coins) VALUES ({0},{1},{2},{3},999999);" -f (Sql-Escape $accountName),(Sql-Escape $hash),(Sql-Escape $email),$now) | Out-Null
            $accountId = [int](Invoke-Db ("SELECT id FROM accounts WHERE name = {0} LIMIT 1;" -f (Sql-Escape $accountName)))[0]
            foreach ($group in @('Enemies','Friends','Trading Partner')) {
                Invoke-Db ("INSERT INTO account_vipgroups (account_id,name,customizable) VALUES ({0},{1},0);" -f $accountId,(Sql-Escape $group)) | Out-Null
            }
            $town = Invoke-Db 'SELECT id,posx,posy,posz FROM towns WHERE id = 1 LIMIT 1;'
            if ($town.Count -gt 0) { $t = $town[0].Split("`t"); $townId=$t[0]; $posx=$t[1]; $posy=$t[2]; $posz=$t[3] } else { $townId=1; $posx=32069; $posy=31901; $posz=6 }
            Invoke-Db ("INSERT INTO players (name,account_id,level,vocation,health,healthmax,experience,lookbody,lookfeet,lookhead,looklegs,looktype,mana,manamax,soul,town_id,posx,posy,posz,conditions,cap,sex) VALUES ({0},{1},8,0,185,185,4200,68,76,78,58,{2},90,90,100,{3},{4},{5},{6},'',470,{7});" -f (Sql-Escape $characterName),$accountId,$lookType,$townId,$posx,$posy,$posz,$sex) | Out-Null
            Send-Json $Stream ([pscustomobject]@{Success=$true; AccountID=$accountName; AccountName=$accountName; EMail=$email; CharacterName=$characterName})
        }
        default { Send-Error $Stream 'Unknown action.' 400 }
    }
}

function Handle-Login($Stream, $Payload) {
    $type = ([string]$Payload.type).ToLowerInvariant()
    if ($type -ne 'login') { Send-Json $Stream ([pscustomobject]@{categorycounts=@(); gamenews=@(); idOfNewestReadEntry=0; isreturner=$false; lastupdatetimestamp=0; maxeditdate=0; showrewardnews=$false}); return }
    $emailValue = if ($Payload.PSObject.Properties.Name -contains 'email') { $Payload.email } else { $Payload.accountname }
    $email = ([string]$emailValue).Trim().ToLowerInvariant()
    $password = [string]$Payload.password
    if (([string]::IsNullOrWhiteSpace($email) -or [string]::IsNullOrWhiteSpace($password)) -and $Payload.sessionkey) {
        $parts = ([string]$Payload.sessionkey -replace "`r`n","`n").Split("`n",2)
        if ($parts.Count -eq 2) { $email = $parts[0].Trim().ToLowerInvariant(); $password = $parts[1] }
    }
    $rows = Invoke-Db ("SELECT id,password,lastday FROM accounts WHERE email = {0} OR name = {0} LIMIT 1;" -f (Sql-Escape $email))
    if ($rows.Count -eq 0) { Send-Json $Stream ([pscustomobject]@{errorCode=3; errorMessage='Email or password is not correct.'}); return }
    $account = $rows[0].Split("`t")
    if ((New-Sha1 $password) -ne $account[1]) { Send-Json $Stream ([pscustomobject]@{errorCode=3; errorMessage='Email or password is not correct.'}); return }
    $accountId = [int]$account[0]
    $players = Invoke-Db ("SELECT name,level,sex,vocation,looktype,lookhead,lookbody,looklegs,lookfeet,lookaddons,isreward,istutorial FROM players WHERE account_id = {0} AND deletion = 0 ORDER BY name ASC;" -f $accountId)
    $characters = @()
    foreach ($line in $players) {
        $p = $line.Split("`t")
        $characters += [pscustomobject]@{worldid=0; name=$p[0]; ismale=([int]$p[2] -eq 1); tutorial=([int]$p[11] -eq 1); level=[int]$p[1]; vocation='None'; outfitid=[int]$p[4]; headcolor=[int]$p[5]; torsocolor=[int]$p[6]; legscolor=[int]$p[7]; detailcolor=[int]$p[8]; addonsflags=[int]$p[9]; ishidden=$false; istournamentparticipant=$false; ismaincharacter=$false; dailyrewardstate=[int]$p[10]; remainingdailytournamentplaytime=0}
    }
    Send-Json $Stream ([pscustomobject]@{
        session=[pscustomobject]@{sessionkey=($email+"`n"+$password); lastlogintime=0; ispremium=$false; premiumuntil=0; status='active'; returnernotification=$false; showrewardnews=$false; isreturner=$false; fpstracking=$false; optiontracking=$false; tournamentticketpurchasestate=0; emailcoderequest=$false}
        playdata=[pscustomobject]@{worlds=@([pscustomobject]@{id=0; name='FazendoTibia'; externaladdress=$WorldAddress; externaladdressprotected=$WorldAddress; externaladdressunprotected=$WorldAddress; externalport=$GamePort; externalportprotected=$GamePort; externalportunprotected=$GamePort; previewstate=0; location='BRA'; anticheatprotection=$false; pvptype=0; istournamentworld=$false; restrictedstore=$false; currenttournamentphase=2}); characters=$characters}
    })
}

function Get-LocalVersion {
    $path = Join-Path $Root 'version.json'
    if (-not (Test-Path $path)) { return [pscustomobject]@{version='unknown'} }
    return (Get-Content -Path $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse($BindAddress), $HttpPort)
$listener.Start()
Write-EndpointLog "Portable web endpoint listening on ${BindAddress}:$HttpPort world=${WorldAddress}:$GamePort"
while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $request = Get-Request $stream
        if ($null -eq $request) { continue }
        $payload = if ([string]::IsNullOrWhiteSpace($request.Body)) { [pscustomobject]@{} } else { $request.Body | ConvertFrom-Json }
        if ($request.Path -like '/version.json*') { Send-Json $stream (Get-LocalVersion) }
        elseif ($request.Path -like '/clientcreateaccount.php*') { Handle-ClientCreate $stream $payload }
        elseif ($request.Path -like '/login.php*') { Handle-Login $stream $payload }
        else { Send-Json $stream ([pscustomobject]@{ok=$true}) }
    } catch {
        Write-EndpointLog $_.Exception.Message
        try { Send-Error $stream $_.Exception.Message 101 } catch {}
    } finally {
        $client.Close()
    }
}
'@ | Set-Content -Path $Path -Encoding UTF8
}

function Start-TrmPortableWebEndpoint {
    param(
        [object]$Config,
        [scriptblock]$ProgressCallback,
        [string]$BindAddress = '127.0.0.1',
        [string]$WorldAddress = '127.0.0.1',
        [int]$GamePort = 7172
    )
    $root = Get-TrmRoot
    $port = [int]$Config.webServerPort
    $databaseExe = Resolve-TrmRuntimePath ([string]$Config.databaseExe)
    $mysqlExe = Join-Path (Split-Path -Parent $databaseExe) 'mysql.exe'
    if (-not (Test-Path $mysqlExe)) { throw "mysql.exe not found: $mysqlExe" }
    $scriptPath = Join-Path $root 'UserData\Runtime\portable-web-endpoint.ps1'
    Write-TrmPortableWebEndpointScript -Path $scriptPath
    if ($ProgressCallback) { & $ProgressCallback 'Iniciando webservice local portatil...' 0 0 0 }
    $databaseName = 'otserv'
    if ($Config.PSObject.Properties.Name -contains 'databaseName' -and -not [string]::IsNullOrWhiteSpace([string]$Config.databaseName)) { $databaseName = [string]$Config.databaseName }
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath,'-Root',$root,'-MysqlExe',$mysqlExe,'-DbPort',[string]$Config.databasePort,'-HttpPort',[string]$port,'-Database',$databaseName,'-BindAddress',$BindAddress,'-WorldAddress',$WorldAddress,'-GamePort',[string]$GamePort) -WorkingDirectory $root -WindowStyle Hidden -PassThru
    Save-TrmPortableWebEndpointState -BindAddress $BindAddress -WorldAddress $WorldAddress -GamePort $GamePort -HttpPort $port -ProcessId $process.Id
}

function Get-TrmPortableWebEndpointStatePath {
    $dir = Join-Path (Get-TrmRoot) 'UserData\Runtime'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return (Join-Path $dir 'portable-web-endpoint-state.json')
}

function Get-TrmPortableWebEndpointState {
    return (Read-TrmJsonFile -Path (Get-TrmPortableWebEndpointStatePath) -Default ([pscustomobject]@{}))
}

function Save-TrmPortableWebEndpointState {
    param(
        [string]$BindAddress,
        [string]$WorldAddress,
        [int]$GamePort,
        [int]$HttpPort,
        [int]$ProcessId = 0
    )
    Save-TrmJsonFile -Path (Get-TrmPortableWebEndpointStatePath) -Value ([pscustomobject]@{
        bindAddress = $BindAddress
        worldAddress = $WorldAddress
        gamePort = $GamePort
        httpPort = $HttpPort
        processId = $ProcessId
        startedAt = (Get-Date).ToString('s')
    })
}

function Test-TrmPortableWebEndpointMode {
    param(
        [object]$Config,
        [string]$BindAddress,
        [string]$WorldAddress,
        [int]$GamePort
    )
    $state = Get-TrmPortableWebEndpointState
    $port = [int]$Config.webServerPort
    return (
        (Test-TrmWebEndpointHealthy -Port $port) -and
        ($state.PSObject.Properties.Match('bindAddress').Count -gt 0) -and ([string]$state.bindAddress -eq $BindAddress) -and
        ($state.PSObject.Properties.Match('worldAddress').Count -gt 0) -and ([string]$state.worldAddress -eq $WorldAddress) -and
        ($state.PSObject.Properties.Match('gamePort').Count -gt 0) -and ([int]$state.gamePort -eq $GamePort) -and
        ($state.PSObject.Properties.Match('httpPort').Count -gt 0) -and ([int]$state.httpPort -eq $port)
    )
}

function Stop-TrmPortableWebEndpoint {
    $root = Get-TrmRoot
    $scriptPath = Join-Path $root 'UserData\Runtime\portable-web-endpoint.ps1'
    $state = Get-TrmPortableWebEndpointState
    $stopped = 0
    if (($state.PSObject.Properties.Match('processId').Count -gt 0) -and ([int]$state.processId -gt 0)) {
        $tracked = Get-Process -Id ([int]$state.processId) -ErrorAction SilentlyContinue
        if ($tracked -and ($tracked.ProcessName -in @('powershell','pwsh'))) {
            Stop-Process -Id $tracked.Id -Force -ErrorAction SilentlyContinue
            $stopped++
        }
    }
    try {
        $processes = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -and $_.CommandLine.Contains($scriptPath) })
        foreach ($process in $processes) {
            if (-not (($state.PSObject.Properties.Match('processId').Count -gt 0) -and ([int]$state.processId -eq [int]$process.ProcessId))) {
                Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
                $stopped++
            }
        }
    } catch {}
    if (($state.PSObject.Properties.Match('httpPort').Count -gt 0) -and ([int]$state.httpPort -gt 0)) {
        $port = [int]$state.httpPort
        $listeners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
        foreach ($listener in $listeners) {
            $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
            if ($owner -and ($owner.ProcessName -in @('powershell','pwsh'))) {
                Stop-Process -Id $owner.Id -Force -ErrorAction SilentlyContinue
                $stopped++
            }
        }
        try {
            $lines = @(& netstat.exe -ano 2>$null | Where-Object { $_ -match "^\s*TCP\s+\S+:$port\s+\S+\s+LISTENING\s+(\d+)\s*$" })
            foreach ($line in $lines) {
                if ($line -match "^\s*TCP\s+\S+:$port\s+\S+\s+LISTENING\s+(\d+)\s*$") {
                    $pid = [int]$Matches[1]
                    $owner = Get-Process -Id $pid -ErrorAction SilentlyContinue
                    if ($owner -and ($owner.ProcessName -in @('powershell','pwsh'))) {
                        Stop-Process -Id $owner.Id -Force -ErrorAction SilentlyContinue
                        $stopped++
                    }
                }
            }
        } catch {}
    }
    return $stopped
}

function Ensure-TrmPortableWebEndpointMode {
    param(
        [object]$Config,
        [scriptblock]$ProgressCallback,
        [string]$BindAddress = '127.0.0.1',
        [string]$WorldAddress = '127.0.0.1',
        [int]$GamePort = 7172
    )
    $port = [int]$Config.webServerPort
    if (Test-TrmPortableWebEndpointMode -Config $Config -BindAddress $BindAddress -WorldAddress $WorldAddress -GamePort $GamePort) { return }
    if (Test-TrmWebEndpointHealthy -Port $port) {
        Stop-TrmPortableWebEndpoint | Out-Null
        $deadline = (Get-Date).AddSeconds(5)
        while ((Get-Date) -lt $deadline) {
            if (-not (Test-TrmLocalPortListening -Port $port)) { break }
            Start-Sleep -Milliseconds 250
        }
    }
    if (Test-TrmLocalPortListening -Port $port) {
        throw "A porta web $port esta em uso por outro processo. Feche o processo nessa porta antes de alternar entre Offline e Host Assistido."
    }
    Start-TrmPortableWebEndpoint -Config $Config -ProgressCallback $ProgressCallback -BindAddress $BindAddress -WorldAddress $WorldAddress -GamePort $GamePort
    $deadline = (Get-Date).AddSeconds([int]$Config.webServerStartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-TrmPortableWebEndpointMode -Config $Config -BindAddress $BindAddress -WorldAddress $WorldAddress -GamePort $GamePort) { return }
        Start-Sleep -Seconds 1
    }
    throw "Endpoint web portatil nao iniciou no modo solicitado ($WorldAddress`:$GamePort)."
}

function Ensure-TrmWebEndpoint {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = [int]$Config.webServerPort
    if (Test-TrmPortableWebEndpointMode -Config $Config -BindAddress '127.0.0.1' -WorldAddress '127.0.0.1' -GamePort 7172) { return }
    if (Test-TrmWebEndpointHealthy -Port $port) {
        Stop-TrmPortableWebEndpoint | Out-Null
        $deadline = (Get-Date).AddSeconds(5)
        while ((Get-Date) -lt $deadline) {
            if (-not (Test-TrmLocalPortListening -Port $port)) { break }
            Start-Sleep -Milliseconds 250
        }
    }
    if (Test-TrmLocalPortListening -Port $port) {
        throw "A porta web $port esta aberta, mas nao responde ao endpoint local de criacao/login. Feche Apache/IIS/outro servidor nessa porta e abra o launcher novamente."
    }
    $webServerExe = [string]$Config.webServerExe
    if (-not [string]::IsNullOrWhiteSpace($webServerExe) -and (Test-Path $webServerExe)) {
        if ($ProgressCallback) { & $ProgressCallback 'Iniciando endpoint web local...' 0 0 0 }
        $args = [string]$Config.webServerArguments
        if ([string]::IsNullOrWhiteSpace($args)) {
            Start-Process -FilePath $webServerExe -WorkingDirectory ([string]$Config.webServerWorkingDirectory) -WindowStyle Hidden | Out-Null
        } else {
            Start-Process -FilePath $webServerExe -ArgumentList $args -WorkingDirectory ([string]$Config.webServerWorkingDirectory) -WindowStyle Hidden | Out-Null
        }
        $deadline = (Get-Date).AddSeconds([int]$Config.webServerStartupTimeoutSeconds)
        while ((Get-Date) -lt $deadline) {
            if (Test-TrmWebEndpointHealthy -Port $port) { return }
            Start-Sleep -Seconds 1
        }
        Write-TrmLog "Configured web server did not provide launcher endpoints; falling back to portable endpoint." 'WARN'
    }
    Start-TrmPortableWebEndpoint -Config $Config -ProgressCallback $ProgressCallback -BindAddress '127.0.0.1' -WorldAddress '127.0.0.1' -GamePort 7172
    $deadline = (Get-Date).AddSeconds([int]$Config.webServerStartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-TrmWebEndpointHealthy -Port $port) { return }
        Start-Sleep -Seconds 1
    }
    throw "Web endpoint did not open port $port before timeout."
}

function Resolve-TrmRuntimePath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path (Get-TrmRoot) $Path)
}

function Get-TrmAdminPanelAllowed {
    $config = Get-TrmConfig
    if ($env:TRM_DEVELOPER_MODE -eq '1' -or $env:TRM_ADMIN_PANEL -eq '1') { return $true }
    $developerMode = $false
    $adminPanelEnabled = $false
    if ($config.PSObject.Properties.Name -contains 'developerMode') { $developerMode = [bool]$config.developerMode }
    if ($config.PSObject.Properties.Name -contains 'adminPanelEnabled') { $adminPanelEnabled = [bool]$config.adminPanelEnabled }
    return ($developerMode -and $adminPanelEnabled)
}

function Get-TrmBalanceTestLogDirectory {
    $root = Get-TrmRoot
    $path = Join-Path $root 'Logs\BalanceTests'
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Get-TrmRemasteredFeatureFlag {
    param([string]$Name)
    $path = Join-Path (Get-TrmRoot) 'Modules\Remastered\Config\features.lua'
    if (-not (Test-Path $path)) { return $null }
    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*=\s*(true|false)\s*,?'
    foreach ($line in (Get-Content -Path $path -Encoding UTF8)) {
        if ($line -match $pattern) { return ($Matches[1] -eq 'true') }
    }
    return $null
}

function Clear-TrmAdminBalanceTestLogs {
    if (-not (Get-TrmAdminPanelAllowed)) { throw 'Admin panel is disabled. Enable developerMode and adminPanelEnabled in Config\launcher-config.json, or set TRM_DEVELOPER_MODE=1.' }
    $dir = Get-TrmBalanceTestLogDirectory
    Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Remove-Item -Force
    $legacy = Join-Path (Get-TrmRoot) 'Logs\remastered-balance-tests.log'
    if (Test-Path $legacy) { Remove-Item -Path $legacy -Force }
    return $dir
}

function Invoke-TrmAdminBalancePanelTest {
    param(
        [ValidateSet('balance','xp','skill','loot')][string]$Command,
        [string]$Param = '',
        [int]$TimeoutSeconds = 15
    )
    if (-not (Get-TrmAdminPanelAllowed)) { throw 'Admin panel is disabled. Enable developerMode and adminPanelEnabled in Config\launcher-config.json, or set TRM_DEVELOPER_MODE=1.' }

    $config = Get-TrmConfig
    if (-not (Wait-TrmServerPorts -Ports @($config.serverPorts) -TimeoutSeconds 3)) {
        throw 'Server is not open. Click Jogar first and wait until the server starts.'
    }

    $dir = Get-TrmBalanceTestLogDirectory
    $id = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()).ToString()
    $requestPath = Join-Path $dir 'admin-panel-request.txt'
    $resultPath = Join-Path $dir ("admin-panel-result-$id.log")
    if (Test-Path $resultPath) { Remove-Item -Path $resultPath -Force }

    $request = @(
        "id=$id",
        "command=$Command",
        "param=$($Param -replace "`r",' ' -replace "`n",' ')",
        "createdAt=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "source=launcher"
    )
    Set-Content -Path $requestPath -Value $request -Encoding ASCII

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $resultPath) {
            return (Get-Content -Path $resultPath -Raw -Encoding UTF8)
        }
        Start-Sleep -Milliseconds 500
    }
    throw "Admin test timed out. Request was written to $requestPath, but the server did not create $resultPath."
}

function Get-TrmLocalIPv4Address {
    $addresses = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -ExpandProperty IPAddress)
    if ($addresses.Count -gt 0) { return [string]$addresses[0] }
    return '127.0.0.1'
}

function Get-TrmLocalHostAliases {
    $aliases = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($value in @('localhost', '127.0.0.1', '::1', $env:COMPUTERNAME, [System.Net.Dns]::GetHostName())) {
        if (-not [string]::IsNullOrWhiteSpace([string]$value)) { [void]$aliases.Add(([string]$value).Trim()) }
    }
    try {
        $addresses = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' } |
            Select-Object -ExpandProperty IPAddress)
        foreach ($address in $addresses) {
            if (-not [string]::IsNullOrWhiteSpace([string]$address)) { [void]$aliases.Add(([string]$address).Trim()) }
        }
    } catch {}
    return @($aliases)
}

function Test-TrmHostIsLocalMachine {
    param([string]$Host)
    if ([string]::IsNullOrWhiteSpace($Host)) { return $false }
    $normalized = $Host.Trim().Trim('[',']')
    return (@(Get-TrmLocalHostAliases) -contains $normalized)
}

function Resolve-TrmClientWorldAddress {
    param([string]$Host)
    if (Test-TrmHostIsLocalMachine -Host $Host) { return '127.0.0.1' }
    return $Host
}

function Write-TrmClientLaunchLog {
    param(
        [string]$Mode,
        [string]$Host,
        [int]$Port,
        [string]$ClientWorldAddress,
        [string]$ConfigDescription,
        [string]$ClientExe,
        [string]$ClientWorkingDirectory
    )
    $command = '"{0}" (WorkingDirectory="{1}")' -f $ClientExe, $ClientWorkingDirectory
    Write-TrmLog ("Client launch: mode={0}; host={1}; clientWorldAddress={2}; port={3}; config={4}; command={5}" -f $Mode, $Host, $ClientWorldAddress, $Port, $ConfigDescription, $command)
}

function Get-TrmConnectionTestDirectory {
    $path = Join-Path (Get-TrmRoot) 'Logs\ConnectionTests'
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Test-TrmLoopbackHost {
    param([string]$Host)
    if ([string]::IsNullOrWhiteSpace($Host)) { return $false }
    $normalized = $Host.Trim().Trim('[',']').ToLowerInvariant()
    return ($normalized -in @('127.0.0.1','localhost','::1'))
}

function Test-TrmTcpConnectionDirect {
    param([string]$Host, [int]$Port, [int]$TimeoutMs = 2500)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($Host, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            return [pscustomobject]@{host=$Host; port=$Port; succeeded=$false; error='timeout'; direct=$true}
        }
        $client.EndConnect($async)
        return [pscustomobject]@{host=$Host; port=$Port; succeeded=$true; error=''; direct=$true}
    } catch {
        return [pscustomobject]@{host=$Host; port=$Port; succeeded=$false; error=$_.Exception.Message; direct=$true}
    } finally {
        $client.Close()
    }
}

function Test-TrmLoginHttpEndpoint {
    param([string]$Host, [int]$WebPort = 80)
    $statusUri = "http://${Host}:$WebPort/clientcreateaccount.php"
    try {
        $body = '{"type":"GetAccountCreationStatus"}'
        $response = Invoke-RestMethod -Uri $statusUri -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 4
        $ok = ($response -and ($response.PSObject.Properties.Name -contains 'RecommendedWorld'))
        return [pscustomobject]@{url=$statusUri; responded=$ok; error=''; recommendedWorld=$(if($ok){[string]$response.RecommendedWorld}else{''})}
    } catch {
        return [pscustomobject]@{url=$statusUri; responded=$false; error=$_.Exception.Message; recommendedWorld=''}
    }
}

function New-TrmConnectionTestReport {
    param(
        [ValidateSet('offline','host-local','remote')][string]$Mode,
        [string]$RawInvite = '',
        [string]$Host = '',
        [int]$Port = 7172,
        [int]$WebPort = 80,
        [string]$WorldName = '',
        [string]$ExpectedVersion = '',
        [string]$ClientWorldAddress = '',
        [string]$ClientExe = '',
        [string]$ClientWorkingDirectory = '',
        [string]$ConfigDescription = '',
        [string]$ErrorMessage = '',
        [string]$Phase = 'preflight'
    )
    $parsedInvite = if (-not [string]::IsNullOrWhiteSpace($RawInvite)) { ConvertFrom-TrmWorldInvite -InviteText $RawInvite } else { $null }
    $invitePublicHost = if ($parsedInvite) { [string]$parsedInvite.publicHost } else { '' }
    $isLoopback = Test-TrmLoopbackHost -Host $Host
    $tcp = if (-not [string]::IsNullOrWhiteSpace($Host)) { Test-TrmTcpConnectionDirect -Host $Host -Port $Port } else { [pscustomobject]@{host=$Host; port=$Port; succeeded=$false; error='host vazio'; direct=$true} }
    $login = if (-not [string]::IsNullOrWhiteSpace($Host)) { Test-TrmLoginHttpEndpoint -Host $Host -WebPort $WebPort } else { [pscustomobject]@{url=''; responded=$false; error='host vazio'; recommendedWorld=''} }
    $version = if (-not [string]::IsNullOrWhiteSpace($Host)) { Test-TrmVersionCompatibility -Host $Host -WebPort $WebPort } else { [pscustomobject]@{compatible=$false; localVersion=(GetCurrentVersion); hostVersion='unknown'; hostVersionAvailable=$false; message='host vazio'} }
    $localPortUsage = Get-TrmPortUsage -Port $Port
    $endpointState = Get-TrmPortableWebEndpointState
    $clientCommand = if (-not [string]::IsNullOrWhiteSpace($ClientExe)) { '"{0}" (WorkingDirectory="{1}")' -f $ClientExe, $ClientWorkingDirectory } else { '' }

    $failure = ''
    if ($Mode -eq 'remote' -and $isLoopback) { $failure = 'convite usa localhost; convidado remoto nunca deve conectar em 127.0.0.1/localhost' }
    elseif (-not $tcp.succeeded) { $failure = "porta fechada ou bloqueada em ${Host}:$Port" }
    elseif (-not $version.compatible) { $failure = $version.message }
    elseif (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) { $failure = $ErrorMessage }

    $path = Join-Path (Get-TrmConnectionTestDirectory) ('connection-test-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
    $report = [pscustomobject]@{
        generatedAt = (Get-Date).ToString('s')
        mode = $Mode
        phase = $Phase
        rawInvite = $RawInvite
        worldName = $WorldName
        extractedHost = $Host
        publicHost = $invitePublicHost
        inviteVersion = $ExpectedVersion
        inviteMode = if ($parsedInvite) { [string]$parsedInvite.mode } else { $Mode }
        finalHost = $Host
        finalPort = $Port
        webPort = $WebPort
        isLoopbackHost = $isLoopback
        tcpTest = $tcp
        localPortUsage = $localPortUsage
        loginServer = $login
        version = $version
        clientWorldAddress = $ClientWorldAddress
        clientUsesSameHostAndPort = ($ClientWorldAddress -eq $Host -and $Port -gt 0)
        clientConfigDescription = $ConfigDescription
        portableEndpointState = $endpointState
        clientCommand = $clientCommand
        possibleFirewallOrNatBlock = (-not $tcp.succeeded -and -not $isLoopback)
        errorMessage = $ErrorMessage
        failureReason = $failure
        status = if ([string]::IsNullOrWhiteSpace($failure)) { 'passed' } else { 'failed' }
        reportPath = $path
    }
    Save-TrmJsonFile -Path $path -Value $report
    return $report
}

function Format-TrmConnectionFailure {
    param([object]$Report)
    if ($null -eq $Report) { return 'Erro de conexao sem relatorio detalhado.' }
    if (-not [string]::IsNullOrWhiteSpace([string]$Report.failureReason)) {
        return "Falha de conexao: $($Report.failureReason). Relatorio: $($Report.reportPath)"
    }
    return "Falha de conexao. Relatorio: $($Report.reportPath)"
}

function Get-TrmPublicIPAddress {
    try {
        return ((Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 4).ToString())
    } catch {
        return 'indisponivel'
    }
}

function Get-TrmOnlineDiagnosticDirectory {
    $path = Join-Path (Get-TrmRoot) 'Logs\OnlineDiagnostics'
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Get-TrmPortUsage {
    param([int]$Port)
    $connections = @(Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue)
    if ($connections.Count -eq 0) {
        return [pscustomobject]@{port=$Port; inUse=$false; processes=@()}
    }
    $processes = @()
    foreach ($connection in $connections) {
        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        $processPath = ''
        if ($process) {
            try { $processPath = [string]$process.Path } catch { $processPath = '' }
        }
        $processes += [pscustomobject]@{
            pid = $connection.OwningProcess
            name = if ($process) { $process.ProcessName } else { 'unknown' }
            path = $processPath
            state = $connection.State
        }
    }
    return [pscustomobject]@{port=$Port; inUse=$true; processes=$processes}
}

function Get-TrmLocalVersion {
    $version = Read-TrmJsonFile -Path (Join-Path (Get-TrmRoot) 'version.json') -Default ([pscustomobject]@{version='unknown'})
    if ($version.PSObject.Properties.Name -contains 'version') { return [string]$version.version }
    return 'unknown'
}

function GetCurrentVersion {
    return Get-TrmLocalVersion
}

function Get-TrmWorldName {
    $config = Get-TrmConfig
    if ($config.PSObject.Properties.Name -contains 'worldName' -and -not [string]::IsNullOrWhiteSpace([string]$config.worldName)) {
        return [string]$config.worldName
    }
    return 'FazendoTibia'
}

function Get-TrmConnectedPlayerCount {
    param([int]$Port = 7172)
    try {
        $connections = @(Get-NetTCPConnection -LocalPort $Port -State Established -ErrorAction SilentlyContinue)
        return $connections.Count
    } catch {
        return 0
    }
}

function New-TrmWorldInvite {
    param(
        [string]$WorldName,
        [string]$Host,
        [string]$PublicHost = '',
        [int]$Port,
        [string]$Version,
        [ValidateSet('remote','host-local')][string]$Mode = 'remote'
    )
    if ([string]::IsNullOrWhiteSpace($WorldName)) { $WorldName = Get-TrmWorldName }
    if ([string]::IsNullOrWhiteSpace($Version)) { $Version = GetCurrentVersion }
    if ([string]::IsNullOrWhiteSpace($PublicHost)) { $PublicHost = $Host }
    if ($Mode -eq 'remote') {
        if (Test-TrmLoopbackHost -Host $Host) { throw 'Convite remoto nao pode usar localhost ou 127.0.0.1.' }
        if ([string]::IsNullOrWhiteSpace($Host)) { throw 'Convite remoto exige um IP/endereco LAN ou publico.' }
        if ((Test-TrmLoopbackHost -Host $PublicHost) -or $PublicHost -eq 'indisponivel') { $PublicHost = $Host }
    }
    $invite = @"
TIBIA_REMASTERED_INVITE
world=$WorldName
host=$Host
publicHost=$PublicHost
port=$Port
version=$Version
mode=$Mode
"@
    return $invite.Trim()
}

function ConvertFrom-TrmWorldInvite {
    param([string]$InviteText)
    $result = [ordered]@{
        worldName = ''
        host = ''
        publicHost = ''
        port = 7172
        version = ''
        mode = ''
        valid = $false
        error = ''
    }
    if ([string]::IsNullOrWhiteSpace($InviteText)) { return [pscustomobject]$result }
    $normalizedInvite = ([string]$InviteText).TrimStart([char]0xFEFF)
    if ($normalizedInvite -match '\\r\\n|\\n') {
        $normalizedInvite = $normalizedInvite -replace '\\r\\n', "`n"
        $normalizedInvite = $normalizedInvite -replace '\\n', "`n"
    }
    $lines = @(($normalizedInvite -replace "`r`n","`n") -split "`n")
    $hasOfficialHeader = @($lines | Where-Object { $_.Trim().TrimStart([char]0xFEFF) -ieq 'TIBIA_REMASTERED_INVITE' }).Count -gt 0
    $seenOfficial = @{}
    foreach ($line in $lines) {
        $trimmed = $line.Trim().TrimStart([char]0xFEFF)
        if ($hasOfficialHeader -and $trimmed -match '^([A-Za-z][A-Za-z0-9_-]*)\s*(=|:)\s*(.*)$') {
            $key = $Matches[1].Trim().ToLowerInvariant()
            $value = $Matches[3].Trim()
            $seenOfficial[$key] = $true
            if ($key -eq 'world') { $result.worldName = $value; continue }
            if ($key -eq 'host') { $result.host = $value; continue }
            if ($key -eq 'publichost') { $result.publicHost = $value; continue }
            if ($key -eq 'port') {
                if ($value -match '^\d+$') { $result.port = [int]$value } else { $result.error = "Convite invalido: port=$value nao e numerico." }
                continue
            }
            if ($key -eq 'version') { $result.version = $value; continue }
            if ($key -eq 'mode') { $result.mode = $value.ToLowerInvariant(); continue }
            continue
        }
        if (-not $hasOfficialHeader -and $trimmed -match '^(Mundo|World)\s*:\s*(.+)$') { $result.worldName = $Matches[2].Trim(); continue }
        if (-not $hasOfficialHeader -and $trimmed -match '^(IP|Host|Endereco|Address)\s*:\s*(.+)$') { $result.host = $Matches[2].Trim(); continue }
        if (-not $hasOfficialHeader -and $trimmed -match '^(Porta|Port)\s*:\s*(\d+)$') { $result.port = [int]$Matches[2]; continue }
        if (-not $hasOfficialHeader -and $trimmed -match '^(Versao|Version)\s*:\s*(.+)$' -and [string]::IsNullOrWhiteSpace([string]$result.version)) { $result.version = $Matches[2].Trim(); continue }
        if ($trimmed -match '^([a-zA-Z0-9\.\-]+):(\d+)$') { $result.host = $Matches[1].Trim(); $result.port = [int]$Matches[2]; continue }
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.mode)) {
        $result.mode = if ($hasOfficialHeader) { '' } else { 'remote' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.publicHost)) { $result.publicHost = $result.host }
    if ($hasOfficialHeader -and -not [string]::IsNullOrWhiteSpace([string]$result.error)) { }
    elseif ($hasOfficialHeader -and (-not $seenOfficial.ContainsKey('host') -or [string]::IsNullOrWhiteSpace([string]$result.host))) { $result.error = 'Convite invalido: campo host ausente.' }
    elseif ($hasOfficialHeader -and (-not $seenOfficial.ContainsKey('port') -or [int]$result.port -le 0)) { $result.error = 'Convite invalido: campo port ausente ou invalido.' }
    elseif ($hasOfficialHeader -and (-not $seenOfficial.ContainsKey('version') -or [string]::IsNullOrWhiteSpace([string]$result.version))) { $result.error = 'Convite invalido: campo version ausente.' }
    elseif ($hasOfficialHeader -and (-not $seenOfficial.ContainsKey('mode') -or [string]::IsNullOrWhiteSpace([string]$result.mode))) { $result.error = 'Convite invalido: campo mode ausente.' }
    elseif ($result.mode -eq 'host-local') { $result.error = 'Este convite e local do host e nao deve ser usado por convidados.' }
    elseif ($hasOfficialHeader -and $result.mode -ne 'remote') { $result.error = "Convite invalido: mode=$($result.mode) nao e aceito em Entrar em Mundo." }
    elseif ($result.mode -eq 'remote' -and (Test-TrmLoopbackHost -Host ([string]$result.host))) { $result.error = 'Convite remoto invalido: host nao pode ser localhost ou 127.0.0.1.' }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$result.version) -and $result.version -notmatch '^\d+\.\d+\.\d+([-.][A-Za-z0-9.-]+)?$') { $result.error = "Convite invalido: version=$($result.version) nao parece uma versao do projeto." }
    $result.valid = ([string]::IsNullOrWhiteSpace([string]$result.error) -and -not [string]::IsNullOrWhiteSpace([string]$result.host) -and [int]$result.port -gt 0)
    return [pscustomobject]$result
}

function Get-TrmCopyableWorldInvite {
    param([string]$InviteText)
    $parsed = ConvertFrom-TrmWorldInvite -InviteText $InviteText
    if (-not $parsed.valid -or $parsed.mode -ne 'remote' -or (Test-TrmLoopbackHost -Host $parsed.host)) {
        throw "Convite remoto invalido para copia: $($parsed.error)"
    }
    return (New-TrmWorldInvite -WorldName $parsed.worldName -Host $parsed.host -PublicHost $parsed.publicHost -Port ([int]$parsed.port) -Version $parsed.version -Mode remote)
}

function Get-TrmHostVersion {
    param([string]$Host, [int]$WebPort = 80)
    try {
        $uri = "http://${Host}:$WebPort/version.json"
        $response = Invoke-RestMethod -Uri $uri -TimeoutSec 4
        if ($response -and ($response.PSObject.Properties.Name -contains 'version')) {
            return [pscustomobject]@{available=$true; version=[string]$response.version; source=$uri}
        }
    } catch {
        return [pscustomobject]@{available=$false; version='unknown'; source="http://${Host}:$WebPort/version.json"; error=$_.Exception.Message}
    }
    return [pscustomobject]@{available=$false; version='unknown'; source="http://${Host}:$WebPort/version.json"}
}

function Test-TrmVersionCompatibility {
    param([string]$Host, [int]$WebPort = 80)
    $localVersion = GetCurrentVersion
    $hostVersion = Get-TrmHostVersion -Host $Host -WebPort $WebPort
    $compatible = $true
    $message = 'Host version unavailable; continuing with local compatibility assumption.'
    if ($hostVersion.available) {
        $compatible = ($hostVersion.version -eq $localVersion)
        $message = if ($compatible) { "Version compatible: $localVersion" } else { "Version mismatch: local=$localVersion host=$($hostVersion.version)" }
    }
    return [pscustomobject]@{
        compatible = $compatible
        localVersion = $localVersion
        hostVersion = $hostVersion.version
        hostVersionAvailable = $hostVersion.available
        message = $message
        source = $hostVersion.source
    }
}

function New-TrmNetworkDiagnosticReport {
    param(
        [string]$Mode,
        [string]$Host = '',
        [int]$Port = 7172,
        [int]$WebPort = 80
    )
    $localIp = Get-TrmLocalIPv4Address
    $publicIp = Get-TrmPublicIPAddress
    $serverPort = Get-TrmPortUsage -Port $Port
    $webPortUsage = Get-TrmPortUsage -Port $WebPort
    $targetReachable = $false
    if (-not [string]::IsNullOrWhiteSpace($Host)) {
        $targetReachable = Test-TrmAssistedHostConnection -Host $Host -Port $Port
    } elseif ($Mode -eq 'host') {
        $targetReachable = Test-TrmAssistedHostConnection -Host '127.0.0.1' -Port $Port
    }
    $currentVersion = GetCurrentVersion
    $connectionMode = if ($Mode -eq 'host') { 'host-local' } elseif ($Mode -eq 'join') { 'remote' } else { $Mode }
    $version = if (-not [string]::IsNullOrWhiteSpace($Host)) {
        Test-TrmVersionCompatibility -Host $Host -WebPort $WebPort
    } else {
        [pscustomobject]@{
            compatible = $true
            localVersion = $currentVersion
            hostVersion = $currentVersion
            hostVersionAvailable = $true
            message = "version=$currentVersion"
            source = 'version.json'
        }
    }

    $warnings = @()
    if (-not $serverPort.inUse) { $warnings += "Porta do servidor $Port nao esta aberta localmente." }
    if ($Mode -eq 'join' -and -not $targetReachable) { $warnings += "Host inacessivel em ${Host}:$Port." }
    if ($Mode -eq 'host' -and $publicIp -eq 'indisponivel') { $warnings += 'Internet indisponivel ou IP publico nao detectado.' }
    if ($Mode -eq 'host' -and $localIp -ne '127.0.0.1' -and $publicIp -ne 'indisponivel') { $warnings += 'Conexao externa nao confirmada; firewall, NAT ou CGNAT podem bloquear acessos pela internet.' }
    if ($webPortUsage.inUse -and $Mode -eq 'host') { $warnings += "Porta web $WebPort esta em uso; se nao for o endpoint do Launcher, login/criacao podem falhar." }
    if (-not $version.compatible) { $warnings += $version.message }

    $path = Join-Path (Get-TrmOnlineDiagnosticDirectory) ('online-diagnostic-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
    $report = [pscustomobject]@{
        generatedAt = (Get-Date).ToString('s')
        mode = $Mode
        connectionMode = $connectionMode
        currentVersion = $currentVersion
        host = $Host
        port = $Port
        webPort = $WebPort
        localIp = $localIp
        publicIp = $publicIp
        serverPort = $serverPort
        webPortUsage = $webPortUsage
        targetReachable = $targetReachable
        version = $version
        warnings = $warnings
        status = if ($warnings.Count -eq 0) { 'passed' } else { 'warning' }
        reportPath = $path
    }
    Save-TrmJsonFile -Path $path -Value $report
    return $report
}

function Get-TrmOnlineStatePath {
    $dir = Join-Path (Get-TrmRoot) 'UserData\Online'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return (Join-Path $dir 'host-assisted.json')
}

function Get-TrmOnlineState {
    $default = [pscustomobject]@{
        lastHost = '127.0.0.1'
        lastPort = 7172
        lastWorld = ''
        lastConnectedAt = ''
        history = @()
        recentWorlds = @()
    }
    return (Read-TrmJsonFile -Path (Get-TrmOnlineStatePath) -Default $default)
}

function Save-TrmOnlineState {
    param([string]$Host, [int]$Port, [string]$WorldName = '', [string]$Version = '')
    $state = Get-TrmOnlineState
    $history = @()
    if ($state.PSObject.Properties.Name -contains 'history') { $history = @($state.history) }
    $entry = "$Host`:$Port"
    $history = @($entry) + @($history | Where-Object { $_ -ne $entry })
    $history = @($history | Select-Object -First 5)
    if ([string]::IsNullOrWhiteSpace($WorldName)) { $WorldName = $Host }
    if ([string]::IsNullOrWhiteSpace($Version)) { $Version = GetCurrentVersion }
    $recentWorlds = @()
    if ($state.PSObject.Properties.Name -contains 'recentWorlds') { $recentWorlds = @($state.recentWorlds) }
    $recentWorlds = @([pscustomobject]@{
        worldName = $WorldName
        host = $Host
        port = $Port
        version = $Version
        lastConnectedAt = (Get-Date).ToString('s')
    }) + @($recentWorlds | Where-Object { -not (($_.host -eq $Host) -and ([int]$_.port -eq $Port)) })
    $recentWorlds = @($recentWorlds | Select-Object -First 8)
    $state = [pscustomobject]@{
        lastHost = $Host
        lastPort = $Port
        lastWorld = $WorldName
        lastConnectedAt = (Get-Date).ToString('s')
        history = $history
        recentWorlds = $recentWorlds
        updatedAt = (Get-Date).ToString('s')
    }
    Save-TrmJsonFile -Path (Get-TrmOnlineStatePath) -Value $state
    return $state
}

function Get-TrmRuntimeConfigResolved {
    $root = Get-TrmRoot
    $config = Get-TrmConfig
    $serverExe = [string]$config.serverExe
    $clientExe = [string]$config.clientExe
    $serverWorkingDirectory = [string]$config.serverWorkingDirectory
    $clientWorkingDirectory = [string]$config.clientWorkingDirectory
    if (-not [System.IO.Path]::IsPathRooted($serverExe)) { $serverExe = Join-Path $root $serverExe }
    if (-not [System.IO.Path]::IsPathRooted($clientExe)) { $clientExe = Join-Path $root $clientExe }
    if (-not [System.IO.Path]::IsPathRooted($serverWorkingDirectory)) { $serverWorkingDirectory = Join-Path $root $serverWorkingDirectory }
    if (-not [System.IO.Path]::IsPathRooted($clientWorkingDirectory)) { $clientWorkingDirectory = Join-Path $root $clientWorkingDirectory }
    return [pscustomobject]@{
        config = $config
        serverExe = $serverExe
        clientExe = $clientExe
        serverWorkingDirectory = $serverWorkingDirectory
        clientWorkingDirectory = $clientWorkingDirectory
    }
}

function Ensure-TrmLocalServerStarted {
    param([object]$Resolved, [scriptblock]$ProgressCallback)
    Ensure-TrmDatabaseServer -Config $Resolved.config -ProgressCallback $ProgressCallback
    $serverPortsOpen = Wait-TrmServerPorts -Ports @($Resolved.config.serverPorts) -TimeoutSeconds 3
    if (-not $serverPortsOpen) {
        $serverRunning = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $Resolved.serverExe }
        if (-not $serverRunning) {
            if ($ProgressCallback) { & $ProgressCallback 'Iniciando servidor local...' 0 0 0 }
            Start-Process -FilePath $Resolved.serverExe -WorkingDirectory $Resolved.serverWorkingDirectory -WindowStyle Minimized | Out-Null
        }
    }
    if (-not (Wait-TrmServerPorts -Ports @($Resolved.config.serverPorts) -TimeoutSeconds ([int]$Resolved.config.serverStartupTimeoutSeconds))) {
        $ports = (@($Resolved.config.serverPorts) -join ', ')
        throw "Connection refused: o Crystal Server nao abriu as portas esperadas ($ports)."
    }
}

function Start-TrmHostedWorld {
    param([scriptblock]$ProgressCallback)
    Ensure-TrmProjectStructure
    $resolved = Get-TrmRuntimeConfigResolved
    Ensure-TrmPlayerPackage -Config $resolved.config -ServerExe $resolved.serverExe -ClientExe $resolved.clientExe -ProgressCallback $ProgressCallback
    Ensure-TrmLocalServerStarted -Resolved $resolved -ProgressCallback $ProgressCallback
    $localIp = Get-TrmLocalIPv4Address
    if (Test-TrmLoopbackHost -Host $localIp) {
        throw 'Nao foi encontrado um IP LAN valido. O convite remoto nao sera gerado com localhost.'
    }
    $publicIp = Get-TrmPublicIPAddress
    $port = [int](@($resolved.config.serverPorts)[1])
    $worldName = Get-TrmWorldName
    $version = GetCurrentVersion
    Ensure-TrmPortableWebEndpointMode -Config $resolved.config -ProgressCallback $ProgressCallback -BindAddress '0.0.0.0' -WorldAddress $localIp -GamePort $port
    $diagnostic = New-TrmNetworkDiagnosticReport -Mode 'host' -Port $port -WebPort ([int]$resolved.config.webServerPort)
    $players = Get-TrmConnectedPlayerCount -Port $port
    $invite = New-TrmWorldInvite -WorldName $worldName -Host $localIp -PublicHost $publicIp -Port $port -Version $version -Mode remote
    return [pscustomobject]@{
        status = 'online'
        worldName = $worldName
        version = $version
        playersOnline = $players
        localIp = $localIp
        publicIp = $publicIp
        port = $port
        webPort = [int]$resolved.config.webServerPort
        connection = "$localIp`:$port"
        invite = $invite
        diagnostic = $diagnostic
        note = 'LAN tende a funcionar diretamente. Internet pode exigir port forwarding/firewall liberado.'
    }
}

function HostWorld {
    param([scriptblock]$ProgressCallback)
    return (Start-TrmHostedWorld -ProgressCallback $ProgressCallback)
}

function Stop-TrmHostedWorld {
    $resolved = Get-TrmRuntimeConfigResolved
    $stopped = 0
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $resolved.serverExe } | ForEach-Object {
        Stop-Process -Id $_.Id -Force
        $stopped++
    }
    return [pscustomobject]@{stopped=$stopped; databasePreserved=$true; offlineDataPreserved=$true}
}

function Test-TrmAssistedHostConnection {
    param([string]$Host, [int]$Port)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($Host, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(2000, $false)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch {
        if ((Test-TrmHostIsLocalMachine -Host $Host) -and $Host -ne '127.0.0.1') {
            return (Test-TrmAssistedHostConnection -Host '127.0.0.1' -Port $Port)
        }
        return $false
    } finally {
        $client.Close()
    }
}

function Start-TrmClientForWorld {
    param(
        [ValidateSet('own-hosted','remote')][string]$Mode,
        [string]$Host,
        [string]$ClientWorldAddress,
        [int]$Port = 7172,
        [string]$WorldName = '',
        [string]$ExpectedVersion = '',
        [string]$RawInvite = '',
        [scriptblock]$ProgressCallback
    )
    if ([string]::IsNullOrWhiteSpace($Host)) { throw 'Informe o IP ou endereco do host.' }
    if ([string]::IsNullOrWhiteSpace($ClientWorldAddress)) { throw 'Endereco do mundo nao definido.' }
    $resolved = Get-TrmRuntimeConfigResolved
    Ensure-TrmProjectStructure
    Ensure-TrmPlayerPackage -Config $resolved.config -ServerExe $resolved.serverExe -ClientExe $resolved.clientExe -ProgressCallback $ProgressCallback
    $webPort = [int]$resolved.config.webServerPort
    $configDescription = ("portable-web-endpoint bind=127.0.0.1 world={0}:{1}" -f $ClientWorldAddress, $Port)
    $preflightMode = if ($Mode -eq 'own-hosted') { 'host-local' } else { 'remote' }
    $preflight = New-TrmConnectionTestReport -Mode $preflightMode -RawInvite $RawInvite -Host $Host -Port $Port -WebPort $webPort -WorldName $WorldName -ExpectedVersion $ExpectedVersion -ClientWorldAddress $ClientWorldAddress -ClientExe $resolved.clientExe -ClientWorkingDirectory $resolved.clientWorkingDirectory -ConfigDescription $configDescription -Phase 'preflight'
    if ($Mode -eq 'remote' -and $preflight.isLoopbackHost) {
        throw (Format-TrmConnectionFailure $preflight)
    }
    if (-not $preflight.tcpTest.succeeded) {
        throw (Format-TrmConnectionFailure $preflight)
    }
    if (-not $preflight.loginServer.responded) {
        throw (Format-TrmConnectionFailure $preflight)
    }
    $diagnostic = New-TrmNetworkDiagnosticReport -Mode 'join' -Host $Host -Port $Port -WebPort ([int]$resolved.config.webServerPort)
    if (-not $diagnostic.targetReachable) {
        throw "Host inacessivel em ${Host}:$Port. Rode Testar Conexao e confira IP, porta, firewall e NAT."
    }
    if (-not $diagnostic.version.compatible) {
        throw $diagnostic.version.message
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedVersion) -and $diagnostic.version.hostVersionAvailable -and $diagnostic.version.hostVersion -ne $ExpectedVersion) {
        throw "Versao incompativel: convite=$ExpectedVersion host=$($diagnostic.version.hostVersion)."
    }
    Save-TrmOnlineState -Host $Host -Port $Port -WorldName $WorldName -Version $diagnostic.version.localVersion | Out-Null
    Ensure-TrmPortableWebEndpointMode -Config $resolved.config -ProgressCallback $ProgressCallback -BindAddress '127.0.0.1' -WorldAddress $ClientWorldAddress -GamePort $Port
    if ($ProgressCallback) { & $ProgressCallback "Abrindo cliente para $ClientWorldAddress`:$Port..." 100 0 0 }
    Remove-Item Env:\QT_QUICK_BACKEND -ErrorAction SilentlyContinue
    Remove-Item Env:\QT_OPENGL -ErrorAction SilentlyContinue
    Remove-Item Env:\QSG_RHI_BACKEND -ErrorAction SilentlyContinue
    $env:QSG_RENDER_LOOP = 'basic'
    $env:TRM_ONLINE_MODE = $Mode
    $env:TRM_ONLINE_HOST = $ClientWorldAddress
    $env:TRM_ONLINE_PORT = [string]$Port
    Write-TrmClientLaunchLog -Mode $Mode -Host $Host -Port $Port -ClientWorldAddress $ClientWorldAddress -ConfigDescription $configDescription -ClientExe $resolved.clientExe -ClientWorkingDirectory $resolved.clientWorkingDirectory
    $connectionReport = New-TrmConnectionTestReport -Mode $preflightMode -RawInvite $RawInvite -Host $Host -Port $Port -WebPort $webPort -WorldName $WorldName -ExpectedVersion $ExpectedVersion -ClientWorldAddress $ClientWorldAddress -ClientExe $resolved.clientExe -ClientWorkingDirectory $resolved.clientWorkingDirectory -ConfigDescription $configDescription -Phase 'client-launch'
    Start-Process -FilePath $resolved.clientExe -WorkingDirectory $resolved.clientWorkingDirectory | Out-Null
    return [pscustomobject]@{mode=$Mode; host=$Host; clientWorldAddress=$ClientWorldAddress; port=$Port; worldName=$WorldName; clientStarted=$true; statePath=(Get-TrmOnlineStatePath); diagnostic=$diagnostic; connectionReport=$connectionReport}
}

function JoinOwnHostedWorld {
    param([int]$Port = 7172, [string]$WorldName = '', [scriptblock]$ProgressCallback)
    $resolved = Get-TrmRuntimeConfigResolved
    Ensure-TrmLocalServerStarted -Resolved $resolved -ProgressCallback $ProgressCallback
    return (Start-TrmClientForWorld -Mode 'own-hosted' -Host '127.0.0.1' -ClientWorldAddress '127.0.0.1' -Port $Port -WorldName $WorldName -ProgressCallback $ProgressCallback)
}

function JoinRemoteWorld {
    param([string]$Host, [int]$Port = 7172, [string]$WorldName = '', [string]$ExpectedVersion = '', [string]$RawInvite = '', [scriptblock]$ProgressCallback)
    if (-not [string]::IsNullOrWhiteSpace($RawInvite)) {
        $parsedInvite = ConvertFrom-TrmWorldInvite -InviteText $RawInvite
        if (-not $parsedInvite.valid) { throw "Convite remoto invalido: $($parsedInvite.error)" }
        $Host = [string]$parsedInvite.host
        $Port = [int]$parsedInvite.port
        $WorldName = [string]$parsedInvite.worldName
        $ExpectedVersion = [string]$parsedInvite.version
    }
    if (Test-TrmLoopbackHost -Host $Host) {
        $resolved = Get-TrmRuntimeConfigResolved
        $report = New-TrmConnectionTestReport -Mode 'remote' -RawInvite $RawInvite -Host $Host -Port $Port -WebPort ([int]$resolved.config.webServerPort) -WorldName $WorldName -ExpectedVersion $ExpectedVersion -ClientWorldAddress $Host -ClientExe $resolved.clientExe -ClientWorkingDirectory $resolved.clientWorkingDirectory -ConfigDescription ("blocked remote loopback world={0}:{1}" -f $Host, $Port) -Phase 'blocked-loopback'
        throw (Format-TrmConnectionFailure $report)
    }
    if (Test-TrmHostIsLocalMachine -Host $Host) {
        throw "Use Entrar no Meu Mundo para conectar ao proprio servidor local. Entrar em Mundo preserva o IP do convite e nao troca por 127.0.0.1."
    }
    return (Start-TrmClientForWorld -Mode 'remote' -Host $Host -ClientWorldAddress $Host -Port $Port -WorldName $WorldName -ExpectedVersion $ExpectedVersion -RawInvite $RawInvite -ProgressCallback $ProgressCallback)
}

function Start-TrmOnlineClient {
    param([string]$Host, [int]$Port = 7172, [string]$WorldName = '', [string]$ExpectedVersion = '', [scriptblock]$ProgressCallback)
    return (JoinRemoteWorld -Host $Host -Port $Port -WorldName $WorldName -ExpectedVersion $ExpectedVersion -ProgressCallback $ProgressCallback)
}

function StartOffline {
    param([scriptblock]$ProgressCallback)
    Start-TrmGame -ProgressCallback $ProgressCallback
}

function Ensure-TrmPlayerPackage {
    param(
        [object]$Config,
        [string]$ServerExe,
        [string]$ClientExe,
        [scriptblock]$ProgressCallback
    )
    $databaseExe = Resolve-TrmRuntimePath ([string]$Config.databaseExe)
    if ((Test-Path $ServerExe) -and (Test-Path $ClientExe) -and (Test-Path $databaseExe)) { return }

    $packageUrl = ''
    if ($Config.PSObject.Properties.Name -contains 'playerPackageUrl') { $packageUrl = [string]$Config.playerPackageUrl }
    if ([string]::IsNullOrWhiteSpace($packageUrl)) {
        throw "Server/client files are missing and playerPackageUrl is not configured. Missing server=$ServerExe client=$ClientExe"
    }

    $root = Get-TrmRoot
    $tmpRoot = Join-Path $root 'tmp\player-package-download'
    $zipPath = Join-Path $tmpRoot 'TibiaRemastered-Player.zip'
    $extractPath = Join-Path $tmpRoot 'extract'
    if (-not (Test-Path $tmpRoot)) { New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null }
    if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
    if (Test-Path $extractPath) { Remove-Item -Path $extractPath -Recurse -Force }

    if ($ProgressCallback) { & $ProgressCallback 'Baixando pacote completo do jogo...' 0 0 0 }
    Write-TrmLog "Downloading player package: $packageUrl"
    $parts = @()
    if ($Config.PSObject.Properties.Name -contains 'playerPackageParts') { $parts = @($Config.playerPackageParts) }
    if ($parts.Count -gt 0) {
        Save-TrmPackagePartsDownload -Parts $parts -Destination $zipPath -WorkDirectory $tmpRoot -ProgressCallback $ProgressCallback
    } else {
        Save-TrmLargeDownload -Url $packageUrl -Destination $zipPath -ProgressCallback $ProgressCallback
    }

    if ($Config.PSObject.Properties.Name -contains 'playerPackageSha256' -and -not [string]::IsNullOrWhiteSpace([string]$Config.playerPackageSha256)) {
        if ($ProgressCallback) { & $ProgressCallback 'Validando pacote completo...' 50 0 0 }
        $actual = Get-TrmSha256 $zipPath
        $expected = ([string]$Config.playerPackageSha256).ToLowerInvariant()
        if ($actual -ne $expected) {
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            throw "Player package hash mismatch. expected=$expected actual=$actual"
        }
    }

    if ($ProgressCallback) { & $ProgressCallback 'Extraindo pacote completo...' 75 0 0 }
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    foreach ($folder in @('Client','Server','Database')) {
        $source = Join-Path $extractPath $folder
        $destFolder = if ($folder -eq 'Database') { 'Database_Template' } else { $folder }
        $dest = Join-Path $root $destFolder
        if (-not (Test-Path $source)) { throw "Player package is invalid: missing $folder folder." }
        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
        Copy-Item -Path (Join-Path $source '*') -Destination $dest -Recurse -Force
    }

    if (-not ((Test-Path $ServerExe) -and (Test-Path $ClientExe) -and (Test-Path $databaseExe))) {
        throw "Player package was extracted, but runtime files are still missing. server=$ServerExe client=$ClientExe database=$databaseExe"
    }
    if ($ProgressCallback) { & $ProgressCallback 'Pacote completo instalado.' 100 0 0 }
}

function Save-TrmLargeDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [scriptblock]$ProgressCallback
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (Test-Path $Url) {
        Copy-Item -Path $Url -Destination $Destination -Force
        return
    }
    try {
        $uri = [System.Uri]$Url
        if ($uri.IsFile) {
            Copy-Item -LiteralPath $uri.LocalPath -Destination $Destination -Force
            return
        }
    } catch {
    }
    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if (Test-Path $Destination) { Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue }
            if ($ProgressCallback) { & $ProgressCallback "Baixando pacote completo do jogo... tentativa $attempt/3" 0 0 0 }
            Write-TrmLog "Player package download attempt $attempt via BITS: $Url"
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $Url -Destination $Destination -DisplayName 'Tibia Remastered Player Package' -Description 'Download do pacote completo do jogo' -TransferType Download -ErrorAction Stop
            if (Test-Path $Destination) { return }
            throw 'BITS finished without creating the destination file.'
        } catch {
            $lastError = $_.Exception.Message
            Write-TrmLog "BITS download attempt $attempt failed: $lastError" 'WARN'
            Start-Sleep -Seconds (5 * $attempt)
        }
    }

    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            if (Test-Path $Destination) { Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue }
            if ($ProgressCallback) { & $ProgressCallback "Baixando pacote completo por HTTP... tentativa $attempt/2" 0 0 0 }
            Write-TrmLog "Player package download attempt $attempt via HTTP: $Url"
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 3600
            if (Test-Path $Destination) { return }
            throw 'HTTP download finished without creating the destination file.'
        } catch {
            $lastError = $_.Exception.Message
            Write-TrmLog "HTTP download attempt $attempt failed: $lastError" 'WARN'
            Start-Sleep -Seconds (5 * $attempt)
        }
    }

    throw "Nao foi possivel baixar o pacote completo automaticamente. Tente baixar manualmente: $Url . Erro: $lastError"
}

function Save-TrmPackagePartsDownload {
    param(
        [object[]]$Parts,
        [string]$Destination,
        [string]$WorkDirectory,
        [scriptblock]$ProgressCallback
    )
    if ($Parts.Count -eq 0) { throw 'Player package parts are not configured.' }
    $partDir = Join-Path $WorkDirectory 'parts'
    if (-not (Test-Path $partDir)) { New-Item -ItemType Directory -Force -Path $partDir | Out-Null }

    $index = 0
    foreach ($part in $Parts) {
        $index++
        $partUrl = [string]$part.url
        if ([string]::IsNullOrWhiteSpace($partUrl)) { throw "Player package part $index has no URL." }
        $partName = Split-Path -Leaf ([System.Uri]$partUrl).AbsolutePath
        if ([string]::IsNullOrWhiteSpace($partName)) { $partName = 'part-{0:D3}' -f $index }
        $partPath = Join-Path $partDir $partName
        $expected = ''
        if ($part.PSObject.Properties.Name -contains 'sha256') { $expected = ([string]$part.sha256).ToLowerInvariant() }

        $valid = $false
        if ((Test-Path $partPath) -and -not [string]::IsNullOrWhiteSpace($expected)) {
            $valid = ((Get-TrmSha256 $partPath) -eq $expected)
        }
        if (-not $valid) {
            if ($ProgressCallback) { & $ProgressCallback ("Baixando pacote parte {0}/{1}" -f $index, $Parts.Count) (($index - 1) / $Parts.Count * 70) 0 0 }
            Save-TrmLargeDownload -Url $partUrl -Destination $partPath -ProgressCallback $null
        }
        if (-not [string]::IsNullOrWhiteSpace($expected)) {
            $actual = Get-TrmSha256 $partPath
            if ($actual -ne $expected) {
                Remove-Item -Path $partPath -Force -ErrorAction SilentlyContinue
                throw "Player package part hash mismatch for part $index. expected=$expected actual=$actual"
            }
        }
    }

    if ($ProgressCallback) { & $ProgressCallback 'Montando pacote completo...' 72 0 0 }
    if (Test-Path $Destination) { Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue }
    $output = [System.IO.File]::Create($Destination)
    try {
        foreach ($part in $Parts) {
            $partUrl = [string]$part.url
            $partName = Split-Path -Leaf ([System.Uri]$partUrl).AbsolutePath
            $partPath = Join-Path $partDir $partName
            $input = [System.IO.File]::OpenRead($partPath)
            try { $input.CopyTo($output) }
            finally { $input.Dispose() }
        }
    } finally {
        $output.Dispose()
    }
}

function Start-TrmGame {
    param([scriptblock]$ProgressCallback)
    Ensure-TrmProjectStructure
    $config = Get-TrmConfig
    $autoUpdateBeforePlay = $false
    if ($config.PSObject.Properties.Name -contains 'autoUpdateBeforePlay') { $autoUpdateBeforePlay = [bool]$config.autoUpdateBeforePlay }
    if ($config.remoteManifestUrl -and $autoUpdateBeforePlay) {
        try {
            $updateReport = Invoke-TrmUpdateOrRepair -ProgressCallback $ProgressCallback
            $launcherUpdated = $false
            foreach ($action in @($updateReport.actions)) {
                $path = ''
                if ($action.PSObject.Properties.Name -contains 'path') { $path = ([string]$action.path -replace '\\','/') }
                $actionName = ''
                if ($action.PSObject.Properties.Name -contains 'action') { $actionName = [string]$action.action }
                if ($actionName -eq 'downloaded' -and ($path -eq 'Launcher/Launcher.ps1' -or $path.StartsWith('Launcher/Modules/', [System.StringComparison]::OrdinalIgnoreCase))) {
                    $launcherUpdated = $true
                    break
                }
            }
            if ($launcherUpdated -and [string]::IsNullOrWhiteSpace($env:TRM_RESTARTED_AFTER_UPDATE)) {
                if ($ProgressCallback) { & $ProgressCallback 'Launcher atualizado. Reiniciando para continuar...' 100 0 0 }
                $launcherPath = Join-Path (Get-TrmRoot) 'Launcher\Launcher.ps1'
                if ($env:TRM_TEST_RESTART_AFTER_UPDATE -eq '1') { throw 'TRM_TEST_RESTART_AFTER_UPDATE: launcher restart requested.' }
                $env:TRM_RESTARTED_AFTER_UPDATE = '1'
                Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $launcherPath, '-Play') -WorkingDirectory (Get-TrmRoot) | Out-Null
                [Environment]::Exit(0)
            }
        } catch {
            Write-TrmLog "Update check failed before play; continuing with local runtime: $($_.Exception.Message)" 'WARN'
            if ($ProgressCallback) { & $ProgressCallback 'Atualizacao indisponivel. Usando runtime local...' 0 0 0 }
        }
    }
    $root = Get-TrmRoot
    $serverExe = [string]$config.serverExe
    $clientExe = [string]$config.clientExe
    $serverWorkingDirectory = [string]$config.serverWorkingDirectory
    $clientWorkingDirectory = [string]$config.clientWorkingDirectory
    if (-not [System.IO.Path]::IsPathRooted($serverExe)) { $serverExe = Join-Path $root $serverExe }
    if (-not [System.IO.Path]::IsPathRooted($clientExe)) { $clientExe = Join-Path $root $clientExe }
    if (-not [System.IO.Path]::IsPathRooted($serverWorkingDirectory)) { $serverWorkingDirectory = Join-Path $root $serverWorkingDirectory }
    if (-not [System.IO.Path]::IsPathRooted($clientWorkingDirectory)) { $clientWorkingDirectory = Join-Path $root $clientWorkingDirectory }
    Ensure-TrmPlayerPackage -Config $config -ServerExe $serverExe -ClientExe $clientExe -ProgressCallback $ProgressCallback
    if (-not (Test-Path $serverExe)) { throw "Server exe not found: $serverExe" }
    if (-not (Test-Path $clientExe)) { throw "Client exe not found: $clientExe" }

    Ensure-TrmDatabaseServer -Config $config -ProgressCallback $ProgressCallback
    Ensure-TrmWebEndpoint -Config $config -ProgressCallback $ProgressCallback

    $serverPortsOpen = Wait-TrmServerPorts -Ports @($config.serverPorts) -TimeoutSeconds 1
    if (-not $serverPortsOpen) {
        $serverRunning = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $serverExe }
        if (-not $serverRunning) {
            if ($ProgressCallback) { & $ProgressCallback 'Iniciando servidor local...' 0 0 0 }
            Start-Process -FilePath $serverExe -WorkingDirectory $serverWorkingDirectory -WindowStyle Minimized | Out-Null
        }
    }
    if (-not (Wait-TrmServerPorts -Ports @($config.serverPorts) -TimeoutSeconds ([int]$config.serverStartupTimeoutSeconds))) {
        $ports = (@($config.serverPorts) -join ', ')
        throw "Connection refused: o Crystal Server nao abriu as portas esperadas ($ports). Abra pelo Start Launcher.bat e confira se o banco de dados iniciou sem erro."
    }
    if ($ProgressCallback) { & $ProgressCallback 'Iniciando cliente...' 100 0 0 }
    Remove-Item Env:\QT_QUICK_BACKEND -ErrorAction SilentlyContinue
    Remove-Item Env:\QT_OPENGL -ErrorAction SilentlyContinue
    Remove-Item Env:\QSG_RHI_BACKEND -ErrorAction SilentlyContinue
    $env:QSG_RENDER_LOOP = 'basic'
    Start-Process -FilePath $clientExe -WorkingDirectory $clientWorkingDirectory | Out-Null
}

Export-ModuleMember -Function *-Trm*,GetCurrentVersion,StartOffline,HostWorld,JoinOwnHostedWorld,JoinRemoteWorld
