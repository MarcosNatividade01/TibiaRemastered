param(
    [string]$Version = '',
    [string]$ApprovalPath = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ApprovalPath)) {
    $ApprovalPath = Join-Path $root 'Logs\QAReports\official-release-approval.json'
}

$checks = New-Object System.Collections.ArrayList

function Add-ReleaseCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details,
        [string]$RequiredAction = ''
    )
    [void]$checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
        requiredAction = $RequiredAction
    })
}

function Invoke-CheckedCommand {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$RequiredAction
    )
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    $text = ($output | Select-Object -Last 20) -join [Environment]::NewLine
    Add-ReleaseCheck $Name ($code -eq 0) $text $RequiredAction
}

function Test-JsonFile {
    param([string]$RelativePath)
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) {
        Add-ReleaseCheck "$RelativePath existe" $false "$RelativePath nao encontrado." "Restaure ou gere $RelativePath antes da release."
        return $null
    }
    try {
        $value = Get-Content -Path $path -Raw -Encoding UTF8 | ConvertFrom-Json
        Add-ReleaseCheck "$RelativePath valido" $true "$RelativePath parseado com sucesso."
        return $value
    } catch {
        Add-ReleaseCheck "$RelativePath valido" $false $_.Exception.Message "Corrija o JSON antes da release."
        return $null
    }
}

Set-Location $root

$versionJson = Test-JsonFile 'version.json'
$manifestJson = Test-JsonFile 'manifest.json'

if ($versionJson -and ($versionJson.PSObject.Properties.Name -contains 'version')) {
    $localVersion = [string]$versionJson.version
    Add-ReleaseCheck 'Version possui identificador' (-not [string]::IsNullOrWhiteSpace($localVersion)) "version.json=$localVersion" 'Defina uma versao valida.'
} else {
    $localVersion = ''
    Add-ReleaseCheck 'Version possui identificador' $false 'Campo version ausente.' 'Defina version em version.json.'
}

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    Add-ReleaseCheck 'Versao solicitada e estavel' ($Version -match '^\d+\.\d+\.\d+$') "Version solicitada: $Version" 'Publicacao oficial em main aceita apenas versoes estaveis, como 0.1.3.'
}

if ($manifestJson -and ($manifestJson.PSObject.Properties.Name -contains 'files')) {
    $manifestFiles = @($manifestJson.files)
    Add-ReleaseCheck 'Manifest possui arquivos' ($manifestFiles.Count -gt 0) "Arquivos no manifest: $($manifestFiles.Count)" 'Gere um manifest valido antes da release.'
} else {
    Add-ReleaseCheck 'Manifest possui arquivos' $false 'Campo files ausente.' 'Gere um manifest valido antes da release.'
}

$branchOutput = & git -C $root branch --show-current 2>$null
$branch = ([string]$branchOutput).Trim()
Add-ReleaseCheck 'Branch oficial main' ($branch -eq 'main') "Branch atual: $branch" 'Publique releases oficiais apenas da branch main.'

Invoke-CheckedCommand 'Launcher abre em modo inicializacao' 'powershell.exe' @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'Launcher\Launcher.ps1'),'-NoGui') 'Corrija o Launcher antes da release.'
Invoke-CheckedCommand 'QA minimo automatico' 'powershell.exe' @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'Scripts\Test-Project.ps1'),'-MinimumQA') 'Corrija os itens do QA minimo antes da release.'
Invoke-CheckedCommand 'Simulacao de atualizacao' 'powershell.exe' @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'Scripts\Test-UpdateSimulation.ps1')) 'Corrija o fluxo de atualizacao antes da release.'

