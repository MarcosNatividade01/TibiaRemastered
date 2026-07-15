# Upstream Update Pack 02

## Status

Update Pack 02 was started as a playable-content selection and validation pass.

No gameplay content was imported and no release was published in this pass because no upstream candidate met all required conditions at the same time:

- compatible with client `15.24.eb0021`;
- no protocol/client update;
- no C++ core update;
- no database migration;
- no replacement of `world.otbm`;
- publishable through the current Git/manifest/auto-update flow;
- playable as a complete hunt/area, not only isolated Lua/XML.

## Candidate Matrix

| Conteudo | Tipo | Depende de 15.25 | Sprites no 15.24 | Banco novo | Core C++ | Risco | Recomendacao |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Targuna / Aragonia pirates | Hunt + monsters + NPCs + quest | Parcialmente incerto | Parcial: common pirate outfits exist; Targuna corpses/items `530xx/531xx` are not fully confirmed in current `items.xml` | No | No | High | Best design candidate, but blocked until map patch/spawn/NPC positions are publishable and assets are confirmed |
| Targuna / Herald of Fire | Mini-boss + lever + mechanics | Partially | Blocked: corpse `53108`, loot names and effect scripts require full asset validation | No | No | High | Defer; depends on Targuna map and custom mechanics |
| Targuna / Crimson Court infernoids | Hunt + monsters | Likely | Blocked: lookTypes `1927-1930` and corpse IDs `53078-53094` need client 15.24 proof | No | No | High | Defer until asset scan and map patch tooling |
| Targuna / Hidden Lizard Temple | Hunt + monsters | No obvious protocol dependency | Outfits are older lizard types, but area/map still absent from publishable files | No | No | Medium/High | Candidate for future map-patch project |
| Targuna NPC travel hub | NPCs | No obvious protocol dependency | NPC outfits mostly older | No | No | Medium/High | Blocked because NPC positions are in `world-npc.xml`, which is runtime/protected and not publishable |
| Rotten Blood / Darklight Core | Hunt + monsters | Mostly no; content already local | Present locally in `Server/data-global/monster/quests/rotten_bood` and spawns in local world file | No | No | Medium | Not a Pack 02 import: already present locally; needs runtime verification, not upstream import |
| Rotten Blood bosses | Bosses + quest mechanics | No protocol dependency detected, but systems are complex | Monsters/items partially present | No direct migration, but storages/mechanics are complex | Possible Lua API dependencies | High | Defer to dedicated boss-mechanics project |
| Newhaven 2025 | Tutorial/area/quest | Monk/vocation dependent | Mixed | No | Possible login/tutorial flow dependency | Critical | Reject; conflicts with Remastered login/tutorial/new character flow |
| Storm arrows / Vocation Adjustment | Items + weapons | Yes/likely 15.25 | Blocked: item IDs `53168-53172` absent from current `items.xml` | No | No | High | Reject for Pack 02; protocol/client 15.25 content |
| Cursor Aim | Client-facing mechanic | Yes | Client/UI dependent | No | Protocol/client dependent | Critical | Reject; requires protocol/client project |

## Selected Candidate

The best content candidate is **Targuna / Aragonia pirates**, because it is the closest upstream package to a complete low-level playable area:

- monsters: `Freshwater Turtle`, `Pirate Cook`, `Pirate Gunner`, `Pirate Navigator`, `Pirate Quartermaster`, `Sea Captain`;
- NPCs: `Captain Indigo`, `Morla`, `Sterling`, and related Targuna NPCs;
- quest scripts: long lost treasure, pirate kill counter, turtle eggs, treasure chest;
- boss path: `Herald of Fire` can be staged later.

## Blocking Dependencies

Targuna is not safe to import yet because the playable part depends on map/runtime files:

- upstream spawns are in `Upstream/CrystalLatest/data-global/world/world-monster.xml`;
- upstream NPC positions are in `Upstream/CrystalLatest/data-global/world/world-npc.xml`;
- upstream area data is in `world.otbm` / `maps.7z`;
- current project protects `Server/data-global/world/world.otbm` from publication;
- `Server/data-global/world/*` is runtime/local and not part of the safe auto-update release flow;
- there is no verified OTBM patch/merge tool in the project to add only the Targuna area without replacing the main map.

Publishing only monsters/NPC Lua without the map/spawns would not create a real playable hunt. Publishing spawn XML changes directly would affect runtime-local world files and is outside the current safe manifest policy.

## Asset Validation Notes

Observed Targuna asset risks:

- `Captain Indigo` uses item `53167` (`Sail Pass`) for travel; it was not confirmed in the current `items.xml`.
- `Morla` rewards item `53158` (`old treasure map`); it was not confirmed in the current `items.xml`.
- treasure chest grants item `53074` (`adventurer backpack`); it was not confirmed in the current `items.xml`.
- Targuna corpses include `53078`, `53082`, `53086`, `53090`, `53094`, `53098`, `53103`, `53108`, `53110`, `53113`, `53119`, `53122`, `53125`, `53128`, `53132`; these need client 15.24 appearance validation before import.
- Several monster lookTypes are modern (`1927-1931`) and need explicit client asset validation before being considered compatible.

## Rotten Blood / Darklight Finding

Rotten Blood/Darklight is not selected for Pack 02 import because the Remastered tree already contains local tracked monster files under:

`Server/data-global/monster/quests/rotten_bood/`

The local world file also already contains Darklight spawn references. This should be treated as a runtime verification task, not as an upstream import package.

## Feature Flags

The requested flags were not added because no content was imported:

- `enable_upstream_pack_02`
- `enable_upstream_pack_02_map`
- `enable_upstream_pack_02_monsters`
- `enable_upstream_pack_02_bosses`
- `enable_upstream_pack_02_items`
- `enable_upstream_pack_02_quests`

They should be added only with a concrete import that can be enabled in a test runtime.

## Tests Performed

Automated discovery and static checks only:

- read `Reports/upstream_diff_inventory.json`;
- inspected upstream-only content paths;
- checked current world references for Targuna and Darklight;
- checked current tracked files for existing Rotten Blood/Darklight monsters;
- checked selected Targuna item IDs against current `Server/data/items/items.xml`;
- checked whether `Server/data-global/world/*` is tracked/publishable.

No server runtime test was run because no candidate reached the integration stage.

## Publication

No `CHANGELOG.md`, `version.json`, `manifest.json`, commit, or push was performed for Update Pack 02.

Publishing an empty or partially staged Pack 02 would not satisfy the requested playable-content requirement and could falsely imply that a hunt was available.

## Recommended Next Step

Before importing playable areas, create a dedicated **Map Patch Pipeline**:

1. identify a minimal Targuna map region from upstream;
2. prove every tile/item/outfit/corpse exists in client `15.24.eb0021`;
3. generate a patch instead of replacing `world.otbm`;
4. make `world-monster.xml` and `world-npc.xml` patchable/publishable or load spawns dynamically from a module;
5. run a sandbox server and physically walk the area;
6. only then create `UpdatePack02` with the feature flags and publish as `-test`.
