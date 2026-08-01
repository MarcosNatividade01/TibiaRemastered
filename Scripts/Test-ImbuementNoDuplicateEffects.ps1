. "$PSScriptRoot\YanaImbuementTestCommon.ps1"

$source = Join-Path $ProjectRoot "Upstream\CrystalLatest\src\creatures\players\player.cpp"
$text = if (Test-Path $source) { Get-Content -LiteralPath $source -Raw } else { "" }
Assert-Equal ($text -match "You cannot apply the same imbuement in multiple slots") $true "Native duplicate-name rejection"
Assert-Equal ($text.Contains("slot < 0 || slot >= itemSlots")) $true "Native free-slot rejection"
Assert-Equal ($text.Contains("g_imbuements().getImbuements(static_self_cast<Player>(), item)")) $true "Native compatibility rejection"
Assert-Equal ($text -match "removeItemOfType") $true "Native scroll consumption after validation"

Write-Result MANUAL_REQUIRED "Duplicate runtime" "try same imbuement twice and full-slot item in-game"
