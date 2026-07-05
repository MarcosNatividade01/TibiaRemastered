# Auditoria de requisitos de magias

Data: 2026-06-28 11:54:13

## Resultado do exemplo informado

- `exevo frigo hur` e a magia `Ice Wave`.
- No servidor: level 18, magic level 0, vocacao Druid/Elder Druid.
- No Tibia original: Ice Wave e level 18.
- Portanto personagem level 11 ainda nao atende ao requisito; a mensagem de level insuficiente esta correta nesse caso.
- Se alguma janela do client mostra level 8 para `exevo frigo hur`, isso e divergencia de exibicao/metadado do client ou confusao com outra magia, nao o requisito validado pelo servidor.

## Arquivos analisados

- `C:\otserv\data\scripts\spells\**\*.lua`
- `C:\otserv\data\scripts\actions\items\spellbook.lua`
- `C:\otserv\data\XML\vocations.xml`
- `C:\otserv\src\creatures\combat\spells.cpp`
- `C:\otserv\src\server\network\protocol\protocolgame.cpp`
- `C:\otserv\src\utils\tools.cpp`
- Banco MySQL: `players`, `player_spells`

## Tabela completa

A tabela completa com todas as 201 magias analisadas esta em: C:\otserv\SPELL_REQUIREMENTS_AUDIT.csv.

## Magias com diferenca/correcao conhecida

| Vocacao | Magia | Words | Level configurado | Level validado | Problema encontrado | Correcao feita |
|---|---|---|---:|---:|---|---|
| "sorcerer;true", "master sorcerer;true" | Great Death Beam | exevo max mort | 66 | 66 | Corrigida anteriormente: estava como level 300/Wheel; requisito atual usado pelo servidor e 66 com grade base quando sem Wheel. | Mantido level 66 e fallback grade 1. |
| "druid;true", "elder druid;true" | Ice Wave | exevo frigo hur | 18 | 18 | Sem erro de level: Tibia original usa level 18; personagem level 11 deve receber mensagem de level insuficiente. Se o client mostrar 8, e divergencia de display/metadado do client ou confusao com outra magia. | Nenhuma alteracao no requisito; mantido original level 18. |

## Duplicidades detectadas

Nao ha duplicidade de words. Existem IDs duplicados; isso pode afetar a lista nativa do client, porque o servidor envia IDs de spells no login. Nao alterei IDs sem tabela oficial de IDs do client para evitar quebrar icones/metadados.

| ID | Magia | Words | Level | Arquivo |
|---:|---|---|---:|---|
| 20 | Find Person | exiva | 8 | C:\otserv\data\scripts\spells\support\find_person.lua |
| 20 | Find Fiend | exiva moe res | 25 | C:\otserv\data\scripts\spells\support\find_fiend.lua |
| 92 | Enchant Staff | exeta vis | 41 | C:\otserv\data\scripts\spells\conjuring\enchant_staff.lua |
| 92 | Conjure Wand of Darkness | exevo gran mort | 41 | C:\otserv\data\scripts\spells\conjuring\conjure_wand_of_darkness.lua |
| 169 | Lesser Ethereal Spear | exori infir con | 1 | C:\otserv\data\scripts\spells\attack\lesser_ethereal_spear.lua |
| 169 | Apprentice's Strike | exori min flam | 8 | C:\otserv\data\scripts\spells\attack\apprentice's_strike.lua |
| 174 | Mud Attack | exori infir tera | 1 | C:\otserv\data\scripts\spells\attack\mud_attack.lua |
| 174 | Magic Patch | exura infir | 1 | C:\otserv\data\scripts\spells\healing\magic_patch.lua |

## Conclusao tecnica

- A mensagem de level insuficiente vem apenas de `Spell::playerSpellCheck` em C++, comparando `player->getLevel()` com `spell:level(...)`.
- O spellbook do item le os mesmos objetos de spell do servidor via `player:getInstantSpells()`; para Ice Wave ele deve exibir level 18.
- A lista nativa do client recebe apenas IDs em `ProtocolGame::sendBasicData`; levels exibidos ali vêm do staticdata/metadados do client.
- `player_spells` esta vazio e `toggleLearnSpells=false`; o problema nao vem de magia aprendida no banco.
