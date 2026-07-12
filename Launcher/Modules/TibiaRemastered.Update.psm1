Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking

function Test-TrmInternetConnection {
    param([string]$Url)
    try {
        if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
        if (Test-Path $Url) { return $true }
        $requestUrl = Resolve-TrmRequestUrl $Url
        $headers = Get-TrmRequestHeaders $Url
        Invoke-WebRequest -Uri $requestUrl -Headers $headers -UseBasicParsing -Method Head -TimeoutSec 12 | Out-Null
        return $true
    } catch {
        Write-TrmLog "Remote check failed: $($_.Exception.Message)" 'WARN'
        return $false
    }
}

function Get-TrmRemoteText {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { throw 'Remote URL is not configured.' }
    if (Test-Path $Url) { return (Get-Content -Path $Url -Raw -Encoding UTF8) }
    if ($Url -notmatch '^https?://') {
        throw "Arquivo remoto/local nao encontrado.`nEtapa: download JSON remoto`nURL: $Url`nErro completo: caminho local inexistente.`nAcao recomendada: confira Config/launcher-config.json e tente novamente."
    }
    try {
        $requestUrl = Resolve-TrmRequestUrl $Url
        $headers = Get-TrmRequestHeaders $Url
        $response = Invoke-WebRequest -Uri $requestUrl -Headers $headers -UseBasicParsing -TimeoutSec 30
        return [string]$response.Content
    } catch {
        throw "Falha ao baixar JSON remoto.`nEtapa: download JSON remoto`nURL: $Url`nErro completo: $($_.Exception.Message)`nAcao recomendada: verifique internet, GitHub Raw e tente Atualizar/Reparar novamente."
    }
}

function Get-TrmRemoteJson {
    param([string]$Url, [string]$Description = 'JSON remoto')
    Write-TrmLog "Downloading json: $Url"
    try {
        $raw = (Get-TrmRemoteText $Url).TrimStart([char]0xFEFF)
        if ($raw.StartsWith('ï»¿')) { $raw = $raw.Substring(3) }
        if ([string]::IsNullOrWhiteSpace($raw)) { throw "$Description vazio." }
        return ($raw | ConvertFrom-Json)
    } catch {
        throw "Falha ao validar $Description.`nEtapa: parse JSON remoto`nURL: $Url`nErro completo: $($_.Exception.Message)`nAcao recomendada: publique novamente version.json/manifest.json em UTF-8 JSON valido."
    }
}

function Get-TrmRequiredJsonString {
    param([object]$Json, [string]$Property, [string]$Description, [string]$Url)
    if ($null -eq $Json -or -not ($Json.PSObject.Properties.Name -contains $Property)) {
        throw "$Description invalido.`nEtapa: validacao de campo`nURL: $Url`nErro completo: campo obrigatorio '$Property' ausente.`nAcao recomendada: gere e publique novamente os arquivos de release."
    }
    $value = [string]$Json.$Property
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Description invalido.`nEtapa: validacao de campo`nURL: $Url`nErro completo: campo obrigatorio '$Property' vazio.`nAcao recomendada: gere e publique novamente os arquivos de release."
    }
    return $value
}

function ConvertTo-TrmVersionInfo {
    param([string]$Version, [string]$Channel = '')
    $raw = ([string]$Version).Trim().TrimStart([char]0xFEFF)
    $result = [ordered]@{
        raw = $raw
        valid = $false
        major = 0
        minor = 0
        patch = 0
        label = ''
        labelNumber = 0
        channel = ([string]$Channel).Trim().ToLowerInvariant()
        channelRank = -1
        normalized = ''
    }
    if ($raw -match '^(\d+)\.(\d+)\.(\d+)(?:-([A-Za-z]+)(\d*))?$') {
        $result.valid = $true
        $result.major = [int]$Matches[1]
        $result.minor = [int]$Matches[2]
        $result.patch = [int]$Matches[3]
        $result.label = ([string]$Matches[4]).ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace([string]$Matches[5])) { $result.labelNumber = [int]$Matches[5] }
    }
    if ($result.valid) {
        # A ausencia de sufixo significa release estavel. O campo channel e
        # metadado de distribuicao e nao pode rebaixar "0.1.17" para dev.
        $effective = if ([string]::IsNullOrWhiteSpace($result.label)) { 'stable' } else { $result.label }
        switch -Regex ($effective) {
            '^dev$' { $result.channelRank = 0; break }
            '^test$' { $result.channelRank = 1; break }
            '^rc$' { $result.channelRank = 2; break }
            '^stable$' { $result.channelRank = 3; break }
            default { $result.valid = $false; $result.channelRank = -1; break }
        }
        if ($result.valid) {
            $suffix = if ([string]::IsNullOrWhiteSpace($result.label)) { '' } else { '-' + $result.label + $(if ($result.labelNumber -gt 0) { [string]$result.labelNumber } else { '' }) }
            $result.normalized = '{0}.{1}.{2}{3}|{4}' -f $result.major,$result.minor,$result.patch,$suffix,$result.channel
        }
    }
    return [pscustomobject]$result
}

