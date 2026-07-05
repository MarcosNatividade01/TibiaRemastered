# Lua XML SQL Audit

Auditoria dos arquivos Lua, XML e SQL reais encontrados no pacote runtime.

Fonte auditada inicialmente:

```text
tmp/player-package-download/TibiaRemastered-Player.zip
```

Na Fase 3.1, o runtime foi extraido para `Server/` e `Database_Template/`.

## Contagem por raiz

| Raiz | Lua | XML | SQL | OTBM | JSON |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Server/data` | 708 | 15 | 0 | 0 | 2 |
| `Server/data-crystal` | 2412 | 7 | 0 | 1 | 0 |
| `Server/data-global` | 4792 | 164 | 0 | 32 | 0 |
| `Server/` raiz | n/a | n/a | 4 | n/a | 6 |
| `Database_Template/mysql/share` | n/a | 25 | 10 | n/a | n/a |

Total observado no pacote `Server/`:

- Lua: 7913
- XML: 186
- SQL: 4
- OTBM: 33

## Arquivos de inicializacao

Arquivos principais:

- `Server/config.lua`
- `Server/data/core.lua`
- `Server/data/global.lua`
- `Server/data/update.lua`
- `Server/data/stages.lua`
- `Server/data/libs/libs.lua`
- `Server/data/libs/systems/load.lua`
- `Server/data/modules/modules.xml`

Configuracao importante:

- `dataPackDirectory = "data-global"`
- `coreDirectory = "data"`

Isso indica que o core vem de `Server/data` e o datapack ativo vem de `Server/data-global`.

## Sistemas identificados por arquivos

| Sistema | Evidencia principal | Status |
| --- | --- | --- |
| Spells | `Server/data/scripts/spells/`, `register_spells.lua` | Encontrado |
| Runas | `Server/data/scripts/runes/` | Encontrado |
| Vocation | `Server/data/XML/vocations.xml`, libs de vocation | Encontrado |
| Items | `Server/data/items/items.xml`, `appearances.dat`, actions de items | Encontrado |
| Monsters | `Server/data-crystal/monster/`, `Server/data-global/monster/`, libs de monster | Encontrado |
| NPCs | `Server/data-crystal/npc/`, `Server/data-global/npc/`, `Server/data/npclib/` | Encontrado |
| Quests | `Server/data/scripts/lib/quests.lua`, arquivos de quest em scripts | Encontrado |
| Respawn/world | `Server/data-global/world/`, arquivos `.otbm`, eventos de respawn | Encontrado |
| Store | `Server/data/modules/scripts/gamestore/`, `store_coins.lua` | Encontrado |
| Tibia coins | `store_coins.lua`, gamestore, coluna `coins` usada no endpoint | Encontrado |
| Prey | referencias em docs/scripts de auditoria e eventos | Encontrado parcialmente |
| Forge | `exaltation_forge.lua`, actions de forge | Encontrado |
| Bestiary/charms | `register_bestiary_charm.lua`, `bestiary_charms.lua` | Encontrado |
| Imbuements | `Server/data/XML/imbuements.xml`, shrine/actions | Encontrado |
| Cooldowns | disperso em scripts de spells/actions/events | Encontrado por sistema |
| Skills | config/rates e scripts de treinamento/offline training | Encontrado parcialmente |
| Loot | sistemas de loot em monsters/boss/reward, docs de auditoria | Encontrado parcialmente |
| Login | endpoint launcher + servidor real | Encontrado parcialmente |
| Criacao de personagem | endpoint launcher + schema SQL | Encontrado parcialmente |
| Saves | banco MySQL local e server persistence | Encontrado parcialmente |
| Raids | `Server/data/libs/systems/raids.lua`, `Server/data-global/raids/` | Encontrado |
| Daily reward | `daily_reward.lua`, libs de daily reward | Encontrado |
| Hireling | `hireling.lua`, `hireling_module.lua`, actions de hireling | Sistema existente no pacote |
| Familiar | `familiar.lua`, creaturescripts de familiar | Sistema existente no pacote |

Observacao: sistemas existentes como familiar/hireling foram apenas mapeados. Nenhuma mecanica nova foi adicionada.

## Diretórios principais

### `Server/data`

Contem core, libs, modules, migrations, chatchannels, items e scripts base.

Subdiretorios principais:

- `chatchannels`
- `events`
- `items`
- `libs`
- `migrations`
- `modules`
- `npclib`
- `scripts`
- `XML`

### `Server/data/scripts`

Subdiretorios observados:

- `actions`
- `creaturescripts`
- `eventcallbacks`
- `globalevents`
- `lib`
- `movements`
- `runes`
- `spells`
- `systems`
- `talkactions`
- `weapons`

### `Server/data-crystal`

Subdiretorios observados:

- `lib`
- `monster`
- `npc`
- `raids`
- `scripts`
- `startup`
- `world`

### `Server/data-global`

Subdiretorios observados:

- `lib`
- `monster`
- `npc`
- `raids`
- `scripts`
- `startup`
- `world`

## Arquivos SQL

Arquivos principais:

- `Database_Template/schema.sql`
- `Database_Template/otserv.sql`

Arquivos SQL de MariaDB:

- `Database_Template/mysql/share/*.sql`

Uso atual pelo launcher:

- `databaseSeedSql = "Database_Template\\schema.sql"`

Risco:

- `otserv.sql` pode conter dados iniciais adicionais ou dump; deve ser revisado antes de virar template oficial.
- `schema.sql` esta em `Database_Template/` e deve permanecer limpo, sem contas/personagens reais.

## Como testar sem alterar gameplay

Com runtime instalado nas pastas oficiais:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```

Testes manuais:

- servidor abre portas 7171 e 7172;
- banco abre porta 3306;
- endpoint web responde em 127.0.0.1;
- cliente abre;
- conta pode ser criada;
- personagem pode ser criado;
- login funciona;
- progresso persiste apos reiniciar.

## Riscos antes de gameplay

- modificar `data-crystal` pode nao afetar o jogo se `data-global` estiver ativo.
- modificar spells/runes/items sem testes pode alterar balanceamento.
- alterar `schema.sql` pode quebrar endpoint e servidor.
- publicar `Database/` ou dumps reais e proibido.
- o volume de Lua exige validacao automatica com `lua` ou `luac` instalado.
