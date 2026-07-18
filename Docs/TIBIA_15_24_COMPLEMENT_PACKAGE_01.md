# Tibia 15.24 Complement Package 1

Data: 2026-07-18

Escopo: complemento controlado LOW_RISK baseado em `Docs/TIBIA_15_24_COMPLETENESS_AUDIT.md`.

Nao foram alterados:

- mapa;
- spawns XML;
- banco real;
- migrations;
- sistemas complexos;
- GitHub;
- manifest/version/changelog.

Backup criado antes das alteracoes:

- `Backups/Complement15_24_Package1_20260718-110420/Server/data/items/items.xml`

## Lista Nominal E Risco

### Monsters

| Conteudo | Origem upstream | Dependencias | Mapa | Protocolo | Banco | Risco | Pacote 1 |
|---|---|---|---|---|---|---|---|
| `elderbloodjaw` | `data-global/monster/quests/rotten_blood_quest/elderbloodjaw.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Infernoid Blob` | `data-global/monster/targuna/crimson_court/infernoid_blob.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Infernoid Hound` | `data-global/monster/targuna/crimson_court/infernoid_hound.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Infernoid Soul` | `data-global/monster/targuna/crimson_court/infernoid_soul.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Infernoid Spiritual` | `data-global/monster/targuna/crimson_court/infernoid_spiritual.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Lizard Commander` | `data-global/monster/targuna/hidden_lizard_temple/lizard_commander.lua` | `TargunaLizardCommanderDeath` ja presente | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Lizard Executioner` | `data-global/monster/targuna/hidden_lizard_temple/lizard_executioner.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Lizard Henchman` | `data-global/monster/targuna/hidden_lizard_temple/lizard_henchman.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Lizard Magician` | `data-global/monster/targuna/hidden_lizard_temple/lizard_magician.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Lizard Swordmaster` | `data-global/monster/targuna/hidden_lizard_temple/lizard_swordmaster.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |
| `Pillar of Dark Energy` | `data-global/monster/quests/rotten_blood_quest/pillar of dark energy.lua` | loot item IDs | spawn opcional | corpse/lookType | nao | LOW_RISK | implementado |

Status dos monsters no Pacote 1: `PRESENT_UNSPAWNED` quando nao houver spawn ativo no mapa/XML. Nenhum spawn foi adicionado.

### NPC

| Conteudo | Origem upstream | Dependencias | Mapa | Protocolo | Banco | Risco | Pacote 1 |
|---|---|---|---|---|---|---|---|
| `Adrian` | `data-global/npc/adrian.lua` | dialogo/possivel quest integration/posicao | sim | outfit | nao | MEDIUM_RISK | adiado |

Motivo do adiamento: NPC precisa de posicao/tile e validacao de integracao. Nao foi incluido para manter Pacote 1 sem mapa/spawns.

### Quest

| Conteudo | Origem upstream | Dependencias | Mapa | Protocolo | Banco | Risco | Pacote 1 |
|---|---|---|---|---|---|---|---|
| `newhaven` | `data-global/scripts/quests/newhaven/*.lua`, `data-global/lib/others/newhaven.lua` | NPCs, storages, movements, login/death/use, mapa/tutorial | sim | possivel client tutorial | possivel storage/schema existente | HIGH_RISK | adiado |

Motivo do adiamento: quest com movements/login/death/use e dependencias de mapa/tutorial. Requer pacote proprio.

### Spells

