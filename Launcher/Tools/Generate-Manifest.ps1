param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Version = '0.1.0',
    [string]$RawBaseUrl = '',
    [string]$Output = '',
    [string]$VersionOutput = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Output)) { $Output = Join-Path $Root 'manifest.json' }
if ([string]::IsNullOrWhiteSpace($VersionOutput)) { $VersionOutput = Join-Path $Root 'version.json' }

$excludeRoots = @(
    'UserData','Logs','Backup','Backups','Saves','Save','.git','.github','.vs','.vscode','.idea',
    'Reports','release','Release','dist','build','tmp','temp','cache','Cache'
)
$excludePatterns = @(
    '.gitignore','.gitattributes','manifest.json','version.json','*.tmp','*.temp','*.log','*.bak*',
    '*.backup','*.download','*.pdb','*.dmp','*.db','*.sqlite','*.sqlite3','*.sql','*.token',
    '*.key','*.pem','*.p12','*.pfx','*.crt','*token*','*secret*','*password*','desktop.ini',
    'Thumbs.db','.DS_Store','Config/launcher-config.json'
)

function Convert-ToRelativePath([string]$Base, [string]$Path) {
    $basePath = (Resolve-Path $Base).Path.TrimEnd('\','/')
    $fullPath = (Resolve-Path $Path).Path
    $rel = $fullPath.Substring($basePath.Length).TrimStart('\','/')
    return ($rel -replace '\\','/')
}

function Test-Ignored([string]$Relative) {
    foreach ($rootName in $excludeRoots) {
        if ($Relative -ieq $rootName -or $Relative.StartsWith($rootName + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    foreach ($pattern in $excludePatterns) {
        if ($Relative -like $pattern) { return $true }
    }
    return $false
}

function Get-FileUrl([string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($RawBaseUrl)) { return '' }
    $encoded = [System.Uri]::EscapeDataString($Relative).Replace('%2F','/')
    return $RawBaseUrl.TrimEnd('/') + '/' + $encoded
}

$files = @()
Get-ChildItem -Path $Root -File -Recurse | ForEach-Object {
    $rel = Convert-ToRelativePath -Base $Root -Path $_.FullName
    if (Test-Ignored $rel) { return }
    $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $overwrite = -not ($rel.StartsWith('Config/', [System.StringComparison]::OrdinalIgnoreCase))
    $category = ($rel.Split('/')[0])
    $files += [pscustomobject]@{
        path = $rel
        sha256 = $hash
        size = $_.Length
        url = Get-FileUrl $rel
        overwrite = $overwrite
        category = $category
    }
}

$manifest = [pscustomobject]@{
    version = $Version
    generatedAt = (Get-Date).ToString('s')
    hashAlgorithm = 'SHA256'
    files = @($files | Sort-Object path)
}
$versionJson = [pscustomobject]@{
    name = 'TibiaRemastered'
    version = $Version
    channel = 'dev'
    releaseDate = (Get-Date -Format 'yyyy-MM-dd')
    minimumLauncherVersion = '0.1.0'
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $Output -Encoding UTF8
$versionJson | ConvertTo-Json -Depth 8 | Set-Content -Path $VersionOutput -Encoding UTF8
[pscustomobject]@{Output=$Output; VersionOutput=$VersionOutput; Version=$Version; Files=$files.Count}
