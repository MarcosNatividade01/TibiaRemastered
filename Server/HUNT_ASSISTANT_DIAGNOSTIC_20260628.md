# Hunt Assistant - Diagnostico de Viabilidade - 2026-06-28

## Resultado curto

A implementacao solicitada como modulo `/modules/game_huntassistant` nao e aplicavel ao client atualmente usado para jogar.

O client iniciado por `C:\Users\marco\Tibiafriends\JOGAR.bat` e:

- `C:\Users\marco\Tibiafriends\bin\client-local.exe`
- pacote Qt6/WebEngine com assets oficiais/empacotados
- versao do pacote: `15.24.eb0021`
- sem arvore `modules/`
- sem arquivos `.otmod` / `.otui` carregaveis encontrados no client ativo

Portanto, nao ha como adicionar um modulo OTClient Lua nesse pacote sem trocar/compilar um client customizado que suporte modulos.

## Servidor

- Base: Crystal Server
- Datapack ativo: `data-global`
- Core ativo: `data`
- Login: 7171
- Game: 7172
- Server name: FazendoTibia

## Client

O README do servidor cita suporte a:

- Game Client da Crystal/zimbadev
- Mehah OTClient

O pacote instalado em `C:\Users\marco\Tibiafriends` e o Game Client empacotado, nao uma checkout de Mehah OTClient com modules Lua.

## Vocation IDs encontrados

Arquivo: `C:\otserv\data\XML\vocations.xml`

| ID | Client ID | Nome |
|---:|---:|---|
| 0 | 0 | None |
| 1 | 3 | Sorcerer |
| 2 | 4 | Druid |
| 3 | 2 | Paladin |
| 4 | 1 | Knight |
| 5 | 13 | Master Sorcerer |
| 6 | 14 | Elder Druid |
| 7 | 12 | Royal Paladin |
| 8 | 11 | Elite Knight |
| 9 | 5 | Monk |
| 10 | 15 | Exalted Monk |

## O que seria implementavel com Mehah OTClient / OTClientV8

Diretorio:

`modules/game_huntassistant/`

Arquivos:

- `huntassistant.otmod`
- `huntassistant.lua`
- `huntassistant_config.lua`
- `huntassistant_profiles.lua`
- `huntassistant_engine.lua`
- `huntassistant_actions.lua`
- `huntassistant_conditions.lua`
- `huntassistant_storage.lua`
- `huntassistant_debug.lua`
- `huntassistant_ui.lua`
- `huntassistant.otui`

Esse modulo poderia usar APIs normais do OTClient, como:

- `g_game.talk()` para spells, deixando o servidor validar cooldown, mana, level e vocation
- `g_game.useInventoryItemWith()` ou equivalente para potions/runes, se disponivel na base
- `g_game.getLocalPlayer()` para HP/mana/vocation
- `g_game.getAttackingCreature()` para alvo atual
- `g_map.getSpectators()` para contar monstros proximos
- `g_settings` para storage local

## O que nao deve ser feito no client atual

- Injetar DLL no client oficial/Qt
- Simular teclado/mouse
- Alterar binario do client
- Mandar packets artificiais
- Implementar cavebot externo
- Rodar automacao fora do client

Essas alternativas contrariam os limites definidos e sao tecnicamente mais arriscadas.

## Opcoes corretas

1. Usar/compilar Mehah OTClient compativel com o protocolo do servidor e implementar o modulo Lua nele.
2. Obter o source do Game Client usado e adicionar uma API/modulo proprio nele.
3. Fazer apenas comandos informativos no servidor, sem automacao de combate. Isso nao entregaria o Hunt Assistant solicitado.

## Conclusao

O sistema e viavel, mas nao dentro do client atualmente instalado. A implementacao limpa e segura exige um client com suporte a modulos Lua, preferencialmente Mehah OTClient conforme o proprio README do Crystal Server.
