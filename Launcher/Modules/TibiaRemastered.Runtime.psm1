Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

function Test-TrmLocalPortListening {
    param([int]$Port)
    $open = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $open)
}

function Wait-TrmServerPorts {
    param([int[]]$Ports, [int]$TimeoutSeconds)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $allOpen = $true
        foreach ($port in $Ports) {
            if (-not (Test-TrmLocalPortListening -Port $port)) { $allOpen = $false; break }
        }
        if ($allOpen) { return $true }
        Start-Sleep -Seconds 2
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

function Ensure-TrmWebEndpoint {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = [int]$Config.webServerPort
    if (Test-TrmLocalPortListening -Port $port) { return }
    $webServerExe = [string]$Config.webServerExe
    if ([string]::IsNullOrWhiteSpace($webServerExe) -or -not (Test-Path $webServerExe)) {
        Write-TrmLog "Web server exe not found or not configured: $webServerExe" 'WARN'
        return
    }
    if ($ProgressCallback) { & $ProgressCallback 'Iniciando endpoint web local...' 0 0 0 }
    $args = [string]$Config.webServerArguments
    if ([string]::IsNullOrWhiteSpace($args)) {
        Start-Process -FilePath $webServerExe -WorkingDirectory ([string]$Config.webServerWorkingDirectory) -WindowStyle Hidden | Out-Null
    } else {
        Start-Process -FilePath $webServerExe -ArgumentList $args -WorkingDirectory ([string]$Config.webServerWorkingDirectory) -WindowStyle Hidden | Out-Null
    }
    $deadline = (Get-Date).AddSeconds([int]$Config.webServerStartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-TrmLocalPortListening -Port $port) { return }
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
        throw 'Server did not open expected ports before timeout.'
    }
    if ($ProgressCallback) { & $ProgressCallback 'Iniciando cliente...' 100 0 0 }
    Remove-Item Env:\QT_QUICK_BACKEND -ErrorAction SilentlyContinue
    Remove-Item Env:\QT_OPENGL -ErrorAction SilentlyContinue
    Remove-Item Env:\QSG_RHI_BACKEND -ErrorAction SilentlyContinue
    $env:QSG_RENDER_LOOP = 'basic'
    Start-Process -FilePath $clientExe -WorkingDirectory $clientWorkingDirectory | Out-Null
}

Export-ModuleMember -Function *-Trm*
