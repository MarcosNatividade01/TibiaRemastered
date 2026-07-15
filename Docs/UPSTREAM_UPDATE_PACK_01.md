# Upstream Update Pack 01

## Scope

Update Pack 01 imports only low-risk upstream content that can remain inactive by default through Remastered feature flags.

No protocol, client, C++ core, database, migration, Forge, Bestiary, Bosstiary, Weapon Proficiency, map, Launcher, Auto Update, Offline, Multiplayer, account, character, save, or `Client/storeimages` file was changed.

## Feature flags

All flags start disabled:

- `enable_upstream_pack_01 = false`
- `enable_upstream_pack_01_items = false`
- `enable_upstream_pack_01_monsters = false`
- `enable_upstream_pack_01_npcs = false`
- `enable_upstream_pack_01_quests = false`
- `enable_upstream_pack_01_maps = false`

## Package layout

`Modules/Remastered/Upstream/UpdatePack01/`

| Folder | Purpose |
| --- | --- |
| `Items/` | item-selection notes |
| `Monsters/` | monster-selection notes |
| `NPCs/` | NPC-selection notes |
| `Quests/` | quest-selection notes |
| `Maps/` | map-selection notes |
| `Scripts/` | staged upstream scripts |
| `Tests/` | automated validation |
| `Documentation/` | selection rationale |

## Content table

| Conteudo | Tipo | Origem | Compatibilidade | Importado | Feature Flag | Testado | Observacao |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Singeing Steed usable item action | Item action Lua | Upstream `data/scripts/actions/items/usable_singeing_steed_items.lua` | B | Sim | `enable_upstream_pack_01_items` | Validacao estatica | Usa item existente `36938` e mount existente `184`; fica inativo enquanto as flags estiverem falsas |
| Storm arrows `53168-53172` | Items/weapons | Upstream `data/items/items.xml` + weapon scripts | D | Nao | N/A | Validado como rejeitado | IDs ausentes no `items.xml` atual; associados a upstream 15.25/vocation adjustment |
| Rotten Blood monsters/bosses/scripts | Monsters/quests/bosses | Upstream `data-global` e `data-crystal` | C | Nao | N/A | Validado como adiado | Dependem de mapa, quest mechanics, boss mechanics e validacao separada |
| Targuna monsters/NPCs/scripts | Content/quest/map | Upstream `data-global` | B/C | Nao | N/A | Validado como adiado | Dependem de mapa/quests/storages e NPC flow |
| Newhaven scripts | Quest/tutorial flow | Upstream `data-global/scripts/quests/newhaven` | E | Nao | N/A | Validado como rejeitado | Conflita com fluxo local de login/tutorial/personagem |
| Cursor Aim | Client/protocol system | Upstream `data/modules/scripts/cursor_aim` | D | Nao | N/A | Validado como rejeitado | Depende de protocolo/client |
| Monster AI library | Engine/system library | Upstream `data/libs/systems/monster_ai.lua` | C | Nao | N/A | Validado como adiado | Depende de API/engine e comportamento de monstros |
| Proficiencies JSON | Weapon Proficiency | Upstream `data/json/proficiencies.json` | C/D | Nao | N/A | Validado como rejeitado | Fora do Pack 01 por regra |
| Upstream maps archive | Maps/hunts | Upstream `data-global/world/maps.7z` | C/D | Nao | N/A | Validado como rejeitado | Nao substituir mapa principal; exige projeto de patch de mapa |

## Imported

- 1 Lua item action staged in the Remastered module tree.
- 0 new item definitions.
- 0 monsters.
- 0 NPCs.
- 0 quests.
- 0 maps/hunts.

## Adapted

- The upstream script was staged under the Remastered module system instead of being copied directly into `Server/data/scripts`.
- The module is listed in `modules.available`, but the module and subflags are disabled by default.

## Rejected

- Storm arrows because their item IDs are absent in the current 15.24 content set.
- Newhaven because it conflicts with local Remastered flows.
- Cursor Aim and proficiency content because they depend on protocol/client or critical systems.

## Deferred

- Rotten Blood.
- Targuna.
- Map/hunt imports.
- Monster AI.
- Boss mechanics.

## Test notes

Automated static validation is available at:

`Modules/Remastered/Upstream/UpdatePack01/Tests/validate_update_pack_01.ps1`

Executed automated checks:

| Test | Result | Observation |
| --- | --- | --- |
| Update Pack 01 static validation | Passed | Flags are disabled; item `36938`, mount `184`, XML, module path, and script tokens validated |
| Lua external syntax checker | Not available | `lua`/`luajit` were not found in PATH |
| StrictRuntime | Passed | Zero errors after restoring corrupted local `Client/storeimages` cache files and regenerating `manifest.json`; only `lua.checker.missing` warning remains |
| Publish DryRun `0.1.26-test` | Passed | Official approval file was promoted to `0.1.26-test` through `Scripts/New-OfficialReleaseApproval.ps1` |
| Manifest hash validation | Passed | 22567 files validated |
| Manifest publishable-path validation | Passed | `/Upstream/`, `/UpstreamTesting/`, `Reports/`, logs, UserData, saves and protected paths excluded |

Runtime smoke tests for Offline, Multiplayer, Launcher, Host Assistido, login, character list, persistence, invites, and Auto Update still require the full application/runtime flow before a release publication.

The release gate passed for `0.1.26-test` after automated checks and formal local approval. The second-computer guest join test was not physically rerun on this machine; `onlineDiagnosticClear=true` is recorded as the accepted `-test` fallback.

## Storeimages audit

`Client/storeimages` had 39 divergent files before release correction. They were classified as corrupted local HTTP cache files because their content included `http://127.0.0.1/images/store/...` and `{"ok":true}`, while their sizes were much smaller than the Git/manifest baseline.

They were restored from the Git baseline before regenerating `manifest.json`. The full audit was written to ignored local file `Reports/storeimages_audit.csv`.
