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
    [string]$Database = 'otserv'
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
        playdata=[pscustomobject]@{worlds=@([pscustomobject]@{id=0; name='FazendoTibia'; externaladdress='127.0.0.1'; externaladdressprotected='127.0.0.1'; externaladdressunprotected='127.0.0.1'; externalport=7172; externalportprotected=7172; externalportunprotected=7172; previewstate=0; location='BRA'; anticheatprotection=$false; pvptype=0; istournamentworld=$false; restrictedstore=$false; currenttournamentphase=2}); characters=$characters}
    })
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse('127.0.0.1'), $HttpPort)
$listener.Start()
Write-EndpointLog "Portable web endpoint listening on 127.0.0.1:$HttpPort"
while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $request = Get-Request $stream
        if ($null -eq $request) { continue }
        $payload = if ([string]::IsNullOrWhiteSpace($request.Body)) { [pscustomobject]@{} } else { $request.Body | ConvertFrom-Json }
        if ($request.Path -like '/clientcreateaccount.php*') { Handle-ClientCreate $stream $payload }
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
    param([object]$Config, [scriptblock]$ProgressCallback)
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
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath,'-Root',$root,'-MysqlExe',$mysqlExe,'-DbPort',[string]$Config.databasePort,'-HttpPort',[string]$port,'-Database',$databaseName) -WorkingDirectory $root -WindowStyle Hidden | Out-Null
}

function Ensure-TrmWebEndpoint {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = [int]$Config.webServerPort
    if (Test-TrmWebEndpointHealthy -Port $port) { return }
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
    Start-TrmPortableWebEndpoint -Config $Config -ProgressCallback $ProgressCallback
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
        $dest = Join-Path $root $folder
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
    if ($config.remoteManifestUrl) {
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

Export-ModuleMember -Function *-Trm*
