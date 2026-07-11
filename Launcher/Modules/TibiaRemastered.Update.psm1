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
    } elseif ($raw -match '^(\d+)\.(\d+)\.(\d+)$') {
        $result.valid = $true
        $result.major = [int]$Matches[1]
        $result.minor = [int]$Matches[2]
        $result.patch = [int]$Matches[3]
    }
    if ($result.valid) {
        $effective = $result.label
        if ([string]::IsNullOrWhiteSpace($effective)) {
            if (-not [string]::IsNullOrWhiteSpace($result.channel)) { $effective = $result.channel } else { $effective = 'stable' }
        }
        switch -Regex ($effective) {
            '^dev$' { $result.channelRank = 0; break }
            '^test$' { $result.channelRank = 1; break }
            '^rc$' { $result.channelRank = 2; break }
            '^stable$' { $result.channelRank = 3; break }
            default { $result.channelRank = -1; break }
        }
        $suffix = if ([string]::IsNullOrWhiteSpace($result.label)) { '' } else { '-' + $result.label + $(if ($result.labelNumber -gt 0) { [string]$result.labelNumber } else { '' }) }
        $result.normalized = '{0}.{1}.{2}{3}|{4}' -f $result.major,$result.minor,$result.patch,$suffix,$result.channel
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

function Assert-TrmRemoteVersionJson {
    param([object]$VersionJson, [string]$Url)
    $version = Get-TrmRequiredJsonString -Json $VersionJson -Property 'version' -Description 'version.json remoto' -Url $Url
    [void](Get-TrmRequiredJsonString -Json $VersionJson -Property 'channel' -Description 'version.json remoto' -Url $Url)
    [void](Get-TrmRequiredJsonString -Json $VersionJson -Property 'minimumLauncherVersion' -Description 'version.json remoto' -Url $Url)
    $parsed = ConvertTo-TrmVersionInfo -Version $version -Channel ([string]$VersionJson.channel)
    if (-not $parsed.valid) {
        throw "version.json remoto invalido.`nEtapa: validacao de version`nURL: $Url`nErro completo: version '$version' nao segue major.minor.patch[-dev|-test|-rcN].`nAcao recomendada: corrija version.json e publique novamente."
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
        }

        $manifestVersion = '0.0.0'
        if ($Manifest.PSObject.Properties.Name -contains 'version') { $manifestVersion = [string]$Manifest.version }
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
    param([switch]$ForceRepair, [scriptblock]$ProgressCallback)
    Ensure-TrmProjectStructure
    $config = Get-TrmConfig
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
    return Sync-TrmFromManifest -Manifest $manifest -RemoteVersion $remoteVersion -ForceRepair:$ForceRepair -ProgressCallback $ProgressCallback
}

Export-ModuleMember -Function *-Trm*
