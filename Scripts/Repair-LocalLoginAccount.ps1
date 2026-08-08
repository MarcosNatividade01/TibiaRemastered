param(
    [Parameter(Mandatory = $true)]
    [string]$Email,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$CharacterName = 'Ranger Sorcerer',
    [ValidateSet('sorcerer', 'druid', 'paladin', 'knight', 'monk')]
    [string]$Vocation = 'sorcerer',
    [string]$Database = 'otserv',
    [string]$HostName = '127.0.0.1',
    [int]$DbPort = 3306,
    [int]$WebPort = 80,
    [switch]$SkipHttpLoginTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MysqlExe = Join-Path $ProjectRoot 'Database_Template\mysql\bin\mysql.exe'

if (-not (Test-Path -LiteralPath $MysqlExe)) {
    throw "mysql.exe not found: $MysqlExe"
}

function Sql-Escape([string]$Value) {
    return "'" + (($Value -replace "\\", "\\") -replace "'", "''") + "'"
}

function Convert-ToAccountName([string]$Value) {
    $name = (($Value.Split('@')[0]) -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($name)) { $name = 'account' }
    if ($name.Length -gt 32) { $name = $name.Substring(0, 32) }
    return $name
}

function Convert-ToSafeCharacterName([string]$Value) {
    $name = [regex]::Replace($Value.Trim(), '[^A-Za-z ]+', ' ')
    $name = [regex]::Replace($name, '\s+', ' ').Trim()
    if ($name.Length -lt 3 -or $name.Length -gt 29) {
        throw 'CharacterName must be between 3 and 29 letters/spaces after normalization.'
    }
    return (Get-Culture).TextInfo.ToTitleCase($name.ToLowerInvariant())
}

function Invoke-MySql([string]$Sql) {
    $result = $Sql | & $MysqlExe -h $HostName -P $DbPort -uroot --batch --skip-column-names $Database
    if ($LASTEXITCODE -ne 0) {
        throw "mysql.exe failed with exit code $LASTEXITCODE"
    }
    return @($result)
}

$emailValue = $Email.Trim().ToLowerInvariant()
if ($emailValue -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
    throw 'Email format is invalid.'
}
if ([string]::IsNullOrEmpty($Password)) {
    throw 'Password cannot be empty.'
}

$accountName = Convert-ToAccountName $emailValue
$character = Convert-ToSafeCharacterName $CharacterName
$vocationId = @{
    sorcerer = 1
    druid = 2
    paladin = 3
    knight = 4
    monk = 9
}[$Vocation]

$sql = @"
SET @Email := $(Sql-Escape $emailValue);
SET @AccountName := $(Sql-Escape $accountName);
SET @Password := $(Sql-Escape $Password);
SET @CharacterName := $(Sql-Escape $character);
SET @VocationId := $vocationId;
SET @Now := UNIX_TIMESTAMP();

START TRANSACTION;

INSERT INTO accounts (name, password, email, premdays, premdays_purchased, lastday, type, coins, coins_transferable, tournament_coins, creation)
SELECT @AccountName, SHA1(@Password), @Email, 30, 30, @Now + 2592000, 1, 999999, 0, 0, @Now
WHERE NOT EXISTS (
    SELECT 1 FROM accounts WHERE LOWER(email) = LOWER(@Email) OR LOWER(name) = LOWER(@AccountName)
);

UPDATE accounts
SET password = SHA1(@Password),
    email = @Email,
    premdays = GREATEST(premdays, 30),
    premdays_purchased = GREATEST(premdays_purchased, 30),
    lastday = GREATEST(lastday, @Now + 2592000),
    type = GREATEST(type, 1),
    coins = GREATEST(coins, 999999)
WHERE LOWER(email) = LOWER(@Email) OR LOWER(name) = LOWER(@AccountName);

SET @AccountId := (
    SELECT id FROM accounts
    WHERE LOWER(email) = LOWER(@Email) OR LOWER(name) = LOWER(@AccountName)
    ORDER BY id
    LIMIT 1
);

INSERT INTO account_vipgroups (account_id, name, customizable)
SELECT @AccountId, 'Enemies', 0
WHERE NOT EXISTS (SELECT 1 FROM account_vipgroups WHERE account_id = @AccountId AND name = 'Enemies');

INSERT INTO account_vipgroups (account_id, name, customizable)
SELECT @AccountId, 'Friends', 0
WHERE NOT EXISTS (SELECT 1 FROM account_vipgroups WHERE account_id = @AccountId AND name = 'Friends');

INSERT INTO account_vipgroups (account_id, name, customizable)
SELECT @AccountId, 'Trading Partner', 0
WHERE NOT EXISTS (SELECT 1 FROM account_vipgroups WHERE account_id = @AccountId AND name = 'Trading Partner');

INSERT INTO players (name, account_id, level, vocation, health, healthmax, experience, lookbody, lookfeet, lookhead, looklegs, looktype, lookaddons, maglevel, mana, manamax, manaspent, soul, town_id, posx, posy, posz, conditions, cap, sex, save, stamina)
SELECT @CharacterName, @AccountId, 8, @VocationId, 185, 185, 4200, 68, 76, 78, 58, 128, 0, 0, 90, 90, 0, 100, 1, 32369, 32241, 7, '', 470, 1, 1, 2520
WHERE NOT EXISTS (
    SELECT 1 FROM players
    WHERE account_id = @AccountId AND deletion = 0 AND vocation IN (@VocationId, @VocationId + 4)
);

UPDATE players
SET deletion = 0,
    save = 1,
    town_id = CASE WHEN town_id = 0 THEN 1 ELSE town_id END,
    posx = CASE WHEN posx = 0 THEN 32369 ELSE posx END,
    posy = CASE WHEN posy = 0 THEN 32241 ELSE posy END,
    posz = CASE WHEN posz = 0 THEN 7 ELSE posz END,
    health = CASE WHEN health <= 0 THEN healthmax ELSE health END,
    mana = CASE WHEN mana < 0 THEN 0 ELSE mana END
WHERE account_id = @AccountId AND deletion = 0;

DELETE po FROM players_online po
JOIN players p ON p.id = po.player_id
WHERE p.account_id = @AccountId;

COMMIT;

SELECT a.id, a.name, a.email, a.password = SHA1(@Password), COUNT(p.id)
FROM accounts a
LEFT JOIN players p ON p.account_id = a.id AND p.deletion = 0
WHERE a.id = @AccountId
GROUP BY a.id, a.name, a.email, a.password;

SELECT p.name, p.vocation, p.level, p.deletion
FROM players p
WHERE p.account_id = @AccountId AND p.deletion = 0
ORDER BY p.name;
"@

$rows = Invoke-MySql $sql
$accountRow = $rows[0].Split("`t")
$characters = @()
foreach ($row in $rows[1..($rows.Count - 1)]) {
    if ([string]::IsNullOrWhiteSpace($row)) { continue }
    $parts = $row.Split("`t")
    $characters += [pscustomobject]@{
        name = $parts[0]
        vocation = [int]$parts[1]
        level = [int]$parts[2]
        deletion = [int]$parts[3]
    }
}

$loginOk = $null
if (-not $SkipHttpLoginTest) {
    $body = @{ type = 'login'; email = $emailValue; password = $Password } | ConvertTo-Json -Compress
    $response = Invoke-RestMethod -Uri "http://${HostName}:$WebPort/login.php" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 5
    $loginOk = -not ($response.PSObject.Properties.Name -contains 'errorCode')
    if (-not $loginOk) {
        throw "HTTP login failed with errorCode=$($response.errorCode)"
    }
}

[pscustomobject]@{
    status = 'passed'
    accountId = [int]$accountRow[0]
    accountName = $accountRow[1]
    email = $accountRow[2]
    passwordMatches = ([int]$accountRow[3] -eq 1)
    activeCharacters = [int]$accountRow[4]
    characters = $characters
    httpLoginTest = $loginOk
} | ConvertTo-Json -Depth 5
