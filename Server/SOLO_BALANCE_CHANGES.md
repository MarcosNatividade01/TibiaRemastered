# Solo Balance Changes

Backup created before changes: C:\otserv\backup-solo-balance-20260628-094949

Modified files:
- C:\otserv\config.lua
- C:\otserv\data\stages.lua
- C:\otserv\data\scripts\lib\register_monster_type.lua
- C:\otserv\data\events\scripts\player.lua
- C:\otserv\data\XML\imbuements.xml
- C:\otserv\data\items\items.xml
- C:\otserv\data\scripts\systems\item_tiers.lua
- C:\xampp\htdocs\clientcreateaccount.php

Summary:
- Monster XP is multiplied by 3 in the central monster registration layer.
- Existing non-magic skill stages are multiplied by 5.
- Attack speed, health regen, spell cooldown, weapon proficiency and bestiary kill rate use existing config.lua rates.
- Bestiary charm points are multiplied by 3 in the central monster registration layer.
- Forge dust costs are 0 in config.lua and forge gold prices are 10% in item_tiers.lua.
- Existing imbuement-capable items now have 3 imbuement slots.
- Imbuement material counts are ceil(original / 3).
- New accounts created by the local client endpoint receive 999999 regular Tibia Coins.
- Offensive player spell damage is multiplied by 1.50 and offensive player rune damage by 1.35 in Player:onCombat.
