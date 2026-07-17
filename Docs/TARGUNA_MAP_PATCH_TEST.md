# Targuna Map Patch Test

## Escopo

Registrar o estado do teste real do patch de mapa de Targuna antes de qualquer promocao ao runtime.

Nenhum arquivo oficial de runtime foi alterado.

## Resultado

Status: `PARTIALLY_READY`

`MapPatches/Targuna/map-fragment.otbm` ainda nao foi criado.

## Evidencias RME4

| Etapa | Resultado | Evidencia |
| --- | --- | --- |
| RME4 oficial validado | PASS | `canary-map-editor-v4.0-windows.zip`, SHA-256 `3B237C1ABE32B5FF2286E29FB1DB97AF3FD1B18DF44EC99D49AD6854D825245B` |
| Mapa atual aberto em copia | PASS | `current-crystal-rt-real/world.otbm` |
| Save As do mapa atual | PASS | `current-crystal-rt-real/world-roundtrip-rme4.otbm` |
| Reabertura do round-trip | PASS | area `x=387 y=419 z=6` renderizada |
| Upstream original aberto | FAIL | arquivo `.otbm` upstream tem assinatura gzip `1F 8B` |
| Upstream descompactado | PASS | `upstream-global-rt-real/world-decompressed.otbm` |
| Targuna localizada | PASS | hub/NPCs em `x~31942..31973 y~31888..31920 z=6..7` |
| Fragmento criado | NOT_DONE | sem crop/export seguro |
| Map Patch Pipeline com fragmento | NOT_RUN | depende do fragmento |
| Servidor de teste com Targuna | NOT_RUN | depende do fragmento |

## Coordenadas confirmadas

Bounding box amplo:

- `x=31920..33550`
- `y=31880..32760`
- `z=6..12`

NPCs usados para confirmacao:

| NPC | Coordenada |
| --- | --- |
| Captain Indigo | `31973,31892,6` |
| Camilla | `31942,31902,6` |
| Emiliana | `31960,31901,6` e `32412,32687,12` |
| Leonora | `31951,31888,7` |
| Sterling | `31928,31903,7` |
| Aurelia | `31955,31916,7` |
| Lizzie | `31941,31920,7` |
| Morla | `33514,32748,8` |

## Bloqueio atual

O RME v4.0 consegue abrir, salvar e reabrir mapas em sandbox, mas nesta etapa nao foi encontrado comando seguro para exportar automaticamente uma selecao do mapa como fragmento OTBM isolado.

Nao foi feita edicao automatica de tile, porque a automacao por GUI seria fragil e poderia gerar um falso positivo.

## Proxima acao recomendada

1. Usar RME4 manualmente em sandbox para selecionar o bounding box real de Targuna.
2. Copiar a selecao para um mapa novo, mantendo somente a area necessaria.
3. Salvar como `MapPatches/Targuna/map-fragment.otbm`.
4. Reabrir o fragmento no RME.
5. Executar o Remastered Map Patch Pipeline em copia.
6. So depois iniciar servidor de teste com mapa patchado.

Nao promover Targuna ao runtime sem aprovacao explicita.

## Execucao de Patch - 2026-07-15

