param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Version = '0.1.0',
    [string]$RawBaseUrl = '',
    [string]$Output = '',
    [string]$VersionOutput = '',
    [int64]$MaxFileBytes = 100MB
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Output)) { $Output = Join-Path $Root 'manifest.json' }
if ([string]::IsNullOrWhiteSpace($VersionOutput)) { $VersionOutput = Join-Path $Root 'version.json' }

$excludeRoots = @(
    'UserData','Logs','Backup','Backups','Saves','Save','.git','.github','.vs','.vscode','.idea',
    'Reports','release','Release','dist','build','tmp','temp','cache','Cache',
    'Client/characterdata','Client/minimap'
)
$excludePatterns = @(
    '.gitignore','.gitattributes','manifest.json','version.json','*.tmp','*.temp','*.log','*.bak*',
    '*.backup','*.download','*.pdb','*.dmp','*.db','*.sqlite','*.sqlite3','*.token',
    '*.key','*.pem','*.p12','*.pfx','*.crt','*token*','*secret*','*password*','desktop.ini',
    'Thumbs.db','.DS_Store','Config/launcher-config.json','Client/bin/Qt6WebEngineCore.dll','Client/bin/Qt6WebEngineCore.dll.part*',
    'Server/data-global/world/world.otbm'
)

function Convert-ToRelativePath([string]$Base, [string]$Path) {
    $basePath = (Resolve-Path $Base).Path.TrimEnd('\','/')
    $fullPath = (Resolve-Path $Path).Path
    $rel = $fullPath.Substring($basePath.Length).TrimStart('\','/')
    return ($rel -replace '\\','/')
}

function Test-Ignored([string]$Relative) {
    if ($Relative -ieq 'Client/conf/clientoptions.json') { return $true }
    if ($Relative.StartsWith('Client/cache/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($Relative.StartsWith('Database_Template/', [System.StringComparison]::OrdinalIgnoreCase) -and $Relative -like '*.sql') { return $false }
    foreach ($rootName in $excludeRoots) {
        if ($Relative -ieq $rootName -or $Relative.StartsWith($rootName + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    if ($Relative -like '*.sql') { return $true }
    foreach ($pattern in $excludePatterns) {
        if ($Relative -like $pattern) { return $true }
    }
    return $false
}

function Get-GitPublishablePathSet([string]$Base) {
    $set = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { return $set }

    $previous = Get-Location
    try {
        Set-Location $Base
        $inside = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($inside)) { return $set }
        $paths = & git ls-files --cached --others --exclude-standard
        foreach ($path in @($paths)) {
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                [void]$set.Add(([string]$path -replace '\\','/'))
            }
        }
    } finally {
        Set-Location $previous
    }
    return $set
}

function Add-UrlQuery([string]$Url, [string]$Query) {
    if ([string]::IsNullOrWhiteSpace($Url)) { return '' }
    $separator = '?'
    if ($Url.Contains('?')) { $separator = '&' }
    return $Url + $separator + $Query
}

function Get-FileUrl([string]$Relative, [string]$Hash) {
    if ([string]::IsNullOrWhiteSpace($RawBaseUrl)) { return '' }
    $encoded = [System.Uri]::EscapeDataString($Relative).Replace('%2F','/')
    $url = $RawBaseUrl.TrimEnd('/') + '/' + $encoded
    return Add-UrlQuery -Url $url -Query ('v={0}&sha={1}' -f ([System.Uri]::EscapeDataString($Version)), $Hash)
}

function Test-BinaryBytes([byte[]]$Bytes) {
    $limit = [Math]::Min($Bytes.Length, 8192)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Bytes[$i] -eq 0) { return $true }
    }
    return $false
}

function Convert-ToGitPublishedBytes([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (Test-BinaryBytes $bytes) {
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

function Get-GitPublishedFileInfo([string]$Path) {
    $bytes = Convert-ToGitPublishedBytes $Path
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject]@{Sha256=$hash; Size=$bytes.Length}
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$versionJson = [pscustomobject]@{
    name = 'TibiaRemastered'
    version = $Version
    channel = 'dev'
    releaseDate = (Get-Date -Format 'yyyy-MM-dd')
    minimumLauncherVersion = '0.1.0'
}
Write-Utf8NoBomFile -Path $VersionOutput -Content ($versionJson | ConvertTo-Json -Depth 8)

$publishablePaths = Get-GitPublishablePathSet $Root
$filterByGit = ($publishablePaths.Count -gt 0)

$files = @()
Get-ChildItem -Path $Root -File -Recurse | ForEach-Object {
    $rel = Convert-ToRelativePath -Base $Root -Path $_.FullName
    if (Test-Ignored $rel) { return }
    if ($filterByGit -and -not $publishablePaths.Contains($rel)) { return }
    if ($_.Length -gt $MaxFileBytes) { return }
    $fileInfo = Get-GitPublishedFileInfo $_.FullName
    $overwrite = -not ($rel.StartsWith('Config/', [System.StringComparison]::OrdinalIgnoreCase))
    $category = ($rel.Split('/')[0])
    $files += [pscustomobject]@{
        path = $rel
        sha256 = $fileInfo.Sha256
        size = $fileInfo.Size
        url = Get-FileUrl -Relative $rel -Hash $fileInfo.Sha256
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
Write-Utf8NoBomFile -Path $Output -Content ($manifest | ConvertTo-Json -Depth 8)
[pscustomobject]@{Output=$Output; VersionOutput=$VersionOutput; Version=$Version; Files=$files.Count}
