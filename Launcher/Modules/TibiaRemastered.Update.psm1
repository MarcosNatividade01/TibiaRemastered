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
    $requestUrl = Resolve-TrmRequestUrl $Url
    $headers = Get-TrmRequestHeaders $Url
    $response = Invoke-WebRequest -Uri $requestUrl -Headers $headers -UseBasicParsing -TimeoutSec 30
    return [string]$response.Content
}

function Get-TrmRemoteJson {
    param([string]$Url)
    Write-TrmLog "Downloading json: $Url"
    $raw = (Get-TrmRemoteText $Url).TrimStart([char]0xFEFF)
    if ($raw.StartsWith('ï»¿')) { $raw = $raw.Substring(3) }
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Remote JSON is empty: $Url" }
    return ($raw | ConvertFrom-Json)
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
    $headers = Get-TrmRequestHeaders $Url
    Invoke-WebRequest -Uri $Url -Headers $headers -OutFile $Destination -UseBasicParsing -TimeoutSec 120
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
            Write-TrmLog "Update downloading file: $relative from $($file.url)"
            Copy-TrmRemoteFile -Url ([string]$file.url) -Destination $tmp
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
        Save-TrmJsonFile -Path (Join-Path $root 'version.json') -Value ([pscustomobject]@{
            name = 'TibiaRemastered'
            version = $manifestVersion
            channel = 'dev'
            updatedAt = (Get-Date).ToString('s')
        })
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
    if (-not (Test-TrmInternetConnection $config.remoteManifestUrl)) {
        throw 'Nao foi possivel acessar o manifest remoto. Configure Config/launcher-config.json ou verifique a internet.'
    }
    $remoteVersion = if ($config.remoteVersionUrl) { Get-TrmRemoteJson $config.remoteVersionUrl } else { $null }
    $manifest = Get-TrmRemoteJson $config.remoteManifestUrl
    if ($ProgressCallback -and $remoteVersion -and ($remoteVersion.PSObject.Properties.Name -contains 'version')) {
        & $ProgressCallback ("Versao disponivel: " + $remoteVersion.version) 0 0 0
    }
    return Sync-TrmFromManifest -Manifest $manifest -ForceRepair:$ForceRepair -ProgressCallback $ProgressCallback
}

Export-ModuleMember -Function *-Trm*
