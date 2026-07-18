# Tibia Remastered 15.24 Completeness Audit

Data: 2026-07-18

Escopo: auditoria estatica, sem alterar producao, sem modificar mapa, sem executar migrations, sem importar conteudo e sem publicar no GitHub.

Base atual auditada:

- `Server/data`
- `Server/data-global`
- `Server/data-crystal`
- `Server/schema.sql`
- `Server/otserv.sql`
- `Client/package.json`
- `Client/assets.json`
- `MapPatches/Targuna`

Referencia 15.24 usada:

- `Upstream/CrystalLatest/data`
- `Upstream/CrystalLatest/data-global`
- `Upstream/CrystalLatest/data-crystal`
- `Upstream/CrystalLatest/schema.sql`
- `Upstream/CrystalLatest/config.lua.dist`

Versoes 15.25, 15.30 ou superiores nao foram usadas como referencia.

## Metodo

Esta auditoria compara nomes e dependencias por arquivos Lua/XML/SQL, hashes de arquivos e presenca de assets. Foram lidos:

- definicoes Lua de monstros via `Game.createMonsterType`;
- definicoes Lua de NPCs via `internalNpcName` / `Game.createNpcType`;
- spells e runas via `Spell(...)` e `:name(...)`;
- spawns de monstros em `world-monster.xml`;
- spawns de NPCs em `world-npc.xml`;
- quests por diretorios e scripts em `scripts/quests` e `lib/quests`;
- itens/equipamentos por `items.xml` e `bags.xml`;
- tabelas SQL por `CREATE TABLE`;
- sistemas por arquivos e tags de caminho relacionadas a forge, prey, bestiary, bosstiary, charms, imbuements, proficiencies, store, rewards, daily rewards e afins.

Limite importante: esta auditoria nao executa o servidor e nao valida jogabilidade real. Portanto, conteudo presente em arquivo mas nao testado em runtime foi classificado como `PRESENT_UNTESTED`, `CUSTOMIZED` ou `PARTIAL`, conforme o caso.

## Matriz Final De Completude

| Categoria | Total upstream | Presentes | Parciais | Ausentes | Nao testados |
|---|---:|---:|---:|---:|---:|
| Hunts/Areas | 11 | 11 | 0 | 0 | 11 |
| Monsters | 1770 | 1759 | 1752 | 11 | 7 |
| Bosses | 453 | 453 | 452 | 0 | 1 |
| NPCs | 1129 | 1128 | 1120 | 1 | 8 |
| Quests | 126 | 125 | 1 | 1 | 124 |
| Spells | 815 | 794 | 793 | 21 | 1 |
| Runes | 42 | 42 | 42 | 0 | 0 |
| Items | 17570 | 17534 | 517 | 36 | 17017 |
| Equipments | 1476 | 1470 | 516 | 6 | 954 |
| Systems | 14 | 5 | 8 | 1 | 14 |
| Database | 53 | 53 | 0 | 0 | 53 |
| Client Assets | 1 | 1 | 1 | 0 | 1 |

Estimativa global de completude 15.24: **aprox. 98.8% por inventario estatico de conteudo**, mas **85-90% por prontidao operacional**, porque a maior parte do conteudo presente esta modificada/customizada em relacao ao upstream e ainda nao foi validada ponta a ponta.

## Mapa, Towns, Hunts E Areas

Status geral: `CUSTOMIZED / PRESENT_UNTESTED`.

Evidencias:

- `Server/data-global/world/world.otbm` difere do upstream 15.24.
- Mapa global atual: `195806537` bytes.
- Mapa global upstream: `52836960` bytes.
- `Server/data-crystal/world/world.otbm` e identico ao upstream.
- Spawns globais atuais: `87212`.
- Spawns globais upstream: `87287`.
- NPCs globais atuais: `1053`.
- NPCs globais upstream: `1046`.

Conclusao:

