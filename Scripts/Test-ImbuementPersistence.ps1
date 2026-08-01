. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$source = Join-Path $ProjectRoot "Upstream\CrystalLatest\src\items\item.cpp"
$source2 = Join-Path $ProjectRoot "Upstream\CrystalLatest\src\creatures\players\player.cpp"
if ((Test-Path $source) -and (Select-String -LiteralPath $source -Pattern "ITEM_IMBUEMENT_SLOT" -Quiet) -and (Select-String -LiteralPath $source2 -Pattern "setImbuement\(slot, imbuement->getID\(\), baseImbuement->duration\)" -Quiet)) {
	Write-Result STATIC_PASS "Imbuement persistence storage" "item imbuement slots store id and duration in item custom attributes"
} else {
	Write-Result BLOCKED "Imbuement persistence storage" "native persistence source pattern not found"
}

Write-Result MANUAL_REQUIRED "Persistence runtime" "apply imbuement, relog and restart server with a test character"