| Spell | Origem upstream | Vocacao | Level | Mana | Cooldown | Tipo | Risco | Pacote 1 |
|---|---|---|---:|---:|---|---|---|---|
| `agonyfield` | `data-global/scripts/spells/monster/agony_field.lua` | monster | n/a | n/a | `2000` | agony | MEDIUM_RISK | adiado |
| `Aura of Exposed Weakness` | `data/scripts/spells/support/aura_of_exposed_weakness.lua` | Sorcerer/Master Sorcerer | 175 | 200 | `2s` | support | LOW_RISK | implementado |
| `Aura of Sapped Strength` | `data/scripts/spells/support/aura_of_sapped_strength.lua` | Sorcerer/Master Sorcerer | 175 | 200 | `2s` | support | LOW_RISK | implementado |
| `chagorzring` | `data-global/scripts/spells/monster/chagorzring.lua` | monster | n/a | n/a | `2000` | energy | MEDIUM_RISK | adiado |
| `Death Echo` | `data/scripts/spells/attack/death_echo.lua` | Sorcerer/Master Sorcerer | 120 | 155 | `6s` | death/fire/energy | LOW_RISK | implementado +15% |
| `Divine Barrage` | `data/scripts/spells/attack/divine_barrage.lua` | Paladin/Royal Paladin | 70 | 175 | `4s` | holy | LOW_RISK | implementado +15% |
| `Divine Defiance` | `data/scripts/spells/support/divine_defiance.lua` | Paladin/Royal Paladin | 100 | 200 | `2s` | support | LOW_RISK | implementado |
| `Elemental Synthesis` | `data/scripts/spells/support/elemental_synthesis.lua` | Druid/Elder Druid | 100 | 200 | `2s` | support | LOW_RISK | implementado |
| `Ethereal Barrage` | `data/scripts/spells/attack/ethereal_barrage.lua` | Paladin/Royal Paladin | 60 | 135 | `4s` | physical | LOW_RISK | implementado +15% |
| `Forked Glacier` | `data/scripts/spells/attack/forked_glacier.lua` | Druid/Elder Druid | 90 | 180 | `6s` | ice | LOW_RISK | implementado +15% |
| `Forked Thorns` | `data/scripts/spells/attack/forked_thorns.lua` | Druid/Elder Druid | 80 | 180 | `6s` | earth | LOW_RISK | implementado +15% |
| `Life Drain Circle` | `data-global/scripts/spells/monster/life_drain_circle.lua` | monster | n/a | n/a | `2000` | drain | MEDIUM_RISK | adiado |
| `Master of Decay` | `data/scripts/spells/support/master_of_decay.lua` | Sorcerer/Master Sorcerer | 20 | 400 | `30s` | support | LOW_RISK | implementado |
| `Master of Flames` | `data/scripts/spells/support/master_of_flames.lua` | Sorcerer/Master Sorcerer | 20 | 400 | `30s` | support | LOW_RISK | implementado |
| `Master of Thunder` | `data/scripts/spells/support/master_of_thunder.lua` | Sorcerer/Master Sorcerer | 20 | 400 | `30s` | support | LOW_RISK | implementado |
| `murcionring` | `data-global/scripts/spells/monster/murcion_ring.lua` | monster | n/a | n/a | `2000` | death | MEDIUM_RISK | adiado |
| `pillar chain` | `data-global/scripts/spells/monster/pillar_chain.lua` | monster | n/a | n/a | `2000` | energy | MEDIUM_RISK | adiado |
| `Shared Conservation` | `data/scripts/spells/support/shared_conservation.lua` | Druid/Elder Druid | 100 | 200 | `2s` | support | LOW_RISK | implementado |
| `Shield Bash` | `data/scripts/spells/attack/shield_bash.lua` | Knight/Elite Knight | 18 | 30 | `4s` | physical | LOW_RISK | implementado +15% |
| `Shield Slam` | `data/scripts/spells/attack/shield_slam.lua` | Knight/Elite Knight | 30 | 110 | `6s` | physical | LOW_RISK | implementado +15% |
| `Thousand Fist Blows` | `data/scripts/spells/attack/thousand_fist_blows.lua` | Monk/Exalted Monk | 120 | 145 | `12s` | physical/energy/earth | LOW_RISK | implementado +15% |

Regra Remastered preservada:

- ofensivas novas de jogador receberam multiplicador local `1.15`;
- suporte/buff nao recebeu multiplicador;
- runas nao foram alteradas.

### Items E Equipments

Todos os 36 item IDs ausentes foram implementados a partir de `Upstream/CrystalLatest/data/items/items.xml`.

