. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$yana = Get-Content -LiteralPath $YanaPath -Raw
$items = Get-Content -LiteralPath $ItemsPath -Raw
$actions = Get-Content -LiteralPath $ScrollActionPath -Raw

Assert-Equal ($yana -match "local goldTokenId = 22721") $true "Yana Gold Token ID"
Assert-Equal ($yana -match "basic = 1, intricate = 2, powerful = 3") $true "Yana tier prices"
Assert-Equal ($yana -match "applyImbuementScrollToItem") $true "Yana native imbuement API"
Assert-Equal ($yana -match "player:removeItem\(goldTokenId, state.price\)") $true "Yana token removal"
Assert-Equal ($yana.IndexOf("player:applyImbuementScrollToItem") -lt $yana.IndexOf("player:removeItem(goldTokenId, state.price)")) $true "Yana removes tokens after native apply"
Assert-Equal ($yana -match "addDialogOptions") $true "Yana exposes dialog options"
Assert-Equal ($yana -match "\{Skills\}") $true "Yana clickable categories"
Assert-Equal ($yana -match "\{Basic\}.*\{Intricate\}.*\{Powerful\}") $true "Yana clickable tiers"
Assert-Equal ($yana -match "\{Helmet\}.*\{Armor\}.*\{Left\}.*\{Right\}.*\{Boots\}.*\{Backpack\}") $true "Yana clickable item slots"
Assert-Equal ($yana -match "\{Yes\}.*\{No\}") $true "Yana clickable confirmation"

foreach ($entry in $ExpectedScrolls.GetEnumerator()) {
	$name = $entry.Key
	$scrolls = $entry.Value
	$nodes = Get-ImbuementNodes $name
	Assert-Equal $nodes.Count 3 "$name tier definitions" | Out-Null
	for ($i = 0; $i -lt 3; $i++) {
		Assert-Equal $nodes[$i].scrollid $scrolls[$i] "$name base $($i + 1) scroll" | Out-Null
		Assert-Equal ($items -match "id=`"$($scrolls[$i])`"") $true "$name base $($i + 1) scroll item" | Out-Null
		Assert-Equal ($actions -match "$($scrolls[$i])") $true "$name base $($i + 1) scroll action" | Out-Null
	}
}

$proc = Get-ServerProcess
if ($proc) {
	Write-Result MANUAL_REQUIRED "Yana runtime dialogue" "server process detected; in-game NPC flow still requires client/admin validation"
} else {
	Write-Result BLOCKED "Yana runtime dialogue" "crystalserver.exe is not running"
}