- Nao ha diretorios de area/hunt ausentes nos conjuntos `world/quest`, `world/world_changes`, `world/annual_events` e `world/custom`.
- O mapa global atual nao e uma copia pura do upstream: ele esta customizado e maior.
- O delta de spawns mostra que ha removocoes/adicoes no XML ativo. Isso exige validacao em servidor de teste antes de considerar `PRESENT_AND_WORKING`.
- Areas podem ter tiles presentes e scripts presentes, mas esta auditoria estatica nao comprova pathing, doors, teleports, storages ou boss rooms jogaveis.

## Targuna / Aragonia

Status atual real: `PARTIAL / PRESENT_UNTESTED`.

Evidencias ativas:

- `MapPatches/Targuna/map-fragment.otbm` existe.
- Definicoes de monstros ativas encontradas: `Freshwater Turtle`, `Pirate Cook`, `Pirate Gunner`, `Pirate Navigator`, `Pirate Quartermaster`, `Sea Captain`, `Herald of Fire`.
- Definicoes de NPCs ativas encontradas: `Anna`, `Emiliana`.
- Spawns ativos:
  - `Pirate Navigator`: 43
  - `Pirate Cook`: 9
  - `Pirate Gunner`: 18
  - `Pirate Quartermaster`: 16
  - `Herald of Fire`: 0
- NPC spawns ativos:
  - `Anna`: 1
  - `Emiliana`: 2
  - `Matilda`: 0
  - `A Strange Whirl`: 0
  - `Saturnin`: 0

Conclusao Targuna:

- Aragonia pirates estao parcialmente presentes com definicoes e spawns.
- Herald of Fire tem definicao, mas nao tem spawn ativo detectado no XML principal.
- Matilda, A Strange Whirl e Saturnin nao tem spawn ativo detectado.
- Estado recomendado: manter como `PARTIAL` ate teste real de mapa, ferry/travel, boss room, quest storages, deaths e rewards.

## Monsters

Status geral: `PARTIAL / CUSTOMIZED`.

Ausentes no Remastered atual em relacao ao upstream 15.24:

- `elderbloodjaw`
- `Infernoid Blob`
- `Infernoid Hound`
- `Infernoid Soul`
- `Infernoid Spiritual`
- `Lizard Commander`
- `Lizard Executioner`
- `Lizard Henchman`
- `Lizard Magician`
- `Lizard Swordmaster`
- `Pillar of Dark Energy`

Observacoes:

- 1759/1770 definicoes existem.
- 1752 definicoes presentes diferem por hash do upstream, provavelmente por customizacoes, normalizacao ou port local.
- A existencia da definicao nao garante spawn nem mecanica.
- Muitos bosses/event monsters aparecem sem spawn direto porque sao criados por scripts, levers, raids ou quest logic. Isso nao deve ser tratado automaticamente como ausencia.

## Bosses

Status geral: `CUSTOMIZED / PRESENT_UNTESTED`.

- Total upstream detectado: 453.
- Presentes: 453.
- Ausentes por definicao Lua: 0.
- Quase todos diferem por hash, entao devem ser tratados como customizados/nao testados.

Riscos:

- Boss presente como monster file pode ainda faltar em lever, teleport, reward chest, cooldown, room cleanup, storage ou spawn script.
- `Herald of Fire` tem definicao, mas nao teve spawn ativo detectado.

## NPCs

Status geral: `PARTIAL`.

NPC ausente por definicao Lua:

- `Adrian`

NPCs com definicao mas sem spawn direto detectado incluem exemplos como:

- `A Beautiful Girl`
- `A Dead Bureaucrat`
- `A Frog`
- `Adolfo`
- `Adrian`
- `An Ominous Bat`
- `Anaztassja Moroia Init`
- `Archery`
- `Bambi Bonecrusher`
- `Captain Haba (Open Sea)`
- `Dal the Huntress (Day)`
- `Dal the Huntress (Night)`
- `Emiliana` esta spawnada, mas outros NPCs Targuna esperados nao foram detectados.

Observacao: varios NPCs sem spawn direto podem ser summonados ou alternados por scripts/eventos. Eles precisam de teste funcional antes de qualquer classificacao `PRESENT_AND_WORKING`.

## Quests

Status geral: `PARTIAL / PRESENT_UNTESTED`.

Quest ausente por inventario de scripts:

