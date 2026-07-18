Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root 'Logs\QAReports'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][bool]$Passed,
        [string]$Details = '',
        [string]$Evidence = ''
    )
    $checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
        evidence = $Evidence
    }) | Out-Null
}

function Invoke-RepoScript {
    param(
        [Parameter(Mandatory=$true)][string]$RelativePath,
        [string[]]$Arguments = @()
    )
    $script = Join-Path $root $RelativePath
    if (-not (Test-Path $script)) {
        Add-Check $RelativePath $false 'Script not found.' ''
        return
    }
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script @Arguments 2>&1
    $passed = ($LASTEXITCODE -eq 0)
    Add-Check ($RelativePath + ' ' + ($Arguments -join ' ')).Trim() $passed ("exit=$LASTEXITCODE") (($output | Select-Object -Last 20) -join [Environment]::NewLine)
}

function Invoke-MySqlText {
    param([Parameter(Mandatory=$true)][string]$Sql)
    $mysql = Join-Path $root 'Database_Template\mysql\bin\mysql.exe'
    $result = & $mysql -h 127.0.0.1 -P 3306 -u root -D otserv -N -e $Sql 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($result -join [Environment]::NewLine)
    }
    return @($result)
}

function Get-Counts {
    Invoke-MySqlText "SELECT 'accounts', COUNT(*) FROM accounts UNION ALL SELECT 'players', COUNT(*) FROM players UNION ALL SELECT 'players_online', COUNT(*) FROM players_online;"
}

$countsBefore = Get-Counts
Add-Check 'Baseline accounts/players readable' ($countsBefore.Count -eq 3) ($countsBefore -join '; ') 'otserv counts before full suite'

$bootLogDir = Join-Path $root ('Logs\BootTests\boot-full-operational-15-24-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $bootLogDir -Force | Out-Null
$out = Join-Path $bootLogDir 'server.out.log'
$err = Join-Path $bootLogDir 'server.err.log'
$server = Start-Process -FilePath (Join-Path $root 'Server\crystalserver.exe') -WorkingDirectory (Join-Path $root 'Server') -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 45
$alive = -not $server.HasExited
if ($alive) { Stop-Process -Id $server.Id -Force }
$tail = @()
if (Test-Path $out) { $tail = Get-Content $out -Tail 220 }
$online = @($tail | Where-Object { $_ -match 'server online' }).Count -gt 0
$criticalErrors = @($tail | Where-Object { $_ -match 'Lua Script Error|Unknown secondaryGroup|stack traceback' })
Add-Check 'Server boot reaches online state' ($alive -and $online -and $criticalErrors.Count -eq 0) "alive=$alive online=$online criticalErrors=$($criticalErrors.Count)" $bootLogDir
Add-Check 'Boot loads proficiency-capable items' (@($tail | Where-Object { $_ -match 'Loaded .* items with proficiency' }).Count -gt 0) 'Boot log contains proficiency item load.' (($tail | Where-Object { $_ -match 'Loaded .* items with proficiency' }) -join '; ')

Invoke-RepoScript 'Scripts\Test-Project.ps1'
Invoke-RepoScript 'Scripts\Test-Project.ps1' @('-MinimumQA')
Invoke-RepoScript 'Scripts\Test-StructuralSystems15_24.ps1'
Invoke-RepoScript 'Scripts\Test-AccountCharacterList.ps1'
Invoke-RepoScript 'Scripts\Test-OfflineIsolation.ps1'
Invoke-RepoScript 'Scripts\Test-MultiplayerHostDiagnostics.ps1'
Invoke-RepoScript 'Scripts\Test-RemoteAccountProxy.ps1'
Invoke-RepoScript 'Scripts\Test-LauncherUpdateUx.ps1'
Invoke-RepoScript 'Scripts\Test-BalanceConfig.ps1'
Invoke-RepoScript 'Scripts\Test-DamageMultipliers.ps1'

$requiredTables = @(
    'daily_reward_history',
    'forge_history',
    'player_prey',
    'player_taskhunt',
    'player_charms',
    'player_bosstiary',
    'player_rewards',
    'player_wheeldata',
    'kv_store',
    'player_bounty_tasks',
    'player_weekly_tasks'
)
foreach ($table in $requiredTables) {
    $exists = Invoke-MySqlText "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='otserv' AND TABLE_NAME='$table';"
    Add-Check "Schema table $table" (-not [string]::IsNullOrWhiteSpace(($exists -join ''))) $table 'information_schema'
}

$requiredColumns = @('forge_dusts','forge_dust_level','boss_points','animus_mastery','weapon_proficiencies','prey_wildcard','isreward')
foreach ($column in $requiredColumns) {
    $exists = Invoke-MySqlText "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='otserv' AND TABLE_NAME='players' AND COLUMN_NAME='$column';"
    Add-Check "Players column $column" (-not [string]::IsNullOrWhiteSpace(($exists -join ''))) $column 'information_schema'
}

$targunaFiles = @(
    'Server\data-global\npc\lizzie.lua',
    'Server\data-global\npc\adrian.lua',
    'Server\data-global\monster\targuna\bosses\herald_of_fire.lua',
    'Server\data-global\monster\targuna\crimson_court\infernoid_hound.lua',
    'Server\data-global\monster\targuna\hidden_lizard_temple\lizard_commander.lua'
)
foreach ($file in $targunaFiles) {
    Add-Check "Targuna file $file" (Test-Path (Join-Path $root $file)) $file 'runtime content'
}
$worldNpc = Get-Content (Join-Path $root 'Server\data-global\world\world-npc.xml') -Raw
Add-Check 'Targuna NPC spawns present' ($worldNpc -match 'Lizzie' -and $worldNpc -match 'Adrian') 'Lizzie and Adrian are in world-npc.xml.' 'world-npc.xml'

$countsAfter = Get-Counts
Add-Check 'Accounts/players preserved' (($countsBefore -join '|') -eq ($countsAfter -join '|')) ("before=$($countsBefore -join '; ') after=$($countsAfter -join '; ')") 'otserv counts after full suite'

$failed = @($checks.ToArray() | Where-Object { -not $_.passed })
$status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    status = $status
    checks = @($checks.ToArray())
    countsBefore = @($countsBefore)
    countsAfter = @($countsAfter)
    limitations = @(
        'This suite proves server boot, script loading, schema persistence, launcher/offline/multiplayer/update regressions, and server-side structural evidence.',
        'It does not claim full GUI/client interaction proof for Weapon Proficiency, Wheel of Destiny, or Animus Mastery without a reliable automated client session.'
    )
    reportPath = ''
}
$reportPath = Join-Path $reportDir ('full-operational-15-24-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$report.reportPath = $reportPath
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8
$report | ConvertTo-Json -Depth 8
if ($failed.Count -gt 0) { exit 1 }
