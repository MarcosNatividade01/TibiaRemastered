# Targuna Asset Compatibility

## Metodo

Foram comparados:

- servidor atual: `Server/data/items/items.xml`
- upstream: `Upstream/CrystalLatest/data/items/items.xml`
- client ativo 15.24: `Client/assets/appearances-ee339aff5b3cb38289287ff25cec261d8d2790e6e146938d4dfd9f138b065980.dat`
- client antigo/cache: `Client/assets/appearances-5997985a63a3e937581971c125efd546c0dfd0623341744ea8fa481c7fc9a560.dat`
- upstream appearances: `Upstream/CrystalLatest/data/items/appearances.dat`

O arquivo `appearances.dat` foi lido apenas para confirmar IDs de object appearances. Nenhum sprite ou asset proprietario foi extraido ou redistribuido.

## Resultado Binario

| Arquivo | Object count | IDs Targuna presentes |
| --- | ---: | --- |
| Client ativo `ee339...dat` | 42099 | 18/18 |
| Client antigo `599...dat` | 40921 | 0/18 |
| Upstream `appearances.dat` | 42108 | 18/18 |

## Resultado por ID

| ID | Nome | Tipo | Usado por | Existe no 15.24 | Existe equivalente | Pode adaptar | Bloqueado |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 53074 | adventurer backpack | container | recompensa/quest Targuna | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53078 | dead lizard henchman | corpse/container | quest lizard relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53082 | dead lizard magician | corpse/container | quest lizard relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53086 | dead lizard swordmaster | corpse/container | quest lizard relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53090 | dead lizard commander | corpse/container | quest lizard relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53094 | dead lizard executioner | corpse/container | quest lizard relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53098 | dead pirate navigator | corpse/container | Pirate Navigator | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53103 | dead pirate quartermaster | corpse/container | Pirate Quartermaster | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53108 | dead herald of fire | corpse/container | Herald of Fire | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53110 | dead pirate gunner | corpse/container | Pirate Gunner | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53113 | dead pirate cook | corpse/container | Pirate Cook | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53119 | dead sea captain | corpse/container | Sea Captain | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53122 | dead infernoid hound | corpse/container | quest/boss secundaria relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53125 | dead infernoid soul | corpse/container | quest/boss secundaria relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53128 | dead infernoid spiritual | corpse/container | quest/boss secundaria relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53132 | dead infernoid blob | corpse/container | quest/boss secundaria relacionada | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53158 | old treasure map | quest item | Sterling/Morla/treasure quest | Sim, appearance e item server existem | Nao necessario | Portado | Nao |
| 53167 | sail pass | quest/travel item | Captain Indigo/travel | Sim, appearance e item server existem | Nao necessario | Portado | Nao |

## Classificacao

Todos os 18 IDs estao classificados como:

`C - pode ser portado sem mudar protocolo`

Status atual:

- 18/18 object appearances existem no client ativo 15.24.
- 18/18 definicoes foram adicionadas ao `Server/data/items/items.xml`.
- 0/18 dependem exclusivamente de client/protocolo 15.25 com a evidencia atual.

## Proxima Validacao

Antes de ativar monstros, boss, NPC travel ou quest:

1. iniciar servidor de teste;
2. spawnar/ver `look`/mover itens;
3. matar monstro que usa corpse novo;
4. confirmar que o client 15.24 renderiza os objects;
5. manter `enable_map_patch_targuna = false` ate existir fragmento OTBM real.
