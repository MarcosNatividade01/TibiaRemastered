# Targuna In-Game Validation

## Escopo

Registrar o estado real dos testes in-game de Targuna em runtime isolado.

Producao nao foi alterada:

- `Server/data-global/world/world.otbm` nao foi substituido.
- `Server/data-crystal/world/world.otbm` nao foi substituido.
- Nenhum release foi publicado.

## Runtime Isolado

Runtime:

- `UpstreamTesting/TargunaRuntime/Server`

Mapa:

- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world.otbm`

Banco:

- `otserv_targuna_test`

Portas:

- login/status: `7271`
- game: `7272`

## Coordenadas Sandbox

| Area | Bounds |
| --- | --- |
| Hub Targuna | `x=49985..50055, y=49995..50055, z=6..8` |
| Aragonia pirates | `x=51545..51630, y=50800..50880, z=7..8` |
| Crimson Court staging | `x=50460..50500, y=50790..50820, z=12` |

## Resultado dos Testes

| Teste | Status | Observacao |
| --- | --- | --- |
| Runtime isolado criado | PASS | criado em `UpstreamTesting/TargunaRuntime/Server` |
| Banco de teste criado | PASS | `otserv_targuna_test` importado de `Database_Template/otserv.sql` |
| Mapa do runtime validado pelo parser | PASS | 23.035 tiles nos bounds sandbox |
| XMLs do mundo validados | PASS | monster/npc/house/zones validos |
| Servidor iniciou | PASS | `TargunaSandbox server online` |
| Erro fatal OTBM | PASS | nenhum erro fatal observado |
| Monstros Targuna carregados | PASS | erros `Can not find Pirate...` removidos apos copiar scripts de monstro para sandbox |
| NPCs Targuna carregados | PASS | erros `Can not find Captain Indigo...` removidos apos copiar scripts de NPC para sandbox |
| Quest scripts Targuna carregados | FAIL | `eventcallbacks_secondary_tasks.lua` usa callbacks nao suportados |
| Boss Herald of Fire spell | PASS | `heraldoffirefields` carregado apos copiar spell upstream |
| Personagem entrou em Targuna | NOT_EXECUTED | requer cliente/login in-game |
| Movimento em Targuna | NOT_EXECUTED | requer cliente/login in-game |
| NPC dialog | NOT_EXECUTED | requer cliente/login in-game |
| Spawns in-game | NOT_EXECUTED | requer cliente/login in-game |
| Loot/XP | NOT_EXECUTED | requer cliente/login in-game |
| Teleports | NOT_EXECUTED | requer cliente/login in-game |

## Erros Restantes

Erro especifico de Targuna:

- `eventcallbacks_secondary_tasks.lua`: `Invalid EventCallback with name: {}`

Erros/avisos nao especificos de Targuna:

- `key.pem` ausente: servidor usa chave RSA padrao.
- world changes dinamicos apontam para mapas auxiliares removidos da pasta `world` isolada.
- avisos de API deprecated `player:getStorageValueByName`.

## Status

`PARTIALLY_READY`

Motivo: boot do servidor isolado passou, mas ainda faltam validacao visual RME4, round-trip RME4, login in-game, teste de movimento, NPCs, spawns, teleports e correcao/adaptacao do callback secundario.

## Atualizacao - 2026-07-16

O callback secundario foi tratado no sandbox.

| Item | Status | Observacao |
| --- | --- | --- |
| Daily reward task | PASS | `playerOnStorageUpdate` mantido |
| Stash item task | DISABLED | `playerOnStowItem` nao existe no runtime atual |
| Take from stash task | DISABLED | `playerOnStashWithdraw` nao existe no runtime atual |
| Boot apos ajuste | PASS | `TargunaSandbox server online` |
| Erro de callback | PASS | removido |

Validacao RME4 e teste in-game continuam pendentes porque a automacao de Windows nao ficou disponivel nesta sessao.

## Checklist In-Game Manual

Usar runtime:

- `UpstreamTesting/TargunaRuntime/Server`

Portas:

- login/status: `7271`
- game: `7272`

Passos:

1. iniciar o servidor em `UpstreamTesting/TargunaRuntime/Server`;
2. configurar o client para `127.0.0.1:7271/7272`;
3. entrar com conta/personagem de teste do banco `otserv_targuna_test`;
4. confirmar login e lista de personagens;
5. entrar no mundo;
6. teleportar para o hub Targuna em torno de `x=49985..50055, y=49995..50055, z=6..8`;
7. caminhar no hub e trocar floors;
8. validar NPCs: Captain Indigo, Camilla, Emiliana, Leonora, Sterling, Aurelia, Lizzie, Morla;
9. teleportar para Aragonia em torno de `x=51545..51630, y=50800..50880, z=7..8`;
10. validar spawns, movimento, combate, morte e loot dos pirates;
11. teleportar para Crimson Court em torno de `x=50460..50500, y=50790..50820, z=12`;
12. validar Herald of Fire e scripts associados;
13. validar teleports internos e externos;
14. relogar e confirmar persistencia no banco de teste.

## Atualizacao - Testes Automatizaveis 2026-07-16

Resultados obtidos sem usar banco real, personagens reais ou mapa oficial.

| Area | Teste | Status | Evidencia |
| --- | --- | --- | --- |
| Servidor | Boot curto runtime isolado | PASS | processo `crystalserver.exe` sandbox ficou ativo apos 20s |
| Servidor | Login port `7271` | PASS | conexao TCP local aceita |
| Servidor | Game port `7272` | PASS | conexao TCP local aceita |
| Login | Autenticacao protocolar | BLOCKED | nao existe cliente/headless protocol client confiavel no projeto |
| Personagem | Entrada no mundo | BLOCKED | depende do client ou protocolo completo |
| Coordenadas | Hub Targuna | PASS | NPCs em `x=49998..50043, y=50008..50040, z=6..7` |
| Coordenadas | Aragonia Pirates | PASS | 88 spawns e Morla dentro dos bounds |
| Coordenadas | Crimson Court | PASS | Emiliana em `x=50482, y=50807, z=12` |
| NPCs | Definicoes e scripts | PASS | Captain Indigo, Camilla, Emiliana, Leonora, Sterling, Aurelia, Lizzie e Morla encontrados |
| Spawns | XML e bounds | PASS | 88 spawns: 1 Freshwater Turtle, 9 Pirate Cook, 18 Pirate Gunner, 43 Pirate Navigator, 16 Pirate Quartermaster, 1 Sea Captain |
| Monstros | Definicoes | PASS | 6 monstros Aragonia + Herald of Fire encontrados |
| Combate/loot | Teste real in-game | BLOCKED | depende de personagem conectado |
| Teleports | XML/metadata | PASS | `teleports.xml` permanece documentado como blocked por quest/travel, sem ativacao silenciosa |
| Scripts | Boot Lua | PASS | sem `Invalid EventCallback` e sem erro Targuna no boot ajustado |

Status: `PARTIALLY_READY`.

## Atualizacao Final GUI Manual - 2026-07-16

Evidencia aceita: teste GUI manual executado no client real pelo operador, em runtime sandbox, usando coordenadas originais efetivas do runtime.

Producao nao foi alterada. GitHub nao foi publicado. Targuna nao foi promovido.

### Resultado Manual Confirmado

| Criterio | Status | Evidencia |
| --- | --- | --- |
| Login | PASS | Login manual no client real |
| Entrada no mundo | PASS | Targuna Tester entrou no mundo |
| Movimento | PASS | Movimento real no mapa |
| Mapa expandido | PASS | Area preta resolvida visualmente |
| Navegacao | PASS | Mapa navegavel sem bloqueio anormal observado |
| NPC/dialogo | PASS | Dialogo manual validado |
| Escadas/floors | PASS | Transicoes reais validadas |
| Barco/rota | PASS | Rota manual validada |
| Spawns essenciais | PASS | Piratas encontrados em jogo |
| Combate | PASS | Combate real executado |
| Morte de monstros | PASS | Piratas mortos em jogo |
| Corpo de monstros | PASS | Corpos gerados |
| Loot | PASS | Loot verificado |
| Coleta de loot | PASS | Item de loot coletado |
| Morte do personagem | PASS | Morte do personagem ocorreu sem comportamento anormal |

### Evidencia Tecnica Complementar

Sessao sandbox:

- `players_online = 1`
- Targuna Tester salvo em `33494,32739,7`
- health atual no banco: `208/500`
- login probe: `player_onlogin_start` e `player_onlogin_complete` em `31947,31903,7`, `tileFound=true`

Log principal analisado:

- `UpstreamTesting/TargunaRuntime/Logs/TargunaSandbox-20260716-212705.log`

Sinais positivos no log:

- `proxy_identifying_ok`
- `rsa_ok`
- `xtea_ok`
- `auth_ok`
- `load_player_ok`
- `place_creature_ok`

Anomalia encontrada:

- `MySQL error [1062]: Duplicate entry '10' for key 'PRIMARY'` em `players_online`.

Classificacao: `NON_BLOCKING`.

Motivo: o erro ocorreu com o personagem ja online, sem crash, sem erro Lua e sem falha observada de gameplay. O estado atual confirma `players_online=1` para o player 10. Deve ser limpo/monitorado antes de uma janela de producao, mas nao bloqueia a promocao do conteudo Targuna.

Nao foram encontrados no log da sessao:

- `Lua Script Error`
- `stack traceback`
- `Unknown house id 3701`
- crash/fatal relacionado a Targuna
- erro de spawn Targuna durante a sessao manual
- erro de loot Targuna durante a sessao manual

### Auditoria de Promocao

| Area | Status | Bloqueio |
| --- | --- | --- |
| Mapa | PASS | nao |
| Navegacao | PASS | nao |
| Login | PASS | nao |
| NPCs essenciais | PASS | nao |
| Floors essenciais | PASS | nao |
| Barco/rotas | PASS | nao |
| Spawns essenciais | PASS | nao |
| Combate | PASS | nao |
| Morte de monstros | PASS | nao |
| Loot/coleta | PASS | nao |
| Morte do personagem | PASS | nao |
| Teleports essenciais | NON_BLOCKING | nao |
| Herald of Fire | NON_BLOCKING | nao |
| Quests/storages | NON_BLOCKING | nao |

GO_FOR_PROMOTION foi aprovado para promocao controlada.

## Promocao Local para Runtime Principal - 2026-07-16

Escopo aplicado somente no runtime principal local antes da publicacao:

- `Server/data-global/world/world.otbm`
- `Server/data-global/world/world-npc.xml`
- `Server/data-global/world/world-monster.xml`
- `Server/data-global/world/world-house.xml`
- `Server/data-global/world/world-zones.xml`
- NPCs essenciais de Targuna
- monstros de Targuna/Aragonia
- scripts de quest e Herald relacionados
- `Storage.Quest.U15_24.Targuna`

Coordenadas finais: coordenadas originais do runtime (`319xx/324xx/334xx`), sem aplicar o offset `500xx/515xx`.

Boot de producao:

- `Server protocol: 15.24`
- datapack ativo: `data-global`
- portas: `7171/7172`
- sem erro fatal OTBM
- sem `Unknown house id 3701`
- NPCs/spawns carregaram

Regressao de entrada:

- endpoint local corrigido para anunciar `127.0.0.1:7172`
- conta de teste local criou character list corretamente
- personagem de teste entrou em Targuna em `31946,31903,7`
- `players_online` foi de `0` para `1`
- conexao real `127.0.0.1 -> 127.0.0.1:7172`
- sem redirecionamento para Thais

Distribuicao:

- `world.otbm` continua protegido contra publicacao direta.
- O mapa promovido sera distribuido por `Server/data-global/world/map-parts/world.otbm.partNNN`.
- O Launcher monta `Server/data-global/world/world.otbm` localmente e valida o SHA256 final.

Status: `GO_FOR_PROMOTION`.
| Morte de monstros | PASS | nao |
| Loot | PASS | nao |
| Morte do personagem | PASS | nao |
| Teleports essenciais | PASS para rota/barco testada; demais internos com coordenadas validadas | NON_BLOCKING |
| Herald of Fire | Coordenadas/create PASS; encounter completo nao testado manualmente | NON_BLOCKING |
| Quests/storages | Namespace/scripts PASS; progressao completa nao testada manualmente | NON_BLOCKING |

Decisao:

```text
GO_FOR_PROMOTION
```

Justificativa: os criterios essenciais para integracao segura do mapa/conteudo base foram validados em GUI real: entrada, navegacao, NPC/dialogo, floors, rota, spawns, combate, morte, corpos, loot, coleta e morte do personagem. Herald/Crimson/quests/storages completos permanecem como regressao funcional pos-promocao ou validacao de conteudo opcional, nao como bloqueadores de integracao segura.
