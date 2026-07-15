# Upstream Compatibility Matrix

| Sistema/Conteudo | Versao Atual | Upstream | Compatibilidade | Risco | Dependencias | Recomendacao |
| --- | --- | --- | --- | --- | --- | --- |
| Itens em `items.xml` | Modificado no Remastered | Modificado upstream | B | Medio | Client assets 15.24/15.25, IDs, appearances | Comparar por ID e importar apenas itens com appearance existente no client atual |
| `data/json/proficiencies.json` | Atual em `data/items/proficiencies.json` | Novo caminho upstream | B/C | Alto | Core de proficiencies, client assets | Nao importar direto; criar auditoria especifica de Weapon Proficiency |
| Monstros Rotten Blood | Ausentes/parciais | Presentes | B/C | Medio/Alto | Scripts de quest, areas, boss mechanics, map | Portar primeiro como conteudo desativado; nao ativar sem area/mapa |
| Bosses Rotten Blood | Ausentes/parciais | Presentes | C | Alto | Bosstiary, areas, scripts, storages | Adiar para pacote especifico |
| Targuna | Ausente/parcial | Presente | B/C | Medio | Scripts, NPCs, mapa, storages | Candidato apos validação de dependencias |
| Newhaven | Custom local existe | Upstream tem fluxo proprio | E | Alto | Login/criacao/personagem, vocations, Launcher | Nao substituir; comparar manualmente |
| Novas spells de ataque | Parcial | Varias novas | B/C | Medio | `register_spells`, formulas, vocations, client spell list | Importar somente spells sem protocolo novo e com feature flag |
| Novas spells de suporte | Parcial | Varias novas | B/C | Medio | Cooldowns, vocations, UI client | Adiar ate validar client |
| Novas arrows/weapon scripts | Ausentes | Presentes | B | Baixo/Medio | Items, weapons XML, ammo effects | Bom candidato para Update Pack 01 se IDs existem |
| Monster AI | Ausente | `data/libs/systems/monster_ai.lua` | C | Alto | Lua API e possivel Core behavior | Nao importar no primeiro pacote |
| Cursor Aim | Ausente | `data/modules/scripts/cursor_aim` | D | Alto | Protocolo/client/UI | Nao importar isoladamente |
| Forge | Presente | Alterado | C | Alto | Core, banco, scripts, client | Nao alterar sem projeto de sistema |
| Prey | Presente e customizado | Alterado/Core upstream | E | Alto | Correcoes Remastered de XP/loot/store | Preservar custom; diff manual especifico |
| Bestiary/Charms | Presente | Alterado | C | Alto | Migration 52, Core, client | Nao migrar sem copia de banco |
| Bosstiary | Presente | Alterado/Core upstream | C | Alto | Core, boss cooldowns, DB | Adiar |
| Imbuements | Presente | Alterado | B/C | Medio | XML, NPCs, shrine, Core | Candidato parcial, mas nao Pack 01 |
| Store | Presente | Alterado | E | Alto | Launcher, client store, moedas, XP boost | Nao importar sem preservar fixes Remastered |
| Protocolo 15.25 | Client 15.24.eb0021 | 15.25 | D | Critico | Client, assets, packets, Launcher, Multiplayer | Projeto separado |
| Core C++ | Fonte local ausente | Fonte upstream presente | C/D | Critico | Rebuild engine, toolchain, binario | Nao substituir engine |
| Banco/migrations | Template local | 75 diffs detectados | C | Alto | Backup, copia, rollback | Testar somente em sandbox |
| Launcher/Auto-Update | Remastered custom | Nao existe upstream | E | Critico | Manifest, versioning, protected paths | Preservar integralmente |
| Module Loader | Remastered custom | Nao existe upstream | E | Critico | Feature flags, bootstrap | Preservar integralmente |
| Balance Remastered | XP/skill/loot/spell/rune custom | Nao existe upstream | E | Critico | Scripts e modules | Preservar integralmente |

## Legenda

| Classe | Significado |
| --- | --- |
| A | Compativel diretamente |
| B | Compativel com adaptacao Lua/XML/config |
| C | Requer alteracao de engine ou banco |
| D | Requer novo protocolo/client |
| E | Conflita com customizacao Remastered |

