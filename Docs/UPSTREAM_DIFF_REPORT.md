# Upstream Diff Report

## Escopo

Comparacao entre:

- atual: `Server/`
- upstream: `Upstream/CrystalLatest/`

O runtime de producao nao foi alterado.

## Resumo numerico

| Status | Quantidade |
| --- | ---: |
| Iguais | 34 |
| Modificados | 8099 |
| Apenas no Remastered | 86 |
| Apenas no upstream | 685 |
| Total de caminhos comparados | 8904 |

## Por categoria

| Categoria | Iguais | Modificados | Apenas Remastered | Apenas Upstream |
| --- | ---: | ---: | ---: | ---: |
| CORE | 0 | 0 | 0 | 471 |
| DATAPACK | 2 | 1984 | 20 | 72 |
| CONTENT | 32 | 5986 | 54 | 88 |
| DATABASE | 0 | 75 | 1 | 0 |
| BUILD | 0 | 26 | 0 | 13 |
| DOCS | 0 | 3 | 7 | 7 |
| OTHER | 0 | 25 | 4 | 34 |

## Core

O projeto atual nao contem `Server/src`. O upstream contem 471 arquivos de Core C++ em `src/`, incluindo:

- account;
- config;
- protocol;
- combat;
- creatures;
- player;
- monsters;
- persistence;
- Lua bindings;
- IO de prey, bestiary, bosstiary e banco.

Conclusao: qualquer alteracao de engine deve ser tratada como projeto separado. Nao ha base C++ local versionada para aplicar patch seguro diretamente.

## Protocolo e client

| Item | Atual | Upstream |
| --- | --- | --- |
| Client local | 15.24.eb0021 |
| Protocolo upstream | 15.25 |
| Software upstream | Crystal Server 4.1.9 |
| Game update upstream | Vocation Balancing |

O upstream usa `CLIENT_VERSION = 1525`. Mudanca de protocolo deve ficar fora do Update Pack 01.

## Datapack

Principais novidades detectadas apenas no upstream:

- `data/libs/systems/monster_ai.lua`;
- `data/modules/scripts/cursor_aim/cursor_aim.lua`;
- scripts de Rotten Blood Quest;
- scripts de Targuna;
- scripts de Newhaven;
- novas spells de ataque e suporte;
- novas arrows/weapon scripts;
- ajustes em gamestore, daily reward, potions, player events e register_spells.

## Content

Principais conteudos apenas no upstream:

- monstros de Rotten Blood;
- bosses de Rotten Blood;
- conteudo Targuna;
- novos bosses em `data-global/monster/bosses`;
- novos arquivos de world/quest relacionados;
- ajustes amplos em monstros existentes.

## Database

Foram detectadas 75 diferencas de banco/migrations modificadas. A migration 52 aparece equivalente entre atual e upstream e declara:

```text
feat: support to 14.11
```

Mesmo quando o conteudo SQL parecer igual, nenhuma migration deve ser executada no banco real sem backup, copia de teste e rollback documentado.

## Customizacoes Remastered detectadas

Arquivos Remastered-only relevantes:

- `Server/data/remastered_bootstrap.lua`;
- `Server/data/scripts/eventcallbacks/player/on_gain_experience_solo_balance.lua`;
- `Server/data/scripts/eventcallbacks/player/on_gain_skill_tries_solo_balance.lua`;
- `Server/data/scripts/globalevents/remastered_admin_panel.lua`;
- `Server/data/scripts/talkactions/god/remastered_balance_tests.lua`;
- documentacao de balanceamento/prey/store;
- `Modules/Remastered/*`;
- Launcher, Auto-Update, Host Assistido e ferramentas.

Esses arquivos nao devem ser removidos nem substituidos por upstream.

## Sistemas impactados

| Sistema | Sinais no diff |
| --- | --- |
| Weapon Proficiency | arquivo local em `data/items/proficiencies.json`; upstream em `data/json/proficiencies.json`; Core upstream tem `proficiencies.cpp/hpp` |
| Forge | 62 arquivos modificados e 1 novo relacionado |
| Prey | callbacks e IO C++ upstream |
| Bestiary | scripts Lua modificados e Core upstream |
| Bosstiary | scripts e IO C++ upstream |
| Imbuements | XML/Lua modificados e Core upstream |
| Store | gamestore/init modificados |
| Monk/Vocations | vocations XML, spells e Newhaven |

