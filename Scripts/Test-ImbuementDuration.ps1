. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$xml = Read-XmlFile $ImbuementsPath
foreach ($base in @($xml.imbuements.base | Sort-Object { [int]$_.id })) {
	Assert-Equal $base.duration 72000 "Base $($base.name) duration" | Out-Null
}

$source = Join-Path $ProjectRoot "Upstream\CrystalLatest\src\items\item.cpp"
if ((Test-Path $source) -and (Select-String -LiteralPath $source -Pattern "duration" -Quiet) -and (Select-String -LiteralPath $source -Pattern "setImbuement" -Quiet)) {
	Write-Result STATIC_PASS "Native duration storage" "duration is written with item imbuement slot data"
} else {
	Write-Result BLOCKED "Native duration storage" "source pattern not found"
}

Write-Result MANUAL_REQUIRED "Duration runtime" "expiration timing and equipped-time behavior require in-game wait/control"
