param(
    [switch]$SelfTest,
    [switch]$Repair,
    [switch]$Play,
    [switch]$NoGui
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Script:Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Script:LogFile = Join-Path $Script:Root ('Logs\launcher_' + (Get-Date -Format 'yyyy-MM-dd') + '.log')
$Script:ProtectedRoots = @('UserData','Logs','Backup')
$Script:ProtectedFiles = @('.gitignore','.gitattributes','manifest.json','version.json')

function Write-LauncherLog {
    param([string]$Message, [string]$Level = 'INFO')
    $logDir = Split-Path -Parent $Script:LogFile
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $Script:LogFile -Value $line -Encoding UTF8
}

function Ensure-ProjectStructure {
    $dirs = @('Launcher','Client','Server','Data','Config','Database_Template','UserData\Database','UserData\Config','UserData\Saves','Logs','Backup','Docs')
    foreach ($dir in $dirs) {
        $path = Join-Path $Script:Root $dir
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    }
}

function Read-JsonFile {
    param([string]$Path, [object]$Default)
    if (-not (Test-Path $Path)) { return $Default }
    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    return $raw | ConvertFrom-Json
}

function Save-JsonFile {
    param([string]$Path, [object]$Value)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Value | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding UTF8
}

function Get-LauncherConfig {
    $default = [pscustomobject]@{
        remoteVersionUrl = ''
        remoteManifestUrl = ''
        serverExe = 'C:\otserv\crystalserver.exe'
        serverWorkingDirectory = 'C:\otserv'
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
        clientExe = 'C:\Users\marco\Tibiafriends\bin\client-local.exe'
        clientWorkingDirectory = 'C:\Users\marco\Tibiafriends'
        preserve = @('UserData/**','Logs/**','Backup/**')
    }
    $path = Join-Path $Script:Root 'Config\launcher-config.json'
    if (-not (Test-Path $path)) { Save-JsonFile -Path $path -Value $default }
    $config = Read-JsonFile -Path $path -Default $default
    $changed = $false
    foreach ($property in $default.PSObject.Properties) {
        if (-not ($config.PSObject.Properties.Name -contains $property.Name)) {
            $config | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
            $changed = $true
        }
    }
    if ($changed) { Save-JsonFile -Path $path -Value $config }
    return $config
}

function Get-Sha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-ProtectedPath {
    param([string]$RelativePath)
    $norm = ($RelativePath -replace '\\','/').TrimStart('/')
    foreach ($fileName in $Script:ProtectedFiles) {
        if ($norm -ieq $fileName) { return $true }
    }
    foreach ($root in $Script:ProtectedRoots) {
        if ($norm -ieq $root -or $norm.StartsWith($root + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Get-GitHubRequestHeaders {
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
        Write-LauncherLog "GitHub auth token unavailable: $($_.Exception.Message)" 'WARN'
    }
    return @{}
}
function Get-RemoteJson {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { throw 'Remote URL is not configured.' }
    Write-LauncherLog "Downloading json: $Url"
    $headers = Get-GitHubRequestHeaders $Url
    $response = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing -TimeoutSec 30
    $raw = [string]$response.Content
    $raw = $raw.TrimStart([char]0xFEFF)
    if ($raw.StartsWith('ï»¿')) { $raw = $raw.Substring(3) }
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "JSON remoto vazio: $Url" }
    return ($raw | ConvertFrom-Json)
}

function Test-InternetConnection {
    param([string]$Url)
    try {
        if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
        $headers = Get-GitHubRequestHeaders $Url
        Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing -Method Head -TimeoutSec 12 | Out-Null
        return $true
    } catch {
        Write-LauncherLog "Internet/remote check failed: $($_.Exception.Message)" 'WARN'
        return $false
    }
}

function New-UpdateBackup {
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $dir = Join-Path $Script:Root (Join-Path 'Backup' "update_$stamp")
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

function Backup-FileForUpdate {
    param([string]$RelativePath, [string]$BackupRoot)
    $source = Join-Path $Script:Root $RelativePath
    if (-not (Test-Path $source)) { return }
    $dest = Join-Path $BackupRoot $RelativePath
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item -Path $source -Destination $dest -Force
}

function Restore-Backup {
    param([string]$BackupRoot)
    if (-not (Test-Path $BackupRoot)) { return }
    Get-ChildItem -Path $BackupRoot -File -Recurse | ForEach-Object {
        $relative = $_.FullName.Substring($BackupRoot.Length).TrimStart('\','/')
        $dest = Join-Path $Script:Root $relative
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
        Copy-Item -Path $_.FullName -Destination $dest -Force
    }
}

function Download-ManifestFile {
    param(
        [object]$FileEntry,
        [string]$BackupRoot,
        [scriptblock]$ProgressCallback
    )
    $relative = [string]$FileEntry.path
    if ([string]::IsNullOrWhiteSpace($relative)) { throw 'Manifest contains file without path.' }
    if (Test-ProtectedPath $relative) { Write-LauncherLog "Skipping protected path $relative" 'WARN'; return 'protected' }

    $overwrite = $true
    if ($null -ne $FileEntry.overwrite) { $overwrite = [bool]$FileEntry.overwrite }
    $target = Join-Path $Script:Root $relative
    $exists = Test-Path $target
    if ($exists -and -not $overwrite) { Write-LauncherLog "Skipping overwrite=false file $relative"; return 'preserved' }

    if ($ProgressCallback) { & $ProgressCallback "Downloading $relative" 0 }
    if ([string]::IsNullOrWhiteSpace([string]$FileEntry.url)) { throw "No download URL for $relative" }

    if ($exists) { Backup-FileForUpdate -RelativePath $relative -BackupRoot $BackupRoot }
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
    $tmp = $target + '.download'
    if (Test-Path $tmp) { Remove-Item -Path $tmp -Force }

    $headers = Get-GitHubRequestHeaders ([string]$FileEntry.url)
    Invoke-WebRequest -Uri ([string]$FileEntry.url) -Headers $headers -OutFile $tmp -UseBasicParsing -TimeoutSec 120
    $hash = Get-Sha256 $tmp
    $expected = ([string]$FileEntry.sha256).ToLowerInvariant()
    if ($hash -ne $expected) {
        Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
        throw "Hash mismatch for $relative. expected=$expected actual=$hash"
    }
    Move-Item -Path $tmp -Destination $target -Force
    return 'downloaded'
}

function Sync-FromManifest {
    param(
        [object]$Manifest,
        [switch]$ForceRepair,
        [scriptblock]$ProgressCallback
    )
    if ($null -eq $Manifest) { throw 'Manifest remoto vazio ou invalido.' }
    $manifestVersion = '0.0.0'
    if ($Manifest.PSObject.Properties.Name -contains 'version') { $manifestVersion = [string]$Manifest.version }
    if (-not ($Manifest.PSObject.Properties.Name -contains 'files')) { throw 'Manifest remoto invalido: propriedade files ausente.' }
    if (-not $Manifest.files) { return [pscustomobject]@{Checked=0;Downloaded=0;Skipped=0;Backup=''} }
    $backup = New-UpdateBackup
    $checked = 0; $downloaded = 0; $skipped = 0
    try {
        foreach ($file in @($Manifest.files)) {
            $checked++
            $relative = [string]$file.path
            if ($ProgressCallback) { & $ProgressCallback "Checking $relative" (($checked / @($Manifest.files).Count) * 100) }
            if (Test-ProtectedPath $relative) { $skipped++; continue }
            $target = Join-Path $Script:Root $relative
            $localHash = Get-Sha256 $target
            $remoteHash = ([string]$file.sha256).ToLowerInvariant()
            if ($localHash -eq $remoteHash -and -not $ForceRepair) { $skipped++; continue }
            if ($localHash -eq $remoteHash -and $ForceRepair) { $skipped++; continue }
            $result = Download-ManifestFile -FileEntry $file -BackupRoot $backup -ProgressCallback $ProgressCallback
            if ($result -eq 'downloaded') { $downloaded++ } else { $skipped++ }
        }
        Save-JsonFile -Path (Join-Path $Script:Root 'version.json') -Value ([pscustomobject]@{ version = $manifestVersion; updatedAt = (Get-Date).ToString('s') })
        return [pscustomobject]@{Checked=$checked;Downloaded=$downloaded;Skipped=$skipped;Backup=$backup}
    } catch {
        Write-LauncherLog "Update failed, restoring backup $backup : $($_.Exception.Message)" 'ERROR'
        Restore-Backup -BackupRoot $backup
        throw
    }
}

function Initialize-FirstRun {
    Ensure-ProjectStructure
    $dbDir = Join-Path $Script:Root 'UserData\Database'
    $hasDb = @(Get-ChildItem -Path $dbDir -File -ErrorAction SilentlyContinue).Count -gt 0
    if (-not $hasDb) {
        $template = Join-Path $Script:Root 'Database_Template'
        if (Test-Path $template) {
            Get-ChildItem -Path $template -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $rel = $_.FullName.Substring($template.Length).TrimStart('\','/')
                $dest = Join-Path $dbDir $rel
                $destDir = Split-Path -Parent $dest
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
                Copy-Item -Path $_.FullName -Destination $dest -Force
            }
        }
    }
    Get-LauncherConfig | Out-Null
}

function Invoke-UpdateOrRepair {
    param([switch]$ForceRepair, [scriptblock]$ProgressCallback)
    Initialize-FirstRun
    $config = Get-LauncherConfig
    if (-not (Test-InternetConnection $config.remoteManifestUrl)) {
        throw 'Nao foi possivel acessar o manifest remoto. Configure Config/launcher-config.json ou verifique a internet.'
    }
    $remoteVersion = if ($config.remoteVersionUrl) { Get-RemoteJson $config.remoteVersionUrl } else { $null }
    $manifest = Get-RemoteJson $config.remoteManifestUrl
    if ($ProgressCallback -and $remoteVersion -and ($remoteVersion.PSObject.Properties.Name -contains 'version')) { & $ProgressCallback ("Remote version: " + $remoteVersion.version) 0 }
    return Sync-FromManifest -Manifest $manifest -ForceRepair:$ForceRepair -ProgressCallback $ProgressCallback
}

function Wait-ServerPorts {
    param([int[]]$Ports, [int]$TimeoutSeconds)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $allOpen = $true
        foreach ($port in $Ports) {
            $open = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
            if (-not $open) { $allOpen = $false; break }
        }
        if ($allOpen) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Test-LocalPortListening {
    param([int]$Port)
    $open = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $open)
}

function Ensure-DatabaseServer {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = 3306
    if ($Config.PSObject.Properties.Name -contains 'databasePort') { $port = [int]$Config.databasePort }
    if (Test-LocalPortListening -Port $port) { return }

    if (-not ($Config.PSObject.Properties.Name -contains 'databaseExe')) {
        Write-LauncherLog 'Database port is closed and databaseExe is not configured.' 'WARN'
        return
    }

    $databaseExe = [string]$Config.databaseExe
    if ([string]::IsNullOrWhiteSpace($databaseExe)) { return }
    if (-not (Test-Path $databaseExe)) {
        Write-LauncherLog "Database exe not found: $databaseExe" 'WARN'
        return
    }

    $databaseWorkingDirectory = Split-Path -Parent $databaseExe
    if ($Config.PSObject.Properties.Name -contains 'databaseWorkingDirectory' -and -not [string]::IsNullOrWhiteSpace([string]$Config.databaseWorkingDirectory)) {
        $databaseWorkingDirectory = [string]$Config.databaseWorkingDirectory
    }

    $databaseArguments = ''
    if ($Config.PSObject.Properties.Name -contains 'databaseArguments') { $databaseArguments = [string]$Config.databaseArguments }

    if ($ProgressCallback) { & $ProgressCallback 'Starting local database...' 0 }
    Write-LauncherLog "Starting database: $databaseExe $databaseArguments"
    Start-Process -FilePath $databaseExe -ArgumentList $databaseArguments -WorkingDirectory $databaseWorkingDirectory -WindowStyle Hidden | Out-Null

    $timeout = 60
    if ($Config.PSObject.Properties.Name -contains 'databaseStartupTimeoutSeconds') { $timeout = [int]$Config.databaseStartupTimeoutSeconds }
    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $deadline) {
        if (Test-LocalPortListening -Port $port) { return }
        Start-Sleep -Seconds 1
    }
    throw "Database did not open port $port before timeout."
}
function Ensure-WebEndpoint {
    param([object]$Config, [scriptblock]$ProgressCallback)
    $port = 80
    if ($Config.PSObject.Properties.Name -contains 'webServerPort') { $port = [int]$Config.webServerPort }
    if (Test-LocalPortListening -Port $port) { return }

    if (-not ($Config.PSObject.Properties.Name -contains 'webServerExe')) {
        Write-LauncherLog 'Web endpoint port is closed and webServerExe is not configured.' 'WARN'
        return
    }

    $webServerExe = [string]$Config.webServerExe
    if ([string]::IsNullOrWhiteSpace($webServerExe)) { return }
    if (-not (Test-Path $webServerExe)) {
        Write-LauncherLog "Web server exe not found: $webServerExe" 'WARN'
        return
    }

    $webServerWorkingDirectory = Split-Path -Parent $webServerExe
    if ($Config.PSObject.Properties.Name -contains 'webServerWorkingDirectory' -and -not [string]::IsNullOrWhiteSpace([string]$Config.webServerWorkingDirectory)) {
        $webServerWorkingDirectory = [string]$Config.webServerWorkingDirectory
    }

    $webServerArguments = ''
    if ($Config.PSObject.Properties.Name -contains 'webServerArguments') { $webServerArguments = [string]$Config.webServerArguments }

    if ($ProgressCallback) { & $ProgressCallback 'Starting local web endpoint...' 0 }
    Write-LauncherLog "Starting web endpoint: $webServerExe $webServerArguments"
    if ([string]::IsNullOrWhiteSpace($webServerArguments)) {
        Start-Process -FilePath $webServerExe -WorkingDirectory $webServerWorkingDirectory -WindowStyle Hidden | Out-Null
    } else {
        Start-Process -FilePath $webServerExe -ArgumentList $webServerArguments -WorkingDirectory $webServerWorkingDirectory -WindowStyle Hidden | Out-Null
    }

    $timeout = 30
    if ($Config.PSObject.Properties.Name -contains 'webServerStartupTimeoutSeconds') { $timeout = [int]$Config.webServerStartupTimeoutSeconds }
    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $deadline) {
        if (Test-LocalPortListening -Port $port) { return }
        Start-Sleep -Seconds 1
    }
    throw "Web endpoint did not open port $port before timeout."
}
function Start-Game {
    param([scriptblock]$ProgressCallback)
    Initialize-FirstRun
    $config = Get-LauncherConfig
    if ($config.remoteManifestUrl) {
        Invoke-UpdateOrRepair -ProgressCallback $ProgressCallback | Out-Null
    }
    if (-not (Test-Path ([string]$config.serverExe))) { throw "Server exe not found: $($config.serverExe)" }
    if (-not (Test-Path ([string]$config.clientExe))) { throw "Client exe not found: $($config.clientExe)" }

    Ensure-DatabaseServer -Config $config -ProgressCallback $ProgressCallback
    Ensure-WebEndpoint -Config $config -ProgressCallback $ProgressCallback

    $serverPortsOpen = Wait-ServerPorts -Ports @($config.serverPorts) -TimeoutSeconds 1
    if (-not $serverPortsOpen) {
        $serverRunning = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq ([string]$config.serverExe) }
        if (-not $serverRunning) {
            if ($ProgressCallback) { & $ProgressCallback 'Starting local server...' 0 }
            Start-Process -FilePath ([string]$config.serverExe) -WorkingDirectory ([string]$config.serverWorkingDirectory) -WindowStyle Minimized | Out-Null
        }
    }
    if (-not (Wait-ServerPorts -Ports @($config.serverPorts) -TimeoutSeconds ([int]$config.serverStartupTimeoutSeconds))) {
        throw 'Server did not open expected ports before timeout.'
    }
    if ($ProgressCallback) { & $ProgressCallback 'Starting client...' 100 }
    Remove-Item Env:\QT_QUICK_BACKEND -ErrorAction SilentlyContinue
    Remove-Item Env:\QT_OPENGL -ErrorAction SilentlyContinue
    Remove-Item Env:\QSG_RHI_BACKEND -ErrorAction SilentlyContinue
    $env:QSG_RENDER_LOOP = 'basic'
    Write-LauncherLog 'Starting client with basic Qt render loop'
    Start-Process -FilePath ([string]$config.clientExe) -WorkingDirectory ([string]$config.clientWorkingDirectory) | Out-Null
}

function Show-LauncherGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Initialize-FirstRun
    $config = Get-LauncherConfig
    $localVersion = Read-JsonFile -Path (Join-Path $Script:Root 'version.json') -Default ([pscustomobject]@{version='0.0.0'})

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Tibia Remastered Launcher'
    $form.Size = New-Object System.Drawing.Size(620, 380)
    $form.StartPosition = 'CenterScreen'

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(20, 20)
    $status.Size = New-Object System.Drawing.Size(560, 28)
    $status.Text = 'Ready'
    $form.Controls.Add($status)

    $version = New-Object System.Windows.Forms.Label
    $version.Location = New-Object System.Drawing.Point(20, 55)
    $version.Size = New-Object System.Drawing.Size(560, 24)
    $version.Text = 'Local version: ' + $localVersion.version
    $form.Controls.Add($version)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(20, 90)
    $progress.Size = New-Object System.Drawing.Size(560, 24)
    $progress.Minimum = 0; $progress.Maximum = 100
    $form.Controls.Add($progress)

    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(20, 130)
    $logBox.Size = New-Object System.Drawing.Size(560, 110)
    $logBox.Multiline = $true
    $logBox.ReadOnly = $true
    $logBox.ScrollBars = 'Vertical'
    $form.Controls.Add($logBox)

    function Set-UiStatus([string]$Text, [double]$Percent) {
        $status.Text = $Text
        $p = [Math]::Max(0, [Math]::Min(100, [int]$Percent))
        $progress.Value = $p
        $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + ' ' + $Text + [Environment]::NewLine)
        [System.Windows.Forms.Application]::DoEvents()
    }

    $btnCheck = New-Object System.Windows.Forms.Button
    $btnCheck.Text = 'Verificar atualizacao'
    $btnCheck.Location = New-Object System.Drawing.Point(20, 260)
    $btnCheck.Size = New-Object System.Drawing.Size(150, 32)
    $btnCheck.Add_Click({
        try {
            $cfg = Get-LauncherConfig
            if ([string]::IsNullOrWhiteSpace($cfg.remoteVersionUrl)) { Set-UiStatus 'Configure remoteVersionUrl em Config/launcher-config.json' 0; return }
            $remote = Get-RemoteJson $cfg.remoteVersionUrl
            Set-UiStatus ('Versao remota: ' + $remote.version) 100
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 }
    })
    $form.Controls.Add($btnCheck)

    $btnRepair = New-Object System.Windows.Forms.Button
    $btnRepair.Text = 'Atualizar/Reparar'
    $btnRepair.Location = New-Object System.Drawing.Point(180, 260)
    $btnRepair.Size = New-Object System.Drawing.Size(130, 32)
    $btnRepair.Add_Click({
        try {
            $r = Invoke-UpdateOrRepair -ForceRepair -ProgressCallback ${function:Set-UiStatus}
            Set-UiStatus ("Concluido. Baixados: $($r.Downloaded), verificados: $($r.Checked)") 100
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 }
    })
    $form.Controls.Add($btnRepair)

    $btnPlay = New-Object System.Windows.Forms.Button
    $btnPlay.Text = 'Jogar'
    $btnPlay.Location = New-Object System.Drawing.Point(320, 260)
    $btnPlay.Size = New-Object System.Drawing.Size(90, 32)
    $btnPlay.Add_Click({
        try { Start-Game -ProgressCallback ${function:Set-UiStatus}; Set-UiStatus 'Cliente iniciado.' 100 }
        catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 }
    })
    $form.Controls.Add($btnPlay)

    $btnFolder = New-Object System.Windows.Forms.Button
    $btnFolder.Text = 'Abrir pasta'
    $btnFolder.Location = New-Object System.Drawing.Point(420, 260)
    $btnFolder.Size = New-Object System.Drawing.Size(100, 32)
    $btnFolder.Add_Click({ Start-Process explorer.exe $Script:Root })
    $form.Controls.Add($btnFolder)

    $btnBackup = New-Object System.Windows.Forms.Button
    $btnBackup.Text = 'Backups'
    $btnBackup.Location = New-Object System.Drawing.Point(20, 300)
    $btnBackup.Size = New-Object System.Drawing.Size(100, 32)
    $btnBackup.Add_Click({ Start-Process explorer.exe (Join-Path $Script:Root 'Backup') })
    $form.Controls.Add($btnBackup)

    $btnConfig = New-Object System.Windows.Forms.Button
    $btnConfig.Text = 'Configuracoes'
    $btnConfig.Location = New-Object System.Drawing.Point(130, 300)
    $btnConfig.Size = New-Object System.Drawing.Size(120, 32)
    $btnConfig.Add_Click({ notepad.exe (Join-Path $Script:Root 'Config\launcher-config.json') })
    $form.Controls.Add($btnConfig)

    [void]$form.ShowDialog()
}

