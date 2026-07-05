param(
    [string]$Version = '',
    [switch]$DryRun,
    [switch]$SkipConfirmation
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$RepositoryUrl = 'https://github.com/MarcosNatividade01/TibiaRemastered.git'
$RawBaseUrl = 'https://raw.githubusercontent.com/MarcosNatividade01/TibiaRemastered/main'

function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "[AVISO] $Message" -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
    Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Get-ProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Assert-GitInstalled {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Fail 'Git nao esta instalado ou nao esta no PATH.'
        Write-Host ''
        Write-Host 'Instale o Git for Windows e abra este publicador novamente:'
        Write-Host '  winget install --id Git.Git -e'
        Write-Host ''
        Write-Host 'Download alternativo: https://git-scm.com/download/win'
        exit 1
    }
    Write-Ok "Git encontrado: $($git.Source)"
}

function Invoke-Git {
    param([string[]]$Arguments, [switch]$AllowFailure)
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "git $($Arguments -join ' ') falhou:`n$output"
    }
    return [pscustomobject]@{ExitCode=$code; Output=($output -join [Environment]::NewLine)}
}

function Ensure-GitRepository {
    if (-not (Test-Path '.git')) {
        Write-Warn 'Esta pasta ainda nao e um repositorio Git. Inicializando...'
        Invoke-Git -Arguments @('init') | Out-Null
        Invoke-Git -Arguments @('branch','-M','main') | Out-Null
    } else {
        Write-Ok 'Repositorio Git encontrado.'
    }
}

