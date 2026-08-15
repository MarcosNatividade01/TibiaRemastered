param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Version = '0.1.0',
    [string]$RawBaseUrl = '',
    [string]$Output = '',
    [string]$VersionOutput = '',
    [int64]$MaxFileBytes = 100MB,
    [switch]$UseGitIndex,
    [string]$GeneratedAt = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:gitCatFileProcess = $null
$script:gitCatFileInput = $null
$script:gitCatFileOutput = $null

if ([string]::IsNullOrWhiteSpace($Output)) { $Output = Join-Path $Root 'manifest.json' }
if ([string]::IsNullOrWhiteSpace($VersionOutput)) { $VersionOutput = Join-Path $Root 'version.json' }
if ([string]::IsNullOrWhiteSpace($GeneratedAt)) {
    $GeneratedAt = (Get-Date).ToString('s')
} else {
    $generatedAtValue = $null
    foreach ($format in @('s', 'yyyy-MM-ddTHH:mm:ss', 'MM/dd/yyyy HH:mm:ss', 'M/d/yyyy H:mm:ss', 'dd/MM/yyyy HH:mm:ss', 'd/M/yyyy H:mm:ss')) {
        try {
            $generatedAtValue = [DateTime]::ParseExact($GeneratedAt, $format, [System.Globalization.CultureInfo]::InvariantCulture)
            break
        } catch {
            # Continue through the accepted cross-locale timestamp formats.
        }
    }
    if ($null -eq $generatedAtValue) {
        throw "GeneratedAt must be an ISO 8601 or unambiguous date/time value: $GeneratedAt"
    }
    $GeneratedAt = $generatedAtValue.ToString('s')
}

$excludeRoots = @(
    'UserData','Logs','Backup','Backups','Saves','Save','.git','.github','.vs','.vscode','.idea',
    'Reports','Upstream','UpstreamTesting','release','Release','dist','build','tmp','temp','cache','Cache',
    'Client/characterdata','Client/screenshots'
)
$excludePatterns = @(
    '.gitignore','.gitattributes','manifest.json','version.json','*.tmp','*.temp','*.log','*.bak*',
    '*.backup','*.download','*.pdb','*.dmp','*.db','*.sqlite','*.sqlite3','*.token',
    '*.key','*.pem','*.p12','*.pfx','*.crt','*token*','*secret*','*password*','desktop.ini',
    'Thumbs.db','.DS_Store','Config/launcher-config.json','Client/bin/Qt6WebEngineCore.dll','Client/bin/Qt6WebEngineCore.dll.part*',
    'Server/data-global/world/world.otbm'
)

