$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path $repo 'tmp\account-character-list-tests'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force -Path $work | Out-Null
$env:TRM_ROOT = $work
Set-Content -Path (Join-Path $work 'version.json') -Value '{"name":"TibiaRemastered","version":"0.1.25-test","channel":"dev","minimumLauncherVersion":"0.1.0"}' -Encoding UTF8
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
    param([int]$Port, [int]$TimeoutSeconds = 20)
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

function Invoke-TestMysql {
    param(
        [string]$MysqlExe,
        [int]$Port,
        [string]$Database,
        [string]$Sql
    )
    $args = @('-h','127.0.0.1','-P',[string]$Port,'-u','root','--batch','--raw','--skip-column-names')
    if (-not [string]::IsNullOrWhiteSpace($Database)) { $args += $Database }
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
    return @($stdout -split "`r?`n" | Where-Object { $_ -ne '' })
}

$mysqlBin = Join-Path $repo 'Database_Template\mysql\bin'
$mysqlExe = Join-Path $mysqlBin 'mysql.exe'
$schema = Join-Path $repo 'Database_Template\schema.sql'
Assert-True (Test-Path $mysqlExe) 'mysql.exe nao encontrado.'
Assert-True (Test-Path $schema) 'schema.sql nao encontrado.'

$dbPort = 3306
$httpPort = Get-FreeTcpPort
$endpointScript = Join-Path $work 'portable-web-endpoint.ps1'
$databaseName = 'otserv_test_account_chars'
$endpoint = $null

try {
    Assert-True (Wait-Port -Port $dbPort -TimeoutSeconds 10) 'MariaDB local existente nao esta acessivel em 127.0.0.1:3306.'

    Invoke-TestMysql -MysqlExe $mysqlExe -Port $dbPort -Database '' -Sql "DROP DATABASE IF EXISTS ``$databaseName``; CREATE DATABASE ``$databaseName`` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" | Out-Null
    Invoke-TestMysql -MysqlExe $mysqlExe -Port $dbPort -Database $databaseName -Sql ("SOURCE {0};" -f ($schema -replace '\\','/')) | Out-Null

    Write-TrmPortableWebEndpointScript -Path $endpointScript
    $endpoint = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$endpointScript,'-Root',$work,'-MysqlExe',$mysqlExe,'-DbPort',[string]$dbPort,'-HttpPort',[string]$httpPort,'-Database',$databaseName,'-BindAddress','127.0.0.1','-WorldAddress','127.0.0.1','-GamePort','7172') -WorkingDirectory $work -WindowStyle Hidden -PassThru
    Assert-True (Wait-Port -Port $httpPort -TimeoutSeconds 20) 'Endpoint local temporario nao abriu.'

    $password = 'StrongPass123'
    $email = 'multi-test@example.com'
    foreach ($name in @('Alpha Test','Beta Test','Gamma Test')) {
        $body = @{type='CreateAccountAndCharacter'; EMail=$email; Password=$password; CharacterName=$name} | ConvertTo-Json -Compress
        $created = Invoke-RestMethod -Uri "http://127.0.0.1:$httpPort/clientcreateaccount.php" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10
        Assert-True ([bool]$created.Success) "Criacao falhou para $name."
    }

    $loginByEmailBody = @{type='login'; email=$email; password=$password} | ConvertTo-Json -Compress
    $loginByEmail = Invoke-RestMethod -Uri "http://127.0.0.1:$httpPort/login.php" -Method Post -ContentType 'application/json' -Body $loginByEmailBody -TimeoutSec 10
    $charactersByEmail = @($loginByEmail.playdata.characters)
    Assert-True ($charactersByEmail.Count -eq 3) "Login por email deveria listar 3 personagens; listou $($charactersByEmail.Count)."

    $dbAccountName = [string](@(Invoke-TestMysql -MysqlExe $mysqlExe -Port $dbPort -Database $databaseName -Sql ("SELECT name FROM accounts WHERE LOWER(email) = '{0}' LIMIT 1;" -f $email))[0])
    $loginByAccountBody = @{type='login'; email=''; accountname=$dbAccountName.ToUpperInvariant(); password=$password} | ConvertTo-Json -Compress
    $loginByAccount = Invoke-RestMethod -Uri "http://127.0.0.1:$httpPort/login.php" -Method Post -ContentType 'application/json' -Body $loginByAccountBody -TimeoutSec 10
    $charactersByAccount = @($loginByAccount.playdata.characters)
    Assert-True ($charactersByAccount.Count -eq 3) "Login por accountname deveria listar 3 personagens; listou $($charactersByAccount.Count)."

    $counts = ([string](@(Invoke-TestMysql -MysqlExe $mysqlExe -Port $dbPort -Database $databaseName -Sql ("SELECT COUNT(*), (SELECT COUNT(*) FROM players WHERE account_id = accounts.id) FROM accounts WHERE LOWER(email) = '{0}' GROUP BY id;" -f $email))[0])).Split("`t")
    Assert-True ([int]$counts[0] -eq 1) 'Mais de uma conta foi criada para o mesmo email.'
    Assert-True ([int]$counts[1] -eq 3) 'Os tres personagens nao ficaram no mesmo account_id.'

    [pscustomobject]@{
        status = 'passed'
        database = $databaseName
        accountName = $dbAccountName
        accountCount = [int]$counts[0]
        characterCount = [int]$counts[1]
        characters = @($charactersByEmail | ForEach-Object { $_.name })
    } | ConvertTo-Json -Depth 6
} finally {
    if ($endpoint -and -not $endpoint.HasExited) { Stop-Process -Id $endpoint.Id -Force -ErrorAction SilentlyContinue }
    try { Invoke-TestMysql -MysqlExe $mysqlExe -Port $dbPort -Database '' -Sql "DROP DATABASE IF EXISTS ``$databaseName``;" | Out-Null } catch {}
}
