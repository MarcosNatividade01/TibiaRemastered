# Targuna Merge Report

## Escopo

Aplicar `MapPatches/Targuna/map-fragment.otbm` em uma copia sandbox do mapa global atual, sem alterar `Server/data-global/world/world.otbm` nem `Server/data-crystal/world/world.otbm`.

## Entradas

| Arquivo | Uso |
| --- | --- |
| `Server/data-global/world/world.otbm` | mapa base, somente leitura |
| `MapPatches/Targuna/map-fragment.otbm` | fragmento fonte |
| `MapPatches/Targuna/targuna-sandbox.bounds.csv` | bounds de validacao da area relocada |

## Dry-run

Comando:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\OTBMMerger\Merge-OTBMFragment.ps1 -BaseMap Server\data-global\world\world.otbm -Fragment MapPatches\Targuna\map-fragment.otbm -OffsetX 18070 -OffsetY 18120 -OffsetZ 0 -ExpandMapBounds -DryRun -Report UpstreamTesting\TargunaMerge\targuna-merge-dryrun.json
```

Resultado:

| Campo | Valor |
| --- | ---: |
| status | `passed` |
| blocking issues | `0` |
| warning issues | `3` |
| fragment tiles | `23,035` |
| fragment tile areas | `514` |
| target floors z6/z7/z8/z12 | `959 / 11,297 / 9,544 / 1,235` |

Warnings:

- `Dawnport Tutorial` ja existe e foi pulada;
- `Targuna` ja existe e foi pulada;
- root width/height precisou expandir.

## Merge Sandbox

Saida:

- `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`

Resultado:

| Campo | Valor |
| --- | ---: |
| status | `passed` |
| output bytes | `195,187,258` |
| SHA-256 | `07485F182DAA05761D8DC3F8F65B07AB73267E3328280F79F60A6BD9C0906697` |
| merged tiles | `23,035` |
| merged tile areas | `6` |
| expanded width | `51,631` |
| expanded height | `50,881` |
| blocking issues | `0` |
| warning issues | `5` |

Os warnings de town aparecem novamente durante a etapa de aplicacao porque a analise e repetida antes do merge efetivo.

## Validacao pelo Parser

Arquivo validado:

- `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`

Resultado:

| Campo | Valor |
| --- | ---: |
| status | `passed` |
| selected tiles nos bounds sandbox | `23,035` |
| selected tile areas | `6` |
| map width | `51,631` |
| map height | `50,881` |
| selected house IDs | `3702`, `3701` |
| errors | nenhum |

## Teste de Conflito

Teste com offset zero:

- relatorio: `UpstreamTesting/TargunaMerge/test-conflict-offset0.json`
- resultado: `blocked`
- blocking issues: `22,111`
- motivo: tiles do fragmento colidem com tiles ja existentes no mapa base.

## Arquivos Externos Sandbox

Criado em:

- `UpstreamTesting/TargunaMerge/world/world.otbm`
- `UpstreamTesting/TargunaMerge/world/world-monster.xml`
- `UpstreamTesting/TargunaMerge/world/world-npc.xml`
- `UpstreamTesting/TargunaMerge/world/world-house.xml`
- `UpstreamTesting/TargunaMerge/world/world-zones.xml`

`world-monster.xml` e `world-npc.xml` receberam os grupos candidatos de Targuna com o mesmo offset X/Y/Z.

Validacao:

- XML: `PASS`
- JSON reports: `PASS`

## Nao Executado

| Teste | Status | Motivo |
| --- | --- | --- |
| Abrir `world-targuna-test.otbm` no RME4 | `NOT_EXECUTED` | requer validacao GUI/manual |
| Round-trip RME4 do mapa mesclado | `NOT_EXECUTED` | depende da abertura no RME4 |
| Iniciar servidor de teste | `BLOCKED` | falta runtime isolado apontando para `UpstreamTesting/TargunaMerge/world` |
| Personagem entrar em Targuna | `NOT_EXECUTED` | depende do servidor de teste |
| Testar NPCs/spawns/monsters/loot/scripts in-game | `NOT_EXECUTED` | depende do servidor de teste |

## Status

`PARTIALLY_READY`

Motivo: o mapa sandbox foi gerado e reabriu pelo parser, mas ainda nao passou por RME4, round-trip visual, boot de servidor e teste jogavel.

## Atualizacao - Runtime Isolado 2026-07-15

Foi criado runtime isolado em:

- `UpstreamTesting/TargunaRuntime/Server`

O mapa sandbox foi copiado para:

- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world.otbm`

SHA-256 do mapa:

- `07485F182DAA05761D8DC3F8F65B07AB73267E3328280F79F60A6BD9C0906697`

Validacao do parser no runtime:

| Campo | Valor |
| --- | ---: |
| status | `passed` |
| selected tiles | `23,035` |
| selected tile areas | `6` |
| selected house IDs | `3702`, `3701` |
| map width | `51,631` |
| map height | `50,881` |

Boot do servidor:

| Teste | Status | Observacao |
| --- | --- | --- |
| Banco de teste | PASS | `otserv_targuna_test` criado a partir de `Database_Template/otserv.sql` |
| Servidor online | PASS | `TargunaSandbox server online` |
| Erros fatais | PASS | nenhum erro fatal observado |
| Monstros/NPCs Targuna | PASS | apos copiar definicoes para o datapack sandbox |
| Quest/storage U15_24 | PASS | apos copiar libs upstream para o datapack sandbox |
| Event callbacks secundarios | FAIL | incompatibilidade com engine atual |
| RME4 visual | NOT_EXECUTED | pendente |
| Round-trip RME4 | NOT_EXECUTED | pendente |
| Teste in-game | NOT_EXECUTED | pendente |

Conclusao:

O merge OTBM e o boot de servidor isolado passaram, mas Targuna permanece `PARTIALLY_READY`.

## Atualizacao - Validacao Final Automatizavel 2026-07-16

| Item | Status | Resultado |
| --- | --- | --- |
| SHA-256 `world-targuna-test.otbm` | PASS | `07485F182DAA05761D8DC3F8F65B07AB73267E3328280F79F60A6BD9C0906697` |
| Round-trip RME4 | BLOCKED | Save As automatizado nao criou `world-targuna-rme4-roundtrip.otbm` |
| Parser round-trip | NOT_EXECUTED | sem arquivo gerado |
| Boot runtime isolado | PASS | processo sandbox ficou ativo apos 20s |
| Portas runtime isolado | PASS | `7271` e `7272` aceitaram conexao TCP local |
| Coordenadas Hub | PASS | NPCs relocados dentro dos bounds |
| Coordenadas Aragonia | PASS | 88 spawns dentro dos bounds |
| Coordenadas Crimson Court | PASS | NPC em z12 dentro dos bounds |
| Regressao de producao | PASS | mapa oficial nao foi modificado |

Status final desta rodada: `PARTIALLY_READY`.

## Atualizacao - Callback Secundario 2026-07-16

`eventcallbacks_secondary_tasks.lua` foi ajustado no runtime sandbox:

- `playerOnStorageUpdate`: mantido e registrado com `:type("playerOnStorageUpdate")`.
- `playerOnStowItem`: desativado porque nao existe na engine atual.
- `playerOnStashWithdraw`: desativado porque nao existe na engine atual.

Boot apos ajuste:

| Teste | Status |
| --- | --- |
| `Invalid EventCallback` removido | PASS |
| servidor online | PASS |
| novo erro critico de Targuna | PASS, nenhum observado |

RME4 visual, round-trip RME4 e teste in-game seguem pendentes.
