param(
    [switch]$SelfTest,
    [switch]$Repair,
    [switch]$Check,
    [switch]$Play,
    [switch]$NoGui
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $PSScriptRoot 'Modules'
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Validation.psm1') -Force -DisableNameChecking

function Format-LauncherBytes {
    param([double]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:n2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:n2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:n1} KB' -f ($Bytes / 1KB)) }
    return ('{0:n0} B' -f $Bytes)
}

function Get-LauncherLocalVersionText {
    $version = Read-TrmJsonFile -Path (Join-Path (Get-TrmRoot) 'version.json') -Default ([pscustomobject]@{version='0.0.0'})
    if ($version -and ($version.PSObject.Properties.Name -contains 'version')) { return [string]$version.version }
    return '0.0.0'
}

function Get-LauncherRemoteVersionText {
    try {
        $config = Get-TrmConfig
        if ([string]::IsNullOrWhiteSpace([string]$config.remoteVersionUrl)) { return 'nao configurada' }
        $remote = Get-TrmRemoteJson $config.remoteVersionUrl
        if ($remote.PSObject.Properties.Name -contains 'version') { return [string]$remote.version }
        return 'desconhecida'
    } catch {
        return 'indisponivel'
    }
}

function Show-LauncherGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Ensure-TrmProjectStructure

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Tibia Remastered Launcher'
    $form.Size = New-Object System.Drawing.Size(760, 460)
    $form.MinimumSize = New-Object System.Drawing.Size(720, 420)
    $form.StartPosition = 'CenterScreen'

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(20, 18)
    $status.Size = New-Object System.Drawing.Size(700, 24)
    $status.Text = 'Pronto'
    $form.Controls.Add($status)

    $localVersion = New-Object System.Windows.Forms.Label
    $localVersion.Location = New-Object System.Drawing.Point(20, 50)
    $localVersion.Size = New-Object System.Drawing.Size(220, 22)
    $localVersion.Text = 'Versao local: ' + (Get-LauncherLocalVersionText)
    $form.Controls.Add($localVersion)

    $remoteVersion = New-Object System.Windows.Forms.Label
    $remoteVersion.Location = New-Object System.Drawing.Point(260, 50)
    $remoteVersion.Size = New-Object System.Drawing.Size(250, 22)
    $remoteVersion.Text = 'Versao disponivel: verificando...'
    $form.Controls.Add($remoteVersion)

    $speed = New-Object System.Windows.Forms.Label
    $speed.Location = New-Object System.Drawing.Point(530, 50)
    $speed.Size = New-Object System.Drawing.Size(190, 22)
    $speed.Text = 'Velocidade: 0 B/s'
    $form.Controls.Add($speed)

    $remaining = New-Object System.Windows.Forms.Label
    $remaining.Location = New-Object System.Drawing.Point(20, 80)
    $remaining.Size = New-Object System.Drawing.Size(700, 22)
    $remaining.Text = 'Restante: 0 B'
    $form.Controls.Add($remaining)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(20, 110)
    $progress.Size = New-Object System.Drawing.Size(700, 24)
    $progress.Minimum = 0
    $progress.Maximum = 100
    $form.Controls.Add($progress)

    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(20, 150)
    $logBox.Size = New-Object System.Drawing.Size(700, 140)
    $logBox.Multiline = $true
    $logBox.ReadOnly = $true
    $logBox.ScrollBars = 'Vertical'
    $form.Controls.Add($logBox)

    function Add-UiLog([string]$Text) {
        $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + ' ' + $Text + [Environment]::NewLine)
    }

    function Set-UiStatus([string]$Text, [double]$Percent, [double]$BytesPerSecond, [double]$BytesRemaining) {
        $status.Text = $Text
        $p = [Math]::Max(0, [Math]::Min(100, [int]$Percent))
        $progress.Value = $p
        $speed.Text = 'Velocidade: ' + (Format-LauncherBytes $BytesPerSecond) + '/s'
        $remaining.Text = 'Restante: ' + (Format-LauncherBytes $BytesRemaining)
        Add-UiLog $Text
        [System.Windows.Forms.Application]::DoEvents()
    }

    function Refresh-VersionLabels {
        $localVersion.Text = 'Versao local: ' + (Get-LauncherLocalVersionText)
        $remoteVersion.Text = 'Versao disponivel: ' + (Get-LauncherRemoteVersionText)
    }

    function Refresh-LastUpdate {
        $last = Get-TrmLastUpdateReport
        if ($last) {
            Add-UiLog ('Ultima atualizacao: {0}, baixados: {1}, verificados: {2}' -f $last.status, $last.downloaded, $last.checked)
        }
    }

    $btnPlay = New-Object System.Windows.Forms.Button
    $btnPlay.Text = 'Jogar'
    $btnPlay.Location = New-Object System.Drawing.Point(20, 315)
    $btnPlay.Size = New-Object System.Drawing.Size(100, 34)
    $btnPlay.Add_Click({
        try {
            Start-TrmGame -ProgressCallback ${function:Set-UiStatus}
            Set-UiStatus 'Cliente iniciado.' 100 0 0
            Refresh-VersionLabels
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 0 0 }
    })
    $form.Controls.Add($btnPlay)

    $btnCheck = New-Object System.Windows.Forms.Button
    $btnCheck.Text = 'Verificar Atualizacoes'
    $btnCheck.Location = New-Object System.Drawing.Point(130, 315)
    $btnCheck.Size = New-Object System.Drawing.Size(150, 34)
    $btnCheck.Add_Click({
        try {
            Refresh-VersionLabels
            Set-UiStatus 'Verificacao concluida.' 100 0 0
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 0 0 }
    })
    $form.Controls.Add($btnCheck)

    $btnRepair = New-Object System.Windows.Forms.Button
    $btnRepair.Text = 'Reparar Arquivos'
    $btnRepair.Location = New-Object System.Drawing.Point(290, 315)
    $btnRepair.Size = New-Object System.Drawing.Size(130, 34)
    $btnRepair.Add_Click({
        try {
            $r = Invoke-TrmUpdateOrRepair -ForceRepair -ProgressCallback ${function:Set-UiStatus}
            Set-UiStatus ("Reparo concluido. Baixados: $($r.downloaded), verificados: $($r.checked)") 100 $r.averageBytesPerSecond 0
            Refresh-VersionLabels
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 0 0 }
    })
    $form.Controls.Add($btnRepair)

    $btnConfig = New-Object System.Windows.Forms.Button
    $btnConfig.Text = 'Configuracoes'
    $btnConfig.Location = New-Object System.Drawing.Point(430, 315)
    $btnConfig.Size = New-Object System.Drawing.Size(120, 34)
    $btnConfig.Add_Click({ notepad.exe (Join-Path (Get-TrmRoot) 'Config\launcher-config.json') })
    $form.Controls.Add($btnConfig)

    $btnFolder = New-Object System.Windows.Forms.Button
    $btnFolder.Text = 'Abrir Pasta'
    $btnFolder.Location = New-Object System.Drawing.Point(560, 315)
    $btnFolder.Size = New-Object System.Drawing.Size(110, 34)
    $btnFolder.Add_Click({ Start-Process explorer.exe (Get-TrmRoot) })
    $form.Controls.Add($btnFolder)

    $btnBackup = New-Object System.Windows.Forms.Button
    $btnBackup.Text = 'Backups'
    $btnBackup.Location = New-Object System.Drawing.Point(20, 360)
    $btnBackup.Size = New-Object System.Drawing.Size(100, 32)
    $btnBackup.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Backup') })
    $form.Controls.Add($btnBackup)

    Refresh-VersionLabels
    Refresh-LastUpdate
    [void]$form.ShowDialog()
}

try {
    Write-TrmLog 'Launcher started'
    if ($SelfTest) { Invoke-TrmSelfTest; return }
    if ($Check) {
        $config = Get-TrmConfig
        $remote = Get-TrmRemoteJson $config.remoteVersionUrl
        'LocalVersion: {0}' -f (Get-LauncherLocalVersionText)
        'RemoteVersion: {0}' -f $remote.version
        return
    }
    if ($Repair) { Invoke-TrmUpdateOrRepair -ForceRepair -ProgressCallback { param($m,$p,$s,$r) Write-Host $m } | Format-List; return }
    if ($Play) { Start-TrmGame -ProgressCallback { param($m,$p,$s,$r) Write-Host $m }; return }
    if ($NoGui) { Ensure-TrmProjectStructure; Write-Host 'Launcher initialized.'; return }
    Show-LauncherGui
} catch {
    Write-TrmLog $_.Exception.Message 'ERROR'
    if ($NoGui -or $SelfTest -or $Repair -or $Play -or $Check) { throw }
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Launcher error') | Out-Null
}