O patch Targuna foi validado no modo `Validate` do pipeline:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\MapPatch\Invoke-MapPatch.ps1 -Mode Validate -PatchPath MapPatches\Targuna -Root .
```

Resultado:

```json
{
  "patchId": "targuna",
  "status": "passed",
  "issues": []
}
```

Observacao: o modo `ApplySandbox` nao foi executado nesta etapa porque o pipeline atual nao faz merge de `map-fragment.otbm`. Sem o fragmento real, `ApplySandbox` testaria apenas XML/scripts e poderia gerar falso positivo sobre jogabilidade.

## Conflitos

Nenhum conflito de coordenada foi testado com tiles reais nesta etapa, porque nao ha fragmento OTBM.

Conflitos que permanecem pendentes:

| Tipo | Status | Motivo |
| --- | --- | --- |
| Tiles existentes | Pendente | depende de aplicar fragmento em copia do mapa atual |
| House IDs | Pendente | depende de fragmento e metadata de houses |
| Town IDs | Pendente | depende de fragmento e importacao RME |
| Spawn IDs/posicoes | Pendente | 88 spawns candidatos existem em XML, mas precisam de offset e mapa real |
| NPC positions | Pendente | 9 posicoes candidatas existem em XML, mas precisam de offset e mapa real |
| Teleports | Pendente | `teleports.xml` ainda contem entradas bloqueadas/documentais |
| Action IDs / unique IDs | Pendente | depende de leitura de tiles/scripts do fragmento |

## Status Final da Etapa

`PARTIALLY_READY`

O patch esta consistente como pacote candidato, mas nao esta pronto para promocao porque:

- `MapPatches/Targuna/map-fragment.otbm` agora existe e valida pelo parser proprio;
- o pipeline atual ainda nao faz merge OTBM;
- o mapa patchado nao foi gerado;
- o round-trip do mapa patchado nao foi executado;
- o servidor de teste nao foi iniciado com Targuna;
- personagem nao entrou na area.

## Atualizacao - OTBM Fragment Extractor 2026-07-15

`MapPatches/Targuna/map-fragment.otbm` foi criado com ferramenta propria auditavel.

Resultado:

| Teste | Resultado | Observacao |
| --- | --- | --- |
| Dry-run composto Targuna | PASS | `23,035` tiles em 3 caixas controladas |
| Geracao de `map-fragment.otbm` | PASS | arquivo criado com `245,702` bytes |
| Validacao do fragmento pelo parser | PASS | reabriu `23,035` tiles |
| `Invoke-MapPatch.ps1 -Mode Validate` | PASS | sem issues |
| `Invoke-MapPatch.ps1 -Mode ApplySandbox` | PASS | sandbox criada |
| `Invoke-MapPatch.ps1 -Mode Rollback` | PASS | rollback executado |
| Reaplicacao sandbox | PASS | fluxo idempotente basico |
| Merge real dos tiles no mapa sandbox | NOT_IMPLEMENTED | pipeline atual nao mescla OTBM |
| Mapa patchado reaberto no RME4 | NOT_RUN | depende de merge OTBM |
| Servidor de teste com Targuna | NOT_RUN | depende de mapa patchado |

Observacao critica:

O pipeline atual valida metadados, scripts, XMLs e prepara sandbox, mas nao aplica `map-fragment.otbm` dentro de `world.otbm`. Portanto o resultado ainda nao pode ser classificado como `READY_FOR_PROMOTION`.

Status:

`PARTIALLY_READY`

## Merge/Relocacao OTBM - 2026-07-15

Foi criada a ferramenta `Tools/OTBMMerger/` e gerado um mapa sandbox:

- `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`

Offset usado:

- X: `18070`
- Y: `18120`
- Z: `0`

Resultados:

| Teste | Resultado | Observacao |
| --- | --- | --- |
| Dry-run sem conflito | PASS | `0` blocking issues, `3` warnings |
| Merge sandbox | PASS | `23,035` tiles inseridos |
| Parser reabre mapa mesclado | PASS | `23,035` tiles selecionados nos bounds sandbox |
| XMLs externos sandbox | PASS | `world-monster.xml` e `world-npc.xml` gerados com offset |
| Teste de conflito offset zero | PASS | bloqueou `22,111` conflitos |
| RME4 abre mapa mesclado | NOT_EXECUTED | depende de validacao GUI/manual |
| Round-trip RME4 | NOT_EXECUTED | depende da abertura no RME4 |
| Servidor de teste | BLOCKED | falta runtime isolado apontando para `UpstreamTesting/TargunaMerge/world` |

Status permanece:

`PARTIALLY_READY`

## Runtime Isolado - 2026-07-15

O mapa patchado foi aplicado apenas em uma copia isolada:

- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world.otbm`

Validacoes:

| Teste | Status | Observacao |
| --- | --- | --- |
| Aplicar mapa patchado na copia isolada | PASS | sem alterar producao |
| Parser reabrir mapa do runtime | PASS | `23,035` tiles Targuna encontrados |
| XMLs externos do world | PASS | monster/npc/house/zones validos |
| Banco de teste | PASS | `otserv_targuna_test` criado e importado |
| Boot de servidor isolado | PASS_WITH_ERRORS | servidor ficou online |
| Erros de monstros/NPCs ausentes | PASS | resolvidos ao copiar scripts Targuna para sandbox |
| Dependencias U15_24 | PASS | resolvidas ao copiar libs upstream para sandbox |
| Event callbacks secundarios | FAIL | precisam adaptacao para engine atual |
| RME4 visual e round-trip | NOT_EXECUTED | requer etapa GUI/manual |
| Teste in-game | NOT_EXECUTED | requer cliente/login |

O teste confirma que o merge OTBM e o carregamento de mapa sao viaveis, mas o pacote ainda nao esta pronto para promocao por causa da validacao visual/in-game pendente e do callback secundario incompatível.

## Secondary Tasks - 2026-07-16

O callback secundario incompatível foi tratado somente no runtime sandbox.

| Funcionalidade | Status |
| --- | --- |
| Daily reward via storage update | PASS |
| Stash item auto-complete | DISABLED |
| Take from stash auto-complete | DISABLED |
| Boot sem erro de callback | PASS |

Motivo: `playerOnStowItem` e `playerOnStashWithdraw` nao existem na engine atual. O pacote permanece `PARTIALLY_READY` ate validacao RME4 e in-game.

## Atualizacao - Tentativa RME4/Headless 2026-07-16

| Teste | Status | Observacao |
| --- | --- | --- |
| Abrir RME4 por argumento CLI | PASS | processo inicia com `world-targuna-test.otbm` |
| Carregamento de assets RME4 | PASS | configuracao efetiva apontada para `Client` 15.24 |
| Estado GUI pronto para Save As | BLOCKED | menu Save As nao ficou automatizavel com seguranca no timeout |
| Gerar `world-targuna-rme4-roundtrip.otbm` | BLOCKED | arquivo nao foi criado |
| Validacao parser do round-trip | NOT_EXECUTED | sem arquivo round-trip |
| Boot sandbox final | PASS | servidor sandbox fica ativo e portas `7271`/`7272` respondem |
| Validacao headless de conteudo Targuna | PASS | NPCs, spawns, monster definitions e scripts presentes |

O mapa oficial continua inalterado. O status permanece `PARTIALLY_READY`.
