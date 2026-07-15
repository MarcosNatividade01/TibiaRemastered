Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

function New-TrmValidationIssue {
    param([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '')
    return [pscustomobject]@{severity=$Severity; code=$Code; message=$Message; path=$Path}
}

function Test-TrmValidationBinaryBytes {
    param([byte[]]$Bytes)
    $limit = [Math]::Min($Bytes.Length, 8192)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Bytes[$i] -eq 0) { return $true }
    }
    return $false
}

function ConvertTo-TrmPublishedBytes {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (Test-TrmValidationBinaryBytes $bytes) {
        Write-Output -NoEnumerate $bytes
        return
    }

    $stream = New-Object System.IO.MemoryStream
    try {
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($bytes[$i] -eq 13 -and ($i + 1) -lt $bytes.Length -and $bytes[$i + 1] -eq 10) {
                $stream.WriteByte(10)
                $i++
            } else {
                $stream.WriteByte($bytes[$i])
            }
        }
        Write-Output -NoEnumerate $stream.ToArray()
        return
    } finally {
        $stream.Dispose()
    }
}

function Get-TrmPublishedSha256 {
    param([string]$Path)
    $bytes = ConvertTo-TrmPublishedBytes $Path
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Test-TrmValidationIgnoredPath {
    param([string]$Path)
    $normalized = ($Path -replace '\\','/')
    return (
        $normalized -match '/(\.git|tmp|Release|Reports|Backup|Backups|Logs|UserData|Upstream|UpstreamTesting)/' -or
        $normalized -match '/Database_Template/mysql/'
    )
}

function Test-TrmJsonFiles {
    param([string]$Root)
    $issues = @()
    Get-ChildItem -Path $Root -Filter *.json -File -Recurse | ForEach-Object {
        $file = $_
        if (Test-TrmValidationIgnoredPath $file.FullName) { return }
        try { Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
        catch { $issues += New-TrmValidationIssue 'error' 'json.invalid' $_.Exception.Message (ConvertTo-TrmRelativePath $Root $file.FullName) }
    }
    return $issues
}

function Test-TrmXmlFiles {
    param([string]$Root)
    $issues = @()
    Get-ChildItem -Path $Root -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_
        if (Test-TrmValidationIgnoredPath $file.FullName) { return }
        try { [xml](Get-Content -Path $file.FullName -Raw -Encoding UTF8) | Out-Null }
        catch { $issues += New-TrmValidationIssue 'error' 'xml.invalid' $_.Exception.Message (ConvertTo-TrmRelativePath $Root $file.FullName) }
    }
    return $issues
}

function Test-TrmLuaFiles {
    param([string]$Root)
    $issues = @()
    $lua = Get-Command lua -ErrorAction SilentlyContinue
    $luac = Get-Command luac -ErrorAction SilentlyContinue
    $checker = if ($luac) { $luac.Source } elseif ($lua) { $lua.Source } else { $null }
    $files = @(Get-ChildItem -Path $Root -Filter *.lua -File -Recurse -ErrorAction SilentlyContinue | Where-Object { -not (Test-TrmValidationIgnoredPath $_.FullName) })
    if ($files.Count -gt 0 -and -not $checker) {
        return @(New-TrmValidationIssue 'warning' 'lua.checker.missing' 'Lua files exist, but lua/luac was not found in PATH.')
    }
    foreach ($file in $files) {
        $args = if ($luac) { @('-p', $file.FullName) } else { @('-e', "assert(loadfile([[$($file.FullName)]]))") }
        $p = Start-Process -FilePath $checker -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardError "$($file.FullName).luaerr" -RedirectStandardOutput "$($file.FullName).luaout"
        if ($p.ExitCode -ne 0) {
            $err = Get-Content "$($file.FullName).luaerr" -Raw -ErrorAction SilentlyContinue
            $issues += New-TrmValidationIssue 'error' 'lua.invalid' $err (ConvertTo-TrmRelativePath $Root $file.FullName)
        }
        Remove-Item "$($file.FullName).luaerr","$($file.FullName).luaout" -Force -ErrorAction SilentlyContinue
    }
    return $issues
}

function Test-TrmProjectIntegrity {
    param([string]$Root)
    $issues = @()
    $requiredDirs = @(
        'Client','Server','Launcher','Launcher/Modules','Docs','Scripts','Tools',
        'Database_Template','UserData','Logs','Backup'
    )
    foreach ($relativeDir in $requiredDirs) {
        if (-not (Test-Path (Join-Path $Root $relativeDir))) {
            $issues += New-TrmValidationIssue 'error' 'required.dir.missing' "Required directory is missing: $relativeDir" $relativeDir
        }
    }
    $required = @(
        'README.md','PROJECT_GUIDELINES.md','CHANGELOG.md','ROADMAP.md',
        'version.json','manifest.json','Config/launcher-config.json',
        'Launcher/Launcher.ps1','Launcher/Modules/TibiaRemastered.Core.psm1',
        'Launcher/Modules/TibiaRemastered.Update.psm1','Launcher/Modules/TibiaRemastered.Runtime.psm1',
        'Launcher/Modules/TibiaRemastered.Validation.psm1'
    )
    foreach ($relative in $required) {
        if (-not (Test-Path (Join-Path $Root $relative))) {
            $issues += New-TrmValidationIssue 'error' 'required.missing' "Required file is missing: $relative" $relative
        }
    }
    $manifest = Read-TrmJsonFile -Path (Join-Path $Root 'manifest.json') -Default $null
    if ($null -ne $manifest -and $manifest.PSObject.Properties.Name -contains 'files') {
        $seen = @{}
        foreach ($entry in @($manifest.files)) {
            $path = ([string]$entry.path -replace '\\','/').TrimStart('/')
            if ($seen.ContainsKey($path.ToLowerInvariant())) {
                $issues += New-TrmValidationIssue 'error' 'manifest.duplicate' "Duplicate manifest entry: $path" $path
            }
            $seen[$path.ToLowerInvariant()] = $true
            if (Test-TrmProtectedPath $path) {
                $issues += New-TrmValidationIssue 'error' 'manifest.protected' "Protected file must not be distributed: $path" $path
            }
            $full = Join-Path $Root $path
            if (-not (Test-Path $full)) {
                $issues += New-TrmValidationIssue 'error' 'manifest.missing' "Manifest file is absent locally: $path" $path
                continue
            }
            $hash = Get-TrmPublishedSha256 $full
            if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) {
                $issues += New-TrmValidationIssue 'error' 'manifest.hash' "Manifest hash mismatch for $path" $path
            }
        }
    }
    return $issues
}

