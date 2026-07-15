# Tibia Remastered Upstream Update System

## Objetivo

Criar um processo controlado para comparar o Tibia Remastered atual com o Crystal Server upstream e importar apenas mudanças compatíveis, preservando:

- modo Offline;
- Multiplayer;
- Launcher;
- Auto-Update;
- Remastered Core;
- Module Loader;
- Feature Flags;
- balanceamentos Remastered;
- contas, personagens e dados locais.

Este documento define o fluxo. Nenhuma mudança de gameplay deve ser aplicada automaticamente nesta fase.

## Fotografia tecnica atual

| Item | Estado identificado |
| --- | --- |
| Projeto | TibiaRemastered |
| Versao do pacote | 0.1.25-test |
| Branch local | main |
| Commit local | 8ec527a2 - Corrige login e personagens por conta |
| Base declarada | Crystal Server |
| Upstream declarado no README do Server | https://github.com/zimbadev/crystalserver |
| Servidor runtime | `Server/crystalserver.exe` |
| Fonte C++ local | Ausente em `Server/` |
| Datapacks | `Server/data`, `Server/data-crystal`, `Server/data-global` |
| Banco modelo | `Server/schema.sql`, `Server/otserv.sql`, `Database_Template/` |
| Client local | `Client/package.json.version` = 15.24.eb0021 |
| Protocolo upstream atual | 15.25 |
| Software upstream atual | Crystal Server 4.1.9 |
| Game update upstream | Vocation Balancing |

## Upstream de referencia

O upstream foi clonado apenas para comparacao em:

```text
Upstream/CrystalLatest/
```

Referencia atual:

```text
repo: https://github.com/zimbadev/crystalserver
commit: fdd2b1f13f53894c584346ef3de43658045c42a7
data: 2026-07-14 13:38:26 -0300
mensagem: fix: Remove item IDs from enchanting registration (#827)
```

Essa pasta nao deve ser usada pelo runtime.

## Regras operacionais

1. Nunca sobrescrever `Server/`, `Client/`, `Launcher/`, `Modules/Remastered/` ou `UserData/` com upstream.
2. Nunca executar migrations upstream no banco real.
3. Nunca trocar protocolo/client como parte de um update pack comum.
4. Toda novidade importada deve ser proposta como modulo ou patch isolado.
5. Toda novidade deve iniciar desativada por feature flag quando tecnicamente viavel.
6. Todo teste deve ocorrer primeiro em `UpstreamTesting/`.

## Estrategia modular

Novidades portadas devem preferir:

```text
Modules/
  Remastered/
    Upstream/
      NewItems/
      NewMonsters/
      NewBosses/
      NewSpells/
      NewQuests/
```

Mudancas diretas em `Server/data` so devem ocorrer quando o Module Loader nao conseguir interceptar/registrar o recurso com seguranca.

## Feature flags sugeridas

```lua
enable_upstream_new_items = false
enable_upstream_new_monsters = false
enable_upstream_new_spells = false
enable_upstream_new_bosses = false
enable_upstream_rotten_blood_content = false
enable_upstream_targuna_content = false
enable_upstream_weapon_proficiency_update = false
enable_upstream_vocation_balancing = false
```

## Sandbox de testes

Criar, quando aprovado:

```text
UpstreamTesting/
  Server/
  Database/
  Logs/
  Reports/
```

Fluxo obrigatorio:

```text
importar em sandbox
validar Lua/XML/JSON/SQL
iniciar servidor de teste
testar login e personagem
testar Offline
testar Multiplayer basico
validar Launcher e Auto-Update
comparar regressões
somente depois propor integracao
```

## Artefatos gerados

Inventario estruturado:

```text
Reports/upstream_diff_inventory.json
Reports/upstream_diff_inventory.csv
```

Documentos:

```text
Docs/UPSTREAM_DIFF_REPORT.md
Docs/UPSTREAM_COMPATIBILITY_MATRIX.md
Docs/UPSTREAM_CONTENT_ROADMAP.md
Docs/UPSTREAM_MIGRATION_GUIDE.md
```

