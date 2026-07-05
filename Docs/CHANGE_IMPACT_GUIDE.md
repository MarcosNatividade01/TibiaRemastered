# Change Impact Guide

Guia de impacto para futuras alteracoes no TibiaRemastered.

Use este documento antes de modificar qualquer sistema.

## Regra geral

Antes de alterar:

1. identificar sistema afetado em `Docs/SYSTEMS_INDEX.md`;
2. conferir arquivos principais em `Docs/ARCHITECTURE_MAP.md`;
3. verificar se ha dados protegidos envolvidos;
4. definir teste minimo;
5. rodar validacao automatica;
6. documentar risco residual.

## Baixo impacto

Alteracoes geralmente seguras:

- ajustes de texto em documentacao;
- atualizacao de roadmap/changelog;
- inclusao de exemplos sem dados reais;
- correcao de typos em mensagens sem mudar fluxo;
- adicionar `.gitkeep` em pasta vazia esperada.

Testes minimos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
```

## Medio impacto

Alteracoes que exigem mais cuidado:

- mudar `Config/launcher-config.json`;
- alterar `.gitignore`;
- alterar `Generate-Manifest.ps1`;
- alterar validacoes;
- alterar docs de release;
- alterar lista de arquivos protegidos;
- alterar script de pacote.

Riscos:

- publicar dados sensiveis;
- quebrar update;
- gerar manifest incompleto;
- bloquear release valida.

Testes minimos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-UpdateSimulation.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Publish-Release.ps1 -Version 0.1.0 -SkipGitPush
```

## Alto impacto

Alteracoes de alto risco:

- modificar `TibiaRemastered.Update.psm1`;
- modificar `TibiaRemastered.Runtime.psm1`;
- alterar fluxo de backup/rollback;
- alterar `Start-TrmGame`;
- alterar criacao de banco;
- alterar endpoint de login/criacao;
- alterar paths de servidor, cliente ou banco;
- alterar porta web, banco ou servidor;
- alterar pacote do jogador.

Riscos:

- launcher nao abrir;
- update corromper instalacao;
- rollback falhar;
- banco nao iniciar;
- cliente nao logar;
- personagem nao persistir;
- download grande iniciar sem controle.

Testes minimos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -SelfTest
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -NoGui
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-UpdateSimulation.ps1
```

Com runtime real:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```

## Impacto maximo

Alteracoes em gameplay, banco real, scripts Lua/XML, schema, cliente ou servidor.

Exemplos:

- experiencia;
- skills;
- loot;
- spells;
- runas;
- store;
- tibia coins;
- prey;
- forge;
- bestiario;
- charms;
- imbuements;
- cooldowns;
- vocacoes;
- monstros;
- NPCs;
- quests;
- respawn;
- saves;
- login;
- criacao de personagem.

Riscos:

- perda de progresso;
- incompatibilidade de schema;
- personagem criado com estado invalido;
- servidor nao subir;
- cliente nao conectar;
- economia quebrada;
- balanceamento alterado acidentalmente.

Testes minimos:

- validar schema limpo;
- criar conta;
- criar personagem;
- entrar no jogo;
- executar acao afetada;
- sair;
- reiniciar servidor/cliente;
- confirmar persistencia;
- revisar logs.

## Antes da primeira mudanca de gameplay

O pacote real foi localizado em `tmp/player-package-download/TibiaRemastered-Player.zip` e extraido para as pastas oficiais.

Antes de modificar gameplay:

1. validar o runtime instalado em ambiente controlado;
2. confirmar `Server/config.lua`, especialmente `dataPackDirectory`;
3. confirmar se o datapack ativo e `data-global` ou `data-crystal`;
4. mover apenas templates seguros para `Database_Template/`;
5. rodar validacao estrita;
6. testar login, criacao de personagem e persistencia;
7. criar plano de rollback para qualquer mudanca Lua/XML/SQL.

Nao alterar `Server/data/scripts/spells`, `Server/data/scripts/runes`, `Server/data/items`, `Server/data-global/monster`, `Server/data-global/npc`, `Server/schema.sql` ou `Server/config.lua` sem teste manual especifico.

## Areas protegidas

Nunca sobrescrever automaticamente:

- `UserData/**`
- `Logs/**`
- `Backup/**`
- `Backups/**`
- `Saves/**`
- `Save/**`
- `Database/**`
- `Databases/**`
- `PrivateDatabase/**`
- `Config/launcher-config.json`
- `manifest.json`
- `version.json`

Qualquer mudanca que reduza essa protecao deve ser tratada como alto impacto.

## Guia por arquivo

| Arquivo ou pasta | Impacto esperado | Cuidado principal |
| --- | --- | --- |
| `Launcher/Launcher.ps1` | Alto | GUI, comandos e fluxo principal |
| `TibiaRemastered.Core.psm1` | Alto | paths, config, logs e protecao |
| `TibiaRemastered.Update.psm1` | Alto | download, hash, backup e rollback |
| `TibiaRemastered.Runtime.psm1` | Alto | banco, endpoint, servidor e cliente |
| `TibiaRemastered.Validation.psm1` | Medio | gates de release |
| `Config/launcher-config.json` | Medio/Alto | runtime e URLs remotas |
| `manifest.json` | Alto | arquivos distribuidos e hashes |
| `version.json` | Medio | versao publicada |
| `.gitignore` | Alto | risco de vazar dados reais |
| `Scripts/New-PlayerPackage.ps1` | Alto | pacote pode incluir dados sensiveis |
| `Server/` | Impacto maximo | gameplay e persistencia |
| `Client/` | Impacto maximo | compatibilidade com servidor/protocolo |
| `Database_Template/` | Impacto maximo | schema e dados iniciais |

## Quando nao prosseguir

Pare a mudanca se:

- houver dados reais fora de areas protegidas;
- `manifest.json` listar arquivos protegidos;
- `Test-Project.ps1` falhar;
- `Test-UpdateSimulation.ps1` falhar;
- o runtime estrito falhar em fase de estabilizacao;
- nao houver forma de testar manualmente o sistema afetado.
