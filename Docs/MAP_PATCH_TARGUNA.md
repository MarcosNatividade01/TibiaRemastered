# Targuna / Aragonia Pirates Map Patch

## Status

Patch preparado como candidato de sandbox em `MapPatches/Targuna/`.

Status atual: `PARTIALLY_READY`.

Os 18 item definitions foram portados para a base 15.24. O patch ainda nao esta pronto para promocao ao runtime porque nao existe `map-fragment.otbm` real.

## Seguranca

Nada foi aplicado em:

- `Server/data-global/world/world.otbm`
- `Server/data-global/world/world-monster.xml`
- `Server/data-global/world/world-npc.xml`
- banco de dados
- client
- protocolo
- core C++

As flags continuam desligadas:

```lua
enable_map_patch_targuna = false
enable_targuna_monsters = false
enable_targuna_npcs = false
enable_targuna_quest = false
enable_targuna_bosses = false
```

## Conteudo Empacotado

| Tipo | Quantidade |
| --- | ---: |
| Monstros de Aragonia | 6 |
| Bosses | 1 |
| NPC scripts | 8 |
| Quest scripts | 15 |
| Spawn groups candidatos | 85 |
| Spawns candidatos | 88 |
| NPC positions candidatas | 9 |

Monstros empacotados:

- `Freshwater Turtle`
- `Pirate Cook`
- `Pirate Gunner`
- `Pirate Navigator`
- `Pirate Quartermaster`
- `Sea Captain`

Boss empacotado:

- `Herald of Fire`

NPCs empacotados:

- `Captain Indigo`
- `Sterling`
- `Morla`
- `Aurelia`
- `Camilla`
- `Emiliana`
- `Leonora`
- `Lizzie`

## Assets e Itens

Resultado atual:

- 18/18 IDs existem como object appearances no client atual 15.24.
- 18/18 IDs foram portados para `Server/data/items/items.xml`.
- 0/18 dependem exclusivamente de client/protocolo 15.25 com a evidencia atual.

Relatorios:

- `Docs/TARGUNA_ASSET_COMPATIBILITY.md`
- `Docs/TARGUNA_ITEM_PORT_REPORT.md`
- `MapPatches/Targuna/asset-validation.json`
- `MapPatches/Targuna/asset-validation.csv`

## Coordenadas

Origem upstream aproximada:

- `x=31920..33550`
- `y=31880..32760`
- `z=6..12`

Area-alvo de sandbox:

- `x=50000..51630`
- `y=50000..50880`
- `z=6..12`

A area segue reservada para sandbox. Nenhum tile real foi criado ali porque `map-fragment.otbm` ainda nao existe. Antes de gerar o fragmento, os limites tecnicos dessas coordenadas ainda precisam ser validados pela ferramenta OTBM escolhida e pelo servidor.

## Map Fragment

`MapPatches/Targuna/map-fragment.otbm` **nao foi criado**.

Motivo: nao existe, neste ambiente, ferramenta OTBM confiavel para extrair somente Targuna/Aragonia do `world.otbm` upstream sem risco de substituir ou corromper o mapa inteiro.

Ferramentas verificadas:

- Nenhum Remere/RME executavel encontrado em `C:\Users\marco\Downloads`.
- Nenhum utilitario OTBM de crop/merge em `Tools/`.
- O projeto cita Remere's Map Editor como ferramenta esperada para edicao de mapa, mas ela nao esta embutida no repositorio.

Detalhes em `Docs/TARGUNA_MAP_FRAGMENT_VALIDATION.md`.

## Sandbox

O pipeline continua validando o pacote como candidato bloqueado:

- Validate: passou.
- ApplySandbox: passou.
- Rollback: passou.
- ReapplySandbox: passou.
- Spawns ativos aplicados: 0.
- NPCs ativos aplicados: 0.

Como nao ha fragmento OTBM, nao houve teste jogavel real da area.

## Resultado Tecnico

Targuna esta bloqueada por um ponto principal:

1. gerar `map-fragment.otbm` real com ferramenta OTBM confiavel;
2. validar relocalizacao de tiles, spawns, NPCs, teleports e quest positions;
3. ativar spawns/NPCs apenas na sandbox;
4. executar teste jogavel real.

Enquanto esses pontos nao forem resolvidos, o patch nao deve ser promovido ao runtime.
