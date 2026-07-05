# Auditoria de magias por vocacao

Data: 2026-06-28 11:39:48

## Resumo

- Magias Lua analisadas: 201
- Magias sem inconsistencia encontrada: 171
- Magias corrigidas: 1
- Magias com ID duplicado observado: 8
- Magias com requisito adicional de Wheel/upgrade: 21
- Tabela completa: C:\otserv\SPELL_AUDIT_TABLE.csv

## Causa da mensagem de level

A mensagem de level insuficiente vem da validacao central em src/creatures/combat/spells.cpp, dentro de Spell::playerSpellCheck: player->getLevel() e comparado com o valor carregado de spell:level(...) do arquivo Lua da magia. Nao ha XML separado de level de spells nesta datapack.

## Magias corrigidas

| Vocacao | Magia | Words | Level configurado | Level validado | Problema encontrado | Correcao feita |
|---|---|---|---:|---:|---|---|
| "sorcerer;true", "master sorcerer;true" | Great Death Beam | exevo max mort | 66 | 66 | Level antigo/Wheel: estava como level 300 e bloqueava sem upgrade WOD; client/wiki atual usa magia regular level 66 | Level validado ajustado para 66; sem WOD usa grade base 1 |

## Duplicidades encontradas

Estas duplicidades podem afetar a lista/hotkeys do client porque o protocolo envia IDs de spell. Nao alterei IDs sem referencia oficial local do client para evitar mapear uma magia para icone/metadado errado. Elas nao sao a fonte direta da mensagem de level insuficiente.

| Vocacao | Magia | Words | Level configurado | Level validado | Problema encontrado | Correcao feita |
|---|---|---|---:|---:|---|---|
| "paladin;true", "royal paladin;true" | Lesser Ethereal Spear | exori infir con | 1 | 1 | ID duplicado 169; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "druid;true", "elder druid;true", "paladin;true", "royal paladin;true", "sorcerer;true", "master sorcerer;true", "monk;true", "exalted monk;true" | Magic Patch | exura infir | 1 | 1 | ID duplicado 174; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "druid;true", "elder druid;true" | Mud Attack | exori infir tera | 1 | 1 | ID duplicado 174; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "druid;true", "elder druid;true", "knight;true", "elite knight;true", "paladin;true", "royal paladin;true", "sorcerer;true", "master sorcerer;true", "monk;true", "exalted monk;true" | Find Fiend | exiva moe res | 25 | 25 | ID duplicado 20; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "sorcerer;true", "master sorcerer;true" | Conjure Wand of Darkness | exevo gran mort | 41 | 41 | ID duplicado 92; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "master sorcerer;true" | Enchant Staff | exeta vis | 41 | 41 | ID duplicado 92; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "druid;true", "elder druid;true", "sorcerer;true", "master sorcerer;true" | Apprentice's Strike | exori min flam | 8 | 8 | ID duplicado 169; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |
| "druid;true", "elder druid;true", "knight;true", "elite knight;true", "paladin;true", "royal paladin;true", "sorcerer;true", "master sorcerer;true", "monk;true", "exalted monk;true" | Find Person | exiva | 8 | 8 | ID duplicado 20; pode afetar lista/hotkey do client, mas nao gera mensagem de level | Nao alterado sem ID oficial confirmado |

## Requisitos adicionais Wheel/upgrade

| Vocacao | Magia | Words | Level configurado | Level validado | Problema encontrado | Correcao feita |
|---|---|---|---:|---:|---|---|
| "druid;true", "elder druid;true", "sorcerer;true", "master sorcerer;true" | Magic Shield | utamo vita | 14 | 14 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "knight;true", "elite knight;true" | Chivalrous Challenge | exeta amp res | 150 | 150 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Divine Dazzle | exana amp res | 250 | 250 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "sorcerer;true", "master sorcerer;true" | Expose Weakness | exori moe | 275 | 275 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "sorcerer;true", "master sorcerer;true" | Sap Strength | exori kor | 275 | 275 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "monk;true", "exalted monk;true" | Avatar of Balance | uteta res tio | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Avatar of Light | uteta res sac | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "druid;true", "elder druid;true" | Avatar of Nature | uteta res dru | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "knight;true", "elite knight;true" | Avatar of Steel | uteta res eq | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "sorcerer;true", "master sorcerer;true" | Avatar of Storm | uteta res ven | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Divine Empowerment | utevo grav san | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Divine Grenade | exevo tempo mas san | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "knight;true", "elite knight;true" | Executioner's Throw | exori amp kor | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "druid;true", "elder druid;true" | Ice Burst | exevo ulus frigo | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "monk;true", "exalted monk;true" | Spiritual Outburst | exori gran mas nia | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "druid;true", "elder druid;true" | Terra Burst | exevo ulus tera | 300 | 300 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "druid;true", "elder druid;true" | Mass Healing | exura gran mas res | 36 | 36 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "sorcerer;true", "master sorcerer;true" | Energy Wave | exevo vis hur | 38 | 38 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Swift Foot | utamo tempo san | 55 | 55 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "paladin;true", "royal paladin;true" | Sharpshooter | utito tempo san | 60 | 60 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |
| "monk;true", "exalted monk;true" | Chained Penance | exori med pug | 70 | 70 | Requisito adicional de Wheel/upgrade encontrado; nao e erro de level quando level configurado e 300 | Nao alterado |

## Resultado por vocacao

- Knight / Elite Knight: todas as magias de Knight tambem incluem Elite Knight.
- Paladin / Royal Paladin: todas as magias de Paladin tambem incluem Royal Paladin.
- Sorcerer / Master Sorcerer: todas as magias de Sorcerer tambem incluem Master Sorcerer.
- Druid / Elder Druid: todas as magias de Druid tambem incluem Elder Druid.
- Monk / Exalted Monk: todas as magias de Monk tambem incluem Exalted Monk.

## Teste recomendado

1. Reiniciar o servidor apos alterar spells Lua.
2. Testar Great Death Beam com Sorcerer/Master Sorcerer level 65: deve falhar por level.
3. Testar Great Death Beam com Sorcerer/Master Sorcerer level 66+: deve conjurar exevo max mort.
4. Testar uma magia de cada vocacao base e promovida no level minimo configurado no CSV.
5. Se o client estava aberto durante a correcao, fechar e abrir novamente para recarregar a lista de spells enviada no login.

## Cache e banco

Nao e necessario recriar personagem. O banco player_spells esta vazio, e toggleLearnSpells=false; portanto o uso normal nao depende de magia aprendida salva no banco. E necessario reiniciar o servidor para recarregar scripts Lua.
