Set-StrictMode -Version 2.0

function Get-TrmRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:TRM_ROOT)) {
        return $env:TRM_ROOT
    }
    $moduleDir = Split-Path -Parent $PSScriptRoot
    return (Split-Path -Parent $moduleDir)
}

function Get-TrmLogFile {
    $root = Get-TrmRoot
    return (Join-Path $root ('Logs\launcher_' + (Get-Date -Format 'yyyy-MM-dd') + '.log'))
}

function Write-TrmLog {
    param([string]$Message, [string]$Level = 'INFO')
    $logFile = Get-TrmLogFile
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function Ensure-TrmProjectStructure {
    $root = Get-TrmRoot
    $dirs = @(
        'Launcher','Launcher\Modules','Client','Server','Assets','Data','Config',
        'Database_Template','DatabaseTemplate','UserData\Database','UserData\Config',
        'UserData\Saves','Logs','Backup','Docs','Scripts','Tools','Reports'
    )
    foreach ($dir in $dirs) {
        $path = Join-Path $root $dir
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    }
}

function Read-TrmJsonFile {
    param([string]$Path, [object]$Default = $null)
    if (-not (Test-Path $Path)) { return $Default }
    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    return ($raw.TrimStart([char]0xFEFF) | ConvertFrom-Json)
}

function Save-TrmJsonFile {
    param([string]$Path, [object]$Value)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Value | ConvertTo-Json -Depth 16 | Set-Content -Path $Path -Encoding UTF8
}

function Get-TrmDefaultConfig {
    return [pscustomobject]@{
        remoteVersionUrl = 'https://raw.githubusercontent.com/MarcosNatividade01/TibiaRemastered/main/version.json'
        remoteManifestUrl = 'https://raw.githubusercontent.com/MarcosNatividade01/TibiaRemastered/main/manifest.json'
        serverExe = 'Server\crystalserver.exe'
        serverWorkingDirectory = 'Server'
        serverPorts = @(7171, 7172)
        serverStartupTimeoutSeconds = 300
        databaseExe = 'Database\mysql\bin\mysqld.exe'
        databaseArguments = ''
        databaseWorkingDirectory = 'Database\mysql\bin'
        databasePort = 3306
        databaseStartupTimeoutSeconds = 60
        databaseName = 'otserv'
        databaseSeedSql = 'Server\schema.sql'
        webServerExe = 'C:\xampp\apache\bin\httpd.exe'
        webServerArguments = ''
        webServerWorkingDirectory = 'C:\xampp\apache\bin'
        webServerPort = 80
        webServerStartupTimeoutSeconds = 30
        clientExe = 'Client\bin\client-local.exe'
        clientWorkingDirectory = 'Client'
        preserve = @('UserData/**','Logs/**','Backup/**','Backups/**','Saves/**')
        requiredRuntimeFiles = @('Launcher/Launcher.ps1','manifest.json','version.json')
        lastUpdateReport = 'Reports\last-update.json'
        playerPackageUrl = 'https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.3/TibiaRemastered-Player.zip'
        playerPackageSha256 = '2a7a4993fb1659ce8ddb65298718c3670170690f3b955ff5bf6d80242d89772b'
        playerPackageParts = @(
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.001'; sha256='7d768f3ec343729a003a1f0d84cec360375e8d98fc7ce965d0c400c4313ae6f4'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.002'; sha256='4d4dc1d844f6a7fceb757d5d5b72f6f3024bbb27154701f10f694fde50164e7d'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.003'; sha256='de226d94ad226dfca6c47f12eaf9b4e5e268c0c8abc5176e3c1b406f7623f5eb'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.004'; sha256='63d337a60946b9518c08340124dc0e2762bca9e8e662f4e990b8192e5aa5a052'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.005'; sha256='6579e135ad095512d6b40588702246b0326994cd031ac1971214740036df5ba5'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.006'; sha256='078e228a8a65674fbc480acf07e28bdf5d2ff261e7c47e51d9e25432d1fbb9a4'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.007'; sha256='e7f23502bd8aa4780caf602f7f4e60d5495af6504a211a05f59dbd50065fc824'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.008'; sha256='27f89a899804e243b9c86f8e5d881361a9c7755e613f9c984a7814ee51523a7d'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.009'; sha256='0de139259218dcd82fa7cebdcca07df2ba410ed37aced7106d67dd581660dd17'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.010'; sha256='0bf8c6a8eb91434b459202dac7bc6d1860bd39189dc10b55b9472b027e584682'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.011'; sha256='8afe5b32bd1e8a735a3346c110555084373e0ff10027e9e4eb4582d8f0d1a970'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.012'; sha256='f9659b36bd14a6a2c8dd3c1e4a71b3890eef02185be202792038b0c710931bfc'; size=52428800},
            [pscustomobject]@{url='https://github.com/MarcosNatividade01/TibiaRemastered/releases/download/v0.1.6/TibiaRemastered-Player.zip.013'; sha256='167ce715d07d5ec9ae50f4a7ca575cc81c01c8b0553351a80867cd23e3bf3017'; size=49950974}
        )
    }
}

