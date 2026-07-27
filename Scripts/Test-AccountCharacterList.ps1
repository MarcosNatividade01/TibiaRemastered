param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$runtime = Get-Content -Raw (Join-Path $Root 'Launcher/Modules/TibiaRemastered.Runtime.psm1')
Assert-True ($runtime -match 'SELECT\s+.+FROM\s+players\s+WHERE\s+account_id') 'Runtime login endpoint does not query player list by account_id.'
Assert-True ($runtime -match 'playdata\s*=\s*\[pscustomobject\]') 'Runtime login endpoint does not create playdata.'
Assert-True ($runtime -match 'characters\s*=\s*\$characters') 'Runtime login endpoint does not return the account character list.'
Assert-True ($runtime -match 'Resolve-AccountIdentifier') 'Runtime login endpoint does not resolve account identifier.'
Write-Host 'MANUAL_REQUIRED: account character-list implementation checks passed; runtime login and selection require client validation.'
exit 2
