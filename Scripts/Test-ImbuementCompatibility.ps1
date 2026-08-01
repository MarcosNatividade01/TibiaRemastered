. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$rows = Get-ImbuementItemCategories
$categoryMap = [ordered]@{
	Strike = "critical hit"
	Vampirism = "life leech"
	Void = "mana leech"
	Blockade = "skillboost shielding"
	Chop = "skillboost axe"
	Epiphany = "skillboost magic level"
	Precision = "skillboost distance"
	Slash = "skillboost sword"
	Bash = "skillboost club"
	Punch = "skillboost fist"
	Reap = "elemental damage"
	Electrify = "elemental damage"
	Venom = "elemental damage"
	Frost = "elemental damage"
	Scorch = "elemental damage"
	"Cloud Fabric" = "elemental protection energy"
	"Demon Presence" = "elemental protection holy"
	"Dragon Hide" = "elemental protection fire"
	"Lich Shroud" = "elemental protection death"
	"Quara Scale" = "elemental protection ice"
	"Snake Skin" = "elemental protection earth"
	Featherweight = "increase capacity"
	Swiftness = "increase speed"
	Vibrancy = "paralysis removal"
}

Write-Output "IMBUEMENT | ITEM CATEGORY | COMPATIBLE | REASON"
foreach ($entry in $categoryMap.GetEnumerator()) {
	$type = $entry.Value
	$matches = @($rows | Where-Object { $_.ImbuementType -eq $type })
	if ($matches.Count -gt 0) {
		$sample = ($matches | Select-Object -First 8 | ForEach-Object { "$($_.Name)#$($_.ItemId)" }) -join ", "
		Write-Output "$($entry.Key) | $type | YES | $($matches.Count) item definitions, sample: $sample"
		Write-Result STATIC_PASS "$($entry.Key) compatibility" "$($matches.Count) compatible item definitions"
	} else {
		Write-Output "$($entry.Key) | $type | NO | no item definitions expose this imbuement type"
		Write-Result BLOCKED "$($entry.Key) compatibility" "no compatible item definitions"
	}
}

Write-Result MANUAL_REQUIRED "Compatibility runtime rejection" "NPC failure messages must be checked against actual equipped incompatible items"