function Get-TrmConfig {
    Ensure-TrmProjectStructure
    $root = Get-TrmRoot
    $path = Join-Path $root 'Config\launcher-config.json'
    $default = Get-TrmDefaultConfig
    if (-not (Test-Path $path)) { Save-TrmJsonFile -Path $path -Value $default }
    $config = Read-TrmJsonFile -Path $path -Default $default
    $changed = $false
    foreach ($property in $default.PSObject.Properties) {
        if (-not ($config.PSObject.Properties.Name -contains $property.Name)) {
            $config | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
            $changed = $true
        }
    }
    if ($changed) { Save-TrmJsonFile -Path $path -Value $config }
    return $config
}

function Get-TrmSha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-TrmRelativePath {
    param([string]$Base, [string]$Path)
    $basePath = (Resolve-Path $Base).Path.TrimEnd('\','/')
    $fullPath = (Resolve-Path $Path).Path
    $relative = $fullPath.Substring($basePath.Length).TrimStart('\','/')
    return ($relative -replace '\\','/')
}

function Test-TrmProtectedPath {
    param([string]$RelativePath)
    $norm = ($RelativePath -replace '\\','/').TrimStart('/')
    $protectedFiles = @('.gitignore','.gitattributes','manifest.json','version.json','Config/launcher-config.json')
    foreach ($fileName in $protectedFiles) {
        if ($norm -ieq $fileName) { return $true }
    }
    $protectedRoots = @('UserData','Logs','Backup','Backups','Saves','Save','Database','Databases','PrivateDatabase')
    foreach ($root in $protectedRoots) {
        if ($norm -ieq $root -or $norm.StartsWith($root + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Get-TrmRequestHeaders {
    param([string]$Url)
    if ($Url -notmatch '(^https://raw\.githubusercontent\.com/|^https://api\.github\.com/)') { return @{} }
    try {
        $token = (& gh auth token 2>$null)
        if (-not [string]::IsNullOrWhiteSpace($token)) {
            return @{
                Authorization = "Bearer $token"
                'User-Agent' = 'TibiaRemasteredLauncher'
                Accept = 'application/vnd.github.raw'
            }
        }
    } catch {
        Write-TrmLog "GitHub auth token unavailable: $($_.Exception.Message)" 'WARN'
    }
    return @{'User-Agent' = 'TibiaRemasteredLauncher'}
}

function Resolve-TrmRequestUrl {
    param([string]$Url)
    if ($Url -match '^https://raw\.githubusercontent\.com/' -and $Url -match '/main/') {
        $separator = '?'
        if ($Url.Contains('?')) { $separator = '&' }
        return $Url + $separator + 'cb=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    }
    return $Url
}

Export-ModuleMember -Function *-Trm*
