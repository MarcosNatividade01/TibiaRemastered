# Upstream Content Roadmap

## Estado por tema

| Tema | Estado no Remastered | Upstream | Classificacao |
| --- | --- | --- | --- |
| Crystal Server base | Presente | Atualizado | Parcialmente suportada |
| Protocolo 15.25 | Client local 15.24.eb0021 | 15.25 | Depende de protocolo novo |
| Vocation Balancing | Parcial/custom | Declarado no upstream | Possivel de portar com cuidado |
| Monk | Presente/parcial | Atualizado | Parcialmente suportada |
| Weapon Proficiency | Assets e JSON local | Core e JSON upstream | Possivel de portar, depende de validacao |
| Rotten Blood | Ausente/parcial | Presente | Possivel de portar, alto risco |
| Targuna | Ausente/parcial | Presente | Possivel de portar |
| Newhaven | Custom local | Fluxo upstream | Conflita com customizacao |
| Forge | Presente | Alterado | Depende de engine/banco |
| Prey | Presente com fixes Remastered | Alterado | Conflita com customizacao |
| Bestiary/Charms | Presente | Alterado | Depende de banco/Core |
| Bosstiary | Presente | Alterado | Depende de Core |
| Imbuements | Presente | Alterado | Possivel de portar parcialmente |
| Store | Presente | Alterado | Conflita com customizacao |
| Cursor Aim | Ausente | Presente | Depende de protocolo/client |
| Monster AI | Ausente | Presente | Depende de engine/API |

## Conteudos recentes relevantes

### Baixo risco relativo

- weapon scripts de novas arrows, se os itens e effects ja existirem no client atual;
- pequenos fixes Lua sem schema;
- ajustes de XML isolados que nao mudem protocolo;
- novos monstros sem mecanica especial, se spawn/mapa nao for ativado automaticamente.

### Medio risco

- novas spells que dependem de vocations e spell list;
- novos NPCs sem store/protocolo;
- novos monstros com Bestiary simples;
- pequenos ajustes de imbuement.

### Alto risco

- Rotten Blood completo;
- Targuna completo;
- Newhaven;
- Forge;
- Prey;
- Bestiary/Bosstiary;
- qualquer migration;
- qualquer packet/protocol/client.

## Primeiro pacote recomendado

Update Pack 01 deve ser apenas analitico/baixo risco:

1. selecionar 5 a 10 arquivos `upstream_only` de weapons/spells simples;
2. validar IDs contra `Client/assets` e `Server/data/items/items.xml`;
3. criar modulo `Modules/Remastered/Upstream/NewWeapons`;
4. adicionar feature flag `enable_upstream_new_weapons = false`;
5. testar em `UpstreamTesting/`;
6. nao tocar em protocolo, banco, Launcher ou Core.

Nao incluir:

- Rotten Blood completo;
- Targuna completo;
- protocolo 15.25;
- Core C++;
- migrations;
- Store;
- Prey;
- Forge.

