. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

Assert-ImbuementEffects "Featherweight" "capacity" "" @(5, 12, 23) "value"
Assert-ImbuementEffects "Swiftness" "speed" "" @(15, 23, 45) "value"
Assert-ImbuementEffects "Vampirism" "skill" "lifeleech" @(750, 1500, 3750)
Assert-ImbuementEffects "Void" "skill" "manaleech" @(450, 750, 1200)
Assert-ImbuementEffects "Vibrancy" "deflect" "" @(23, 38, 75) "chance"

$strike = Get-ImbuementNodes "Strike"
foreach ($node in $strike) {
	$effect = @($node.attribute | Where-Object { $_.key -eq "effect" })[0]
	Assert-Equal $effect.chance 1500 "Strike base $($node.base) critical chance" | Out-Null
}
Assert-ImbuementEffects "Strike" "skill" "critical" @(2250, 3750, 7500)

Write-Result MANUAL_REQUIRED "Support runtime effects" "capacity, speed, leech, critical and paralyze rates require in-game measurement"