function Compare-TrmVersionString {
    param([string]$LeftVersion, [string]$RightVersion, [string]$LeftChannel = '', [string]$RightChannel = '')
    $left = ConvertTo-TrmVersionInfo -Version $LeftVersion -Channel $LeftChannel
    $right = ConvertTo-TrmVersionInfo -Version $RightVersion -Channel $RightChannel
    if (-not $left.valid -and -not $right.valid) { return 0 }
    if (-not $left.valid) { return -1 }
    if (-not $right.valid) { return 1 }
    foreach ($property in @('major','minor','patch','channelRank','labelNumber')) {
        if ($left.$property -lt $right.$property) { return -1 }
        if ($left.$property -gt $right.$property) { return 1 }
    }
    return [string]::Compare($left.normalized, $right.normalized, $true)
}

function Test-TrmVersionNeedsUpdate {
    param([string]$LocalVersion, [string]$RemoteVersion, [string]$LocalChannel = '', [string]$RemoteChannel = '')
    $remote = ConvertTo-TrmVersionInfo -Version $RemoteVersion -Channel $RemoteChannel
    if (-not $remote.valid) { return $false }
    $local = ConvertTo-TrmVersionInfo -Version $LocalVersion -Channel $LocalChannel
    if (-not $local.valid) { return $true }
    return ((Compare-TrmVersionString -LeftVersion $LocalVersion -LeftChannel $LocalChannel -RightVersion $RemoteVersion -RightChannel $RemoteChannel) -ne 0)
}

function New-TrmLauncherUpdateState {
    param(
        [ValidateSet('CHECKING','UPDATE_AVAILABLE','UP_TO_DATE','UPDATING','UPDATE_SUCCESS','UPDATE_ERROR','OFFLINE_AVAILABLE')]
        [string]$State,
        [string]$LocalVersion = '',
        [string]$RemoteVersion = '',
        [string]$ErrorMessage = ''
    )

    $localDisplay = if ([string]::IsNullOrWhiteSpace($LocalVersion) -or $LocalVersion -eq 'unknown' -or $LocalVersion -eq 'Versao local desconhecida') { 'Versao local desconhecida' } else { $LocalVersion }
    $remoteDisplay = if ([string]::IsNullOrWhiteSpace($RemoteVersion)) { 'verificando...' } else { $RemoteVersion }
    $statusText = ''
    $canUpdate = $false
    $canUpdateAndPlay = $false
    $canNews = $false
    $canCheckAgain = $true
    $updatePlayText = 'Atualizar e Jogar'
    $canPlayOffline = $false
    $canHostWorld = $false
    $canJoinWorld = $false
    $isBusy = $false

    switch ($State) {
        'CHECKING' {
            $remoteDisplay = 'verificando...'
            $statusText = 'Status de atualizacao: verificando...'
            $canCheckAgain = $false
            $canPlayOffline = $true
            $isBusy = $true
        }
        'UPDATE_AVAILABLE' {
            $statusText = "Status de atualizacao: Atualizacao disponivel."
            $canUpdate = $true
            $canUpdateAndPlay = $true
            $canNews = $true
            $updatePlayText = 'Atualizar e Jogar'
        }
        'UP_TO_DATE' {
            $remoteDisplay = if ([string]::IsNullOrWhiteSpace($RemoteVersion)) { 'Voce esta atualizado' } else { $RemoteVersion }
            $statusText = 'Status de atualizacao: Voce possui a versao mais recente.'
            $canUpdate = $false
            $canUpdateAndPlay = $true
            $canNews = $true
            $updatePlayText = 'Jogar'
            $canPlayOffline = $true
            $canHostWorld = $true
            $canJoinWorld = $true
        }
        'UPDATING' {
            $remoteDisplay = if ([string]::IsNullOrWhiteSpace($RemoteVersion)) { 'atualizando...' } else { $RemoteVersion }
            $statusText = 'Status de atualizacao: Atualizando...'
            $canCheckAgain = $false
            $isBusy = $true
        }
        'UPDATE_SUCCESS' {
            $remoteDisplay = if ([string]::IsNullOrWhiteSpace($RemoteVersion)) { 'Voce esta atualizado' } else { $RemoteVersion }
            $statusText = 'Status de atualizacao: Atualizacao concluida.'
            $canUpdate = $false
            $canUpdateAndPlay = $true
            $canNews = $true
            $updatePlayText = 'Jogar'
            $canPlayOffline = $true
            $canHostWorld = $true
            $canJoinWorld = $true
        }
        'UPDATE_ERROR' {
            $remoteDisplay = if ([string]::IsNullOrWhiteSpace($RemoteVersion)) { 'Nao foi possivel verificar' } else { $RemoteVersion }
            $statusText = 'Status de atualizacao: Erro na atualizacao.'
            if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) { $statusText += " $ErrorMessage" }
            $canUpdate = $true
            $canUpdateAndPlay = $true
            $updatePlayText = 'Tentar Atualizar e Jogar'
            $canPlayOffline = $true
        }
        'OFFLINE_AVAILABLE' {
            $remoteDisplay = 'Nao foi possivel verificar'
            $statusText = 'Status de atualizacao: Nao foi possivel verificar atualizacoes.'
            if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) { $statusText += " $ErrorMessage" }
            $canUpdate = $true
            $canUpdateAndPlay = $true
            $updatePlayText = 'Jogar Offline'
            $canPlayOffline = $true
            $canHostWorld = $true
            $canJoinWorld = $true
        }
    }

    return [pscustomobject]@{
        state = $State
        localVersion = $LocalVersion
        remoteVersion = $RemoteVersion
        localVersionDisplay = $localDisplay
        remoteVersionDisplay = $remoteDisplay
        statusText = $statusText
        canUpdate = $canUpdate
        canUpdateAndPlay = $canUpdateAndPlay
        canNews = $canNews
        canRepair = $true
        canCheckAgain = $canCheckAgain
        updatePlayText = $updatePlayText
        canPlayOffline = $canPlayOffline
        canHostWorld = $canHostWorld
        canJoinWorld = $canJoinWorld
        isBusy = $isBusy
        error = $ErrorMessage
    }
}