- `newhaven`

Quest modificada por estrutura/quantidade de arquivos:

- `rotten_blood_quest`

Classificacao:

| Quest | Status | Motivo |
|---|---|---|
| `newhaven` | `MISSING` | Existe no upstream 15.24 e nao foi detectada no conjunto atual de scripts/lib quests. |
| `rotten_blood_quest` | `CUSTOMIZED / PARTIAL` | Existe nos dois lados, mas com diferenca estrutural. |
| Demais 124 quests detectadas | `PRESENT_UNTESTED` | Arquivos presentes; integracao de storages, NPCs, movements, actions, bosses e rewards nao foi executada. |

## Spells E Runas

Status geral de spells: `PARTIAL / CUSTOMIZED`.

Spells ausentes:

- `agonyfield`
- `Aura of Exposed Weakness`
- `Aura of Sapped Strength`
- `chagorzring`
- `Death Echo`
- `Divine Barrage`
- `Divine Defiance`
- `Elemental Synthesis`
- `Ethereal Barrage`
- `Forked Glacier`
- `Forked Thorns`
- `Life Drain Circle`
- `Master of Decay`
- `Master of Flames`
- `Master of Thunder`
- `murcionring`
- `pillar chain`
- `Shared Conservation`
- `Shield Bash`
- `Shield Slam`
- `Thousand Fist Blows`

Runas:

- 42/42 presentes.
- Todas aparecem modificadas por hash.
- Isso e esperado/aceitavel para a customizacao Remastered informada: runas ofensivas +30%.

Spells:

- 794/815 presentes.
- Quase todas aparecem modificadas por hash.
- Isso e esperado/aceitavel para a customizacao Remastered informada: spells ofensivas +15%.
- As ausencias acima devem ser revisadas separadamente por vocacao, especialmente Monk e spells novas/rotas de mastery.

Classificacao por vocacao:

| Vocacao | Status | Observacao |
|---|---|---|
| Sorcerer | `CUSTOMIZED / PRESENT_UNTESTED` | Spells ofensivas alteradas; exige teste de formulas e cooldowns. |
| Druid | `CUSTOMIZED / PRESENT_UNTESTED` | Spells ofensivas e heals precisam teste de formula. |
| Knight | `PARTIAL` | `Shield Bash` e `Shield Slam` ausentes. |
| Paladin | `CUSTOMIZED / PRESENT_UNTESTED` | Ranged/ammo e spells presentes em grande parte, mas ha itens de arrows ausentes. |
| Monk | `PARTIAL` | `Thousand Fist Blows`, `Shared Conservation` e possiveis spells/aura ausentes. |

## Items E Equipamentos

Status geral: `PARTIAL / CUSTOMIZED`.

Itens ausentes:

- `43501 the essence of Murcion`
- `43502 the essence of Ichgahal`
- `43503 the essence of Vemiath`
- `43504 the essence of Chagorz`
- `43744 rotten mushroom`
- `43787 rotten mushroom`
- `43788 rotten mushroom`
- `43789 rotten mushroom`
- `43790 rotten mushroom`
- `43792 rotten crystal`
- `43793 broken rotten crystal`
- `43794 rotten crystal`
- `43795 broken rotten crystal`
- `43796 rotten crystal`
- `43797 broken rotten crystal`
- `43798 rotten crystal`
- `43799 broken rotten crystal`
- `43800 rotten crystal`
- `43801 broken rotten crystal`
- `43854 tainted heart`
- `43855 darklight heart`
- `52964 charred mask`
- `53002 gold tooth`
- `53003 lizard tail`
- `53004 infernoid ember`
- `53005 sailor's burn cure`
- `53073 bunch of turnips`
- `53162 superior mana potion`
- `53163 distilled superior mana potion`
- `53164 distilled ultimate mana potion`
- `53168 shatterstorm arrow`
- `53169 firestorm arrow`
- `53170 terrastorm arrow`
- `53171 froststorm arrow`
- `53172 thunderstorm arrow`
- `54266 lesser proficiency catalyst`

Equipamentos/ammo ausentes:

