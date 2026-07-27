param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$bossLever = Get-Content -Raw (Join-Path $Root 'Server/data/libs/functions/boss_lever.lua')
Assert-True ($bossLever -match 'minPlayers\s*=\s*1') 'BossLever does not force minPlayers to 1.'
Assert-True ($bossLever -match 'disableCooldown\s*=\s*true') 'BossLever does not disable cooldown centrally.'
$fixed = rg -n "You need (4|5) players|exactly (4|5) players|at least (4|5) players|#storePlayers\s*<\s*[45]" (Join-Path $Root 'Server/data-global/scripts/quests') (Join-Path $Root 'Server/data/scripts') -g '*.lua'
if ($LASTEXITCODE -eq 0 -and $fixed) { throw "Fixed boss player requirements remain:`n$fixed" }
Write-Host 'MANUAL_REQUIRED: boss lever flexible player static checks passed; runtime lever pulls require in-game validation.'
exit 2