function Ensure-OriginRemote {
    $remoteList = Invoke-Git -Arguments @('remote') -AllowFailure
    $remotes = @($remoteList.Output -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($remotes -notcontains 'origin') {
        Write-Warn 'Remote origin nao existe. Criando origin oficial...'
        Invoke-Git -Arguments @('remote','add','origin',$RepositoryUrl) | Out-Null
        return
    }

    $remote = Invoke-Git -Arguments @('remote','get-url','origin')
    $current = $remote.Output.Trim()
    if ($current -ne $RepositoryUrl) {
        Write-Warn "Remote origin atual: $current"
        Write-Warn "Ajustando para: $RepositoryUrl"
        Invoke-Git -Arguments @('remote','set-url','origin',$RepositoryUrl) | Out-Null
    } else {
        Write-Ok 'Remote origin aponta para o repositorio oficial.'
    }
}

function Ensure-GitIdentity {
    Write-Step 'Verificando identidade Git local'
    $name = Invoke-Git -Arguments @('config','user.name') -AllowFailure
    $email = Invoke-Git -Arguments @('config','user.email') -AllowFailure
    if ([string]::IsNullOrWhiteSpace($name.Output)) {
        Invoke-Git -Arguments @('config','user.name','Tibia Remastered Publisher') | Out-Null
        Write-Warn 'user.name nao estava configurado. Usando identidade local: Tibia Remastered Publisher'
    } else {
        Write-Ok "user.name: $($name.Output.Trim())"
    }
    if ([string]::IsNullOrWhiteSpace($email.Output)) {
        Invoke-Git -Arguments @('config','user.email','publisher@tibiaremastered.local') | Out-Null
        Write-Warn 'user.email nao estava configurado. Usando email local: publisher@tibiaremastered.local'
    } else {
        Write-Ok "user.email: $($email.Output.Trim())"
    }
}

function Test-GitIgnoreContains {
    param([string]$Pattern)
    $lines = Get-Content '.gitignore' -ErrorAction Stop
    return ($lines -contains $Pattern)
}

function Assert-SafetyRules {
    Write-Step 'Validando .gitignore e arquivos proibidos'
    $requiredPatterns = @(
        'UserData/',
        'Logs/',
        'Backup/',
        'Backups/',
        'Saves/',
        'Save/',
        '*.db',
        '*.sqlite',
        '*.sqlite3',
        '*.dump',
        '*.bak',
        '*.backup',
        'Database/',
        'Databases/',
        'PrivateDatabase/',
        'Config/launcher-config.json',
        '*.log',
        'Reports/',
        'tmp/',
        'temp/',
        'Client/bin/Qt6WebEngineCore.dll',
        'Client/bin/Qt6WebEngineCore.dll.part*',
        'Server/data-global/world/world.otbm'
    )

    $missing = @($requiredPatterns | Where-Object { -not (Test-GitIgnoreContains $_) })
    if ($missing.Count -gt 0) {
        throw "O .gitignore nao protege estes padroes obrigatorios:`n$($missing -join [Environment]::NewLine)"
    }
    Write-Ok '.gitignore contem as protecoes obrigatorias.'
}

function Get-NextPatchVersion {
    $versionFile = Join-Path (Get-ProjectRoot) 'version.json'
    $current = Get-Content $versionFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $value = [string]$current.version
    if ($value -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        throw "version.json possui versao invalida: $value"
    }
    return ('{0}.{1}.{2}' -f $Matches[1], $Matches[2], ([int]$Matches[3] + 1))
}

function Update-Changelog {
    param([string]$ReleaseVersion)
    $path = Join-Path (Get-ProjectRoot) 'CHANGELOG.md'
    $content = Get-Content $path -Raw -Encoding UTF8
    $header = "## [$ReleaseVersion] - Publicacao GitHub"
    if ($content -match [regex]::Escape($header)) {
        Write-Ok "CHANGELOG.md ja contem entrada para $ReleaseVersion."
        return
    }

    $entry = @"
$header

- Publicada versao $ReleaseVersion para testes online/LAN.
- Atualizados ``version.json`` e ``manifest.json`` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para ``UserData``, logs, backups, saves, banco local e arquivos pessoais.

"@
    $updated = $content -replace "(?m)^Todas as alteracoes importantes do projeto serao documentadas aqui\.\s*", "Todas as alteracoes importantes do projeto serao documentadas aqui.`r`n`r`n$entry"
    Set-Content -Path $path -Value $updated -Encoding UTF8
    Write-Ok "CHANGELOG.md atualizado para $ReleaseVersion."
}

function Update-ReleaseFiles {
    param([string]$ReleaseVersion)
    Write-Step "Atualizando version.json, manifest.json e CHANGELOG.md ($ReleaseVersion)"
    Update-Changelog -ReleaseVersion $ReleaseVersion

    $generator = Join-Path (Get-ProjectRoot) 'Launcher\Tools\Generate-Manifest.ps1'
    if (-not (Test-Path $generator)) {
        throw "Gerador de manifest nao encontrado: $generator"
    }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $generator -Version $ReleaseVersion -RawBaseUrl $RawBaseUrl | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao gerar manifest/version.'
    }
}

function Remove-ForbiddenTrackedFiles {
    Write-Step 'Removendo arquivos proibidos do indice Git, se existirem'
    $paths = @(
        'Config/launcher-config.json',
        'Client/bin/Qt6WebEngineCore.dll',
        'Client/bin/Qt6WebEngineCore.dll.part1',
        'Client/bin/Qt6WebEngineCore.dll.part2',
        'Server/data-global/world/world.otbm'
    )
    foreach ($path in $paths) {
        Invoke-Git -Arguments @('rm','--cached','--ignore-unmatch',$path) -AllowFailure | Out-Null
    }
    Write-Ok 'Indice limpo para arquivos proibidos conhecidos.'
}

