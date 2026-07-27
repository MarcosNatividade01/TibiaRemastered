# Remastered Balance Module

Controls the Remastered runtime balance layer:

- Player offensive spell damage: x1.65
- Player offensive rune damage: x1.45
- Player spell cooldowns: x0.50, with a 500 ms floor
- Boss health and damage tiers: weak x0.65, medium x0.50, strong/endgame x0.25
- Boss re-entry cooldowns: disabled through the central boss cooldown API
- Bestiary completion data rewards: x4 through loaded monster Bestiary `CharmsPoints`
- Major and Minor charm costs: x0.50 through the server charm-shop rate
- Bounty task rewards: x5 through server Bounty multipliers
- Hunting Task Shop prices: x0.40 through the shop offer loader
- Loot Rate: 2x

The module is controlled by `enable_remastered_balance`.
