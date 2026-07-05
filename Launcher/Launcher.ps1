param(
    [switch]$SelfTest,
    [switch]$Repair,
    [switch]$Check,
    [switch]$Play,
    [switch]$MinimumQA,
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
    return GetCurrentVersion
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

function ConvertTo-LauncherComparableVersion {
    param([string]$Version)
    if ([string]::IsNullOrWhiteSpace($Version)) { return [version]'0.0.0' }
    $core = ($Version -replace '-.*$','')
    try { return [version]$core } catch { return [version]'0.0.0' }
}

function Test-LauncherRemoteVersionNewer {
    param([string]$LocalVersion, [string]$RemoteVersion)
    return ((ConvertTo-LauncherComparableVersion $RemoteVersion) -gt (ConvertTo-LauncherComparableVersion $LocalVersion))
}

function Get-LauncherRemoteChangelogText {
    $config = Get-TrmConfig
    if ([string]::IsNullOrWhiteSpace([string]$config.remoteVersionUrl)) { throw 'URL de versao remota nao configurada.' }
    $changelogUrl = ([string]$config.remoteVersionUrl) -replace 'version\.json(\?.*)?$', 'CHANGELOG.md'
    if ($changelogUrl -eq [string]$config.remoteVersionUrl) { throw 'Nao foi possivel inferir a URL do changelog remoto.' }
    return Get-TrmRemoteText $changelogUrl
}

function Get-LauncherChangelogSection {
    param([string]$Changelog, [string]$Version)
    if ([string]::IsNullOrWhiteSpace($Changelog)) { return 'Changelog remoto vazio.' }
    if ([string]::IsNullOrWhiteSpace($Version)) { return $Changelog }
    $pattern = "(?ms)^## \[$([regex]::Escape($Version))\].*?(?=^## \[|\z)"
    $match = [regex]::Match($Changelog, $pattern)
    if ($match.Success) { return $match.Value.Trim() }
    return $Changelog
}

function Show-LauncherGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Ensure-TrmProjectStructure

    $colorBackground = [System.Drawing.Color]::FromArgb(24, 22, 20)
    $colorPanel = [System.Drawing.Color]::FromArgb(39, 34, 29)
    $colorBorder = [System.Drawing.Color]::FromArgb(154, 116, 45)
    $colorButton = [System.Drawing.Color]::FromArgb(92, 65, 35)
    $colorButtonText = [System.Drawing.Color]::FromArgb(245, 230, 190)
    $colorText = [System.Drawing.Color]::FromArgb(232, 222, 200)
    $fontMain = New-Object System.Drawing.Font('Segoe UI', 9)
    $fontTitle = New-Object System.Drawing.Font('Georgia', 18, [System.Drawing.FontStyle]::Bold)
    $fontButton = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)

    function Set-LauncherButtonStyle($Button) {
        $Button.BackColor = $colorButton
        $Button.ForeColor = $colorButtonText
        $Button.FlatStyle = 'Flat'
        $Button.FlatAppearance.BorderColor = $colorBorder
        $Button.FlatAppearance.BorderSize = 1
        $Button.Font = $fontButton
    }

    function Set-LauncherTextStyle($Control) {
        $Control.BackColor = $colorPanel
        $Control.ForeColor = $colorText
        $Control.Font = $fontMain
    }

    $script:BtnUpdate = $null
    $script:BtnUpdatePlay = $null
    $script:BtnNews = $null

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Tibia Remastered Launcher'
    $form.Size = New-Object System.Drawing.Size(840, 660)
    $form.MinimumSize = New-Object System.Drawing.Size(800, 620)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = $colorBackground
    $form.ForeColor = $colorText
    $form.Font = $fontMain

    $title = New-Object System.Windows.Forms.Label
    $title.Location = New-Object System.Drawing.Point(20, 16)
    $title.Size = New-Object System.Drawing.Size(760, 34)
    $title.Text = 'Tibia Remastered'
    $title.Font = $fontTitle
    $title.ForeColor = [System.Drawing.Color]::FromArgb(232, 184, 85)
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(22, 58)
    $status.Size = New-Object System.Drawing.Size(740, 24)
    $status.Text = 'Pronto'
    $status.ForeColor = $colorText
    $form.Controls.Add($status)

    $localVersion = New-Object System.Windows.Forms.Label
    $localVersion.Location = New-Object System.Drawing.Point(22, 88)
    $localVersion.Size = New-Object System.Drawing.Size(220, 22)
    $localVersion.Text = 'Versao local: ' + (Get-LauncherLocalVersionText)
    $localVersion.ForeColor = $colorText
    $form.Controls.Add($localVersion)

    $remoteVersion = New-Object System.Windows.Forms.Label
    $remoteVersion.Location = New-Object System.Drawing.Point(260, 88)
    $remoteVersion.Size = New-Object System.Drawing.Size(250, 22)
    $remoteVersion.Text = 'Versao disponivel: verificando...'
    $remoteVersion.ForeColor = $colorText
    $form.Controls.Add($remoteVersion)

    $speed = New-Object System.Windows.Forms.Label
    $speed.Location = New-Object System.Drawing.Point(540, 88)
    $speed.Size = New-Object System.Drawing.Size(190, 22)
    $speed.Text = 'Velocidade: 0 B/s'
    $speed.ForeColor = $colorText
    $form.Controls.Add($speed)

    $remaining = New-Object System.Windows.Forms.Label
    $remaining.Location = New-Object System.Drawing.Point(22, 140)
    $remaining.Size = New-Object System.Drawing.Size(700, 22)
    $remaining.Text = 'Restante: 0 B'
    $remaining.ForeColor = $colorText
    $form.Controls.Add($remaining)

    $updateStatus = New-Object System.Windows.Forms.Label
    $updateStatus.Location = New-Object System.Drawing.Point(22, 116)
    $updateStatus.Size = New-Object System.Drawing.Size(740, 22)
    $updateStatus.Text = 'Status de atualizacao: verificando...'
    $updateStatus.ForeColor = [System.Drawing.Color]::FromArgb(232, 184, 85)
    $form.Controls.Add($updateStatus)

    $rootLabel = New-Object System.Windows.Forms.Label
    $rootLabel.Location = New-Object System.Drawing.Point(22, 164)
    $rootLabel.Size = New-Object System.Drawing.Size(740, 20)
    $rootLabel.Text = 'Launcher atual: ' + (Get-TrmRoot)
    $rootLabel.ForeColor = [System.Drawing.Color]::FromArgb(176, 154, 112)
    $form.Controls.Add($rootLabel)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(22, 190)
    $progress.Size = New-Object System.Drawing.Size(740, 22)
    $progress.Minimum = 0
    $progress.Maximum = 100
    $form.Controls.Add($progress)

    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(22, 226)
    $logBox.Size = New-Object System.Drawing.Size(740, 145)
    $logBox.Multiline = $true
    $logBox.ReadOnly = $true
    $logBox.ScrollBars = 'Vertical'
    Set-LauncherTextStyle $logBox
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
        $localText = Get-LauncherLocalVersionText
        $remoteText = Get-LauncherRemoteVersionText
        $localVersion.Text = 'Versao instalada: ' + $localText
        $remoteVersion.Text = 'Versao disponivel: ' + $remoteText
        $hasUpdate = Test-LauncherRemoteVersionNewer -LocalVersion $localText -RemoteVersion $remoteText
        if ($remoteText -eq 'indisponivel' -or $remoteText -eq 'nao configurada' -or $remoteText -eq 'desconhecida') {
            $updateStatus.Text = 'Status de atualizacao: nao foi possivel verificar agora.'
        } elseif ($hasUpdate) {
            $updateStatus.Text = "Atualizacao disponivel: $localText -> $remoteText"
        } else {
            $updateStatus.Text = 'Voce esta usando a versao mais recente.'
        }
        if ($script:BtnUpdate) { $script:BtnUpdate.Enabled = $hasUpdate }
        if ($script:BtnUpdatePlay) { $script:BtnUpdatePlay.Enabled = $hasUpdate }
        if ($script:BtnNews) { $script:BtnNews.Enabled = ($remoteText -ne 'indisponivel' -and $remoteText -ne 'nao configurada' -and $remoteText -ne 'desconhecida') }
    }

    function Refresh-LastUpdate {
        $last = Get-TrmLastUpdateReport
        if ($last) {
            Add-UiLog ('Ultima atualizacao: {0}, baixados: {1}, verificados: {2}' -f $last.status, $last.downloaded, $last.checked)
        }
    }

    function Show-AdminTestsPanel {
        $adminForm = New-Object System.Windows.Forms.Form
        $adminForm.Text = 'Admin / Testes'
        $adminForm.Size = New-Object System.Drawing.Size(680, 520)
        $adminForm.MinimumSize = New-Object System.Drawing.Size(640, 480)
        $adminForm.StartPosition = 'CenterParent'
        $adminForm.BackColor = $colorBackground
        $adminForm.ForeColor = $colorText

        $info = New-Object System.Windows.Forms.Label
        $info.Location = New-Object System.Drawing.Point(16, 14)
        $info.Size = New-Object System.Drawing.Size(620, 22)
        $balanceFlag = Get-TrmRemasteredFeatureFlag -Name 'enable_remastered_balance'
        $adminFlag = Get-TrmRemasteredFeatureFlag -Name 'enable_admin_balance_tests'
        $info.Text = ('Balance: {0} | Admin Tests: {1}' -f $balanceFlag, $adminFlag)
        $adminForm.Controls.Add($info)

        $xpLabel = New-Object System.Windows.Forms.Label
        $xpLabel.Location = New-Object System.Drawing.Point(16, 50)
        $xpLabel.Size = New-Object System.Drawing.Size(80, 22)
        $xpLabel.Text = 'XP alvo'
        $adminForm.Controls.Add($xpLabel)

        $xpInput = New-Object System.Windows.Forms.TextBox
        $xpInput.Location = New-Object System.Drawing.Point(100, 48)
        $xpInput.Size = New-Object System.Drawing.Size(180, 24)
        $xpInput.Text = 'dragon'
        $adminForm.Controls.Add($xpInput)

        $skillLabel = New-Object System.Windows.Forms.Label
        $skillLabel.Location = New-Object System.Drawing.Point(300, 50)
        $skillLabel.Size = New-Object System.Drawing.Size(80, 22)
        $skillLabel.Text = 'Skill'
        $adminForm.Controls.Add($skillLabel)

        $skillInput = New-Object System.Windows.Forms.TextBox
        $skillInput.Location = New-Object System.Drawing.Point(380, 48)
        $skillInput.Size = New-Object System.Drawing.Size(180, 24)
        $skillInput.Text = 'sword 100'
        $adminForm.Controls.Add($skillInput)

        $lootLabel = New-Object System.Windows.Forms.Label
        $lootLabel.Location = New-Object System.Drawing.Point(16, 84)
        $lootLabel.Size = New-Object System.Drawing.Size(80, 22)
        $lootLabel.Text = 'Loot alvo'
        $adminForm.Controls.Add($lootLabel)

        $lootInput = New-Object System.Windows.Forms.TextBox
        $lootInput.Location = New-Object System.Drawing.Point(100, 82)
        $lootInput.Size = New-Object System.Drawing.Size(180, 24)
        $lootInput.Text = 'dragon 100'
        $adminForm.Controls.Add($lootInput)

        $output = New-Object System.Windows.Forms.TextBox
        $output.Location = New-Object System.Drawing.Point(16, 164)
        $output.Size = New-Object System.Drawing.Size(630, 285)
        $output.Multiline = $true
        $output.ReadOnly = $true
        $output.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $output
        $adminForm.Controls.Add($output)

        function Run-AdminTest([string]$Command, [string]$Param) {
            try {
                $output.Text = "Executando $Command..."
                [System.Windows.Forms.Application]::DoEvents()
                $result = Invoke-TrmAdminBalancePanelTest -Command $Command -Param $Param
                $output.Text = $result
            } catch {
                $output.Text = 'Erro: ' + $_.Exception.Message
            }
        }

        $btnBalance = New-Object System.Windows.Forms.Button
        $btnBalance.Text = 'Testar Balanceamento'
        $btnBalance.Location = New-Object System.Drawing.Point(16, 118)
        $btnBalance.Size = New-Object System.Drawing.Size(140, 32)
        $btnBalance.Add_Click({ Run-AdminTest 'balance' '' })
        Set-LauncherButtonStyle $btnBalance
        $adminForm.Controls.Add($btnBalance)

        $btnXp = New-Object System.Windows.Forms.Button
        $btnXp.Text = 'Testar XP'
        $btnXp.Location = New-Object System.Drawing.Point(166, 118)
        $btnXp.Size = New-Object System.Drawing.Size(90, 32)
        $btnXp.Add_Click({ Run-AdminTest 'xp' $xpInput.Text })
        Set-LauncherButtonStyle $btnXp
        $adminForm.Controls.Add($btnXp)

        $btnSkill = New-Object System.Windows.Forms.Button
        $btnSkill.Text = 'Testar Skill'
        $btnSkill.Location = New-Object System.Drawing.Point(266, 118)
        $btnSkill.Size = New-Object System.Drawing.Size(90, 32)
        $btnSkill.Add_Click({ Run-AdminTest 'skill' $skillInput.Text })
        Set-LauncherButtonStyle $btnSkill
        $adminForm.Controls.Add($btnSkill)

        $btnLoot = New-Object System.Windows.Forms.Button
        $btnLoot.Text = 'Testar Loot'
        $btnLoot.Location = New-Object System.Drawing.Point(366, 118)
        $btnLoot.Size = New-Object System.Drawing.Size(90, 32)
        $btnLoot.Add_Click({ Run-AdminTest 'loot' $lootInput.Text })
        Set-LauncherButtonStyle $btnLoot
        $adminForm.Controls.Add($btnLoot)

        $btnOpenLogs = New-Object System.Windows.Forms.Button
        $btnOpenLogs.Text = 'Abrir Logs'
        $btnOpenLogs.Location = New-Object System.Drawing.Point(466, 118)
        $btnOpenLogs.Size = New-Object System.Drawing.Size(80, 32)
        $btnOpenLogs.Add_Click({ Start-Process explorer.exe (Get-TrmBalanceTestLogDirectory) })
        Set-LauncherButtonStyle $btnOpenLogs
        $adminForm.Controls.Add($btnOpenLogs)

        $btnClearLogs = New-Object System.Windows.Forms.Button
        $btnClearLogs.Text = 'Limpar Logs'
        $btnClearLogs.Location = New-Object System.Drawing.Point(556, 118)
        $btnClearLogs.Size = New-Object System.Drawing.Size(90, 32)
        $btnClearLogs.Add_Click({
            try {
                Clear-TrmAdminBalanceTestLogs | Out-Null
                $output.Text = 'Logs de teste limpos.'
            } catch {
                $output.Text = 'Erro: ' + $_.Exception.Message
            }
        })
        Set-LauncherButtonStyle $btnClearLogs
        $adminForm.Controls.Add($btnClearLogs)

        [void]$adminForm.ShowDialog($form)
    }

    function Show-HostAssistPanel([string]$InitialMode) {
        $hostForm = New-Object System.Windows.Forms.Form
        $hostForm.Text = 'Host Assistido'
        $hostForm.Size = New-Object System.Drawing.Size(780, 720)
        $hostForm.MinimumSize = New-Object System.Drawing.Size(740, 680)
        $hostForm.StartPosition = 'CenterParent'
        $hostForm.BackColor = $colorBackground
        $hostForm.ForeColor = $colorText

        $state = Get-TrmOnlineState
        $currentInvite = ''
        $currentHostPort = 7172
        $currentHostWorld = ''

        function Format-FriendlyError([string]$Message) {
            if ($Message -match 'Host inacessivel|Connection refused|actively refused') {
                return "Servidor nao encontrado.`r`nO host nao respondeu na porta informada.`r`nConfira o IP, a porta, se o servidor esta online e se o firewall liberou a conexao."
            }
            if ($Message -match 'Versao|Version mismatch|incompativel') {
                return "Versao incompativel.`r`nAtualize o Tibia Remastered no host ou no convidado antes de conectar."
            }
            if ($Message -match 'porta web|port.*in use|em uso') {
                return "Porta ocupada.`r`nFeche outro programa usando a porta indicada e tente novamente."
            }
            return "Nao foi possivel concluir a acao.`r`nDetalhes: $Message"
        }

        function Format-OnlineDiagnosticText($Diagnostic) {
            if ($null -eq $Diagnostic) { return 'Diagnostico indisponivel.' }
            $warnings = @($Diagnostic.warnings)
            $warningText = if ($warnings.Count -gt 0) { ($warnings -join "`r`n- ") } else { 'nenhum aviso critico' }
            return "Diagnostico: $($Diagnostic.status)`r`nmode=$($Diagnostic.connectionMode)`r`nversion=$($Diagnostic.currentVersion)`r`nHost alvo acessivel: $($Diagnostic.targetReachable)`r`nIP local: $($Diagnostic.localIp)`r`nIP publico: $($Diagnostic.publicIp)`r`nPorta servidor em uso: $($Diagnostic.serverPort.inUse)`r`nCompatibilidade: $($Diagnostic.version.message)`r`nAvisos: $warningText`r`nRelatorio: $($Diagnostic.reportPath)"
        }

        function Format-ConnectionReportText($Report) {
            if ($null -eq $Report) { return 'Relatorio de conexao indisponivel.' }
            return "Relatorio de conexao: $($Report.status)`r`nmode=$($Report.mode)`r`nFase: $($Report.phase)`r`nIP final: $($Report.finalHost)`r`nPorta Tibia: $($Report.finalPort)`r`nHost e localhost: $($Report.isLoopbackHost)`r`nTCP Tibia direto: $($Report.tcpTest.succeeded) $($Report.tcpTest.error)`r`nWeb/login opcional: $($Report.loginServer.responded) $($Report.loginServer.error)`r`nversion=$($Report.version.localVersion)`r`nCompatibilidade: $($Report.version.message)`r`nClient usa: $($Report.clientWorldAddress):$($Report.finalPort)`r`nConfig client: $($Report.clientConfigDescription)`r`nComando: $($Report.clientCommand)`r`nFalha: $($Report.failureReason)`r`nArquivo: $($Report.reportPath)"
        }

        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Location = New-Object System.Drawing.Point(18, 16)
        $statusLabel.Size = New-Object System.Drawing.Size(710, 24)
        $statusLabel.Text = 'Status: aguardando'
        $statusLabel.ForeColor = $colorText
        $hostForm.Controls.Add($statusLabel)

        $hostGroup = New-Object System.Windows.Forms.GroupBox
        $hostGroup.Text = 'Hospedar Mundo'
        $hostGroup.Location = New-Object System.Drawing.Point(18, 50)
        $hostGroup.Size = New-Object System.Drawing.Size(720, 220)
        $hostGroup.ForeColor = $colorText
        $hostForm.Controls.Add($hostGroup)

        $hostInfo = New-Object System.Windows.Forms.TextBox
        $hostInfo.Location = New-Object System.Drawing.Point(14, 24)
        $hostInfo.Size = New-Object System.Drawing.Size(690, 134)
        $hostInfo.Multiline = $true
        $hostInfo.ReadOnly = $true
        $hostInfo.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $hostInfo
        $hostGroup.Controls.Add($hostInfo)

        $btnStartHost = New-Object System.Windows.Forms.Button
        $btnStartHost.Text = 'Iniciar Mundo'
        $btnStartHost.Location = New-Object System.Drawing.Point(14, 172)
        $btnStartHost.Size = New-Object System.Drawing.Size(120, 32)
        $btnStartHost.Add_Click({
            try {
                $statusLabel.Text = 'Status: servidor iniciando'
                $result = Start-TrmHostedWorld -ProgressCallback ${function:Set-UiStatus}
                $currentInvite = [string]$result.invite
                $currentHostPort = [int]$result.port
                $currentHostWorld = [string]$result.worldName
                $hostInfo.Text = "Servidor online`r`nMundo: $($result.worldName)`r`nJogadores conectados: $($result.playersOnline)`r`nIP local: $($result.localIp)`r`nIP publico: $($result.publicIp)`r`nPorta Tibia: $($result.port)`r`nversion=$($result.version)`r`nmode=host-local`r`n`r`nConvite para amigos:`r`n$currentInvite`r`n`r`n$(Format-OnlineDiagnosticText $result.diagnostic)"
                $statusLabel.Text = 'Status: servidor online'
            } catch {
                $hostInfo.Text = Format-FriendlyError $_.Exception.Message
                $statusLabel.Text = 'Status: erro ao hospedar'
            }
        })
        Set-LauncherButtonStyle $btnStartHost
        $hostGroup.Controls.Add($btnStartHost)

        $btnCopyHost = New-Object System.Windows.Forms.Button
        $btnCopyHost.Text = 'Copiar Convite para Amigos'
        $btnCopyHost.Location = New-Object System.Drawing.Point(144, 172)
        $btnCopyHost.Size = New-Object System.Drawing.Size(170, 32)
        $btnCopyHost.Add_Click({
            if (-not [string]::IsNullOrWhiteSpace($currentInvite)) {
                [System.Windows.Forms.Clipboard]::SetText($currentInvite)
                $statusLabel.Text = 'Status: convite copiado'
            } else {
                $statusLabel.Text = 'Status: hospede o mundo antes de copiar convite'
            }
        })
        Set-LauncherButtonStyle $btnCopyHost
        $hostGroup.Controls.Add($btnCopyHost)

        $btnJoinOwnHost = New-Object System.Windows.Forms.Button
        $btnJoinOwnHost.Text = 'Entrar no Meu Mundo'
        $btnJoinOwnHost.Location = New-Object System.Drawing.Point(324, 172)
        $btnJoinOwnHost.Size = New-Object System.Drawing.Size(150, 32)
        $btnJoinOwnHost.Add_Click({
            try {
                $statusLabel.Text = 'Status: conectando localmente'
                $result = JoinOwnHostedWorld -Port $currentHostPort -WorldName $currentHostWorld -ProgressCallback ${function:Set-UiStatus}
                $hostInfo.Text = "Cliente local iniciado.`r`nModo: $($result.mode)`r`nHost usado: $($result.clientWorldAddress)`r`nPorta: $($result.port)`r`nHistorico salvo em: $($result.statePath)`r`n`r`n$(Format-OnlineDiagnosticText $result.diagnostic)"
                $statusLabel.Text = 'Status: cliente local iniciado'
            } catch {
                $hostInfo.Text = Format-FriendlyError $_.Exception.Message
                $statusLabel.Text = 'Status: erro ao entrar no meu mundo'
            }
        })
        Set-LauncherButtonStyle $btnJoinOwnHost
        $hostGroup.Controls.Add($btnJoinOwnHost)

        $btnHostLogs = New-Object System.Windows.Forms.Button
        $btnHostLogs.Text = 'Abrir Logs'
        $btnHostLogs.Location = New-Object System.Drawing.Point(424, 172)
        $btnHostLogs.Size = New-Object System.Drawing.Size(90, 32)
        $btnHostLogs.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Logs') })
        Set-LauncherButtonStyle $btnHostLogs
        $hostGroup.Controls.Add($btnHostLogs)

        $btnStopHost = New-Object System.Windows.Forms.Button
        $btnStopHost.Text = 'Parar Mundo'
        $btnStopHost.Location = New-Object System.Drawing.Point(524, 172)
        $btnStopHost.Size = New-Object System.Drawing.Size(110, 32)
        $btnStopHost.Add_Click({
            try {
                $result = Stop-TrmHostedWorld
                $statusLabel.Text = "Status: servidor parado ($($result.stopped) processo(s))"
            } catch {
                $statusLabel.Text = 'Status: erro ao parar servidor'
                $hostInfo.Text = 'Erro: ' + $_.Exception.Message
            }
        })
        Set-LauncherButtonStyle $btnStopHost
        $hostGroup.Controls.Add($btnStopHost)

        $joinGroup = New-Object System.Windows.Forms.GroupBox
        $joinGroup.Text = 'Entrar em Mundo'
        $joinGroup.Location = New-Object System.Drawing.Point(18, 285)
        $joinGroup.Size = New-Object System.Drawing.Size(720, 370)
        $joinGroup.ForeColor = $colorText
        $hostForm.Controls.Add($joinGroup)

        $hostLabel = New-Object System.Windows.Forms.Label
        $hostLabel.Location = New-Object System.Drawing.Point(14, 28)
        $hostLabel.Size = New-Object System.Drawing.Size(90, 22)
        $hostLabel.Text = 'IP/endereco'
        $joinGroup.Controls.Add($hostLabel)

        $hostInput = New-Object System.Windows.Forms.TextBox
        $hostInput.Location = New-Object System.Drawing.Point(110, 26)
        $hostInput.Size = New-Object System.Drawing.Size(230, 24)
        $hostInput.Text = [string]$state.lastHost
        $joinGroup.Controls.Add($hostInput)

        $portLabel = New-Object System.Windows.Forms.Label
        $portLabel.Location = New-Object System.Drawing.Point(360, 28)
        $portLabel.Size = New-Object System.Drawing.Size(40, 22)
        $portLabel.Text = 'Porta'
        $joinGroup.Controls.Add($portLabel)

        $portInput = New-Object System.Windows.Forms.TextBox
        $portInput.Location = New-Object System.Drawing.Point(405, 26)
        $portInput.Size = New-Object System.Drawing.Size(80, 24)
        $portInput.Text = [string]$state.lastPort
        $joinGroup.Controls.Add($portInput)

        $historyLabel = New-Object System.Windows.Forms.Label
        $historyLabel.Location = New-Object System.Drawing.Point(505, 28)
        $historyLabel.Size = New-Object System.Drawing.Size(180, 22)
        $historyLabel.Text = 'Historico'
        $joinGroup.Controls.Add($historyLabel)

        $historyList = New-Object System.Windows.Forms.ListBox
        $historyList.Location = New-Object System.Drawing.Point(505, 52)
        $historyList.Size = New-Object System.Drawing.Size(200, 95)
        Set-LauncherTextStyle $historyList
        if ($state.PSObject.Properties.Name -contains 'recentWorlds') {
            foreach ($world in @($state.recentWorlds)) {
                [void]$historyList.Items.Add(('{0} - {1}:{2}' -f $world.worldName, $world.host, $world.port))
            }
        } elseif ($state.PSObject.Properties.Name -contains 'history') {
            foreach ($entry in @($state.history)) { [void]$historyList.Items.Add([string]$entry) }
        }
        $historyList.Add_SelectedIndexChanged({
            if ($historyList.SelectedIndex -lt 0) { return }
            $selected = [string]$historyList.SelectedItem
            if ($selected -match '([a-zA-Z0-9\.\-]+):(\d+)') {
                $hostInput.Text = $Matches[1]
                $portInput.Text = $Matches[2]
                $statusLabel.Text = 'Status: historico selecionado'
            }
        })
        $joinGroup.Controls.Add($historyList)

        $inviteLabel = New-Object System.Windows.Forms.Label
        $inviteLabel.Location = New-Object System.Drawing.Point(14, 100)
        $inviteLabel.Size = New-Object System.Drawing.Size(160, 22)
        $inviteLabel.Text = 'Colar convite'
        $joinGroup.Controls.Add($inviteLabel)

        $inviteInput = New-Object System.Windows.Forms.TextBox
        $inviteInput.Location = New-Object System.Drawing.Point(14, 124)
        $inviteInput.Size = New-Object System.Drawing.Size(370, 74)
        $inviteInput.Multiline = $true
        $inviteInput.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $inviteInput
        $joinGroup.Controls.Add($inviteInput)

        $script:TrmInviteWorld = ''
        $script:TrmInviteVersion = ''

        $btnUseInvite = New-Object System.Windows.Forms.Button
        $btnUseInvite.Text = 'Usar Convite'
        $btnUseInvite.Location = New-Object System.Drawing.Point(394, 124)
        $btnUseInvite.Size = New-Object System.Drawing.Size(95, 32)
        $btnUseInvite.Add_Click({
            $parsed = ConvertFrom-TrmWorldInvite -InviteText $inviteInput.Text
            if (-not $parsed.valid) {
                $reason = if (-not [string]::IsNullOrWhiteSpace([string]$parsed.error)) { [string]$parsed.error } else { 'Cole um convite remoto valido ou informe IP e porta manualmente.' }
                $joinOutput.Text = "Convite nao reconhecido.`r`n$reason`r`n`r`nHost extraido: $($parsed.host)`r`nPorta extraida: $($parsed.port)`r`nVersao extraida: $($parsed.version)`r`nModo extraido: $($parsed.mode)"
                $statusLabel.Text = 'Status: convite invalido'
                return
            }
            $hostInput.Text = $parsed.host
            $portInput.Text = [string]$parsed.port
            $script:TrmInviteWorld = [string]$parsed.worldName
            $script:TrmInviteVersion = [string]$parsed.version
            $joinOutput.Text = "Convite carregado.`r`nMundo: $script:TrmInviteWorld`r`nHost: $($parsed.host)`r`nPorta Tibia: $($parsed.port)`r`nversion=$script:TrmInviteVersion`r`nmode=$($parsed.mode)"
            $statusLabel.Text = 'Status: convite carregado'
        })
        Set-LauncherButtonStyle $btnUseInvite
        $joinGroup.Controls.Add($btnUseInvite)

        $joinOutput = New-Object System.Windows.Forms.TextBox
        $joinOutput.Location = New-Object System.Drawing.Point(14, 210)
        $joinOutput.Size = New-Object System.Drawing.Size(690, 130)
        $joinOutput.Multiline = $true
        $joinOutput.ReadOnly = $true
        $joinOutput.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $joinOutput
        $joinGroup.Controls.Add($joinOutput)

        $historyText = ''
        if ($state.PSObject.Properties.Name -contains 'history') { $historyText = (@($state.history) -join ', ') }
        $joinOutput.Text = "Ultimos servidores: $historyText"

        $btnTestConnection = New-Object System.Windows.Forms.Button
        $btnTestConnection.Text = 'Testar Conexao'
        $btnTestConnection.Location = New-Object System.Drawing.Point(14, 62)
        $btnTestConnection.Size = New-Object System.Drawing.Size(120, 30)
        $btnTestConnection.Add_Click({
            $port = 7172
            [void][int]::TryParse($portInput.Text, [ref]$port)
            try {
                $resolved = Get-TrmRuntimeConfigResolved
                $connectionReport = New-TrmConnectionTestReport -Mode 'remote' -RawInvite $inviteInput.Text -Host $hostInput.Text -Port $port -WebPort ([int]$resolved.config.webServerPort) -WorldName $script:TrmInviteWorld -ExpectedVersion $script:TrmInviteVersion -ClientWorldAddress $hostInput.Text -ClientExe $resolved.clientExe -ClientWorkingDirectory $resolved.clientWorkingDirectory -ConfigDescription ("test remote world={0}:{1}" -f $hostInput.Text, $port) -Phase 'ui-test-connection'
                $diagnostic = New-TrmNetworkDiagnosticReport -Mode 'join' -Host $hostInput.Text -Port $port -WebPort ([int]$resolved.config.webServerPort)
                if ($connectionReport.status -eq 'passed' -and $diagnostic.targetReachable) {
                    $joinOutput.Text = "Servidor encontrado.`r`nHost: $($hostInput.Text)`r`nPorta: $port`r`n`r`n$(Format-ConnectionReportText $connectionReport)`r`n`r`n$(Format-OnlineDiagnosticText $diagnostic)"
                    $statusLabel.Text = 'Status: servidor encontrado'
                } else {
                    $joinOutput.Text = "Servidor nao encontrado.`r`nMotivo: $($connectionReport.failureReason)`r`n`r`n$(Format-ConnectionReportText $connectionReport)`r`n`r`n$(Format-OnlineDiagnosticText $diagnostic)"
                    $statusLabel.Text = 'Status: servidor nao encontrado'
                }
            } catch {
                $joinOutput.Text = "Erro no diagnostico.`r`n$($_.Exception.Message)"
                $statusLabel.Text = 'Status: erro no diagnostico'
            }
        })
        Set-LauncherButtonStyle $btnTestConnection
        $joinGroup.Controls.Add($btnTestConnection)

        $btnConnect = New-Object System.Windows.Forms.Button
        $btnConnect.Text = 'Entrar'
        $btnConnect.Location = New-Object System.Drawing.Point(144, 62)
        $btnConnect.Size = New-Object System.Drawing.Size(90, 30)
        $btnConnect.Add_Click({
            try {
                $port = 7172
                [void][int]::TryParse($portInput.Text, [ref]$port)
                $statusLabel.Text = 'Status: conectando'
                $result = JoinRemoteWorld -Host $hostInput.Text -Port $port -WorldName $script:TrmInviteWorld -ExpectedVersion $script:TrmInviteVersion -RawInvite $inviteInput.Text -ProgressCallback ${function:Set-UiStatus}
                $joinOutput.Text = "Conectando ao mundo.`r`nModo: $($result.mode)`r`nMundo: $($result.worldName)`r`nHost do convite: $($result.host)`r`nIP usado pelo client: $($result.clientWorldAddress)`r`nPorta: $($result.port)`r`nHistorico salvo em: $($result.statePath)`r`n`r`n$(Format-ConnectionReportText $result.connectionReport)`r`n`r`n$(Format-OnlineDiagnosticText $result.diagnostic)"
                $statusLabel.Text = 'Status: cliente online iniciado'
            } catch {
                $joinOutput.Text = "Erro ao conectar.`r`n$($_.Exception.Message)"
                $statusLabel.Text = 'Status: erro ao conectar'
            }
        })
        Set-LauncherButtonStyle $btnConnect
        $joinGroup.Controls.Add($btnConnect)

        if ($InitialMode -eq 'host') {
            $hostInfo.Text = 'Clique em Hospedar Mundo para iniciar servidor local e obter dados de conexao.'
        } elseif ($InitialMode -eq 'join') {
            $joinOutput.Text = "Informe IP/endereco e porta. Ultimos servidores: $historyText"
        }

        [void]$hostForm.ShowDialog($form)
    }

    function Show-LauncherSettingsPanel {
        $settingsForm = New-Object System.Windows.Forms.Form
        $settingsForm.Text = 'Configuracoes'
        $settingsForm.Size = New-Object System.Drawing.Size(560, 360)
        $settingsForm.MinimumSize = New-Object System.Drawing.Size(520, 320)
        $settingsForm.StartPosition = 'CenterParent'
        $settingsForm.BackColor = $colorBackground
        $settingsForm.ForeColor = $colorText

        $info = New-Object System.Windows.Forms.TextBox
        $info.Location = New-Object System.Drawing.Point(16, 16)
        $info.Size = New-Object System.Drawing.Size(505, 130)
        $info.Multiline = $true
        $info.ReadOnly = $true
        $info.Text = "Configuracoes do Tibia Remastered`r`n`r`nO modo Offline nao depende da internet e nao precisa de ajustes manuais.`r`nUse Reparar Arquivos apenas se algum arquivo do Launcher, Client ou Server estiver faltando.`r`nDados locais em UserData, Logs e Backup sao protegidos."
        Set-LauncherTextStyle $info
        $settingsForm.Controls.Add($info)

        $btnRepair = New-Object System.Windows.Forms.Button
        $btnRepair.Text = 'Reparar Arquivos'
        $btnRepair.Location = New-Object System.Drawing.Point(16, 170)
        $btnRepair.Size = New-Object System.Drawing.Size(130, 34)
        $btnRepair.Add_Click({
            try {
                $r = Invoke-TrmUpdateOrRepair -ForceRepair -ProgressCallback ${function:Set-UiStatus}
                $info.Text = "Reparo concluido.`r`nArquivos baixados: $($r.downloaded)`r`nArquivos verificados: $($r.checked)"
            } catch {
                $info.Text = "Nao foi possivel reparar agora.`r`nConfira sua internet e tente novamente.`r`nDetalhes: $($_.Exception.Message)"
            }
        })
        Set-LauncherButtonStyle $btnRepair
        $settingsForm.Controls.Add($btnRepair)

        $btnCheck = New-Object System.Windows.Forms.Button
        $btnCheck.Text = 'Verificar Atualizacoes'
        $btnCheck.Location = New-Object System.Drawing.Point(156, 170)
        $btnCheck.Size = New-Object System.Drawing.Size(150, 34)
        $btnCheck.Add_Click({
            try {
                Refresh-VersionLabels
                $info.Text = "Verificacao concluida.`r`n$(($localVersion.Text))`r`n$(($remoteVersion.Text))"
            } catch {
                $info.Text = "Nao foi possivel verificar atualizacoes.`r`nO modo Offline continua disponivel.`r`nDetalhes: $($_.Exception.Message)"
            }
        })
        Set-LauncherButtonStyle $btnCheck
        $settingsForm.Controls.Add($btnCheck)

        $btnLogs = New-Object System.Windows.Forms.Button
        $btnLogs.Text = 'Abrir Logs'
        $btnLogs.Location = New-Object System.Drawing.Point(316, 170)
        $btnLogs.Size = New-Object System.Drawing.Size(95, 34)
        $btnLogs.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Logs') })
        Set-LauncherButtonStyle $btnLogs
        $settingsForm.Controls.Add($btnLogs)

        $btnBackup = New-Object System.Windows.Forms.Button
        $btnBackup.Text = 'Backups'
        $btnBackup.Location = New-Object System.Drawing.Point(421, 170)
        $btnBackup.Size = New-Object System.Drawing.Size(90, 34)
        $btnBackup.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Backup') })
        Set-LauncherButtonStyle $btnBackup
        $settingsForm.Controls.Add($btnBackup)

        if (Get-TrmAdminPanelAllowed) {
            $btnAdmin = New-Object System.Windows.Forms.Button
            $btnAdmin.Text = 'Admin / Testes'
            $btnAdmin.Location = New-Object System.Drawing.Point(16, 220)
            $btnAdmin.Size = New-Object System.Drawing.Size(120, 34)
            $btnAdmin.Add_Click({ Show-AdminTestsPanel })
            Set-LauncherButtonStyle $btnAdmin
            $settingsForm.Controls.Add($btnAdmin)
        }

        [void]$settingsForm.ShowDialog($form)
    }

    function Show-LauncherDiagnosticsPanel {
        $diagForm = New-Object System.Windows.Forms.Form
        $diagForm.Text = 'Diagnostico'
        $diagForm.Size = New-Object System.Drawing.Size(680, 500)
        $diagForm.MinimumSize = New-Object System.Drawing.Size(640, 460)
        $diagForm.StartPosition = 'CenterParent'
        $diagForm.BackColor = $colorBackground
        $diagForm.ForeColor = $colorText

        $hostLabel = New-Object System.Windows.Forms.Label
        $hostLabel.Location = New-Object System.Drawing.Point(16, 18)
        $hostLabel.Size = New-Object System.Drawing.Size(90, 22)
        $hostLabel.Text = 'IP/endereco'
        $diagForm.Controls.Add($hostLabel)

        $state = Get-TrmOnlineState
        $hostInput = New-Object System.Windows.Forms.TextBox
        $hostInput.Location = New-Object System.Drawing.Point(110, 16)
        $hostInput.Size = New-Object System.Drawing.Size(220, 24)
        $hostInput.Text = [string]$state.lastHost
        Set-LauncherTextStyle $hostInput
        $diagForm.Controls.Add($hostInput)

        $portLabel = New-Object System.Windows.Forms.Label
        $portLabel.Location = New-Object System.Drawing.Point(350, 18)
        $portLabel.Size = New-Object System.Drawing.Size(45, 22)
        $portLabel.Text = 'Porta'
        $diagForm.Controls.Add($portLabel)

        $portInput = New-Object System.Windows.Forms.TextBox
        $portInput.Location = New-Object System.Drawing.Point(400, 16)
        $portInput.Size = New-Object System.Drawing.Size(80, 24)
        $portInput.Text = [string]$state.lastPort
        Set-LauncherTextStyle $portInput
        $diagForm.Controls.Add($portInput)

        $output = New-Object System.Windows.Forms.TextBox
        $output.Location = New-Object System.Drawing.Point(16, 62)
        $output.Size = New-Object System.Drawing.Size(620, 320)
        $output.Multiline = $true
        $output.ReadOnly = $true
        $output.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $output
        $diagForm.Controls.Add($output)

        function Format-DiagnosticForUser($Diagnostic) {
            $warnings = @($Diagnostic.warnings)
            $warningText = if ($warnings.Count -gt 0) { ($warnings -join "`r`n- ") } else { 'Nenhum problema critico encontrado.' }
            return "Resultado: $($Diagnostic.status)`r`nmode=$($Diagnostic.connectionMode)`r`nversion=$($Diagnostic.currentVersion)`r`nHost acessivel: $($Diagnostic.targetReachable)`r`nIP local: $($Diagnostic.localIp)`r`nIP publico: $($Diagnostic.publicIp)`r`nPorta: $($Diagnostic.port)`r`nCompatibilidade: $($Diagnostic.version.message)`r`n`r`nAvisos:`r`n- $warningText`r`n`r`nRelatorio salvo em:`r`n$($Diagnostic.reportPath)"
        }

        $btnHostDiag = New-Object System.Windows.Forms.Button
        $btnHostDiag.Text = 'Diagnostico Host'
        $btnHostDiag.Location = New-Object System.Drawing.Point(16, 400)
        $btnHostDiag.Size = New-Object System.Drawing.Size(125, 34)
        $btnHostDiag.Add_Click({
            try {
                $resolved = Get-TrmRuntimeConfigResolved
                $port = [int](@($resolved.config.serverPorts)[1])
                $diag = New-TrmNetworkDiagnosticReport -Mode 'host' -Port $port -WebPort ([int]$resolved.config.webServerPort)
                $output.Text = Format-DiagnosticForUser $diag
            } catch {
                $output.Text = "Nao foi possivel gerar diagnostico.`r`nDetalhes: $($_.Exception.Message)"
            }
        })
        Set-LauncherButtonStyle $btnHostDiag
        $diagForm.Controls.Add($btnHostDiag)

        $btnJoinDiag = New-Object System.Windows.Forms.Button
        $btnJoinDiag.Text = 'Testar Conexao'
        $btnJoinDiag.Location = New-Object System.Drawing.Point(151, 400)
        $btnJoinDiag.Size = New-Object System.Drawing.Size(125, 34)
        $btnJoinDiag.Add_Click({
            try {
                $port = 7172
                [void][int]::TryParse($portInput.Text, [ref]$port)
                $resolved = Get-TrmRuntimeConfigResolved
                $diag = New-TrmNetworkDiagnosticReport -Mode 'join' -Host $hostInput.Text -Port $port -WebPort ([int]$resolved.config.webServerPort)
                $output.Text = Format-DiagnosticForUser $diag
            } catch {
                $output.Text = "Nao foi possivel testar conexao.`r`nConfira IP, porta e rede.`r`nDetalhes: $($_.Exception.Message)"
            }
        })
        Set-LauncherButtonStyle $btnJoinDiag
        $diagForm.Controls.Add($btnJoinDiag)

        $btnOpenReports = New-Object System.Windows.Forms.Button
        $btnOpenReports.Text = 'Abrir Relatorios'
        $btnOpenReports.Location = New-Object System.Drawing.Point(286, 400)
        $btnOpenReports.Size = New-Object System.Drawing.Size(125, 34)
        $btnOpenReports.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Logs\OnlineDiagnostics') })
        Set-LauncherButtonStyle $btnOpenReports
        $diagForm.Controls.Add($btnOpenReports)

        [void]$diagForm.ShowDialog($form)
    }

    function Show-LauncherHelpPanel {
        $helpForm = New-Object System.Windows.Forms.Form
        $helpForm.Text = 'Ajuda'
        $helpForm.Size = New-Object System.Drawing.Size(620, 480)
        $helpForm.MinimumSize = New-Object System.Drawing.Size(580, 420)
        $helpForm.StartPosition = 'CenterParent'
        $helpForm.BackColor = $colorBackground
        $helpForm.ForeColor = $colorText

        $helpText = New-Object System.Windows.Forms.TextBox
        $helpText.Location = New-Object System.Drawing.Point(16, 16)
        $helpText.Size = New-Object System.Drawing.Size(570, 360)
        $helpText.Multiline = $true
        $helpText.ReadOnly = $true
        $helpText.ScrollBars = 'Vertical'
        $helpText.Text = "Como jogar`r`n`r`nJogar Offline`r`nAbre o servidor local e o client no seu computador. Nao precisa de internet.`r`n`r`nHospedar Mundo`r`nInicia seu servidor local, mostra IP, porta, jogadores conectados e gera um convite para copiar.`r`n`r`nEntrar em Mundo`r`nCole o convite recebido ou informe IP e porta manualmente. O Launcher testa a conexao antes de abrir o client.`r`n`r`nLAN e Internet`r`nNa mesma rede, use o IP local mostrado pelo host. Pela internet, pode ser necessario liberar firewall e redirecionar portas no roteador.`r`n`r`nLimitacoes`r`nO Launcher nao instala VPN, nao altera roteador e nao contorna CGNAT. Se o online falhar, o modo Offline continua funcionando."
        Set-LauncherTextStyle $helpText
        $helpForm.Controls.Add($helpText)

        $btnDocs = New-Object System.Windows.Forms.Button
        $btnDocs.Text = 'Abrir Guias'
        $btnDocs.Location = New-Object System.Drawing.Point(16, 392)
        $btnDocs.Size = New-Object System.Drawing.Size(100, 34)
        $btnDocs.Add_Click({ Start-Process explorer.exe (Join-Path (Get-TrmRoot) 'Docs') })
        Set-LauncherButtonStyle $btnDocs
        $helpForm.Controls.Add($btnDocs)

        [void]$helpForm.ShowDialog($form)
    }

    function Invoke-LauncherUpdateFromUi([bool]$PlayAfterUpdate) {
        try {
            Set-UiStatus 'Atualizacao iniciada...' 0 0 0
            $result = Invoke-TrmUpdateOrRepair -ProgressCallback ${function:Set-UiStatus}
            Refresh-VersionLabels
            Set-UiStatus ("Atualizacao concluida. Baixados: $($result.downloaded), verificados: $($result.checked), protegidos: $($result.protected)") 100 $result.averageBytesPerSecond 0
            $launcherUpdated = $false
            foreach ($action in @($result.actions)) {
                $path = ''
                if ($action.PSObject.Properties.Name -contains 'path') { $path = ([string]$action.path -replace '\\','/') }
                $actionName = ''
                if ($action.PSObject.Properties.Name -contains 'action') { $actionName = [string]$action.action }
                if ($actionName -eq 'downloaded' -and ($path -eq 'Launcher/Launcher.ps1' -or $path.StartsWith('Launcher/Modules/', [System.StringComparison]::OrdinalIgnoreCase))) {
                    $launcherUpdated = $true
                    break
                }
            }
            if ($launcherUpdated) {
                $launcherPath = Join-Path (Get-TrmRoot) 'Launcher\Launcher.ps1'
                $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$launcherPath)
                if ($PlayAfterUpdate) { $args += '-Play' }
                Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory (Get-TrmRoot) | Out-Null
                $form.Close()
                return
            }
            if ($PlayAfterUpdate) {
                Start-TrmGame -ProgressCallback ${function:Set-UiStatus}
                Set-UiStatus 'Atualizacao concluida. Cliente iniciado.' 100 0 0
            }
        } catch {
            Set-UiStatus ("Erro na atualizacao: $($_.Exception.Message)") 0 0 0
        }
    }

    function Show-LauncherNewsPanel {
        $newsForm = New-Object System.Windows.Forms.Form
        $newsForm.Text = 'Novidades'
        $newsForm.Size = New-Object System.Drawing.Size(720, 520)
        $newsForm.MinimumSize = New-Object System.Drawing.Size(640, 460)
        $newsForm.StartPosition = 'CenterParent'
        $newsForm.BackColor = $colorBackground
        $newsForm.ForeColor = $colorText

        $newsText = New-Object System.Windows.Forms.TextBox
        $newsText.Location = New-Object System.Drawing.Point(16, 16)
        $newsText.Size = New-Object System.Drawing.Size(670, 420)
        $newsText.Multiline = $true
        $newsText.ReadOnly = $true
        $newsText.ScrollBars = 'Vertical'
        Set-LauncherTextStyle $newsText
        $newsForm.Controls.Add($newsText)

        try {
            $remoteText = Get-LauncherRemoteVersionText
            $newsText.Text = Get-LauncherChangelogSection -Changelog (Get-LauncherRemoteChangelogText) -Version $remoteText
        } catch {
            $newsText.Text = "Nao foi possivel obter as novidades remotas.`r`nDetalhes: $($_.Exception.Message)"
        }
        [void]$newsForm.ShowDialog($form)
    }

    $btnPlay = New-Object System.Windows.Forms.Button
    $btnPlay.Text = 'Jogar Offline'
    $btnPlay.Location = New-Object System.Drawing.Point(22, 440)
    $btnPlay.Size = New-Object System.Drawing.Size(125, 38)
    $btnPlay.Add_Click({
        try {
            Start-TrmGame -ProgressCallback ${function:Set-UiStatus}
            Set-UiStatus 'Cliente iniciado.' 100 0 0
            Refresh-VersionLabels
        } catch { Set-UiStatus ('Erro: ' + $_.Exception.Message) 0 0 0 }
    })
    Set-LauncherButtonStyle $btnPlay
    $form.Controls.Add($btnPlay)

    $btnHostWorld = New-Object System.Windows.Forms.Button
    $btnHostWorld.Text = 'Hospedar Mundo'
    $btnHostWorld.Location = New-Object System.Drawing.Point(157, 440)
    $btnHostWorld.Size = New-Object System.Drawing.Size(135, 38)
    $btnHostWorld.Add_Click({ Show-HostAssistPanel 'host' })
    Set-LauncherButtonStyle $btnHostWorld
    $form.Controls.Add($btnHostWorld)

    $btnJoinWorld = New-Object System.Windows.Forms.Button
    $btnJoinWorld.Text = 'Entrar em Mundo'
    $btnJoinWorld.Location = New-Object System.Drawing.Point(302, 440)
    $btnJoinWorld.Size = New-Object System.Drawing.Size(135, 38)
    $btnJoinWorld.Add_Click({ Show-HostAssistPanel 'join' })
    Set-LauncherButtonStyle $btnJoinWorld
    $form.Controls.Add($btnJoinWorld)

    $btnDiagnostics = New-Object System.Windows.Forms.Button
    $btnDiagnostics.Text = 'Diagnostico'
    $btnDiagnostics.Location = New-Object System.Drawing.Point(447, 440)
    $btnDiagnostics.Size = New-Object System.Drawing.Size(105, 38)
    $btnDiagnostics.Add_Click({ Show-LauncherDiagnosticsPanel })
    Set-LauncherButtonStyle $btnDiagnostics
    $form.Controls.Add($btnDiagnostics)

    $script:BtnUpdate = New-Object System.Windows.Forms.Button
    $script:BtnUpdate.Text = 'Atualizar'
    $script:BtnUpdate.Location = New-Object System.Drawing.Point(22, 388)
    $script:BtnUpdate.Size = New-Object System.Drawing.Size(110, 38)
    $script:BtnUpdate.Add_Click({ Invoke-LauncherUpdateFromUi $false })
    Set-LauncherButtonStyle $script:BtnUpdate
    $form.Controls.Add($script:BtnUpdate)

    $script:BtnUpdatePlay = New-Object System.Windows.Forms.Button
    $script:BtnUpdatePlay.Text = 'Atualizar e Jogar'
    $script:BtnUpdatePlay.Location = New-Object System.Drawing.Point(142, 388)
    $script:BtnUpdatePlay.Size = New-Object System.Drawing.Size(145, 38)
    $script:BtnUpdatePlay.Add_Click({ Invoke-LauncherUpdateFromUi $true })
    Set-LauncherButtonStyle $script:BtnUpdatePlay
    $form.Controls.Add($script:BtnUpdatePlay)

    $script:BtnNews = New-Object System.Windows.Forms.Button
    $script:BtnNews.Text = 'Ver Novidades'
    $script:BtnNews.Location = New-Object System.Drawing.Point(297, 388)
    $script:BtnNews.Size = New-Object System.Drawing.Size(125, 38)
    $script:BtnNews.Add_Click({ Show-LauncherNewsPanel })
    Set-LauncherButtonStyle $script:BtnNews
    $form.Controls.Add($script:BtnNews)

    $btnRepairMain = New-Object System.Windows.Forms.Button
    $btnRepairMain.Text = 'Reparar Arquivos'
    $btnRepairMain.Location = New-Object System.Drawing.Point(432, 388)
    $btnRepairMain.Size = New-Object System.Drawing.Size(130, 38)
    $btnRepairMain.Add_Click({
        try {
            $r = Invoke-TrmUpdateOrRepair -ForceRepair -ProgressCallback ${function:Set-UiStatus}
            Set-UiStatus ("Reparo concluido. Baixados: $($r.downloaded), verificados: $($r.checked)") 100 $r.averageBytesPerSecond 0
            Refresh-VersionLabels
        } catch { Set-UiStatus ("Erro no reparo. O modo Offline continua disponivel. $($_.Exception.Message)") 0 0 0 }
    })
    Set-LauncherButtonStyle $btnRepairMain
    $form.Controls.Add($btnRepairMain)

    $btnConfig = New-Object System.Windows.Forms.Button
    $btnConfig.Text = 'Configuracoes'
    $btnConfig.Location = New-Object System.Drawing.Point(562, 440)
    $btnConfig.Size = New-Object System.Drawing.Size(125, 38)
    $btnConfig.Add_Click({ Show-LauncherSettingsPanel })
    Set-LauncherButtonStyle $btnConfig
    $form.Controls.Add($btnConfig)

    $btnHelp = New-Object System.Windows.Forms.Button
    $btnHelp.Text = 'Ajuda'
    $btnHelp.Location = New-Object System.Drawing.Point(697, 440)
    $btnHelp.Size = New-Object System.Drawing.Size(90, 38)
    $btnHelp.Add_Click({ Show-LauncherHelpPanel })
    Set-LauncherButtonStyle $btnHelp
    $form.Controls.Add($btnHelp)

    Refresh-VersionLabels
    Refresh-LastUpdate
    [void]$form.ShowDialog()
}

try {
    Write-TrmLog 'Launcher started'
    if ($MinimumQA) { Invoke-TrmMinimumQA | ConvertTo-Json -Depth 12; return }
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
