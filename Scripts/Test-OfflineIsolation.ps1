Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'Launcher\Modules\TibiaRemastered.Runtime.psm1') -Force -DisableNameChecking

try {
    StartOffline
    Start-Sleep -Seconds 3
    $state = Get-TrmPortableWebEndpointState
    if ($state.worldAddress -ne '127.0.0.1' -or $state.bindAddress -ne '127.0.0.1' -or [int]$state.gamePort -ne 7172) {
        throw ('Offline endpoint incorreto: ' + ($state | ConvertTo-Json -Compress))
    }
    [pscustomobject]@{
        status = 'passed'
        mode = 'offline'
        worldAddress = $state.worldAddress
        bindAddress = $state.bindAddress
        gamePort = $state.gamePort
    } | ConvertTo-Json
} finally {
    Stop-Process -Name client-local -Force -ErrorAction SilentlyContinue
    Stop-TrmHostedWorld | Out-Null
}