| ID | Nome | Tipo/observacao | Risco | Pacote 1 |
|---:|---|---|---|---|
| 43501 | the essence of Murcion | quest/Rotten Blood | LOW_RISK | implementado |
| 43502 | the essence of Ichgahal | quest/Rotten Blood | LOW_RISK | implementado |
| 43503 | the essence of Vemiath | quest/Rotten Blood | LOW_RISK | implementado |
| 43504 | the essence of Chagorz | quest/Rotten Blood | LOW_RISK | implementado |
| 43744 | rotten mushroom | quest item | LOW_RISK | implementado |
| 43787 | rotten mushroom | quest item | LOW_RISK | implementado |
| 43788 | rotten mushroom | quest item | LOW_RISK | implementado |
| 43789 | rotten mushroom | quest item | LOW_RISK | implementado |
| 43790 | rotten mushroom | quest item | LOW_RISK | implementado |
| 43792 | rotten crystal | quest item | LOW_RISK | implementado |
| 43793 | broken rotten crystal | quest item | LOW_RISK | implementado |
| 43794 | rotten crystal | quest item | LOW_RISK | implementado |
| 43795 | broken rotten crystal | quest item | LOW_RISK | implementado |
| 43796 | rotten crystal | quest item | LOW_RISK | implementado |
| 43797 | broken rotten crystal | quest item | LOW_RISK | implementado |
| 43798 | rotten crystal | quest item | LOW_RISK | implementado |
| 43799 | broken rotten crystal | quest item | LOW_RISK | implementado |
| 43800 | rotten crystal | quest item | LOW_RISK | implementado |
| 43801 | broken rotten crystal | quest item | LOW_RISK | implementado |
| 43854 | tainted heart | quest item | LOW_RISK | implementado |
| 43855 | darklight heart | quest item | LOW_RISK | implementado |
| 52964 | charred mask | equipment/head | LOW_RISK | implementado |
| 53002 | gold tooth | creature product | LOW_RISK | implementado |
| 53003 | lizard tail | creature product | LOW_RISK | implementado |
| 53004 | infernoid ember | creature product | LOW_RISK | implementado |
| 53005 | sailor's burn cure | quest/use candidate | LOW_RISK | implementado |
| 53073 | bunch of turnips | item | LOW_RISK | implementado |
| 53162 | superior mana potion | potion definition | LOW_RISK | implementado |
| 53163 | distilled superior mana potion | potion definition | LOW_RISK | implementado |
| 53164 | distilled ultimate mana potion | potion definition | LOW_RISK | implementado |
| 53168 | shatterstorm arrow | ammunition/equipment | LOW_RISK | implementado |
| 53169 | firestorm arrow | ammunition/equipment | LOW_RISK | implementado |
| 53170 | terrastorm arrow | ammunition/equipment | LOW_RISK | implementado |
| 53171 | froststorm arrow | ammunition/equipment | LOW_RISK | implementado |
| 53172 | thunderstorm arrow | ammunition/equipment | LOW_RISK | implementado |
| 54266 | lesser proficiency catalyst | proficiency item | LOW_RISK | implementado |

Correcao de conflito:

- O arquivo atual tinha `fromid="43786" toid="43790" name="spore reservoir"`.
- Para evitar conflito de ID, o range foi substituido pelas definicoes upstream individuais `43786..43790` como `rotten mushroom`.
- `43786` nao estava na lista de ausencias original, mas precisou ser corrigido para nao deixar `43787..43790` duplicados/incoerentes.

## Arquivos Alterados

