# Upstream Migration Guide

## Regra principal

Toda migracao deve ser proposta, revisada e aprovada antes de alterar gameplay. Este guia descreve o processo para uma futura implementacao, nao executada nesta fase.

## Ordem recomendada

1. Conteudo de baixo risco.
2. Itens.
3. Monstros simples.
4. NPCs simples.
5. Quests sem migrations.
6. Bosses isolados.
7. Mapas/areas.
8. Sistemas Lua/XML.
9. Banco/migrations.
10. Engine C++.
11. Protocolo/client.

## Checklist antes de importar

- Confirmar que o arquivo nao conflita com Remastered Core.
- Confirmar que nao altera XP 8x, Skills 3x, Magic Level 3x, Attack Speed 1.3x, spells +15% ou runas +30%.
- Confirmar que nao toca em Launcher, Auto-Update, Multiplayer ou Host Assistido.
- Confirmar que o recurso pode iniciar desativado.
- Confirmar rollback.

## Estrutura do pacote

```text
Modules/Remastered/Upstream/<NomeDoPacote>/
  module.json
  main.lua
  README.md
  data/
  tests/
```

## Feature flag

Toda novidade deve iniciar desligada:

```lua
enable_upstream_pack_01 = false
```

## Banco de dados

Nunca executar SQL upstream no banco real. Processo obrigatorio:

1. backup;
2. restauracao em copia;
3. execucao de migration em sandbox;
4. validacao de rollback;
5. validacao de login/personagem/persistencia;
6. aprovacao manual.

## Protocolo/client

Mudanca de protocolo e projeto separado. Antes de qualquer tentativa:

- documentar protocolo atual;
- documentar protocolo novo;
- listar packets alterados;
- validar client 15.25;
- validar assets;
- validar Launcher;
- validar Multiplayer;
- validar contas/personagens.

## Testes obrigatorios

1. StrictRuntime.
2. Validacao Lua.
3. Validacao XML.
4. Validacao JSON.
5. Validacao SQL.
6. Inicializacao do servidor.
7. Launcher.
8. Jogar Offline.
9. Login.
10. Lista de personagens.
11. Persistencia.
12. Hospedar Mundo.
13. Multiplayer basico.
14. Balanceamento Remastered.
15. Atualizacao automatica.

Se qualquer regressao aparecer, nao integrar.

## Primeiro pacote recomendado

Nome sugerido:

```text
Update Pack 01 - Low Risk Datapack Additions
```

Escopo recomendado:

- pequenas adicoes Lua/XML sem banco;
- weapons/arrows simples;
- eventuais monstros sem spawn automatico;
- nada de protocolo;
- nada de Core;
- nada de migration.

