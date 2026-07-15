param(
    [Parameter(Mandatory=$true)][ValidateSet('Validate','ApplySandbox','Rollback')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$PatchPath,
    [string]$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Convert-ToRelativePath([string]$Base, [string]$Path) {
    $basePath = (Resolve-Path $Base).Path.TrimEnd('\','/')
    $fullPath = (Resolve-Path $Path).Path
    return ($fullPath.Substring($basePath.Length).TrimStart('\','/') -replace '\\','/')
}

function Get-Sha256([string]$Path) {
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLowerInvariant()
}

function New-Issue([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '') {
    [pscustomobject]@{
        severity = $Severity
        code = $Code
        message = $Message
        path = $Path
    }
}

function Test-InArea($Area, [int]$X, [int]$Y, [int]$Z) {
    return (
        $Z -ge [int]$Area.from.z -and $Z -le [int]$Area.to.z -and
        $X -ge [int]$Area.from.x -and $X -le [int]$Area.to.x -and
        $Y -ge [int]$Area.from.y -and $Y -le [int]$Area.to.y
    )
}

function Get-EntityAbsolutePosition($GroupNode, $ChildNode) {
    [pscustomobject]@{
        x = [int]$GroupNode.centerx + [int]$ChildNode.x
        y = [int]$GroupNode.centery + [int]$ChildNode.y
        z = [int]$ChildNode.z
    }
}

function Test-MonsterExists([string]$Name) {
    $escaped = [regex]::Escape($Name)
    $patterns = @(
        "Game\.createMonsterType\(`"$escaped`"\)",
        "Game\.createMonsterType\('$escaped'\)"
    )
    foreach ($path in @('Server\data-global\monster','Server\data-crystal\monster','Server\data\monster')) {
        $full = Join-Path $Root $path
        if (Test-Path $full) {
            $files = @(Get-ChildItem -Path $full -Recurse -Filter '*.lua' -File -ErrorAction SilentlyContinue)
            foreach ($pattern in $patterns) {
                if ($files.Count -gt 0 -and @($files | Select-String -Pattern $pattern -List -ErrorAction SilentlyContinue | Select-Object -First 1).Count -gt 0) {
                    return $true
                }
            }
        }
    }
    return $false
}

function Test-NpcExists([string]$Name) {
    $escaped = [regex]::Escape($Name)
    $patterns = @(
        "Game\.createNpcType\(`"$escaped`"\)",
        "Game\.createNpcType\('$escaped'\)",
        "local\s+internalNpcName\s*=\s*`"$escaped`"",
        "local\s+internalNpcName\s*=\s*'$escaped'"
    )
    foreach ($path in @('Server\data-global\npc','Server\data-crystal\npc','Server\data\npc')) {
        $full = Join-Path $Root $path
        if (Test-Path $full) {
            $files = @(Get-ChildItem -Path $full -Recurse -Filter '*.lua' -File -ErrorAction SilentlyContinue)
            foreach ($pattern in $patterns) {
                if ($files.Count -gt 0 -and @($files | Select-String -Pattern $pattern -List -ErrorAction SilentlyContinue | Select-Object -First 1).Count -gt 0) {
                    return $true
                }
            }
        }
    }
    return $false
}

function Get-WorldPaths {
    $world = Join-Path $Root 'Server\data-global\world'
    [pscustomobject]@{
        WorldRoot = $world
        Map = Join-Path $world 'world.otbm'
        Monsters = Join-Path $world 'world-monster.xml'
        Npcs = Join-Path $world 'world-npc.xml'
        Houses = Join-Path $world 'world-house.xml'
        Zones = Join-Path $world 'world-zones.xml'
    }
}

function Read-Patch([string]$Path) {
    if (-not (Test-Path $Path)) { throw "Patch not found: $Path" }
    $patch = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($required in @('id','name','version','featureFlag','area')) {
        if (-not ($patch.PSObject.Properties.Name -contains $required)) {
            throw "Patch metadata missing required field: $required"
        }
    }
    return $patch
}

function Test-Patch($Patch, [string]$PatchFile) {
    $paths = Get-WorldPaths
    $issues = @()

    foreach ($path in @($paths.Map, $paths.Monsters, $paths.Npcs, $paths.Houses)) {
        if (-not (Test-Path $path)) {
            $issues += New-Issue 'error' 'world.file.missing' "Required world file not found: $path" (Convert-ToRelativePath $Root $path)
        }
    }

    if ($Patch.featureFlag -and (Test-Path (Join-Path $Root 'Modules\Remastered\Config\features.lua'))) {
        $featureText = Get-Content -Raw (Join-Path $Root 'Modules\Remastered\Config\features.lua')
        $expected = "$($Patch.featureFlag) = false"
        if ($featureText -notmatch [regex]::Escape($expected)) {
            $issues += New-Issue 'error' 'feature.flag.invalid' "Feature flag must exist and default to false: $expected" 'Modules/Remastered/Config/features.lua'
        }
    }

    $area = $Patch.area
    if ([int]$area.from.x -gt [int]$area.to.x -or [int]$area.from.y -gt [int]$area.to.y -or [int]$area.from.z -gt [int]$area.to.z) {
        $issues += New-Issue 'error' 'area.invalid' 'Patch area has invalid from/to coordinates.' $PatchFile
    }

    [xml]$monsterXml = Get-Content -Path $paths.Monsters -Raw -Encoding UTF8
    [xml]$npcXml = Get-Content -Path $paths.Npcs -Raw -Encoding UTF8
    [xml]$houseXml = Get-Content -Path $paths.Houses -Raw -Encoding UTF8

    foreach ($house in @($houseXml.houses.house)) {
        if (Test-InArea $area ([int]$house.entryx) ([int]$house.entryy) ([int]$house.entryz)) {
            $issues += New-Issue 'error' 'conflict.house' "Patch area overlaps house entry: $($house.name)" 'Server/data-global/world/world-house.xml'
        }
    }

    $existingMonsterPositions = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($group in @($monsterXml.monsters.monster)) {
        foreach ($child in @($group.monster)) {
            $pos = Get-EntityAbsolutePosition $group $child
            [void]$existingMonsterPositions.Add("$($pos.x):$($pos.y):$($pos.z):$($child.name)")
            if (Test-InArea $area $pos.x $pos.y $pos.z) {
                $issues += New-Issue 'error' 'conflict.spawn.area' "Existing monster spawn inside patch area: $($child.name) at $($pos.x),$($pos.y),$($pos.z)" 'Server/data-global/world/world-monster.xml'
            }
        }
    }

    $existingNpcPositions = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($group in @($npcXml.npcs.npc)) {
        foreach ($child in @($group.npc)) {
            $pos = Get-EntityAbsolutePosition $group $child
            [void]$existingNpcPositions.Add("$($pos.x):$($pos.y):$($pos.z):$($child.name)")
            if (Test-InArea $area $pos.x $pos.y $pos.z) {
                $issues += New-Issue 'error' 'conflict.npc.area' "Existing NPC inside patch area: $($child.name) at $($pos.x),$($pos.y),$($pos.z)" 'Server/data-global/world/world-npc.xml'
            }
        }
    }

    foreach ($spawn in @($Patch.spawns)) {
        if (-not (Test-MonsterExists ([string]$spawn.name))) {
            $issues += New-Issue 'error' 'monster.missing' "Monster does not exist: $($spawn.name)" $PatchFile
        }
        if ([int]$spawn.radius -lt 0) {
            $issues += New-Issue 'error' 'spawn.radius.invalid' "Invalid spawn radius for $($spawn.name)" $PatchFile
        }
        if ([int]$spawn.spawntime -lt 1) {
            $issues += New-Issue 'error' 'spawn.time.invalid' "Invalid spawntime for $($spawn.name)" $PatchFile
        }
        if (-not (Test-InArea $area ([int]$spawn.x) ([int]$spawn.y) ([int]$spawn.z))) {
            $issues += New-Issue 'error' 'spawn.outside.area' "Spawn is outside patch area: $($spawn.name)" $PatchFile
        }
        $key = "$($spawn.x):$($spawn.y):$($spawn.z):$($spawn.name)"
        if ($existingMonsterPositions.Contains($key)) {
            $issues += New-Issue 'error' 'conflict.spawn.duplicate' "Duplicate monster spawn: $key" 'Server/data-global/world/world-monster.xml'
        }
    }

    foreach ($npc in @($Patch.npcs)) {
        if (-not (Test-NpcExists ([string]$npc.name))) {
            $issues += New-Issue 'error' 'npc.missing' "NPC does not exist: $($npc.name)" $PatchFile
        }
        if (-not (Test-InArea $area ([int]$npc.x) ([int]$npc.y) ([int]$npc.z))) {
            $issues += New-Issue 'error' 'npc.outside.area' "NPC is outside patch area: $($npc.name)" $PatchFile
        }
        $key = "$($npc.x):$($npc.y):$($npc.z):$($npc.name)"
        if ($existingNpcPositions.Contains($key)) {
            $issues += New-Issue 'error' 'conflict.npc.duplicate' "Duplicate NPC position: $key" 'Server/data-global/world/world-npc.xml'
        }
    }

    foreach ($tp in @($Patch.teleports)) {
        foreach ($field in @('from','to')) {
            $coord = $tp.$field
            if ($coord -eq $null) {
                $issues += New-Issue 'error' 'teleport.invalid' "Teleport missing $field coordinate: $($tp.id)" $PatchFile
                continue
            }
            if ([int]$coord.x -lt 0 -or [int]$coord.y -lt 0 -or [int]$coord.z -lt 0 -or [int]$coord.z -gt 15) {
                $issues += New-Issue 'error' 'teleport.coordinate.invalid' "Teleport $field coordinate invalid: $($tp.id)" $PatchFile
            }
        }
        if ($tp.from -and $tp.to -and [int]$tp.from.x -eq [int]$tp.to.x -and [int]$tp.from.y -eq [int]$tp.to.y -and [int]$tp.from.z -eq [int]$tp.to.z) {
            $issues += New-Issue 'error' 'teleport.loop' "Teleport loops to itself: $($tp.id)" $PatchFile
        }
    }

    [pscustomobject]@{
        patchId = $Patch.id
        status = if (@($issues | Where-Object { $_.severity -eq 'error' }).Count -eq 0) { 'passed' } else { 'failed' }
        issues = @($issues)
    }
}

function Add-MonsterSpawns([xml]$Xml, $Spawns) {
    foreach ($spawn in @($Spawns)) {
        $group = $Xml.CreateElement('monster')
        foreach ($attr in @{centerx=$spawn.x; centery=$spawn.y; centerz=$spawn.z; radius=$spawn.radius}.GetEnumerator()) {
            $a = $Xml.CreateAttribute($attr.Key)
            $a.Value = [string]$attr.Value
            [void]$group.Attributes.Append($a)
        }
        $child = $Xml.CreateElement('monster')
        foreach ($attr in @{name=$spawn.name; x=0; y=0; z=$spawn.z; spawntime=$spawn.spawntime}.GetEnumerator()) {
            $a = $Xml.CreateAttribute($attr.Key)
            $a.Value = [string]$attr.Value
            [void]$child.Attributes.Append($a)
        }
        [void]$group.AppendChild($child)
        [void]$Xml.monsters.AppendChild($group)
    }
}

function Add-NpcSpawns([xml]$Xml, $Npcs) {
    foreach ($npc in @($Npcs)) {
        $group = $Xml.CreateElement('npc')
        foreach ($attr in @{centerx=$npc.x; centery=$npc.y; centerz=$npc.z; radius=1}.GetEnumerator()) {
            $a = $Xml.CreateAttribute($attr.Key)
            $a.Value = [string]$attr.Value
            [void]$group.Attributes.Append($a)
        }
        $child = $Xml.CreateElement('npc')
        foreach ($attr in @{name=$npc.name; x=0; y=0; z=$npc.z; spawntime=60}.GetEnumerator()) {
            $a = $Xml.CreateAttribute($attr.Key)
            $a.Value = [string]$attr.Value
            [void]$child.Attributes.Append($a)
        }
        [void]$group.AppendChild($child)
        [void]$Xml.npcs.AppendChild($group)
    }
}

function Invoke-ApplySandbox($Patch, [string]$PatchFile) {
    $validation = Test-Patch $Patch $PatchFile
    if ($validation.status -ne 'passed') { return $validation }

    $paths = Get-WorldPaths
    $sandboxRoot = Join-Path $Root ("UpstreamTesting\MapPatches\" + $Patch.id)
    $worldSandbox = Join-Path $sandboxRoot 'world'
    $backupRoot = Join-Path $sandboxRoot 'backup'
    New-Item -ItemType Directory -Force -Path $worldSandbox, $backupRoot | Out-Null

    $backupManifest = @()
    foreach ($name in @('world.otbm','world-monster.xml','world-npc.xml','world-house.xml','world-zones.xml')) {
        $source = Join-Path $paths.WorldRoot $name
        if (Test-Path $source) {
            $backup = Join-Path $backupRoot $name
            Copy-Item -LiteralPath $source -Destination $backup -Force
            Copy-Item -LiteralPath $source -Destination (Join-Path $worldSandbox $name) -Force
            $backupManifest += [pscustomobject]@{
                file = $name
                source = Convert-ToRelativePath $Root $source
                backup = Convert-ToRelativePath $Root $backup
                sha256 = Get-Sha256 $source
            }
        }
    }

    [xml]$monsterXml = Get-Content -Path (Join-Path $worldSandbox 'world-monster.xml') -Raw -Encoding UTF8
    [xml]$npcXml = Get-Content -Path (Join-Path $worldSandbox 'world-npc.xml') -Raw -Encoding UTF8
    Add-MonsterSpawns $monsterXml $Patch.spawns
    Add-NpcSpawns $npcXml $Patch.npcs
    $monsterXml.Save((Join-Path $worldSandbox 'world-monster.xml'))
    $npcXml.Save((Join-Path $worldSandbox 'world-npc.xml'))

    $state = [pscustomobject]@{
        patchId = $Patch.id
        appliedAt = (Get-Date).ToString('s')
        mode = 'sandbox'
        root = Convert-ToRelativePath $Root $sandboxRoot
        backups = $backupManifest
    }
    $state | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $sandboxRoot 'state.json') -Encoding UTF8

    [pscustomobject]@{
        patchId = $Patch.id
        status = 'passed'
        sandbox = Convert-ToRelativePath $Root $sandboxRoot
        issues = @()
    }
}

function Invoke-Rollback($Patch) {
    $sandboxRoot = Join-Path $Root ("UpstreamTesting\MapPatches\" + $Patch.id)
    $statePath = Join-Path $sandboxRoot 'state.json'
    if (-not (Test-Path $statePath)) {
        return [pscustomobject]@{patchId=$Patch.id; status='failed'; issues=@(New-Issue 'error' 'rollback.state.missing' 'Sandbox state.json not found.')}
    }
    Remove-Item -LiteralPath (Join-Path $sandboxRoot 'world') -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $sandboxRoot 'world') | Out-Null
    $state = Get-Content -Raw $statePath | ConvertFrom-Json
    foreach ($entry in @($state.backups)) {
        Copy-Item -LiteralPath (Join-Path $Root $entry.backup) -Destination (Join-Path $sandboxRoot "world\$($entry.file)") -Force
    }
    [pscustomobject]@{patchId=$Patch.id; status='passed'; sandbox=Convert-ToRelativePath $Root $sandboxRoot; issues=@()}
}

$patchFile = if (Test-Path $PatchPath -PathType Leaf) { (Resolve-Path $PatchPath).Path } else { Join-Path (Resolve-Path $PatchPath).Path 'patch.json' }
$patch = Read-Patch $patchFile

$result = switch ($Mode) {
    'Validate' { Test-Patch $patch $patchFile }
    'ApplySandbox' { Invoke-ApplySandbox $patch $patchFile }
    'Rollback' { Invoke-Rollback $patch }
}

$reportRoot = Join-Path $Root ("UpstreamTesting\MapPatches\" + $patch.id)
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
$reportPath = Join-Path $reportRoot ("map-patch-$($Mode.ToLowerInvariant()).json")
$result | ConvertTo-Json -Depth 12 | Set-Content -Path $reportPath -Encoding UTF8
$result | ConvertTo-Json -Depth 12
if ($result.status -ne 'passed') { exit 1 }
