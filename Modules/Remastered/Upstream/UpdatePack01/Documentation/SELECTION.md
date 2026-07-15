# Update Pack 01 Selection

## Imported

- `data/scripts/actions/items/usable_singeing_steed_items.lua`
  - imported to `Modules/Remastered/Upstream/UpdatePack01/Scripts/actions/items/usable_singeing_steed_items.lua`;
  - depends on existing item `36938`;
  - depends on existing mount id `184`;
  - no protocol, client, database, migration, map, Forge, Bestiary, Bosstiary, Weapon Proficiency, or C++ dependency detected.

## Rejected or deferred

- storm arrows `53168-53172`: item IDs are absent from the current `items.xml` and are tied to upstream 15.25 vocation adjustment content;
- Rotten Blood monsters/scripts/bosses: require quest mechanics, map content, boss mechanics, and additional validation;
- Targuna monsters/NPCs/scripts: require map and quest integration;
- Newhaven scripts: conflict with local login/tutorial/new character flow;
- Cursor Aim: protocol/client dependent;
- Monster AI library: engine/API dependent;
- proficiency JSON: Weapon Proficiency project, not Pack 01;
- upstream `maps.7z`: not imported because the main map must not be replaced.