- `Server/data/items/items.xml`
- `Server/data-global/monster/quests/rotten_blood_quest/elderbloodjaw.lua`
- `Server/data-global/monster/quests/rotten_blood_quest/pillar of dark energy.lua`
- `Server/data-global/monster/targuna/crimson_court/infernoid_blob.lua`
- `Server/data-global/monster/targuna/crimson_court/infernoid_hound.lua`
- `Server/data-global/monster/targuna/crimson_court/infernoid_soul.lua`
- `Server/data-global/monster/targuna/crimson_court/infernoid_spiritual.lua`
- `Server/data-global/monster/targuna/hidden_lizard_temple/lizard_commander.lua`
- `Server/data-global/monster/targuna/hidden_lizard_temple/lizard_executioner.lua`
- `Server/data-global/monster/targuna/hidden_lizard_temple/lizard_henchman.lua`
- `Server/data-global/monster/targuna/hidden_lizard_temple/lizard_magician.lua`
- `Server/data-global/monster/targuna/hidden_lizard_temple/lizard_swordmaster.lua`
- `Server/data/scripts/spells/attack/death_echo.lua`
- `Server/data/scripts/spells/attack/divine_barrage.lua`
- `Server/data/scripts/spells/attack/ethereal_barrage.lua`
- `Server/data/scripts/spells/attack/forked_glacier.lua`
- `Server/data/scripts/spells/attack/forked_thorns.lua`
- `Server/data/scripts/spells/attack/shield_bash.lua`
- `Server/data/scripts/spells/attack/shield_slam.lua`
- `Server/data/scripts/spells/attack/thousand_fist_blows.lua`
- `Server/data/scripts/spells/support/aura_of_exposed_weakness.lua`
- `Server/data/scripts/spells/support/aura_of_sapped_strength.lua`
- `Server/data/scripts/spells/support/divine_defiance.lua`
- `Server/data/scripts/spells/support/elemental_synthesis.lua`
- `Server/data/scripts/spells/support/master_of_decay.lua`
- `Server/data/scripts/spells/support/master_of_flames.lua`
- `Server/data/scripts/spells/support/master_of_thunder.lua`
- `Server/data/scripts/spells/support/shared_conservation.lua`
- `Docs/TIBIA_15_24_COMPLEMENT_PACKAGE_01.md`

## Testes Executados

Passaram:

- parse XML de `Server/data/items/items.xml`;
- parse XML de `Server/data/items/bags.xml`;
- parse XML de `Server/data-global/world/world-monster.xml`;
- parse XML de `Server/data-global/world/world-npc.xml`;
- verificacao de IDs esperados sem duplicidade;
- verificacao de presenca das 11 definicoes de monsters;
- verificacao de presenca das 16 spells LOW_RISK implementadas;
- `Scripts/Test-Project.ps1 -MinimumQA`: `passed`.

Bloqueados/nao executados:

- sintaxe Lua por interpretador externo: nao havia `lua`/`luajit` no PATH;
- iniciar servidor: bloqueado por seguranca porque `Server/config.lua` aponta para MySQL local `otserv`, e esta etapa nao deve tocar banco real;
- login/personagem/spell cast/manual spawn/loot runtime: depende de servidor em banco descartavel;
- regressao jogavel de Offline, Multiplayer, Targuna, XP 8x, Skills 3x, ML 3x, Attack Speed 1.3x, Spells +15%, Runas +30%: nao executada sem runtime descartavel.

## Resultado De Completude

Antes do Pacote 1:

- monsters ausentes: 11;
- NPCs ausentes: 1;
- quests ausentes: 1;
- spells ausentes: 21;
- items ausentes: 36;
- equipments ausentes: 6.

Depois do Pacote 1, por inventario estatico:

- monsters ausentes: 0;
- NPCs ausentes: 1 (`Adrian`);
- quests ausentes: 1 (`newhaven`);
- spells ausentes: 5 (`agonyfield`, `chagorzring`, `Life Drain Circle`, `murcionring`, `pillar chain`);
- items ausentes: 0;
- equipments ausentes: 0.

Completude estatica estimada apos Pacote 1: **aprox. 99.5%**.

Completude operacional estimada: **permanece 85-90%** ate teste runtime em banco descartavel.

## Proximo Pacote Recomendado

Pacote 2 deve ser de validacao runtime controlada:

1. subir servidor contra banco descartavel;
2. validar carregamento Lua completo;
3. criar personagem de teste por vocacao;
4. testar as 16 spells novas;
5. spawnar manualmente os 11 monsters e validar loot/corpse;
6. validar arrows/potions/equipment;
7. confirmar que Targuna nao regrediu;
8. so depois decidir se `Adrian` e `newhaven` entram no Pacote 3.

Pacote 3 sugerido:

- `Adrian` com posicao e dialogo;
- auditoria e port controlado de `newhaven`;
- 5 monster/quest spells adiadas, junto com suas mecanicas.

