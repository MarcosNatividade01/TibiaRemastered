# Targuna Dependencies

## Escopo

Inventariar as dependencias conhecidas do patch Targuna/Aragonia Pirates antes de promover qualquer conteudo ao runtime.

Status da etapa: `PARTIALLY_READY`

## Arquivos do Patch

| Arquivo | Tipo | Status |
| --- | --- | --- |
| `MapPatches/Targuna/patch.json` | metadados | validado |
| `MapPatches/Targuna/monsters.xml` | spawns candidatos | XML valido |
| `MapPatches/Targuna/npcs.xml` | NPC positions candidatas | XML valido |
| `MapPatches/Targuna/teleports.xml` | teleports documentais/bloqueados | XML valido |
| `MapPatches/Targuna/scripts/monsters/aragonia/*.lua` | monstros | presente |
| `MapPatches/Targuna/scripts/monsters/bosses/herald_of_fire.lua` | boss | presente |
| `MapPatches/Targuna/scripts/npcs/*.lua` | NPC scripts | presente |
| `MapPatches/Targuna/scripts/quests/*.lua` | quest scripts | presente |
| `MapPatches/Targuna/map-fragment.otbm` | mapa | ausente |

## Conteudo

Monstros incluidos como scripts:

| Nome | Status |
| --- | --- |
| Freshwater Turtle | presente |
| Pirate Cook | presente |
| Pirate Gunner | presente |
| Pirate Navigator | presente |
| Pirate Quartermaster | presente |
| Sea Captain | presente |

Boss:

| Nome | Status |
| --- | --- |
| Herald of Fire | presente |

NPCs:

| NPC | Coordenada upstream |
| --- | --- |
| Captain Indigo | `31973,31892,6` |
| Camilla | `31942,31902,6` |
| Emiliana | `31960,31901,6` e `32412,32687,12` |
| Leonora | `31951,31888,7` |
| Sterling | `31928,31903,7` |
| Aurelia | `31955,31916,7` |
| Lizzie | `31941,31920,7` |
| Morla | `33514,32748,8` |

## Itens

Os 18 itens server-side necessarios foram portados anteriormente para `Server/data/items/items.xml` e validados contra appearances 15.24:

`53074`, `53078`, `53082`, `53086`, `53090`, `53094`, `53098`, `53103`, `53108`, `53110`, `53113`, `53119`, `53122`, `53125`, `53128`, `53132`, `53158`, `53167`.

Resultado conhecido:

- 18/18 existem no client 15.24.
- 18/18 foram portados server-side.
- 0/18 exigem protocolo/client 15.25 com a evidencia atual.

## Dependencias de Mapa

Bounding box amplo upstream:

- `x=31920..33550`
- `y=31880..32760`
- `z=6..12`

Area sandbox planejada:

- `x=50000..51630`
- `y=50000..50880`
- `z=6..12`

O offset planejado e:

- `x +18080`
- `y +18120`
- `z +0`

Esse offset ainda nao foi aplicado a tiles reais porque o fragmento OTBM nao existe.

## Pendencias

| Dependencia | Status | Motivo |
| --- | --- | --- |
| `map-fragment.otbm` real | bloqueado | falta crop/export seguro |
| offset de spawns | pendente | depende do fragmento e coordenadas finais |
| offset de NPCs | pendente | depende do fragmento e coordenadas finais |
| teleports reais | pendente | `teleports.xml` ainda e documental/bloqueado |
| quest action positions | pendente | depende de leitura do fragmento e scripts |
| boss room | pendente | depende do mapa |
| houses | pendente | depende do fragmento |
| zones | pendente | depende do fragmento |
| servidor de teste | pendente | depende de mapa patchado |

## Conclusao

As dependencias de conteudo server-side estao preparadas, mas a dependencia principal continua sendo o fragmento OTBM real. Targuna nao deve ser promovida enquanto esse arquivo nao existir, reabrir no RME4 e carregar no servidor de teste.
