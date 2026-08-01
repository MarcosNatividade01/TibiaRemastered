. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

Assert-ImbuementEffects "Reap" "damage" "" @(15, 38, 75) "value"
Assert-ImbuementEffects "Electrify" "damage" "" @(15, 38, 75) "value"
Assert-ImbuementEffects "Venom" "damage" "" @(15, 38, 75) "value"
Assert-ImbuementEffects "Frost" "damage" "" @(15, 38, 75) "value"
Assert-ImbuementEffects "Scorch" "damage" "" @(15, 38, 75) "value"

Write-Result MANUAL_REQUIRED "Elemental conversion runtime" "controlled combat log validation is required to confirm physical split and resistances"
