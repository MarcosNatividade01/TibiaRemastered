param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..\..\..\..\..").Path
)

$ErrorActionPreference = "Stop"

$packRoot = Join-Path $Root "Modules\Remastered\Upstream\UpdatePack01"
$features = Join-Path $Root "Modules\Remastered\Config\features.lua"
$defaultConfig = Join-Path $Root "Modules\Remastered\Config\default.lua"
$itemsXml = Join-Path $Root "Server\data\items\items.xml"
$mountsXml = Join-Path $Root "Server\data\XML\mounts.xml"
$script = Join-Path $packRoot "Scripts\actions\items\usable_singeing_steed_items.lua"

foreach ($path in @($packRoot, $features, $defaultConfig, $itemsXml, $mountsXml, $script)) {
    if (-not (Test-Path $path)) {
        throw "Missing required path: $path"
    }
}

$featureText = Get-Content -Raw $features
foreach ($flag in @(
    "enable_upstream_pack_01 = false",
    "enable_upstream_pack_01_items = false",
    "enable_upstream_pack_01_monsters = false",
    "enable_upstream_pack_01_npcs = false",
    "enable_upstream_pack_01_quests = false",
    "enable_upstream_pack_01_maps = false"
)) {
    if ($featureText -notmatch [regex]::Escape($flag)) {
        throw "Feature flag missing or not disabled: $flag"
    }
}

$defaultText = Get-Content -Raw $defaultConfig
if ($defaultText -notmatch [regex]::Escape('"Upstream/UpdatePack01"')) {
    throw "UpdatePack01 is not listed in modules.available"
}

$itemsText = Get-Content -Raw $itemsXml
if ($itemsText -notmatch 'id="36938"[^>]*name="fiery horseshoe"') {
    throw "Expected item 36938 fiery horseshoe was not found"
}

$mountsText = Get-Content -Raw $mountsXml
if ($mountsText -notmatch 'id="184"[^>]*name="Singeing Steed"') {
    throw "Expected mount id 184 Singeing Steed was not found"
}

$scriptText = Get-Content -Raw $script
foreach ($token in @("Action()", "usableSingeingSteedItems:id(itemId)", "usableSingeingSteedItems:register()")) {
    if ($scriptText -notmatch [regex]::Escape($token)) {
        throw "Imported script token missing: $token"
    }
}

[xml](Get-Content -Raw $itemsXml) | Out-Null
[xml](Get-Content -Raw $mountsXml) | Out-Null

Write-Output "Update Pack 01 validation passed."
