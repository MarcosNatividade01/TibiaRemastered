param(
    [string]$Output = '',
    [string]$ClientSource = 'C:\Users\marco\Tibiafriends',
    [string]$ServerSource = 'C:\otserv'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Output)) {
    $Output = Join-Path $root 'Release\TibiaRemastered-Player.zip'
}

$staging = Join-Path $root 'tmp\player-package'
if (Test-Path $staging) { Remove-Item -Path $staging -Recurse -Force }
New-Item -ItemType Directory -Force -Path $staging | Out-Null

$repoExcludes = @('\.git($|\\)','\\Logs($|\\)','\\Backup($|\\)','\\Backups($|\\)','\\Reports($|\\)','\\tmp($|\\)','\\Release($|\\)','\\UserData($|\\)')
$clientExcludes = @('\.git($|\\)','\\cache($|\\)','\\log($|\\)','\\crashdump($|\\)','\\screenshots($|\\)','\\backup','\\characterdata($|\\)','\\minimap($|\\)','\.bak','partial\.')
$serverExcludes = @('\.git($|\\)','\\backup','\\logs($|\\)','\\reports($|\\)','\\tests($|\\)','\\src($|\\)','\\vcproj($|\\)','\\cmake($|\\)','\\docs($|\\)','crystalserver\.pdb$','key\.pem$','\.bak','\.backup')
$mysqlExcludes = @('\\data($|\\)','\\backup($|\\)','\\scripts($|\\)','\.pdb$','mysql_error\.log$','mysql\.pid$')

function Test-PackageExcluded([string]$Path, [string[]]$Patterns) {
    foreach ($pattern in $Patterns) {
        if ($Path -match $pattern) { return $true }
    }
    return $false
}

function Copy-PackageTree([string]$Source, [string]$Destination, [string[]]$Patterns) {
    Get-ChildItem -LiteralPath $Source -Recurse -File -Force | ForEach-Object {
        if (Test-PackageExcluded $_.FullName $Patterns) { return }
        $relative = $_.FullName.Substring($Source.TrimEnd('\','/').Length).TrimStart('\','/')
        $target = Join-Path $Destination $relative
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}

Copy-PackageTree -Source $root -Destination $staging -Patterns $repoExcludes
Copy-PackageTree -Source $ClientSource -Destination (Join-Path $staging 'Client') -Patterns $clientExcludes
Copy-PackageTree -Source $ServerSource -Destination (Join-Path $staging 'Server') -Patterns $serverExcludes
Copy-PackageTree -Source 'C:\xampp\mysql' -Destination (Join-Path $staging 'Database\mysql') -Patterns $mysqlExcludes

$outDir = Split-Path -Parent $Output
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
if (Test-Path $Output) { Remove-Item -Path $Output -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $Output -CompressionLevel Optimal

$hash = (Get-FileHash -Path $Output -Algorithm SHA256).Hash.ToLowerInvariant()
[pscustomobject]@{
    output = $Output
    size = (Get-Item $Output).Length
    sha256 = $hash
}
