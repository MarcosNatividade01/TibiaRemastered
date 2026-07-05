$ErrorActionPreference = 'Stop'

$serverRoot = 'C:\otserv'
$serverExe = Join-Path $serverRoot 'crystalserver.exe'
$schemaSql = Join-Path $serverRoot 'schema.sql'
$mysqlExe = 'C:\xampp\mysql\bin\mysqld.exe'
$mysqlClient = 'C:\xampp\mysql\bin\mysql.exe'
$mysqlDefaults = 'C:\xampp\mysql\bin\my.ini'
$apacheExe = 'C:\xampp\apache\bin\httpd.exe'
$publicAddress = '127.0.0.1'

function Test-Port {
    param([string]$HostName, [int]$Port, [int]$TimeoutMs = 800)

    $socket = [System.Net.Sockets.TcpClient]::new()
    try {
        $attempt = $socket.ConnectAsync($HostName, $Port)
        return ($attempt.Wait($TimeoutMs) -and $socket.Connected)
    }
    catch {
        return $false
    }
    finally {
        $socket.Dispose()
    }
}

function Wait-Port {
    param([string]$HostName, [int]$Port, [int]$TimeoutSeconds)

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        if (Test-Port -HostName $HostName -Port $Port -TimeoutMs 1000) {
            return
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    throw "A porta $Port nao abriu em $TimeoutSeconds segundos."
}

function Get-ProcessByPath {
    param([string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq $fullPath) } catch { $false }
    }
}

function Start-MySql {
    foreach ($required in @($mysqlExe, $mysqlDefaults, $mysqlClient)) {
        if (-not (Test-Path -LiteralPath $required)) {
            throw "Arquivo do MySQL nao encontrado: $required"
        }
    }

    if (-not (Test-Port -HostName '127.0.0.1' -Port 3306)) {
        Write-Host 'Iniciando MySQL em segundo plano...'
        Start-Process -FilePath $mysqlExe -ArgumentList @("--defaults-file=$mysqlDefaults", '--standalone') -WorkingDirectory 'C:\xampp' -WindowStyle Hidden
    }

    Wait-Port -HostName '127.0.0.1' -Port 3306 -TimeoutSeconds 45
}

function Start-Apache {
    if (-not (Test-Path -LiteralPath $apacheExe)) {
        throw "Apache nao encontrado: $apacheExe"
    }

    if (-not (Test-Port -HostName '127.0.0.1' -Port 80)) {
        Write-Host 'Iniciando endpoint do cliente em segundo plano...'
        Start-Process -FilePath $apacheExe -WorkingDirectory 'C:\xampp' -WindowStyle Hidden
    }

    Wait-Port -HostName '127.0.0.1' -Port 80 -TimeoutSeconds 30
}

function Ensure-Database {
    if (-not (Test-Path -LiteralPath $schemaSql)) {
        throw "Schema do servidor nao encontrado: $schemaSql"
    }

    & $mysqlClient -uroot -e "CREATE DATABASE IF NOT EXISTS otserv CHARACTER SET utf8 COLLATE utf8_general_ci;"
    if ($LASTEXITCODE -ne 0) {
        throw 'Nao foi possivel criar/verificar o banco otserv.'
    }

    $tableCheck = & $mysqlClient -uroot -N -B otserv -e "SHOW TABLES LIKE 'server_config';"
    if ($LASTEXITCODE -ne 0) {
        throw 'Nao foi possivel consultar o banco otserv.'
    }

    if (-not $tableCheck) {
        Write-Host 'Importando schema inicial do servidor...'
        & $mysqlClient -uroot otserv -e "source C:/otserv/schema.sql"
        if ($LASTEXITCODE -ne 0) {
            throw 'Falha ao importar schema.sql.'
        }
    }
}

function Start-CrystalServer {
    foreach ($required in @($serverRoot, $serverExe)) {
        if (-not (Test-Path -LiteralPath $required)) {
            throw "Arquivo do servidor nao encontrado: $required"
        }
    }

    $running = @(Get-ProcessByPath -Path $serverExe)
    if ($running.Count -eq 0) {
        Write-Host 'Iniciando Crystal Server...'
        Start-Process -FilePath $serverExe -WorkingDirectory $serverRoot -WindowStyle Hidden
    }
    elseif ($running.Count -gt 1) {
        Write-Host "Aviso: existem $($running.Count) instancias do Crystal Server. Mantendo a mais antiga."
    }

    Wait-Port -HostName '127.0.0.1' -Port 7171 -TimeoutSeconds 180
    Wait-Port -HostName '127.0.0.1' -Port 7172 -TimeoutSeconds 30
}

function Enable-FirewallRules {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return
    }

    $rules = @(
        @{ Name = 'Tibiafriends HTTP TCP 80'; Port = 80 },
        @{ Name = 'Tibiafriends Login TCP 7171'; Port = 7171 },
        @{ Name = 'Tibiafriends Game TCP 7172'; Port = 7172 }
    )

    foreach ($rule in $rules) {
        & netsh.exe advfirewall firewall delete rule name="$($rule.Name)" | Out-Null
        & netsh.exe advfirewall firewall add rule name="$($rule.Name)" dir=in action=allow protocol=TCP localport=$($rule.Port) profile=private,public | Out-Null
    }
}

try {
    Write-Host 'Ligando Tibiafriends...' -ForegroundColor Cyan
    Enable-FirewallRules
    Start-MySql
    Ensure-Database
    Start-Apache
    Start-CrystalServer

    Write-Host ''
    Write-Host 'SERVIDOR ONLINE' -ForegroundColor Green
    Write-Host 'MySQL: 127.0.0.1:3306'
    Write-Host 'Criacao pelo cliente: http://127.0.0.1/clientcreateaccount.php'
    Write-Host 'Login: 127.0.0.1:7171'
    Write-Host 'Jogo: 127.0.0.1:7172'
}
catch {
    Write-Host ''
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Pressione Enter para fechar'
    exit 1
}
