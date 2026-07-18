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
        [string]$Details = ''
    )
    $checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    }) | Out-Null
}

function Read-Text([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) { return '' }
    return Get-Content -Path $path -Raw -Encoding UTF8
}

function Invoke-MySqlText {
    param([Parameter(Mandatory=$true)][string]$Sql)
    $mysql = Join-Path $root 'Database_Template\mysql\bin\mysql.exe'
    if (-not (Test-Path $mysql)) {
        throw "mysql.exe not found: $mysql"
    }
    $result = & $mysql -h 127.0.0.1 -P 3306 -u root -D otserv -N -e $Sql 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($result -join [Environment]::NewLine)
    }
    return @($result)
}

$config = Read-Text 'Server\config.lua'
Add-Check 'Forge custom dust preserved' ($config -match 'forgeFusionDustCost\s*=\s*0' -and $config -match 'forgeTransferDustCost\s*=\s*0') 'Fusion/transfer dust costs remain zero.'
Add-Check 'Prey enabled' ($config -match 'preySystemEnabled\s*=\s*true') 'Prey system flag is enabled.'
Add-Check 'Bestiary accelerated' ($config -match 'bestiaryKillMultiplier\s*=\s*[3-9]') 'Bestiary kill multiplier is configured above upstream baseline.'
Add-Check 'Wheel enabled' ($config -match 'wheelSystemEnabled\s*=\s*true') 'Wheel of Destiny server flag is enabled.'
Add-Check 'Animus configured' ($config -match 'animusMasteryMaxMonsterXpMultiplier\s*=' -and $config -match 'animusMasteryMonsterXpMultiplier\s*=') 'Animus Mastery config keys are present.'

$requiredFiles = @(
    'Server\data\libs\systems\exaltation_forge.lua',
    'Server\data\scripts\actions\objects\exaltation_forge.lua',
    'Server\data\scripts\creaturescripts\monster\forge_kill.lua',
    'Server\data\scripts\eventcallbacks\monster\ondroploot_prey.lua',
    'Server\data\scripts\systems\bestiary_charms.lua',
    'Server\data\scripts\systems\reward_chest.lua',
    'Server\data\libs\systems\daily_reward.lua',
    'Server\data\modules\scripts\daily_reward\daily_reward.lua',
    'Server\data\scripts\actions\objects\daily_reward_shrine.lua',
    'Server\data\scripts\actions\objects\imbuement_shrine.lua',
    'Server\data\XML\imbuements.xml',
    'Server\data\items\proficiencies.json'
)
foreach ($file in $requiredFiles) {
    Add-Check "Required structural file: $file" (Test-Path (Join-Path $root $file)) $file
}

try {
    [xml](Read-Text 'Server\data\XML\imbuements.xml') | Out-Null
    Add-Check 'Imbuements XML parses' $true 'Server/data/XML/imbuements.xml'
} catch {
    Add-Check 'Imbuements XML parses' $false $_.Exception.Message
}

try {
    Read-Text 'Server\data\items\proficiencies.json' | ConvertFrom-Json | Out-Null
    Add-Check 'Weapon proficiencies JSON parses' $true 'Server/data/items/proficiencies.json'
} catch {
    Add-Check 'Weapon proficiencies JSON parses' $false $_.Exception.Message
}

$imbuements = [xml](Read-Text 'Server\data\XML\imbuements.xml')
$reducedMaterialCount = 0
foreach ($node in @($imbuements.imbuements.imbuement.attribute)) {
    if ($node.key -eq 'item' -and [int]$node.count -lt 20) {
        $reducedMaterialCount++
    }
}
Add-Check 'Imbuement material reduction preserved' ($reducedMaterialCount -gt 0) "Reduced material entries: $reducedMaterialCount"

$tables = @(
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
foreach ($table in $tables) {
    $exists = Invoke-MySqlText "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='otserv' AND TABLE_NAME='$table';"
    Add-Check "Database table: $table" (-not [string]::IsNullOrWhiteSpace(($exists -join ''))) $table
}

$columns = @(
    'forge_dusts',
    'forge_dust_level',
    'boss_points',
    'animus_mastery',
    'weapon_proficiencies',
    'prey_wildcard',
    'isreward'
)
foreach ($column in $columns) {
    $exists = Invoke-MySqlText "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='otserv' AND TABLE_NAME='players' AND COLUMN_NAME='$column';"
    Add-Check "Players column: $column" (-not [string]::IsNullOrWhiteSpace(($exists -join ''))) $column
}

$counts = Invoke-MySqlText "SELECT 'accounts', COUNT(*) FROM accounts UNION ALL SELECT 'players', COUNT(*) FROM players UNION ALL SELECT 'players_online', COUNT(*) FROM players_online;"
Add-Check 'Accounts/players readable' ($counts.Count -eq 3) ($counts -join '; ')

$failed = @($checks | Where-Object { -not $_.passed })
$status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    status = $status
    checks = @($checks.ToArray())
    counts = @($counts)
    reportPath = ''
}
$reportPath = Join-Path $reportDir ('structural-systems-15-24-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$report.reportPath = $reportPath
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8
$report | ConvertTo-Json -Depth 8
if ($failed.Count -gt 0) { exit 1 }