- `52964 charred mask`
- `53168 shatterstorm arrow`
- `53169 firestorm arrow`
- `53170 terrastorm arrow`
- `53171 froststorm arrow`
- `53172 thunderstorm arrow`

Conclusao:

- 17534/17570 item IDs presentes.
- 1470/1476 equipamentos detectados presentes.
- 517 itens/equipamentos diferem por atributos/nome em relacao ao upstream.
- Itens ausentes tem impacto direto em Rotten Blood, Infernoid/Lizard/Targuna support, superior mana/distilled potions, arrows elementais e proficiency catalyst.

## Sistemas

| Sistema | Status | Evidencia estatica |
|---|---|---|
| Forge | `PARTIAL` | 15/16 arquivos relacionados presentes; falta `src/enums/forge_conversion.hpp` no runtime comparado. |
| Prey | `PARTIAL` | Arquivos IO upstream ausentes no runtime comparado: `src/io/ioprey.cpp/.hpp`. |
| Bestiary | `PARTIAL` | Arquivos IO upstream ausentes no runtime comparado. |
| Bosstiary | `PARTIAL` | Arquivos IO upstream ausentes no runtime comparado. |
| Charms | `PARTIAL` | Funcoes C++ de charm upstream ausentes no runtime comparado. |
| Imbuements | `PARTIAL` | Funcoes C++ e player imbuements upstream ausentes no runtime comparado. |
| Weapon Proficiency | `PARTIAL` | `data/json/proficiencies.json` upstream e arquivos C++ de proficiency nao foram detectados no runtime atual. |
| Store | `CUSTOMIZED` | Arquivos presentes, todos modificados. |
| Daily Rewards | `CUSTOMIZED` | Arquivos presentes, todos modificados. |
| Reward / Reward Chest | `PARTIAL` | Arquivos C++ de reward container/chest upstream ausentes no runtime comparado. |
| Hazard | `CUSTOMIZED` | Arquivos presentes, modificados. |
| Wheel | `PARTIAL` | Varios arquivos C++ de wheel/gems upstream ausentes no runtime comparado. |
| Animus Mastery | `MISSING` | `src/creatures/players/animus_mastery` nao detectado no runtime atual. |
| Concoctions | `CUSTOMIZED` | Arquivos presentes, modificados. |

Nota: a pasta `Server` auditada e um runtime empacotado e nao contem todo o `src/` do upstream. Por isso, sistemas marcados como `PARTIAL` por ausencia de `src/` precisam de uma auditoria do binario/commit de build antes de concluir que a feature nao existe no executavel. Do ponto de vista de repositorio local, a dependencia fonte nao esta presente.

## Banco E Migrations

Status: `PRESENT_UNTESTED`.

- Tabelas upstream detectadas: 53.
- Tabelas atuais detectadas: 53.
- Tabelas ausentes: 0.

Riscos:

- A igualdade de nomes de tabela nao prova igualdade de colunas, constraints, indices ou migrations aplicadas.
- Nenhuma migration foi executada.
- O schema atual deve ser validado em banco descartavel antes de importar conteudo que dependa de novas storages/sistemas.

## Client / Assets

Status: `PARTIAL / CUSTOMIZED`.

- `Client/package.json` informa versao `15.24.eb0021`.
- Arquivos listados no package: 1451.
- Arquivos ausentes conforme package: 1.
- Ausente detectado: `bin/client_launcher.exe`.
- `Server/data/items/appearances.dat` existe, mas difere do upstream.
- `appearances.dat` atual: `4845624` bytes.
- `appearances.dat` upstream: `4862378` bytes.

Conclusao:

- O client atual e 15.24, mas ha pelo menos uma dependencia de package ausente.
- A divergencia de `appearances.dat` exige validar item appearances, outfits, mounts e effects usados por itens ausentes e Targuna.
- A lista de itens ausentes inclui IDs 53xxx/54xxx, entao client/protocolo deve ser conferido antes de importar esses itens.

## Lista Priorizada De Conteudo Ausente

### PRIORIDADE 1 - Mapa / Hunt

