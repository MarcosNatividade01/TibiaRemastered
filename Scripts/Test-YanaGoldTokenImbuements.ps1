. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$yana = Get-Content -LiteralPath $YanaPath -Raw
$items = Get-Content -LiteralPath $ItemsPath -Raw
$actions = Get-Content -LiteralPath $ScrollActionPath -Raw

Assert-Equal ($yana -match "local goldTokenId = 22721") $true "Yana Gold Token ID"
Assert-Equal ($yana -match "basic = 1, intricate = 2, powerful = 3") $true "Yana tier prices"
Assert-Equal ($yana -match "applyImbuementScrollToItem") $true "Yana native imbuement API"
Assert-Equal ($yana -match "player:removeItem\(goldTokenId, state.price\)") $true "Yana token removal"
Assert-Equal ($yana.IndexOf("player:applyImbuementScrollToItem") -lt $yana.IndexOf("player:removeItem(goldTokenId, state.price)")) $true "Yana removes tokens after native apply"
Assert-Equal ($yana -notmatch "addDialogOptions") $true "Yana avoids crash-prone dialog options packet"
Assert-Equal ($yana -match "\{Skills\}") $true "Yana clickable categories"
Assert-Equal ($yana -match "\{Basic\}.*\{Intricate\}.*\{Powerful\}") $true "Yana clickable tiers"
Assert-Equal ($yana -match "\{Yes\}.*\{No\}") $true "Yana clickable confirmation"
Assert-Equal ($yana -match 'CATEGORY = "CATEGORY"') $true "Yana category state"
Assert-Equal ($yana -match 'IMBUEMENT = "IMBUEMENT"') $true "Yana imbuement state"
Assert-Equal ($yana -match 'TIER = "TIER"') $true "Yana tier state"
Assert-Equal ($yana -match 'CONFIRM = "CONFIRM"') $true "Yana confirm state"
Assert-Equal ($yana -match 'APPLY = "APPLY"') $true "Yana apply state"
Assert-Equal ($yana -match "canonicalize") $true "Yana normalizes clicked text"
Assert-Equal ($yana -match '\["roubo de vida"\] = "vampirism"') $true "Yana life leech alias"
Assert-Equal ($yana -match '\["roubo de mana"\] = "void"') $true "Yana mana leech alias"
Assert-Equal ($yana -match '\["protecao contra morte"\] = "lich shroud"') $true "Yana death protection alias"
Assert-Equal ($yana -match "state.state == STATES.CONFIRM[\s\S]*msg == `"yes`"[\s\S]*applyGoldTokenImbuement") $true "Yana yes applies from confirm state"
Assert-Equal ($yana -match "state.state == STATES.TIER[\s\S]*tierPrices\[msg\]") $true "Yana tier handler before generic menu"
Assert-Equal ($yana -match "state.state == STATES.IMBUEMENT[\s\S]*imbuementCategories\[msg\] == state.category") $true "Yana imbuement restricted to current category"
Assert-Equal ($yana -match "state.state == STATES.CATEGORY[\s\S]*categoryTexts\[msg\]") $true "Yana category handler"

$expectedClickableKeywords = @(
	"skills", "elemental damage", "elemental protection", "support",
	"blockade", "chop", "epiphany", "precision", "slash", "bash", "punch",
	"reap", "electrify", "venom", "frost", "scorch",
	"cloud fabric", "demon presence", "dragon hide", "lich shroud", "quara scale", "snake skin",
	"featherweight", "strike", "swiftness", "vampirism", "vibrancy", "void",
	"basic", "intricate", "powerful", "yes", "no", "back"
)
foreach ($option in $expectedClickableKeywords) {
	Assert-Equal ($yana -match [regex]::Escape($option)) $true "Yana clickable keyword $option" | Out-Null
}

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