function Invoke-TrmSelfTest {
    Ensure-TrmProjectStructure
    $root = Get-TrmRoot
    $config = Get-TrmConfig
    $hash = Get-TrmSha256 (Join-Path $root 'Launcher\Launcher.ps1')
    $checks = [ordered]@{
        RootExists = (Test-Path $root)
        ConfigExists = (Test-Path (Join-Path $root 'Config\launcher-config.json'))
        VersionExists = (Test-Path (Join-Path $root 'version.json'))
        ManifestExists = (Test-Path (Join-Path $root 'manifest.json'))
        UserDataProtected = (Test-TrmProtectedPath 'UserData/Database/test.db')
        HashWorks = (-not [string]::IsNullOrWhiteSpace($hash))
        ServerPathConfigured = (-not [string]::IsNullOrWhiteSpace([string]$config.serverExe))
        ClientPathConfigured = (-not [string]::IsNullOrWhiteSpace([string]$config.clientExe))
    }
    $checks.GetEnumerator() | ForEach-Object { '{0}: {1}' -f $_.Key, $_.Value }
    if ($checks.Values -contains $false) { exit 1 }
}

function Invoke-TrmPrePublishValidation {
    param([switch]$StrictRuntime)
    $root = Get-TrmRoot
    Ensure-TrmProjectStructure
    $issues = @()
    $issues += Test-TrmProjectIntegrity -Root $root
    $issues += Test-TrmJsonFiles -Root $root
    $issues += Test-TrmXmlFiles -Root $root
    $issues += Test-TrmLuaFiles -Root $root

    $config = Get-TrmConfig
    if ($StrictRuntime) {
        if (-not (Test-Path ([string]$config.serverExe))) { $issues += New-TrmValidationIssue 'error' 'runtime.server.missing' "Server exe not found: $($config.serverExe)" }
        if (-not (Test-Path ([string]$config.clientExe))) { $issues += New-TrmValidationIssue 'error' 'runtime.client.missing' "Client exe not found: $($config.clientExe)" }
        if (-not (Test-Path ([string]$config.databaseExe))) { $issues += New-TrmValidationIssue 'error' 'runtime.database.missing' "Database exe not found: $($config.databaseExe)" }
        if (-not (Test-Path ([string]$config.databaseSeedSql))) { $issues += New-TrmValidationIssue 'error' 'runtime.database.seed.missing' "Database seed SQL not found: $($config.databaseSeedSql)" }
    } else {
        if (-not (Test-Path ([string]$config.serverExe))) { $issues += New-TrmValidationIssue 'warning' 'runtime.server.missing' "Server exe not found: $($config.serverExe)" }
        if (-not (Test-Path ([string]$config.clientExe))) { $issues += New-TrmValidationIssue 'warning' 'runtime.client.missing' "Client exe not found: $($config.clientExe)" }
        if (-not (Test-Path ([string]$config.databaseExe))) { $issues += New-TrmValidationIssue 'warning' 'runtime.database.missing' "Database exe not found: $($config.databaseExe)" }
        if (-not (Test-Path ([string]$config.databaseSeedSql))) { $issues += New-TrmValidationIssue 'warning' 'runtime.database.seed.missing' "Database seed SQL not found: $($config.databaseSeedSql)" }
    }

    $report = [pscustomobject]@{
        generatedAt = (Get-Date).ToString('s')
        status = if (@($issues | Where-Object severity -eq 'error').Count -gt 0) { 'failed' } else { 'passed' }
        errors = @($issues | Where-Object severity -eq 'error').Count
        warnings = @($issues | Where-Object severity -eq 'warning').Count
        issues = $issues
    }
    Save-TrmJsonFile -Path (Join-Path $root 'Reports\prepublish-report.json') -Value $report
    return $report
}

