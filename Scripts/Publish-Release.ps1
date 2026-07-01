param(
    [Parameter(Mandatory=$true)][string]$Version,
    [string]$RawBaseUrl = 'https://raw.githubusercontent.com/MarcosNatividade01/TibiaRemastered/main',
    [switch]$StrictRuntime,
    [switch]$SkipGitPush
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $root 'Launcher\Tools\Generate-Manifest.ps1'
$moduleRoot = Join-Path $root 'Launcher\Modules'

& $generator -Root $root -Version $Version -RawBaseUrl $RawBaseUrl | Format-List
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Validation.psm1') -Force -DisableNameChecking
$report = Invoke-TrmPrePublishValidation -StrictRuntime:$StrictRuntime
$report | ConvertTo-Json -Depth 12 | Out-Host

if ($report.status -ne 'passed') {
    throw 'Pre-publish validation failed. version.json and manifest.json must not be published until errors are fixed.'
}

if (-not $SkipGitPush) {
    git -C $root status --short
    Write-Host 'Validation passed. Review the status above, commit the generated files, and push to GitHub.'
}
