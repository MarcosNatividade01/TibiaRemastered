# Targuna 15.24 and Protocol 15.25 Report

## Trilha A - Targuna 15.24

Status: `PARTIALLY_READY`.

### Itens

Resultado do porte:

- analisados: 18
- portados: 18
- falharam: 0
- dependem de 15.25: 0

Os IDs portados em `Server/data/items/items.xml` foram:

- `53074` adventurer backpack
- `53078` dead lizard henchman
- `53082` dead lizard magician
- `53086` dead lizard swordmaster
- `53090` dead lizard commander
- `53094` dead lizard executioner
- `53098` dead pirate navigator
- `53103` dead pirate quartermaster
- `53108` dead herald of fire
- `53110` dead pirate gunner
- `53113` dead pirate cook
- `53119` dead sea captain
- `53122` dead infernoid hound
- `53125` dead infernoid soul
- `53128` dead infernoid spiritual
- `53132` dead infernoid blob
- `53158` old treasure map
- `53167` sail pass

Validacoes:

- XML: passou.
- IDs presentes: passou.
- duplicidade de `<item id="...">`: passou.
- appearances 15.24: passou em 18/18.

### OTBM

Ferramenta OTBM encontrada: nenhuma.

Compatibilidade OTBM: nao validada, porque nao ha RME/Remere ou outro parser/exporter OTBM confiavel disponivel neste ambiente.

Round-trip OTBM: nao executado.

`MapPatches/Targuna/map-fragment.otbm`: nao criado.

Motivo: gerar um fragmento sem ferramenta confiavel seria risco de mapa falso/corrompido.

### Sandbox

Resultado:

- Targuna `Validate`: passou.
- XML/JSON: passou.
- Map Patch Pipeline completo: ficou preso ate timeout nesta ultima execucao; havia passado na execucao anterior.
- Spawns ativos: 0.
- NPCs ativos: 0.
- teste jogavel real: bloqueado pela ausencia de `map-fragment.otbm`.

Conteudo funcional agora:

- definicoes de itens server-side para Targuna 15.24.
- scripts, spawns e NPC positions seguem empacotados para sandbox.

Conteudo ainda bloqueado:

- tiles reais de Targuna;
- relocalizacao do mapa;
- ativacao de spawns/NPCs;
- teleports reais;
- teste jogavel com monstros, loot, NPCs, quest e boss.

## Trilha B - Preparacao 15.25

Status: documentada, isolada, nao promovida.

Branch `migration/protocol-15.25`: nao criada.

Motivo: a working tree contem alteracoes pendentes da trilha Targuna 15.24. Criar a branch agora carregaria essas alteracoes para a trilha 15.25.

Estrutura criada:

- `Migration/Protocol_15_25/README.md`
- `Migration/Protocol_15_25/Reports/go-no-go.md`
- `Docs/PROTOCOL_15_25_DIFF.md`

Principais diferencas confirmadas:

- upstream declara `CLIENT_VERSION = 1525`;
- runtime oficial permanece em client `15.24.eb0021`;
- pacote local contem `Server/crystalserver.exe`, mas nao contem `Server/src`, limitando diff C++ local;
- migrations existem ate `63.lua` local e upstream, mas os hashes diferem em 64/64 arquivos comparados.

Mudancas obrigatorias de protocolo:

- gate de versao do cliente;
- `ProtocolGame`;
- `ProtocolLogin`;
- `ProtocolStatus`;
- login/character list;
- opcodes de game protocol.

Mudancas obrigatorias de client:

- client 15.25 separado;
- appearances/assets 15.25;
- validacao de UI/modules/network messages;
- nao substituir client 15.24 oficial.

Mudancas obrigatorias de server:

- source C++ 15.25 ou patch equivalente;
- validacao de protocolo;
- runtime separado;
- testes de boot/login/game.

Banco:

- nao executar migrations upstream no banco real;
- criar diff semantico;
- testar somente em copia;
- validar rollback.

Recomendacao:

- `CONDITIONAL GO` para continuar estudando em ambiente isolado.
- `NO-GO` para promover 15.25 ao runtime oficial agora.

## Gates

- `MinimumQA`: passou.
- `UpdateSimulation`: passou.
- `StrictRuntime`: falhou por manifest hash mismatch em arquivos modificados nesta etapa:
  - `Modules/Remastered/Config/features.lua`
  - `Server/data/items/items.xml`
  - `Tools/MapPatch/Invoke-MapPatch.ps1`
- `StrictRuntime` tambem avisou que `lua/luac` nao esta no PATH.

Manifest nao foi regenerado porque nao houve publicacao.
