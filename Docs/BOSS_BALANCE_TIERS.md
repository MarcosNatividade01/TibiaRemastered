# Boss Balance Tiers

Generated for Mega Gameplay Update 0.1.35-test.

## Central Runtime Rule

Boss balancing is applied centrally through `Modules/Remastered/Balance/api.lua`.

- Tier 1: weak boss, difficulty multiplier `0.85` (-15% HP/damage).
- Tier 2: medium boss, difficulty multiplier `0.80` (-20% HP/damage).
- Tier 3: strong boss, difficulty multiplier `0.70` (-30% HP/damage).
- Tier 4: super strong, lever, or endgame boss, difficulty multiplier `0.50` (-50% HP/damage).

HP is scaled when bosses are created through `BossLever`. Offensive damage is scaled in `Creature:onDrainHealth` only when the attacker is identified as a boss. Loot, rewards, phases, summons, quest storages, cooldowns, and room mechanics are not changed.

## Classification Summary

The static audit classified 483 boss monster scripts:

| Tier | Count | Runtime multiplier |
| --- | ---: | ---: |
| Tier 1 - weak | 376 | 0.85 |
| Tier 2 - medium | 68 | 0.80 |
| Tier 3 - strong | 14 | 0.70 |
| Tier 4 - super strong / lever / endgame | 25 | 0.50 |

## Classification Signals

Boss scripts are classified from existing data only:

- `rewardBoss = true`
- monster scripts under boss folders
- boss or quest boss path names
- high health bands
- known endgame names such as Ferumbras, Goshnar, World Devourer, Arbaziloth, Primal, and Rotten
- runtime monster type boss/reward-boss signals when available

## Representative Samples

| Tier | Examples |
| --- | --- |
| Tier 1 | Apprentice Sheng, Ahau, Azerus, Barbaria, Battlemaster Zunzu |
| Tier 2 | The Fear Feaster, The Dread Maiden, Brother Worm, The False God, The Souldespoiler |
| Tier 3 | Ancient Spawn of Morgathla, The Source of Corruption, The Mutated Pumpkin |
| Tier 4 | Ferumbras, Goshnar bosses, The World Devourer, Arbaziloth, The Primal Menace, Rotten Blood bosses |

## Lever And Team Requirements

The central `BossLever` flow already accepts one to the configured maximum number of players on the entry tiles. This update keeps max players, level, cooldown, storage and access checks, while removing hard vocation composition from the two classic quest levers that required one fixed vocation per tile:

- Desert Dungeon lever
- Elemental Spheres lever

