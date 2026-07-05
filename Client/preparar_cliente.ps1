$ErrorActionPreference = 'Stop'

$clientRoot = 'C:\Users\marco\Tibiafriends'
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

exit 0
