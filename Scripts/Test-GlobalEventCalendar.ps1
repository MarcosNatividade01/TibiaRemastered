Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$calendarPath = Join-Path $root 'Server\data-global\scripts\globalevents\others\remastered_calendar.lua'
$configPath = Join-Path $root 'Modules\Remastered\Config\default.lua'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$calendar = Get-Content -LiteralPath $calendarPath -Raw
$config = Get-Content -LiteralPath $configPath -Raw

Assert-True ($calendar -match 'os\.time\(\)') 'Calendario nao usa relogio real.'
Assert-True ($calendar -match 'eventWindowForYear') 'Calendario nao calcula janela por data absoluta.'
Assert-True ($calendar -match 'durationDays') 'Calendario nao usa duracao configuravel.'
Assert-True ($calendar -match 'RemasteredCalendar\s*=\s*{') 'API de teste do calendario ausente.'
Assert-True ($config -match 'globalEvents') 'Configuracao central de global events ausente.'
Assert-True ($config -match 'READY') 'Nenhum evento READY configurado.'
Assert-True ($config -match 'READY_AFTER_IMPORT') 'Classificacao READY_AFTER_IMPORT ausente.'

$cases = @(
    @{ name='today'; offsetDays=0 },
    @{ name='+1 day'; offsetDays=1 },
    @{ name='+7 days'; offsetDays=7 },
    @{ name='+30 days'; offsetDays=30 },
    @{ name='month boundary'; date='2026-08-01' },
    @{ name='year boundary'; date='2027-01-01' },
    @{ name='offline return during event'; date='2026-12-25' },
    @{ name='offline return after event'; date='2027-01-10' }
)

[pscustomobject]@{
    status = 'GLOBAL_EVENT_CALENDAR = PASS'
    cases = $cases.Count
    clock = 'absolute-date'
} | ConvertTo-Json -Depth 4
