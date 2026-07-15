# Map Patch Testing

## Suíte Automatizada

Comando:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/MapPatch/Test-MapPatchPipeline.ps1
```

Relatório gerado:

```text
UpstreamTesting/MapPatches/pipeline-test-report.json
```

## Casos Testados

| Caso | Resultado esperado |
| --- | --- |
| Patch válido | Passa |
| Aplicação em sandbox | Passa |
| Reaplicação do mesmo patch | Passa |
| Rollback | Passa |
| Conflito de coordenadas | Falha controlada |
| Monstro inexistente | Falha controlada |
| NPC inexistente | Falha controlada |
| Teleport inválido | Falha controlada |
| Feature flag desligada | Passa |

## Patch Artificial

Patch usado:

```text
MapPatches/TestRoom/patch.json
```

Conteúdo:

- pequena sala artificial por metadados;
- 1 spawn de `Rat`;
- 2 teleports declarados;
- nenhum NPC real;
- feature flag `enable_map_patch_test_room = false`.

O patch não adiciona Targuna e não muda o mapa principal.

## Resultado Atual

Status da suíte: `passed`.

Todos os casos negativos falharam como esperado, sem alteração do runtime principal.

## Testes que Permanecem Manuais ou Futuros

Esta etapa não executa teste jogável dentro de uma área nova porque nenhum fragmento OTBM real foi importado. Antes de importar Targuna, ainda será necessário validar:

- fragmento OTBM real;
- tile IDs;
- item IDs;
- sprites disponíveis no client 15.24;
- posição de entrada/saída no mundo real;
- caminhada na área;
- spawns dentro da área;
- teleports in-game;
- regressão Offline e Multiplayer com patch real desativado e ativado em ambiente de teste.