function Invoke-TrmMinimumQA {
    $root = Get-TrmRoot
    Ensure-TrmProjectStructure
    $config = Get-TrmConfig
    $checks = New-Object System.Collections.ArrayList

    function Add-QaCheck([string]$Name, [bool]$Passed, [string]$Details) {
        [void]$checks.Add([pscustomobject]@{name=$Name; passed=$Passed; details=$Details})
    }

    Add-QaCheck 'Launcher abre' (Test-Path (Join-Path $root 'Launcher\Launcher.ps1')) 'Launcher.ps1 encontrado.'
    Add-QaCheck 'Runtime oficial existe' ((Test-Path (Join-Path $root ([string]$config.clientExe))) -and (Test-Path (Join-Path $root ([string]$config.serverExe))) -and (Test-Path (Join-Path $root ([string]$config.databaseExe)))) 'Client, Server e Database_Template configurados.'
    Add-QaCheck 'Client existe' (Test-Path (Join-Path $root 'Client')) 'Diretorio Client/.'
    Add-QaCheck 'Server existe' (Test-Path (Join-Path $root 'Server')) 'Diretorio Server/.'
    Add-QaCheck 'Database_Template existe' (Test-Path (Join-Path $root 'Database_Template')) 'Diretorio Database_Template/.'
    Add-QaCheck 'UserData protegido' (Test-TrmProtectedPath 'UserData/Database/test.db') 'UserData continua protegido contra update/manifest.'
    Add-QaCheck 'Feature flags carregam' (Test-Path (Join-Path $root 'Modules\Remastered\Config\features.lua')) 'Arquivo de feature flags existe.'
    $coreLog = Join-Path $root 'Logs\remastered-core.log'
    $critical = $false
    if (Test-Path $coreLog) {
        $tail = Get-Content -Path $coreLog -Tail 120 -ErrorAction SilentlyContinue
        $critical = @($tail | Where-Object { $_ -match '\[ERROR\]' }).Count -gt 0
    }
    Add-QaCheck 'Module Loader sem erro critico' (-not $critical) 'Sem [ERROR] recente em Logs/remastered-core.log.'
    $offlineConfigured = ($config.PSObject.Properties.Name -contains 'autoUpdateBeforePlay' -and -not [bool]$config.autoUpdateBeforePlay)
    Add-QaCheck 'Modo Offline configurado' $offlineConfigured 'autoUpdateBeforePlay=false.'
    $protectedOk = (Test-TrmProtectedPath 'Logs/test.log') -and (Test-TrmProtectedPath 'Backup/test.bak') -and (Test-TrmProtectedPath 'Config/launcher-config.json')
    Add-QaCheck 'Arquivos protegidos continuam protegidos' $protectedOk 'Logs, Backup e launcher-config protegidos.'

    $failed = @($checks | Where-Object { -not $_.passed })
    $report = [pscustomobject]@{
        generatedAt = (Get-Date).ToString('s')
        status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
        checks = $checks
    }
    $reportDir = Join-Path $root 'Logs\QAReports'
    if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
    $path = Join-Path $reportDir ('qa-minimo-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
    Save-TrmJsonFile -Path $path -Value $report
    $report | Add-Member -NotePropertyName reportPath -NotePropertyValue $path
    return $report
}

Export-ModuleMember -Function *-Trm*
