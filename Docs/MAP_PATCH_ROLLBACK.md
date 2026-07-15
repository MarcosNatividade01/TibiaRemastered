# Map Patch Backup e Rollback

## Backup

`ApplySandbox` cria uma área isolada em:

```text
UpstreamTesting/MapPatches/<patch-id>/
```

Dentro dela:

| Pasta/arquivo | Função |
| --- | --- |
| `backup/` | Cópia original dos arquivos de mundo |
| `world/` | Cópia de teste onde o patch é aplicado |
| `state.json` | Checksums SHA256 antes e depois |
| `map-patch-applysandbox.json` | Resultado da aplicação |
| `map-patch-rollback.json` | Resultado do rollback |

Arquivos copiados para backup:

- `world.otbm`
- `world-monster.xml`
- `world-npc.xml`
- `world-house.xml`
- `world-zones.xml`

## Rollback

O modo `Rollback` restaura a cópia de sandbox a partir de `backup/`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/MapPatch/Invoke-MapPatch.ps1 -Mode Rollback -PatchPath MapPatches/TestRoom
```

O rollback não altera o runtime principal. Ele existe para provar que a aplicação em sandbox é reversível antes de qualquer futura promoção.

## Checksums

O pipeline registra SHA256 dos arquivos copiados. Isso permite auditar:

- quais arquivos foram usados como baseline;
- se o sandbox foi alterado;
- se o rollback restaurou a cópia esperada.

## Proteções

- `world.otbm` de produção não é alterado.
- XMLs de produção não são alterados.
- `UpstreamTesting/` é área de teste e não deve ser publicada.
- Runtime real só poderá receber patch em etapa futura e com aprovação explícita.
