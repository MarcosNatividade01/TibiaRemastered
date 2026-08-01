. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

Assert-ImbuementEffects "Blockade" "skill" "shield" @(2, 3, 6)
Assert-ImbuementEffects "Chop" "skill" "axe" @(2, 3, 6)
Assert-ImbuementEffects "Epiphany" "skill" "magicpoints" @(2, 3, 6)
Assert-ImbuementEffects "Precision" "skill" "distance" @(2, 3, 6)
Assert-ImbuementEffects "Slash" "skill" "sword" @(2, 3, 6)
Assert-ImbuementEffects "Bash" "skill" "club" @(2, 3, 6)
Assert-ImbuementEffects "Punch" "skill" "fist" @(2, 3, 6)

Write-Result MANUAL_REQUIRED "Skill runtime values" "equip/relog verification must be performed in-game"
