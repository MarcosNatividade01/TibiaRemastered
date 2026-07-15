# Map Patch Format

## Estrutura

Um patch deve ficar em `MapPatches/<PatchId>/`:

```text
MapPatches/
  TestRoom/
    patch.json
    README.md
```

Formato planejado para patches reais:

```text
MapPatches/
  ExampleArea/
    patch.json
    map-fragment.otbm
    monsters.xml
    npcs.xml
    teleports.xml
    README.md
    tests/
```

Nesta primeira versão, o pipeline usa `patch.json` como fonte única para spawns, NPCs e teleports. Fragmentos OTBM ainda não são aplicados.

## Campos Obrigatórios

| Campo | Descrição |
| --- | --- |
| `id` | Identificador estável do patch |
| `name` | Nome legível |
| `version` | Versão do patch |
| `featureFlag` | Flag Remastered que controla o patch |
| `area` | Caixa de coordenadas protegida |

## Exemplo

```json
{
  "id": "test-room",
  "name": "Remastered Map Patch Test Room",
  "version": "0.1.0",
  "featureFlag": "enable_map_patch_test_room",
  "area": {
    "from": { "x": 10000, "y": 10000, "z": 7 },
    "to": { "x": 10010, "y": 10010, "z": 7 }
  },
  "dependencies": {
    "client": "15.24.eb0021",
    "protocol": "current",
    "databaseMigration": false,
    "coreChange": false
  },
  "rollback": {
    "strategy": "restore-sandbox-backup",
    "runtimeApplyAllowed": false
  },
  "spawns": [
    {
      "name": "Rat",
      "x": 10005,
      "y": 10005,
      "z": 7,
      "radius": 1,
      "spawntime": 60
    }
  ],
  "npcs": [],
  "teleports": [
    {
      "id": "test-room-entry",
      "from": { "x": 10000, "y": 10005, "z": 7 },
      "to": { "x": 10005, "y": 10005, "z": 7 }
    }
  ]
}
```

## Regras

- A feature flag deve existir e iniciar `false`.
- O patch deve declarar a área que pretende ocupar.
- Spawns e NPCs devem ficar dentro da área declarada.
- Monstros precisam existir nos diretórios Lua de monstros.
- NPCs precisam existir nos diretórios Lua de NPCs.
- Teleports não podem apontar para coordenadas inválidas nem criar loop direto para si mesmos.
- Nenhum patch pode substituir arquivos inteiros do mundo.