- Nenhum diretorio de area/hunt ausente foi detectado no inventario de `world/quest`, `world/world_changes`, `world/annual_events` e `world/custom`.
- Mesmo assim, o mapa global esta customizado e maior que o upstream; precisa validacao visual e runtime.
- Targuna/Aragonia deve permanecer prioridade 1 porque esta `PARTIAL`: pirates spawnados, mas boss/NPCs/teleports nao estao completos.

### PRIORIDADE 2 - Quests E Bosses

- `newhaven` ausente.
- `rotten_blood_quest` modificada, revisar dependencias dos itens Rotten Blood ausentes.
- `Herald of Fire` sem spawn ativo detectado.
- Bosses por definicao estao presentes, mas levers/rewards/cooldowns nao foram testados.

### PRIORIDADE 3 - NPCs / Spawns

- NPC ausente: `Adrian`.
- Targuna NPCs sem spawn ativo detectado: `Matilda`, `A Strange Whirl`, `Saturnin`.
- Revisar NPCs definidos mas sem spawn direto, principalmente variantes day/night, event NPCs e quest NPCs.

### PRIORIDADE 4 - Items / Equipments

- Importar/validar itens ausentes de Rotten Blood, Infernoid, Lizard/Targuna, potions superiores, arrows elementais e proficiency catalyst.
- Equipamentos/ammo ausentes: `charred mask`, `shatterstorm arrow`, `firestorm arrow`, `terrastorm arrow`, `froststorm arrow`, `thunderstorm arrow`.

### PRIORIDADE 5 - Sistemas

- Validar fonte/binario de `Animus Mastery`.
- Validar `Weapon Proficiency`, incluindo `data/json/proficiencies.json`.
- Validar Forge, Prey, Bestiary, Bosstiary, Charms, Imbuements, Wheel e Reward Chest contra o binario real.

## Recomendacao Final

1. Percentual estimado de completude 15.24: **98.8% estatico**, **85-90% operacional estimado**.
2. Hunts ausentes: nenhuma ausente por diretorio, mas Targuna/Aragonia esta parcial e precisa teste real.
3. Quests ausentes: `newhaven`.
4. Bosses ausentes por definicao: nenhum. Boss incompleto evidente: `Herald of Fire` sem spawn ativo.
5. NPCs ausentes: `Adrian`. NPCs Targuna sem spawn ativo: `Matilda`, `A Strange Whirl`, `Saturnin`.
6. Monsters ausentes: 11 listados na secao Monsters.
7. Spells ausentes: 21 listadas na secao Spells.
8. Runes ausentes: nenhuma.
9. Equipamentos ausentes: 6 listados na secao Items E Equipamentos.
10. Sistemas incompletos: Forge, Prey, Bestiary, Bosstiary, Charms, Imbuements, Weapon Proficiency, Reward, Wheel, Animus Mastery.
11. Dependencias de mapa: validar `world.otbm` customizado, Targuna map fragment, spawns XML, NPC positions, teleports e boss rooms.
12. Dependencias de client/protocolo: validar `15.24.eb0021`, `appearances.dat`, item appearances 53xxx/54xxx, outfits/mounts e `bin/client_launcher.exe` ausente no package.
13. Baixo risco para importar: definicoes pontuais de itens ausentes sem scripts complexos, como loot items simples e potions, desde que appearances existam.
14. Exige adaptacao: spells Monk/Knight novas, Rotten Blood, Infernoid/Lizard chain, Targuna ferry/teleports/bosses, Weapon Proficiency e Animus Mastery.
15. Ordem recomendada:
    - validar mapa global atual e Targuna em servidor descartavel;
    - completar itens/equipamentos ausentes com checagem de appearance;
    - completar monsters ausentes e conectar spawns/loot;
    - completar NPCs ausentes e posicoes;
    - completar `newhaven` e revisar `rotten_blood_quest`;
    - completar spells ausentes preservando +15% ofensivo e runas +30%;
    - auditar binario/sources dos sistemas marcados como `PARTIAL`;
    - executar suite de teste em banco descartavel, sem migrations no banco real;
    - somente depois planejar imports controlados por patch.

