# Targuna Coordinate Audit - Sandbox

Date: 2026-07-17 00:02 BRT

Scope: sandbox only. Production, GitHub, and promotion were not touched.

## Summary

The expected relocation offset was:

```text
X + 18070
Y + 18120
Z + 0
```

Example:

```text
31946,31903,7 -> 50016,50023,7
```

The audit found that the sandbox runtime currently resolves Targuna content through the original coordinate space, not through the relocated `50xxx/51xxx` coordinate space.

Evidence:

- `Tile(500xx/515xx)` failed during startup validation.
- `Tile(319xx/324xx/334xx)` passed during startup validation.
- The last known successful in-game login before this audit used `31946,31903,7`.
- The active quest scripts under `data-global/scripts/quests/targuna` were already authored in original coordinates.

Decision for this sandbox pass:

```text
Coordinate truth = original runtime coordinates
```

This is the only coordinate system currently verified by Lua `Tile()` and by the running game server.

## Files Changed

Sandbox files only:

- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-npc.xml`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-monster.xml`
- `UpstreamTesting/TargunaRuntime/Start-Targuna-Test.ps1`
- `UpstreamTesting/TargunaRuntime/Server/data-global/scripts/custom/targuna_validation.lua`
- `UpstreamTesting/TargunaRuntime/Server/data-global/scripts/custom/targuna_startup_validation.lua`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-house.xml`

Backup:

- `UpstreamTesting/TargunaRuntime/Backups/coord-fix-20260716-205234`

## Counts

Comparison source: `coord-fix-20260716-205234`.

| Component | Relocated lines before | Relocated lines after | Corrected mismatch lines |
|---|---:|---:|---:|
| `world-npc.xml` | 9 | 0 | 9 |
| `world-monster.xml` | 85 | 0 | 85 |
| `Start-Targuna-Test.ps1` | 2 | 0 | 2 |
| `targuna_validation.lua` | 20 | 0 | 20 |
| `targuna_startup_validation.lua` | 22 | 0 | 22 |
| Total | 138 | 0 | 138 |

Additional check:

- `data-global/scripts/quests/targuna`: 113 position-related lines.
- Active relocated coordinate references in those scripts: 0.
- The remaining `50xxx` value there is `SHRINE_ITEM_ID = 50242`, not a coordinate.

## NPC Coordinates

All essential NPC positions now point to valid runtime tiles.

| NPC | Position | Tile | Create |
|---|---|---|---|
| Captain Indigo | `31973,31892,6` | PASS | PASS |
| Camilla | `31942,31902,6` | PASS | PASS |
| Emiliana | `31960,31901,6` | PASS | PASS |
| Leonora | `31951,31888,7` | PASS | PASS |
| Sterling | `31928,31903,7` | PASS | PASS |
| Aurelia | `31955,31916,7` | PASS | PASS |
| Lizzie | `31941,31920,7` | PASS | PASS |
| Morla | `33514,32748,8` | PASS | PASS |

There is also an Emiliana entry in Crimson Court:

- `32412,32687,12`

## Spawn Coordinates

Essential monster spawn test points now point to valid runtime tiles and can create monsters.

| Monster | Position | Tile | Create |
|---|---|---|---|
| Freshwater Turtle | `33492,32732,7` | PASS | PASS |
| Pirate Cook | `33521,32735,7` | PASS | PASS |
| Pirate Gunner | `33520,32735,7` | PASS | PASS |
| Pirate Navigator | `33519,32735,7` | PASS | PASS |
| Pirate Quartermaster | `33539,32730,8` | PASS | PASS |
| Sea Captain | `33539,32729,8` | PASS | PASS |

The full Aragonia spawn block in `world-monster.xml` was converted from relocated `515xx/508xx` coordinates back to original `334xx/327xx` coordinates.

## Floors And Key Areas

Startup validation:

| Area | Position | Result |
|---|---|---|
| Hub z6 | `31973,31892,6` | PASS |
| Hub z7 | `31946,31903,7` | PASS |
| Hub z8 | `31924,31904,8` | PASS |
| Crimson z12 | `32414,32690,12` | PASS |
| Aragonia z7 | `33492,32732,7` | PASS |
| Herald z15 | `32496,32656,15` | PASS |

This validates tile existence only. It does not replace manual in-game floor traversal.

## Teleports And Quest Scripts

The active Targuna scripts are already aligned to original runtime coordinates:

- `movements_aragonia.lua`
  - Matilda/Targuna side: `31924,31904,7`
  - Aragonia side: `33479,32734,7`
  - Return: `33478,32729,7 -> 31925,31907,7`
- `movements_crimson_court.lua`
  - Energy portal: `31962,31897,5`
  - Crimson arrival: `32414,32690,12`
  - Return portal: `32414,32691,12`
  - Inner teleports: `32424/32432/32435` region
- `movements_temple_teleport.lua`
  - `31941,31928,9 -> 31935,31861,7`
- `actions_herald_lever.lua`
  - Lever: `32435,32653,15`
  - Herald spawn: `32496,32656,15`
  - Player positions: `32435,32654..32658,15`
- `movements_herald_red_floors.lua`
  - Red floors and center: `32496/32503,32649..32663,15`

Status:

- Internal Targuna/Aragonia/Crimson/Herald coordinate references are coherent with the original runtime coordinate system.
- Teleport behavior still requires manual gameplay validation.

## House 3701

The previous `Unknown house id 3701` error was caused by Targuna house entries in sandbox XML that did not match loadable house IDs in the active sandbox map state.

Sandbox fix already applied:

- Removed `Targuna Cottage 1` / `houseid=3701`
- Removed `Targuna Cottage 2` / `houseid=3702`

Current boot no longer reports `Unknown house id 3701`.

## Runtime Validation

Current sandbox runtime:

- Process: `crystalserver-diagnostic.exe`
- PID: `9208`
- Login port: `7271` LISTENING
- Game port: `7272` LISTENING

Startup validation log:

- `UpstreamTesting/TargunaRuntime/Server/data-global/logs/targuna-startup-validation.log`

Result:

- Tiles: PASS for essential hub/Aragonia/Crimson/Herald points.
- NPC create: PASS for all essential NPCs.
- Monster create: PASS for all essential monster test points.
- Herald create: PASS.
- `Storage.Quest.U15_24.Targuna`: PASS.

Current sandbox map:

```text
Path: UpstreamTesting/TargunaRuntime/Server/data-global/world/world.otbm
Size: 195806537 bytes
SHA256: FB7AACC4795AE6615599F08B0C977FEA6B3EFD6372FA37071B956AC770A96915
Last write: 2026-07-16 19:53:27
```

Known non-Targuna boot warnings remain:

- `Can not find Wes the Blacksmith`
- Missing auxiliary OTBM warnings for unrelated global world-change/quest maps.

No current `Unknown house id 3701` was observed after the sandbox fix.

## Remaining Risk

The expanded sandbox OTBM still has a history of relocated fragment work, while the operational runtime truth is original coordinates. This pass aligns active XML/scripts/DB setup to the runtime-visible original coordinates and unblocks Targuna gameplay validation.

If the final intended architecture is to keep Targuna exclusively in `500xx/515xx`, the remaining work is not XML patching. It is to fix or rebuild the runtime map loading path so Lua `Tile()` sees the relocated coordinate space consistently.

## Next Gameplay Test

Recommended next manual GUI test:

1. Start sandbox.
2. Log in with `Targuna Tester`.
3. Confirm spawn at `31946,31903,7`.
4. Talk to Captain Indigo.
5. Test Hub floors z6/z7/z8.
6. Use Matilda/Aragonia route.
7. Confirm Freshwater Turtle and pirate spawns in Aragonia.
8. Test combat/loot manually.
9. Test Crimson/Herald teleports and lever.

Status after this coordinate audit:

```text
COORDINATE_TRUTH = ORIGINAL_RUNTIME_COORDS
NPC_TILE_VALIDATION = PASS
SPAWN_TILE_VALIDATION = PASS
HERALD_COORDINATES = PASS
TELEPORT_COORDINATES = COHERENT_PENDING_GUI
TARGUNA_STATUS = PARTIALLY_READY
```
