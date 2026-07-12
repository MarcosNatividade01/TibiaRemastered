Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

$existingClientIds = @(Get-Process -Name client-local -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$preexistingUserDataFiles = @()
if (Test-Path (Join-Path $root 'UserData')) {
    $preexistingUserDataFiles = @(Get-ChildItem (Join-Path $root 'UserData') -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
}

try {
    StartOffline
    Start-Sleep -Seconds 3
    $state = Get-TrmPortableWebEndpointState
    if ($state.worldAddress -ne '127.0.0.1' -or $state.bindAddress -ne '127.0.0.1' -or [int]$state.gamePort -ne 7172) {
        throw ('Offline endpoint incorreto: ' + ($state | ConvertTo-Json -Compress))
    }
    foreach ($path in $preexistingUserDataFiles) {
        if (-not (Test-Path -LiteralPath $path)) { throw "Arquivo preexistente de UserData foi removido: $path" }
    }
    [pscustomobject]@{
        status = 'passed'
        mode = 'offline'
        worldAddress = $state.worldAddress
        bindAddress = $state.bindAddress
        gamePort = $state.gamePort
        preexistingUserDataFilesPreserved = $preexistingUserDataFiles.Count
    } | ConvertTo-Json
} finally {
    Get-Process -Name client-local -ErrorAction SilentlyContinue | Where-Object { $existingClientIds -notcontains $_.Id } | Stop-Process -Force -ErrorAction SilentlyContinue
    Stop-TrmHostedWorld | Out-Null
}
