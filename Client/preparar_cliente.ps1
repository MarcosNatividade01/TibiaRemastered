$ErrorActionPreference = 'Stop'

$clientRoot = $PSScriptRoot
$clientExe = Join-Path $clientRoot 'bin\client-local.exe'
$webEngine = Join-Path $clientRoot 'bin\Qt6WebEngineCore.dll'
$packageJson = Join-Path $clientRoot 'package.json'

foreach ($required in @($clientExe, $webEngine, $packageJson)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Host "Arquivo necessario ausente: $required" -ForegroundColor Red
        exit 1
    }
}

$version = (Get-Content -LiteralPath $packageJson -Raw | ConvertFrom-Json).version
if ($version -notlike '15.24*') {
    Write-Host "Cliente incompativel: $version. Esperado: 15.24.x" -ForegroundColor Red
    exit 1
}

$sourceMinimap = Join-Path $clientRoot 'minimap'
$targetMinimap = Join-Path $env:LOCALAPPDATA 'Tibia\packages\Tibia\minimap'
if (Test-Path -LiteralPath $sourceMinimap) {
    New-Item -ItemType Directory -Force -Path $targetMinimap | Out-Null
    Get-ChildItem -LiteralPath $sourceMinimap -File | ForEach-Object {
        $destination = Join-Path $targetMinimap $_.Name
        if ($_.Name -ieq 'minimapmarkers.bin' -and (Test-Path -LiteralPath $destination)) {
            return
        }
        if (-not (Test-Path -LiteralPath $destination)) {
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
            return
        }
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
        if ($sourceHash -ne $targetHash) {
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
        }
    }
    $expected = @(Get-ChildItem -LiteralPath $sourceMinimap -File).Count
    $installed = @(Get-ChildItem -LiteralPath $targetMinimap -File -ErrorAction SilentlyContinue).Count
    if ($installed -lt $expected) {
        Write-Host "Minimap incompleto: instalado $installed de $expected arquivos esperados." -ForegroundColor Red
        exit 1
    }
}

exit 0
