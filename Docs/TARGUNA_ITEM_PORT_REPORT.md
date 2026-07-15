# Targuna Item Port Report

## Escopo

Foram portadas somente as 18 definicoes de item exigidas pelo candidato Targuna/Aragonia Pirates. Nenhum item adjacente do upstream foi importado.

Backup criado antes da alteracao:

- `Backups/targuna-item-port-20260715-154549/items.xml`

SHA256 original de `Server/data/items/items.xml`:

- `4AF7BEABA1F56BF8A4E3B770D3AB6302A73285886D30AC6AA9963FBB3F575D85`

## Resultado

| ID | Nome | Appearance 15.24 | Definicao Upstream | Conflito | Portado | Testado |
| ---: | --- | --- | --- | --- | --- | --- |
| 53074 | adventurer backpack | Sim | Sim | Nao | Sim | XML/ID |
| 53078 | dead lizard henchman | Sim | Sim | Nao | Sim | XML/ID |
| 53082 | dead lizard magician | Sim | Sim | Nao | Sim | XML/ID |
| 53086 | dead lizard swordmaster | Sim | Sim | Nao | Sim | XML/ID |
| 53090 | dead lizard commander | Sim | Sim | Nao | Sim | XML/ID |
| 53094 | dead lizard executioner | Sim | Sim | Nao | Sim | XML/ID |
| 53098 | dead pirate navigator | Sim | Sim | Nao | Sim | XML/ID |
| 53103 | dead pirate quartermaster | Sim | Sim | Nao | Sim | XML/ID |
| 53108 | dead herald of fire | Sim | Sim | Nao | Sim | XML/ID |
| 53110 | dead pirate gunner | Sim | Sim | Nao | Sim | XML/ID |
| 53113 | dead pirate cook | Sim | Sim | Nao | Sim | XML/ID |
| 53119 | dead sea captain | Sim | Sim | Nao | Sim | XML/ID |
| 53122 | dead infernoid hound | Sim | Sim | Nao | Sim | XML/ID |
| 53125 | dead infernoid soul | Sim | Sim | Nao | Sim | XML/ID |
| 53128 | dead infernoid spiritual | Sim | Sim | Nao | Sim | XML/ID |
| 53132 | dead infernoid blob | Sim | Sim | Nao | Sim | XML/ID |
| 53158 | old treasure map | Sim | Sim | Nao | Sim | XML/ID |
| 53167 | sail pass | Sim | Sim | Nao | Sim | XML/ID |

## Validacoes

- XML de `Server/data/items/items.xml`: passou.
- IDs portados presentes: passou.
- Duplicidade de `<item id="...">`: passou.
- Presenca no active `appearances` 15.24: passou em 18/18.

## Limites

Ainda nao foi feito teste jogavel de spawn/look/move/loot porque Targuna segue sem `map-fragment.otbm` real.
