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
        databaseExe = 'C:\xampp\mysql\bin\mysqld.exe'
        databaseArguments = '--defaults-file=C:\xampp\mysql\bin\my.ini'
        databaseWorkingDirectory = 'C:\xampp\mysql\bin'
        databasePort = 3306
        databaseStartupTimeoutSeconds = 60
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
