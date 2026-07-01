param([switch]$StrictRuntime)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $root 'Launcher\Modules'
Import-Module (Join-Path $moduleRoot 'TibiaRemastered.Validation.psm1') -Force -DisableNameChecking

$report = Invoke-TrmPrePublishValidation -StrictRuntime:$StrictRuntime
$report | ConvertTo-Json -Depth 12
if ($report.status -ne 'passed') { exit 1 }