function Invoke-SelfTest {
    Initialize-FirstRun
    $config = Get-LauncherConfig
    $file = Join-Path $Script:Root 'Launcher\Launcher.ps1'
    $hash = Get-Sha256 $file
    $checks = [ordered]@{
        RootExists = (Test-Path $Script:Root)
        ConfigExists = (Test-Path (Join-Path $Script:Root 'Config\launcher-config.json'))
        VersionExists = (Test-Path (Join-Path $Script:Root 'version.json'))
        ManifestExists = (Test-Path (Join-Path $Script:Root 'manifest.json'))
        UserDataProtected = (Test-ProtectedPath 'UserData/Database/test.db')
        HashWorks = (-not [string]::IsNullOrWhiteSpace($hash))
        ServerPathConfigured = (-not [string]::IsNullOrWhiteSpace([string]$config.serverExe))
        ClientPathConfigured = (-not [string]::IsNullOrWhiteSpace([string]$config.clientExe))
    }
    $checks.GetEnumerator() | ForEach-Object { '{0}: {1}' -f $_.Key, $_.Value }
    if ($checks.Values -contains $false) { exit 1 }
}

try {
    Write-LauncherLog 'Launcher started'
    if ($SelfTest) { Invoke-SelfTest; return }
    if ($Repair) { Invoke-UpdateOrRepair -ForceRepair -ProgressCallback { param($m,$p) Write-Host $m } | Format-List; return }
    if ($Play) { Start-Game -ProgressCallback { param($m,$p) Write-Host $m }; return }
    if ($NoGui) { Initialize-FirstRun; Write-Host 'Launcher initialized.'; return }
    Show-LauncherGui
} catch {
    Write-LauncherLog $_.Exception.Message 'ERROR'
    if ($NoGui -or $SelfTest -or $Repair -or $Play) { throw }
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Launcher error') | Out-Null
}