function Assert-NoForbiddenInGitStatus {
    Write-Step 'Verificando se arquivos proibidos seriam publicados'
    $status = Invoke-Git -Arguments @('status','--porcelain') -AllowFailure
    $forbiddenRegex = '(^|\s)(UserData/|Logs/|Backup/|Backups/|Saves/|Save/|tmp/|temp/|Reports/|Config/launcher-config\.json|Client/bin/Qt6WebEngineCore\.dll(\.part[0-9]+)?|Server/data-global/world/world\.otbm|.*\.(db|sqlite|sqlite3|dump|bak|backup|log|token|key|pem|p12|pfx|crt))'
    $bad = @($status.Output -split "`r?`n" | Where-Object { $_ -match $forbiddenRegex })
    if ($bad.Count -gt 0) {
        throw "Arquivos proibidos apareceram no Git status:`n$($bad -join [Environment]::NewLine)"
    }
    Write-Ok 'Nenhum arquivo proibido aparece no Git status.'
}

function Show-StatusAndConfirm {
    Write-Step 'Arquivos que serao enviados'
    $short = Invoke-Git -Arguments @('status','--short')
    $lines = @($short.Output -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $reportDir = Join-Path (Get-ProjectRoot) 'Reports'
    if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
    $statusPath = Join-Path $reportDir 'publish-status.txt'
    Set-Content -Path $statusPath -Value $lines -Encoding UTF8
    Write-Host "Total de arquivos alterados/adicionados: $($lines.Count)"
    Write-Host "Lista completa: $statusPath"
    Write-Host ''
    $lines | Select-Object -First 120 | ForEach-Object { Write-Host $_ }
    if ($lines.Count -gt 120) {
        Write-Host "... ($($lines.Count - 120) itens adicionais gravados no arquivo de status)"
    }
    Write-Host ''
    $full = Invoke-Git -Arguments @('status')
    ($full.Output -split "`r?`n" | Select-Object -First 80) | ForEach-Object { Write-Host $_ }

    if ($DryRun) {
        Write-Warn 'DryRun ativo: commit/push nao serao executados.'
        return $false
    }
    if ($SkipConfirmation) {
        return $true
    }
    $answer = Read-Host 'Confirmar commit e push para GitHub? Digite SIM para continuar'
    return ($answer -eq 'SIM')
}

try {
    $root = Get-ProjectRoot
    Set-Location $root
    Write-Host 'Tibia Remastered - Publicador GitHub' -ForegroundColor Green
    Write-Host "Projeto: $root"

    Write-Step 'Verificando Git'
    Assert-GitInstalled

    Write-Step 'Preparando repositorio'
    Ensure-GitRepository
    Ensure-OriginRemote
    Ensure-GitIdentity
    Assert-SafetyRules

    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = Get-NextPatchVersion
    }
    Update-ReleaseFiles -ReleaseVersion $Version

    Write-Step 'Adicionando arquivos ao Git'
    Invoke-Git -Arguments @('add','-A') | Out-Null
    Remove-ForbiddenTrackedFiles
    Assert-NoForbiddenInGitStatus

    $shouldPublish = Show-StatusAndConfirm
    if (-not $shouldPublish) {
        Write-Warn 'Publicacao cancelada antes do commit/push.'
        exit 0
    }

    Write-Step 'Criando commit'
    $commit = Invoke-Git -Arguments @('commit','-m',"Publica versao $Version para teste online") -AllowFailure
    if ($commit.ExitCode -ne 0) {
        if ($commit.Output -match 'nothing to commit|nada a confirmar') {
            Write-Warn 'Nao ha alteracoes para commitar.'
        } else {
            throw $commit.Output
        }
    } else {
        Write-Host $commit.Output
    }

    Write-Step 'Enviando para GitHub'
    $push = Invoke-Git -Arguments @('push','-u','origin','main')
    Write-Host $push.Output
    Write-Ok "Publicacao concluida: versao $Version enviada para $RepositoryUrl"
} catch {
    Write-Fail $_.Exception.Message
    Write-Host ''
    Write-Host 'Nada em UserData/Logs/Backup deve ter sido alterado por este publicador.'
    Write-Host 'Se um commit foi criado mas o push falhou, corrija o erro e rode Publish.bat novamente.'
    exit 1
}