$configPath = Join-Path $root 'Config\launcher-config.json'
$config = if (Test-Path $configPath) { Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
if ($config) {
    foreach ($runtime in @(
        @{name='Runtime servidor existe'; path=[string]$config.serverExe},
        @{name='Runtime client existe'; path=[string]$config.clientExe},
        @{name='Runtime banco existe'; path=[string]$config.databaseExe},
        @{name='Seed de banco existe'; path=[string]$config.databaseSeedSql}
    )) {
        $full = if ([System.IO.Path]::IsPathRooted($runtime.path)) { $runtime.path } else { Join-Path $root $runtime.path }
        Add-ReleaseCheck $runtime.name (Test-Path $full) $full 'Corrija o runtime antes da release.'
    }
} else {
    Add-ReleaseCheck 'Config do launcher existe' $false $configPath 'Restaure Config\launcher-config.json antes da release.'
}

$requiredManualChecks = @(
    'launcherOpens',
    'offlineWorks',
    'hostCreatesWorld',
    'hostJoinsOwnWorld',
    'guestJoinsWorld',
    'onlineDiagnosticClear',
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

if (-not (Test-Path $ApprovalPath)) {
    Add-ReleaseCheck 'Aprovacao manual oficial' $false "Arquivo ausente: $ApprovalPath" 'Execute os testes manuais completos e registre a aprovacao local em Logs\QAReports\official-release-approval.json.'
} else {
    try {
        $approval = Get-Content -Path $ApprovalPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $approved = ($approval.PSObject.Properties.Name -contains 'approved' -and [bool]$approval.approved)
        $approvalVersion = if ($approval.PSObject.Properties.Name -contains 'version') { [string]$approval.version } else { '' }
        $versionMatches = [string]::IsNullOrWhiteSpace($Version) -or $approvalVersion -eq $Version
        Add-ReleaseCheck 'Aprovacao manual marcada' $approved "approved=$approved" 'Marque approved=true somente apos todos os testes.'
        Add-ReleaseCheck 'Aprovacao corresponde a versao' $versionMatches "approval.version=$approvalVersion requested=$Version" 'A aprovacao deve ser da mesma versao publicada.'

        foreach ($key in $requiredManualChecks) {
            $ok = $false
            if (($approval.PSObject.Properties.Name -contains 'checks') -and ($approval.checks.PSObject.Properties.Name -contains $key)) {
                $ok = [bool]$approval.checks.$key
            }
            if ($key -ne 'guestJoinsWorld') {
                Add-ReleaseCheck "Manual: $key" $ok "checks.$key=$ok" "Valide manualmente e registre checks.$key=true."
            }
        }
        $guestJoins = $false
        if (($approval.PSObject.Properties.Name -contains 'checks') -and ($approval.checks.PSObject.Properties.Name -contains 'guestJoinsWorld')) {
            $guestJoins = [bool]$approval.checks.guestJoinsWorld
        }
        $onlineDiagnosticClear = $false
        if (($approval.PSObject.Properties.Name -contains 'checks') -and ($approval.checks.PSObject.Properties.Name -contains 'onlineDiagnosticClear')) {
            $onlineDiagnosticClear = [bool]$approval.checks.onlineDiagnosticClear
        }
        Add-ReleaseCheck 'Manual: guestJoinsWorld ou onlineDiagnosticClear' ($guestJoins -or $onlineDiagnosticClear) "guestJoinsWorld=$guestJoins; onlineDiagnosticClear=$onlineDiagnosticClear" 'Valide o convidado em outro computador ou registre diagnostico online claro com targetReachable/version compatible.'
    } catch {
        Add-ReleaseCheck 'Aprovacao manual oficial' $false $_.Exception.Message 'Corrija o JSON de aprovacao local.'
    }
}

$failed = @($checks | Where-Object { -not $_.passed })
$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    version = $Version
    status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
    failed = $failed.Count
    checks = $checks
}

$reportDir = Join-Path $root 'Logs\QAReports'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$reportPath = Join-Path $reportDir 'official-release-checklist-report.json'
$reportWritten = $false
try {
    $report | ConvertTo-Json -Depth 12 | Set-Content -Path $reportPath -Encoding UTF8
    $reportWritten = $true
} catch {
    $reportPath = "nao gravado: $($_.Exception.Message)"
}

if ($failed.Count -gt 0) {
    Write-Host 'Checklist Oficial de Release: FALHOU' -ForegroundColor Red
    if ($reportWritten) { Write-Host "Relatorio: $reportPath" }
    else { Write-Host "Relatorio: $reportPath" -ForegroundColor Yellow }
    Write-Host ''
    foreach ($item in $failed) {
        Write-Host ("[FALHOU] {0}" -f $item.name) -ForegroundColor Red
        Write-Host ("  Detalhes: {0}" -f $item.details)
        if (-not [string]::IsNullOrWhiteSpace([string]$item.requiredAction)) {
            Write-Host ("  Acao: {0}" -f $item.requiredAction)
        }
    }
    exit 1
}

Write-Host 'Checklist Oficial de Release: APROVADO' -ForegroundColor Green
if ($reportWritten) { Write-Host "Relatorio: $reportPath" }
else { Write-Host "Relatorio: $reportPath" -ForegroundColor Yellow }
