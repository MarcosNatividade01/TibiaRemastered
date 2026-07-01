Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Core.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot 'TibiaRemastered.Update.psm1') -Force -DisableNameChecking

function New-TrmValidationIssue {
    param([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '')
    return [pscustomobject]@{severity=$Severity; code=$Code; message=$Message; path=$Path}
}

function Test-TrmJsonFiles {
    param([string]$Root)
    $issues = @()
    Get-ChildItem -Path $Root -Filter *.json -File -Recurse | ForEach-Object {
        try { Get-Content -Path $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
        catch { $issues += New-TrmValidationIssue 'error' 'json.invalid' $_.Exception.Message (ConvertTo-TrmRelativePath $Root $_.FullName) }
    }
    return $issues
}

function Test-TrmXmlFiles {
    param([string]$Root)
    $issues = @()
    Get-ChildItem -Path $Root -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try { [xml](Get-Content -Path $_.FullName -Raw -Encoding UTF8) | Out-Null }
        catch { $issues += New-TrmValidationIssue 'error' 'xml.invalid' $_.Exception.Message (ConvertTo-TrmRelativePath $Root $_.FullName) }
    }
    return $issues
}

function Test-TrmLuaFiles {
    param([string]$Root)
    $issues = @()
    $lua = Get-Command lua -ErrorAction SilentlyContinue
    $luac = Get-Command luac -ErrorAction SilentlyContinue
    $checker = if ($luac) { $luac.Source } elseif ($lua) { $lua.Source } else { $null }
    $files = @(Get-ChildItem -Path $Root -Filter *.lua -File -Recurse -ErrorAction SilentlyContinue)
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
    $required = @(
        'README.md','version.json','manifest.json','Config/launcher-config.json',
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
            $hash = Get-TrmSha256 $full
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
    } else {
        if (-not (Test-Path ([string]$config.serverExe))) { $issues += New-TrmValidationIssue 'warning' 'runtime.server.missing' "Server exe not found: $($config.serverExe)" }
        if (-not (Test-Path ([string]$config.clientExe))) { $issues += New-TrmValidationIssue 'warning' 'runtime.client.missing' "Client exe not found: $($config.clientExe)" }
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

Export-ModuleMember -Function *-Trm*