function Convert-ToRelativePath([string]$Base, [string]$Path) {
    $basePath = [System.IO.Path]::GetFullPath($Base).TrimEnd('\','/')
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rel = $fullPath.Substring($basePath.Length).TrimStart('\','/')
    return ($rel -replace '\\','/')
}

function Test-Ignored([string]$Relative) {
    if ($Relative -ieq 'Server/data-global/npc/gold_token_broker.lua') { return $false }
    if ($Relative -ieq 'Client/conf/clientoptions.json') { return $true }
    if ($Relative.StartsWith('Client/cache/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($Relative.StartsWith('Client/screenshots/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
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
        $paths = if ($UseGitIndex) { & git ls-files --cached } else { & git ls-files --cached --others --exclude-standard }
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

function Read-GitBatchLine([System.IO.Stream]$Stream) {
    $bytes = New-Object System.Collections.Generic.List[byte]
    while ($true) {
        $value = $Stream.ReadByte()
        if ($value -lt 0) { throw 'Unexpected end of git cat-file output.' }
        if ($value -eq 10) { break }
        $bytes.Add([byte]$value)
    }
    return [System.Text.Encoding]::UTF8.GetString($bytes.ToArray())
}

function Initialize-GitIndexReader {
    if ($script:gitCatFileProcess) { return }
    $gitCommand = Get-Command git -ErrorAction Stop
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $gitCommand.Source
    $processInfo.WorkingDirectory = $Root
    $processInfo.Arguments = 'cat-file --batch'
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardInput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.CreateNoWindow = $true

    $script:gitCatFileProcess = New-Object System.Diagnostics.Process
    $script:gitCatFileProcess.StartInfo = $processInfo
    [void]$script:gitCatFileProcess.Start()
    $script:gitCatFileInput = $script:gitCatFileProcess.StandardInput
    $script:gitCatFileOutput = $script:gitCatFileProcess.StandardOutput.BaseStream
}

function Get-GitIndexFileInfo([string]$Relative) {
    Initialize-GitIndexReader
    $script:gitCatFileInput.WriteLine(':' + $Relative)
    $script:gitCatFileInput.Flush()

    $header = Read-GitBatchLine $script:gitCatFileOutput
    if ($header -notmatch '^[0-9a-f]+ blob (\d+)$') {
        throw "Unable to read staged file '$Relative': $header"
    }
    $size = [int64]$Matches[1]
    if ($size -gt [int]::MaxValue) { throw "Staged file '$Relative' is too large to hash." }
    $bytes = New-Object byte[] ([int]$size)
    $offset = 0
    while ($offset -lt $bytes.Length) {
        $read = $script:gitCatFileOutput.Read($bytes, $offset, $bytes.Length - $offset)
        if ($read -le 0) { throw "Unexpected end of staged file '$Relative'." }
        $offset += $read
    }
    if ($script:gitCatFileOutput.ReadByte() -ne 10) {
        throw "Invalid git cat-file terminator for '$Relative'."
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject]@{Sha256=$hash; Size=$size}
}

function Close-GitIndexReader {
    if (-not $script:gitCatFileProcess) { return }
    try {
        $script:gitCatFileInput.Close()
        if (-not $script:gitCatFileProcess.WaitForExit(5000)) {
            $script:gitCatFileProcess.Kill()
        }
    } finally {
        $script:gitCatFileProcess.Dispose()
        $script:gitCatFileProcess = $null
        $script:gitCatFileInput = $null
        $script:gitCatFileOutput = $null
    }
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-ReleaseLargeFiles {
    $items = @()
    $worldMap = Join-Path $Root 'Server\data-global\world\world.otbm'
    $worldPartsRoot = Join-Path $Root 'Server\data-global\world\map-parts'
    if ((Test-Path $worldMap) -and (Test-Path $worldPartsRoot)) {
        $partEntries = @(
            Get-ChildItem -Path $worldPartsRoot -File -Filter 'world.otbm.part*' |
                Sort-Object Name |
                ForEach-Object { Convert-ToRelativePath -Base $Root -Path $_.FullName }
        )
        if ($partEntries.Count -gt 0) {
            $worldInfo = Get-GitPublishedFileInfo $worldMap
            $items += [pscustomobject]@{
                path = 'Server/data-global/world/world.otbm'
                sha256 = $worldInfo.Sha256
                size = $worldInfo.Size
                parts = $partEntries
            }
        }
    }
    return @($items)
}

$versionJson = [pscustomobject]@{
    name = 'TibiaRemastered'
    version = $Version
    channel = 'dev'
    releaseDate = ([DateTime]$GeneratedAt).ToString('yyyy-MM-dd')
    minimumLauncherVersion = '0.1.0'
}
Write-Utf8NoBomFile -Path $VersionOutput -Content ($versionJson | ConvertTo-Json -Depth 8)

$largeFiles = @(Get-ReleaseLargeFiles)
$largeFilesDataPath = Join-Path $Root 'Data\large-files.json'
if ($largeFiles.Count -gt 0) {
    $largeFilesData = [pscustomobject]@{
        version = $Version
        generatedAt = $GeneratedAt
        files = @($largeFiles)
    }
    Write-Utf8NoBomFile -Path $largeFilesDataPath -Content ($largeFilesData | ConvertTo-Json -Depth 8)
} elseif (Test-Path $largeFilesDataPath) {
    Remove-Item -Path $largeFilesDataPath -Force
}

$publishablePaths = Get-GitPublishablePathSet $Root
$filterByGit = ($publishablePaths.Count -gt 0)

$files = @()
if ($UseGitIndex) {
    foreach ($rel in @($publishablePaths | Sort-Object)) {
        if (Test-Ignored $rel) { continue }
        $fileInfo = Get-GitIndexFileInfo $rel
        if ($fileInfo.Size -gt $MaxFileBytes) { continue }
        $overwrite = -not ($rel.StartsWith('Config/', [System.StringComparison]::OrdinalIgnoreCase))
        $files += [pscustomobject]@{
            path = $rel
            sha256 = $fileInfo.Sha256
            size = $fileInfo.Size
            url = Get-FileUrl -Relative $rel -Hash $fileInfo.Sha256
            overwrite = $overwrite
            category = ($rel.Split('/')[0])
        }
    }
    Close-GitIndexReader
} else {
    Get-ChildItem -Path $Root -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = Convert-ToRelativePath -Base $Root -Path $_.FullName
        if (Test-Ignored $rel) { return }
        if ($filterByGit -and -not $publishablePaths.Contains($rel)) { return }
        if ($_.Length -gt $MaxFileBytes) { return }
        $fileInfo = Get-GitPublishedFileInfo $_.FullName
        $overwrite = -not ($rel.StartsWith('Config/', [System.StringComparison]::OrdinalIgnoreCase))
        $files += [pscustomobject]@{
            path = $rel
            sha256 = $fileInfo.Sha256
            size = $fileInfo.Size
            url = Get-FileUrl -Relative $rel -Hash $fileInfo.Sha256
            overwrite = $overwrite
            category = ($rel.Split('/')[0])
        }
    }
}

$manifest = [pscustomobject]@{
    version = $Version
    generatedAt = $GeneratedAt
    hashAlgorithm = 'SHA256'
    files = @($files | Sort-Object path)
    largeFiles = @($largeFiles | Sort-Object path)
}
Write-Utf8NoBomFile -Path $Output -Content ($manifest | ConvertTo-Json -Depth 8)
[pscustomobject]@{Output=$Output; VersionOutput=$VersionOutput; Version=$Version; Files=$files.Count; LargeFiles=$largeFiles.Count}