function Resolve-TrmLauncherUpdateState {
    param(
        [string]$LocalVersion,
        [string]$RemoteVersion,
        [string]$LocalChannel = '',
        [string]$RemoteChannel = '',
        [string]$ErrorMessage = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) {
        return New-TrmLauncherUpdateState -State 'OFFLINE_AVAILABLE' -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion -ErrorMessage $ErrorMessage
    }

    $remote = ConvertTo-TrmVersionInfo -Version $RemoteVersion -Channel $RemoteChannel
    if (-not $remote.valid) {
        return New-TrmLauncherUpdateState -State 'OFFLINE_AVAILABLE' -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion -ErrorMessage 'Versao remota vazia ou invalida.'
    }

    if (Test-TrmVersionNeedsUpdate -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion -LocalChannel $LocalChannel -RemoteChannel $RemoteChannel) {
        return New-TrmLauncherUpdateState -State 'UPDATE_AVAILABLE' -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion
    }

    return New-TrmLauncherUpdateState -State 'UP_TO_DATE' -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion
}

function Get-TrmLauncherVersionCheckState {
    param([string]$RemoteVersionUrl = '')
    $root = Get-TrmRoot
    $localJson = Read-TrmJsonFile -Path (Join-Path $root 'version.json') -Default $null
    $localVersion = 'unknown'
    $localChannel = ''
    if ($null -ne $localJson) {
        if ($localJson.PSObject.Properties.Name -contains 'version') { $localVersion = [string]$localJson.version }
        if ($localJson.PSObject.Properties.Name -contains 'channel') { $localChannel = [string]$localJson.channel }
    }

    [void](Write-TrmUpdateStateReport -State (New-TrmLauncherUpdateState -State 'CHECKING' -LocalVersion $localVersion) -Phase 'remote-version-check')

    try {
        $config = Get-TrmConfig
        $url = if ([string]::IsNullOrWhiteSpace($RemoteVersionUrl)) { [string]$config.remoteVersionUrl } else { $RemoteVersionUrl }
        if ([string]::IsNullOrWhiteSpace($url)) {
            $missingUrlState = New-TrmLauncherUpdateState -State 'OFFLINE_AVAILABLE' -LocalVersion $localVersion -ErrorMessage 'URL de version.json remoto nao configurada.'
            [void](Write-TrmUpdateStateReport -State $missingUrlState -Phase 'remote-version-check')
            return $missingUrlState
        }
        $remoteJson = Get-TrmRemoteJson $url 'version.json remoto'
        [void](Assert-TrmRemoteVersionJson -VersionJson $remoteJson -Url $url)
        $remoteChannel = ''
        if ($remoteJson.PSObject.Properties.Name -contains 'channel') { $remoteChannel = [string]$remoteJson.channel }
        $resolvedState = Resolve-TrmLauncherUpdateState -LocalVersion $localVersion -RemoteVersion ([string]$remoteJson.version) -LocalChannel $localChannel -RemoteChannel $remoteChannel
        [void](Write-TrmUpdateStateReport -State $resolvedState -Phase 'remote-version-check')
        return $resolvedState
    } catch {
        Write-TrmLog "Launcher version check failed: $($_.Exception.Message)" 'WARN'
        $offlineState = New-TrmLauncherUpdateState -State 'OFFLINE_AVAILABLE' -LocalVersion $localVersion -ErrorMessage $_.Exception.Message
        [void](Write-TrmUpdateStateReport -State $offlineState -Phase 'remote-version-check' -ErrorMessage $_.Exception.ToString())
        return $offlineState
    }
}

