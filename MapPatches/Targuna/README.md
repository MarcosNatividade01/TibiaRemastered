# Targuna / Aragonia Pirates Candidate

This patch is intentionally sandbox-only and blocked for runtime promotion.

The upstream Targuna package was inventoried and copied into this patch directory, but active `spawns` and `npcs` in `patch.json` remain empty.

Current blocker status:

- The active client 15.24 appearances file contains object appearances for all required IDs `53074`, `53078-53132`, `53158`, and `53167`.
- The server now defines those IDs in `Server/data/items/items.xml` after a controlled 18-item merge.
- There is no safe OTBM fragment extractor/editor in the project yet.

Files:

- `patch.json`: disabled candidate metadata.
- `monsters.xml`: extracted upstream Aragonia pirate/turtle spawns for review only.
- `npcs.xml`: extracted upstream Targuna NPC positions for review only.
- `teleports.xml`: documented travel/teleport candidates for review only.
- `inventory.json` / `inventory.csv`: file-level inventory.
- `asset-validation.json` / `asset-validation.csv`: current server item definition validation.
- `scripts/`: upstream Lua scripts staged for sandbox inspection only.

Do not promote this patch to runtime until a real `map-fragment.otbm` is generated with a trusted OTBM tool and validated in sandbox.
