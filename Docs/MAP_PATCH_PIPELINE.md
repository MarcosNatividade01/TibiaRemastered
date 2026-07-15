# Remastered Map Patch Pipeline

## Objetivo

O Remastered Map Patch Pipeline permite validar e preparar patches de mapa, spawns, NPCs e teleports sem substituir o mapa principal do Tibia Remastered.

Esta primeira versão cria a infraestrutura segura para patches de área. Ela não importa Targuna, não altera protocolo, não altera client, não altera banco, não altera core C++ e não substitui `world.otbm`.

## Arquitetura Atual do Mapa

O runtime atual usa o datapack `data-global`, definido em `Server/config.lua`:

```lua
dataPackDirectory = "data-global"
mapName = "world"
```

Arquivos reais do mundo:

| Função | Arquivo |
| --- | --- |
| Mapa principal | `Server/data-global/world/world.otbm` |
| Spawns de monstros | `Server/data-global/world/world-monster.xml` |
| NPCs posicionados | `Server/data-global/world/world-npc.xml` |
| Houses | `Server/data-global/world/world-house.xml` |
| Zones | `Server/data-global/world/world-zones.xml` |

O `world.otbm` é arquivo local/protegido e não é versionado como conteúdo publicável. O pipeline trata esse arquivo como entrada de referência e só copia para sandbox.

## Ferramentas

| Ferramenta | Função |
| --- | --- |
| `Tools/MapPatch/Invoke-MapPatch.ps1` | Valida, aplica em sandbox ou executa rollback de um patch |
| `Tools/MapPatch/Test-MapPatchPipeline.ps1` | Executa os testes automatizados do pipeline |

Modos disponíveis:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/MapPatch/Invoke-MapPatch.ps1 -Mode Validate -PatchPath MapPatches/TestRoom
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/MapPatch/Invoke-MapPatch.ps1 -Mode ApplySandbox -PatchPath MapPatches/TestRoom
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/MapPatch/Invoke-MapPatch.ps1 -Mode Rollback -PatchPath MapPatches/TestRoom
```

## Fluxo Seguro

1. Criar um patch em `MapPatches/<PatchId>/patch.json`.
2. Validar metadados, feature flag e coordenadas.
3. Detectar conflitos com houses, spawns e NPCs existentes.
4. Validar monstros e NPCs contra os scripts Lua existentes.
5. Validar teleports.
6. Criar sandbox em `UpstreamTesting/MapPatches/<patch-id>/`.
7. Copiar `world.otbm` e XMLs para `backup/` e `world/`.
8. Aplicar o merge apenas nos XMLs da sandbox.
9. Registrar checksums em `state.json`.
10. Validar rollback restaurando a sandbox a partir do backup.

## Estado da Feature Flag

O patch artificial de teste usa:

```lua
enable_map_patch_test_room = false
```

Patches reais devem seguir o mesmo padrão: a flag precisa existir em `Modules/Remastered/Config/features.lua` e iniciar `false`.

## Limites desta Versão

- Não mescla fragmentos OTBM no mapa principal.
- Não substitui `world.otbm`.
- Não promove patches para runtime automaticamente.
- Não valida sprites/tile IDs dentro de fragmentos OTBM, porque nenhum fragmento real foi importado nesta etapa.
- Não importa Targuna.

Essas restrições são intencionais. O objetivo desta etapa é preparar o gate seguro para uma futura importação de Targuna ou outra área real.