function Assert-TrmRemoteVersionJson {
    param([object]$VersionJson, [string]$Url)
    $version = Get-TrmRequiredJsonString -Json $VersionJson -Property 'version' -Description 'version.json remoto' -Url $Url
    $channel = (Get-TrmRequiredJsonString -Json $VersionJson -Property 'channel' -Description 'version.json remoto' -Url $Url).ToLowerInvariant()
    $minimumLauncherVersion = Get-TrmRequiredJsonString -Json $VersionJson -Property 'minimumLauncherVersion' -Description 'version.json remoto' -Url $Url
    if ($channel -notin @('dev','test','rc','stable')) {
        throw "version.json remoto invalido.`nEtapa: validacao de channel`nURL: $Url`nErro completo: channel '$channel' nao e dev/test/rc/stable.`nAcao recomendada: corrija version.json e publique novamente."
    }
    if (-not (ConvertTo-TrmVersionInfo -Version $minimumLauncherVersion).valid) {
        throw "version.json remoto invalido.`nEtapa: validacao de minimumLauncherVersion`nURL: $Url`nErro completo: minimumLauncherVersion '$minimumLauncherVersion' invalida.`nAcao recomendada: corrija version.json e publique novamente."
    }
    $parsed = ConvertTo-TrmVersionInfo -Version $version -Channel ([string]$VersionJson.channel)
    if (-not $parsed.valid) {
        throw "version.json remoto invalido.`nEtapa: validacao de version`nURL: $Url`nErro completo: version '$version' nao segue major.minor.patch[-dev|-test|-rcN|-stable].`nAcao recomendada: corrija version.json e publique novamente."
    }
    return $true
}

function Assert-TrmRemoteManifestJson {
    param([object]$Manifest, [string]$Url, [string]$ExpectedVersion = '')
    $manifestVersion = Get-TrmRequiredJsonString -Json $Manifest -Property 'version' -Description 'manifest.json remoto' -Url $Url
    if (-not ($Manifest.PSObject.Properties.Name -contains 'files')) {
        throw "manifest.json remoto invalido.`nEtapa: validacao de manifest`nURL: $Url`nErro completo: propriedade files ausente.`nAcao recomendada: gere manifest.json por ultimo e publique novamente."
    }
    if (@($Manifest.files).Count -le 0) {
        throw "manifest.json remoto invalido.`nEtapa: validacao de manifest`nURL: $Url`nErro completo: lista files vazia.`nAcao recomendada: gere manifest.json por ultimo e publique novamente."
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedVersion) -and $manifestVersion -ne $ExpectedVersion) {
        throw "manifest.json remoto incompativel.`nEtapa: validacao de versao do manifest`nURL: $Url`nErro completo: manifest=$manifestVersion version.json=$ExpectedVersion.`nAcao recomendada: gere manifest.json por ultimo para a mesma versao e publique novamente."
    }
    foreach ($file in @($Manifest.files)) {
        [void](Get-TrmRequiredJsonString -Json $file -Property 'path' -Description 'entrada do manifest remoto' -Url $Url)
        $hash = Get-TrmRequiredJsonString -Json $file -Property 'sha256' -Description 'entrada do manifest remoto' -Url $Url
        if ($hash -notmatch '^[a-fA-F0-9]{64}$') {
            throw "manifest.json remoto invalido.`nEtapa: validacao de SHA256`nArquivo: $($file.path)`nURL: $Url`nErro completo: sha256 invalido '$hash'.`nAcao recomendada: gere manifest.json novamente."
        }
        [void](Get-TrmRequiredJsonString -Json $file -Property 'url' -Description 'entrada do manifest remoto' -Url $Url)
    }
    return $true
}

