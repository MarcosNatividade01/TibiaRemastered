. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

Assert-ImbuementEffects "Cloud Fabric" "reduction" "" @(5, 12, 23) "value"
Assert-ImbuementEffects "Demon Presence" "reduction" "" @(5, 12, 23) "value"
Assert-ImbuementEffects "Dragon Hide" "reduction" "" @(5, 12, 23) "value"
Assert-ImbuementEffects "Lich Shroud" "reduction" "" @(3, 8, 15) "value"
Assert-ImbuementEffects "Quara Scale" "reduction" "" @(5, 12, 23) "value"
Assert-ImbuementEffects "Snake Skin" "reduction" "" @(5, 12, 23) "value"

Write-Result MANUAL_REQUIRED "Elemental protection runtime" "controlled elemental damage validation is required in-game"
