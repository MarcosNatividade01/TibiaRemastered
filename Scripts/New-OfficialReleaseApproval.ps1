param(
    [Parameter(Mandatory=$true)][string]$Version,
    [switch]$Approve,
    [switch]$LauncherOpens,
    [switch]$OfflineWorks,
    [switch]$HostCreatesWorld,
    [switch]$HostJoinsOwnWorld,
    [switch]$GuestJoinsWorld,
    [switch]$OnlineDiagnosticClear,
    [switch]$InviteWorks,
    [switch]$TestConnectionWorks,
    [switch]$NoCriticalRuntimeErrors,
    [switch]$ModuleLoaderOk,
    [switch]$FeatureFlagsOk,
    [switch]$UserDataPreserved,
    [switch]$DatabaseNotOverwritten,
    [switch]$ManifestValid,
    [switch]$VersionValid,
    [switch]$HostAssistedFullyFunctional,
    [string]$ApprovedBy = 'local-user-request',
    [string]$Notes = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$approvalPath = Join-Path $root 'Logs\QAReports\official-release-approval.json'

if ($Version -notmatch '^\d+\.\d+\.\d+(?:-(?:test|rc)(?:\.\d+)?)?$') {
    throw "Versao invalida: $Version"
}

$checks = [ordered]@{
    launcherOpens = [bool]$LauncherOpens
    offlineWorks = [bool]$OfflineWorks
    hostCreatesWorld = [bool]$HostCreatesWorld
    hostJoinsOwnWorld = [bool]$HostJoinsOwnWorld
    guestJoinsWorld = [bool]$GuestJoinsWorld
    onlineDiagnosticClear = [bool]$OnlineDiagnosticClear
    inviteWorks = [bool]$InviteWorks
    testConnectionWorks = [bool]$TestConnectionWorks
    noCriticalRuntimeErrors = [bool]$NoCriticalRuntimeErrors
    moduleLoaderOk = [bool]$ModuleLoaderOk
    featureFlagsOk = [bool]$FeatureFlagsOk
    userDataPreserved = [bool]$UserDataPreserved
    databaseNotOverwritten = [bool]$DatabaseNotOverwritten
    manifestValid = [bool]$ManifestValid
    versionValid = [bool]$VersionValid
    hostAssistedFullyFunctional = [bool]$HostAssistedFullyFunctional
}

$required = @(
    'launcherOpens',
    'offlineWorks',
    'hostCreatesWorld',
    'hostJoinsOwnWorld',
    'inviteWorks',
    'testConnectionWorks',
    'noCriticalRuntimeErrors',
    'moduleLoaderOk',
    'featureFlagsOk',
    'userDataPreserved',
    'databaseNotOverwritten',
    'manifestValid',
    'versionValid',
    'hostAssistedFullyFunctional'
)

$missing = @($required | Where-Object { -not $checks[$_] })
if (-not ($checks.guestJoinsWorld -or $checks.onlineDiagnosticClear)) {
    $missing += 'guestJoinsWorld or onlineDiagnosticClear'
}

if (-not $Approve) {
    throw 'Use -Approve somente depois de executar e confirmar os testes manuais obrigatorios.'
}

if ($missing.Count -gt 0) {
    throw "Aprovacao recusada. Checks ausentes/falsos:`n$($missing -join [Environment]::NewLine)"
}

$reportDir = Split-Path -Parent $approvalPath
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}

$approval = [ordered]@{
    approved = $true
    version = $Version
    approvedAt = (Get-Date).ToString('s')
    approvedBy = $ApprovedBy
    notes = $Notes
    checks = $checks
}

$approval | ConvertTo-Json -Depth 8 | Set-Content -Path $approvalPath -Encoding UTF8
Write-Output "Official release approval written: $approvalPath"