function New-TrmUpdateBackup {
    $root = Get-TrmRoot
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $dir = Join-Path $root (Join-Path 'Backup' "update_$stamp")
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-TrmLog "Update backup created: $dir"
    return $dir
}

function Backup-TrmFileForUpdate {
    param([string]$RelativePath, [string]$BackupRoot)
    $root = Get-TrmRoot
    $source = Join-Path $root $RelativePath
    if (-not (Test-Path $source)) { return }
    $dest = Join-Path $BackupRoot $RelativePath
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item -Path $source -Destination $dest -Force
    Write-TrmLog "Update backup file: $RelativePath -> $dest"
}

function Restore-TrmBackup {
    param([string]$BackupRoot)
    $root = Get-TrmRoot
    if (-not (Test-Path $BackupRoot)) { return }
    Get-ChildItem -Path $BackupRoot -File -Recurse | ForEach-Object {
        $relative = $_.FullName.Substring($BackupRoot.Length).TrimStart('\','/')
        $dest = Join-Path $root $relative
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
        Copy-Item -Path $_.FullName -Destination $dest -Force
    }
}

function Copy-TrmRemoteFile {
    param([string]$Url, [string]$Destination)
    if (Test-Path $Url) {
        Copy-Item -Path $Url -Destination $Destination -Force
        return
    }
    $requestUrl = Resolve-TrmRequestUrl $Url
    $headers = Get-TrmRequestHeaders $Url
    Invoke-WebRequest -Uri $requestUrl -Headers $headers -OutFile $Destination -UseBasicParsing -TimeoutSec 120
}

function Save-TrmUpdateReport {
    param([object]$Report)
    $root = Get-TrmRoot
    $config = Get-TrmConfig
    $relative = 'Reports\last-update.json'
    if ($config.PSObject.Properties.Name -contains 'lastUpdateReport' -and -not [string]::IsNullOrWhiteSpace([string]$config.lastUpdateReport)) {
        $relative = [string]$config.lastUpdateReport
    }
    Save-TrmJsonFile -Path (Join-Path $root $relative) -Value $Report
}

function Get-TrmLastUpdateReport {
    $root = Get-TrmRoot
    $config = Get-TrmConfig
    $relative = 'Reports\last-update.json'
    if ($config.PSObject.Properties.Name -contains 'lastUpdateReport') { $relative = [string]$config.lastUpdateReport }
    return Read-TrmJsonFile -Path (Join-Path $root $relative) -Default $null
}

function Get-TrmUpdateTestDirectory {
    $path = Join-Path (Get-TrmRoot) 'Logs\UpdateTests'
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Write-TrmUpdateStateReport {
    param(
        [object]$State,
        [string]$Phase = 'state-transition',
        [string]$Trigger = '',
        [string]$ErrorMessage = ''
    )
    try {
        $config = Get-TrmConfig
        $path = Join-Path (Get-TrmUpdateTestDirectory) ('update-test-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
        $stateName = if ($State -and ($State.PSObject.Properties.Name -contains 'state')) { [string]$State.state } else { '' }
        $localVersion = if ($State -and ($State.PSObject.Properties.Name -contains 'localVersion')) { [string]$State.localVersion } else { '' }
        $remoteVersion = if ($State -and ($State.PSObject.Properties.Name -contains 'remoteVersion')) { [string]$State.remoteVersion } else { '' }
        if ([string]::IsNullOrWhiteSpace($ErrorMessage) -and $State -and ($State.PSObject.Properties.Name -contains 'error')) {
            $ErrorMessage = [string]$State.error
        }
        $report = [pscustomobject]@{
            generatedAt = (Get-Date).ToString('s')
            phase = $Phase
            trigger = $Trigger
            updaterState = $stateName
            localVersion = $localVersion
            remoteVersion = $remoteVersion
            remoteVersionUrl = [string]$config.remoteVersionUrl
            remoteManifestUrl = [string]$config.remoteManifestUrl
            error = $ErrorMessage
            reportPath = $path
        }
        Save-TrmJsonFile -Path $path -Value $report
        return $report
    } catch {
        Write-TrmLog "Falha ao salvar log detalhado de update: $($_.Exception.Message)" 'WARN'
        return $null
    }
}

function Sync-TrmFromManifest {
    param(
        [object]$Manifest,
        [object]$RemoteVersion,
        [switch]$ForceRepair,
        [scriptblock]$ProgressCallback
    )
    if ($null -eq $Manifest) { throw 'Remote manifest is empty or invalid.' }
    if (-not ($Manifest.PSObject.Properties.Name -contains 'files')) { throw 'Remote manifest is invalid: missing files property.' }

    $root = Get-TrmRoot
    $files = @($Manifest.files)
    $backup = New-TrmUpdateBackup
    $checked = 0; $downloaded = 0; $skipped = 0; $protected = 0; $bytesDownloaded = 0
    $started = Get-Date
    $actions = @()

    try {
        foreach ($file in $files) {
            $checked++
            $relative = ([string]$file.path -replace '\\','/').TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($relative)) { throw 'Manifest contains file without path.' }
            if ($ProgressCallback) { & $ProgressCallback "Verificando $relative" (($checked / [Math]::Max(1, $files.Count)) * 100) 0 0 }
            Write-TrmLog "Update checking file: $relative"

            if (Test-TrmProtectedPath $relative) {
                $protected++
                $actions += [pscustomobject]@{path=$relative; action='protected'; reason='protected path'}
                Write-TrmLog "Update skipped protected file: $relative"
                continue
            }

            $target = Join-Path $root $relative
            $localHash = Get-TrmSha256 $target
            $remoteHash = ([string]$file.sha256).ToLowerInvariant()
            if ($localHash -eq $remoteHash -and -not $ForceRepair) {
                $skipped++
                $actions += [pscustomobject]@{path=$relative; action='current'; reason='hash match'}
                Write-TrmLog "Update skipped current file: $relative"
                continue
            }
            if ($localHash -eq $remoteHash -and $ForceRepair) {
                $skipped++
                $actions += [pscustomobject]@{path=$relative; action='verified'; reason='repair hash match'}
                Write-TrmLog "Update verified current file during repair: $relative"
                continue
            }

            if ([string]::IsNullOrWhiteSpace([string]$file.url)) { throw "No download URL for $relative" }
            if (Test-Path $target) { Backup-TrmFileForUpdate -RelativePath $relative -BackupRoot $backup }
            $targetDir = Split-Path -Parent $target
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
            $tmp = $target + '.download'
            if (Test-Path $tmp) { Remove-Item -Path $tmp -Force }

            $remaining = 0
            if ($files.Count -gt $checked) {
                $remaining = (@($files | Select-Object -Skip $checked | ForEach-Object { [int64]$_.size }) | Measure-Object -Sum).Sum
            }
            if ($ProgressCallback) { & $ProgressCallback "Baixando $relative" (($checked / [Math]::Max(1, $files.Count)) * 100) 0 $remaining }
            $downloadUrl = [string]$file.url
            Write-TrmLog "Update downloading file: $relative from $downloadUrl"
            try {
                Copy-TrmRemoteFile -Url $downloadUrl -Destination $tmp
            } catch {
                $statusCode = ''
                if ($_.Exception.Response -and $_.Exception.Response.StatusCode) { $statusCode = [int]$_.Exception.Response.StatusCode }
                $statusText = if ([string]::IsNullOrWhiteSpace($statusCode)) { $_.Exception.Message } else { "HTTP $statusCode" }
                $message = "Falha no download da atualizacao.`nArquivo: $relative`nURL: $downloadUrl`nEtapa: download do arquivo`nErro: $statusText`nPossivel causa: o arquivo esta no manifest, mas nao existe no GitHub Raw, foi ignorado pelo .gitignore, foi removido da branch main ou deveria ser distribuido pelo Player Package/Release.`nAcao: depois da correcao publicada, execute Atualizar ou Reparar novamente."
                Write-TrmLog (($message -replace "`r?`n", ' | ')) 'ERROR'
                throw $message
            }
            $hash = Get-TrmSha256 $tmp
            if ($hash -ne $remoteHash) {
                Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
                Write-TrmLog "Update hash mismatch for $relative expected=$remoteHash actual=$hash" 'ERROR'
                throw "Hash mismatch for $relative. expected=$remoteHash actual=$hash"
            }
            Move-Item -Path $tmp -Destination $target -Force
            $downloaded++
            $bytesDownloaded += [int64]$file.size
            $actions += [pscustomobject]@{path=$relative; action='downloaded'; reason='hash mismatch or missing'}
            Write-TrmLog "Update downloaded file: $relative"
            if ($ProgressCallback) {
                $elapsedNow = [Math]::Max(0.1, ((Get-Date) - $started).TotalSeconds)
                $currentSpeed = [int64]($bytesDownloaded / $elapsedNow)
                & $ProgressCallback "Atualizado e validado: $relative" (($checked / [Math]::Max(1, $files.Count)) * 100) $currentSpeed $remaining
            }
        }

        $manifestVersion = '0.0.0'
        if ($Manifest.PSObject.Properties.Name -contains 'version') { $manifestVersion = [string]$Manifest.version }
        $remoteVersionString = $manifestVersion
        if ($null -ne $RemoteVersion -and ($RemoteVersion.PSObject.Properties.Name -contains 'version')) {
            $remoteVersionString = [string]$RemoteVersion.version
        }
        if ($null -ne $RemoteVersion) {
            Save-TrmJsonFile -Path (Join-Path $root 'version.json') -Value $RemoteVersion
        } else {
            Save-TrmJsonFile -Path (Join-Path $root 'version.json') -Value ([pscustomobject]@{
                name = 'TibiaRemastered'
                version = $manifestVersion
                channel = 'dev'
                updatedAt = (Get-Date).ToString('s')
            })
        }
        $elapsed = [Math]::Max(0.1, ((Get-Date) - $started).TotalSeconds)
        $report = [pscustomobject]@{
            status = 'success'
            remoteVersion = $remoteVersionString
            startedAt = $started.ToString('s')
            finishedAt = (Get-Date).ToString('s')
            checked = $checked
            downloaded = $downloaded
            skipped = $skipped
            protected = $protected
            bytesDownloaded = $bytesDownloaded
            averageBytesPerSecond = [int64]($bytesDownloaded / $elapsed)
            backup = $backup
            actions = $actions
        }
        Save-TrmUpdateReport $report
        Write-TrmLog "Update finished successfully. checked=$checked downloaded=$downloaded skipped=$skipped protected=$protected backup=$backup"
        return $report
    } catch {
        Write-TrmLog "Update failed, restoring backup $backup : $($_.Exception.Message)" 'ERROR'
        Restore-TrmBackup -BackupRoot $backup
        $report = [pscustomobject]@{
            status = 'failed'
            remoteVersion = $(if ($null -ne $RemoteVersion -and ($RemoteVersion.PSObject.Properties.Name -contains 'version')) { [string]$RemoteVersion.version } else { '' })
            finishedAt = (Get-Date).ToString('s')
            checked = $checked
            downloaded = $downloaded
            skipped = $skipped
            protected = $protected
            backup = $backup
            error = $_.Exception.Message
            actions = $actions
        }
        Save-TrmUpdateReport $report
        throw
    }
}

function Invoke-TrmUpdateOrRepair {
    param([switch]$ForceRepair, [scriptblock]$ProgressCallback, [string]$Trigger = 'manual')
    Ensure-TrmProjectStructure
    $config = Get-TrmConfig
    $localVersion = Get-TrmLocalVersionForUpdate
    $updatingState = New-TrmLauncherUpdateState -State 'UPDATING' -LocalVersion $localVersion
    [void](Write-TrmUpdateStateReport -State $updatingState -Phase 'manifest-update' -Trigger $Trigger)
    try {
        if ([string]::IsNullOrWhiteSpace([string]$config.remoteVersionUrl)) {
            throw 'URL de version.json remoto nao configurada em Config/launcher-config.json.'
        }
        if ([string]::IsNullOrWhiteSpace([string]$config.remoteManifestUrl)) {
            throw 'URL de manifest.json remoto nao configurada em Config/launcher-config.json.'
        }
        $remoteVersion = Get-TrmRemoteJson $config.remoteVersionUrl 'version.json remoto'
        [void](Assert-TrmRemoteVersionJson -VersionJson $remoteVersion -Url ([string]$config.remoteVersionUrl))
        $manifest = Get-TrmRemoteJson $config.remoteManifestUrl 'manifest.json remoto'
        [void](Assert-TrmRemoteManifestJson -Manifest $manifest -Url ([string]$config.remoteManifestUrl) -ExpectedVersion ([string]$remoteVersion.version))
        if ($ProgressCallback -and $remoteVersion -and ($remoteVersion.PSObject.Properties.Name -contains 'version')) {
            & $ProgressCallback ("Versao disponivel: " + $remoteVersion.version) 0 0 0
        }
        $result = Sync-TrmFromManifest -Manifest $manifest -RemoteVersion $remoteVersion -ForceRepair:$ForceRepair -ProgressCallback $ProgressCallback
        $successState = New-TrmLauncherUpdateState -State 'UPDATE_SUCCESS' -LocalVersion ([string]$remoteVersion.version) -RemoteVersion ([string]$remoteVersion.version)
        [void](Write-TrmUpdateStateReport -State $successState -Phase 'manifest-update' -Trigger $Trigger)
        return $result
    } catch {
        $errorState = New-TrmLauncherUpdateState -State 'UPDATE_ERROR' -LocalVersion (Get-TrmLocalVersionForUpdate) -ErrorMessage $_.Exception.Message
        [void](Write-TrmUpdateStateReport -State $errorState -Phase 'manifest-update' -Trigger $Trigger -ErrorMessage $_.Exception.ToString())
        throw
    }
}

function Get-TrmLocalVersionForUpdate {
    $localJson = Read-TrmJsonFile -Path (Join-Path (Get-TrmRoot) 'version.json') -Default $null
    if ($null -eq $localJson -or -not ($localJson.PSObject.Properties.Name -contains 'version')) { return 'unknown' }
    $value = [string]$localJson.version
    if ([string]::IsNullOrWhiteSpace($value)) { return 'unknown' }
    return $value
}

function Invoke-TrmAutomaticLauncherUpdate {
    param(
        [scriptblock]$ProgressCallback,
        [scriptblock]$StateCallback,
        [string]$Trigger = 'launcher-start'
    )
    $sequence = @()
    $checkingState = New-TrmLauncherUpdateState -State 'CHECKING' -LocalVersion (Get-TrmLocalVersionForUpdate)
    $sequence += $checkingState.state
    if ($StateCallback) { & $StateCallback $checkingState }

    $checkedState = Get-TrmLauncherVersionCheckState
    $sequence += $checkedState.state
    if ($StateCallback) { & $StateCallback $checkedState }
    if ($checkedState.state -ne 'UPDATE_AVAILABLE') {
        return [pscustomobject]@{
            initialState = $checkedState
            finalState = $checkedState
            updateReport = $null
            stateSequence = $sequence
            updateAttempted = $false
            restartRequired = $false
        }
    }

    $updatingState = New-TrmLauncherUpdateState -State 'UPDATING' -LocalVersion ([string]$checkedState.localVersion) -RemoteVersion ([string]$checkedState.remoteVersion)
    $sequence += $updatingState.state
    if ($StateCallback) { & $StateCallback $updatingState }
    try {
        $updateReport = Invoke-TrmUpdateOrRepair -ProgressCallback $ProgressCallback -Trigger $Trigger
        $postCheck = Get-TrmLauncherVersionCheckState
        $localAfter = Get-TrmLocalVersionForUpdate
        if ($postCheck.state -ne 'UP_TO_DATE' -and $localAfter -ne [string]$updateReport.remoteVersion) {
            throw "Atualizacao aplicada, mas a verificacao final nao confirmou a versao. local=$localAfter remoto=$($updateReport.remoteVersion) estado=$($postCheck.state)"
        }
        $successRemote = if (-not [string]::IsNullOrWhiteSpace([string]$postCheck.remoteVersion)) { [string]$postCheck.remoteVersion } else { [string]$updateReport.remoteVersion }
        $successState = New-TrmLauncherUpdateState -State 'UPDATE_SUCCESS' -LocalVersion $localAfter -RemoteVersion $successRemote
        $sequence += $successState.state
        if ($StateCallback) { & $StateCallback $successState }
        [void](Write-TrmUpdateStateReport -State $successState -Phase 'automatic-update-complete' -Trigger $Trigger)
        return [pscustomobject]@{
            initialState = $checkedState
            finalState = $successState
            postCheckState = $postCheck
            updateReport = $updateReport
            stateSequence = $sequence
            updateAttempted = $true
            restartRequired = ([int]$updateReport.downloaded -gt 0)
        }
    } catch {
        $errorState = New-TrmLauncherUpdateState -State 'UPDATE_ERROR' -LocalVersion (Get-TrmLocalVersionForUpdate) -RemoteVersion ([string]$checkedState.remoteVersion) -ErrorMessage $_.Exception.Message
        $sequence += $errorState.state
        if ($StateCallback) { & $StateCallback $errorState }
        [void](Write-TrmUpdateStateReport -State $errorState -Phase 'automatic-update-complete' -Trigger $Trigger -ErrorMessage $_.Exception.ToString())
        return [pscustomobject]@{
            initialState = $checkedState
            finalState = $errorState
            updateReport = $null
            stateSequence = $sequence
            updateAttempted = $true
            restartRequired = $false
            error = $_.Exception.ToString()
        }
    }
}

Export-ModuleMember -Function *-Trm*
