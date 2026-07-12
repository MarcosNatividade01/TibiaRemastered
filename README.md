# TibiaRemastered

Projeto privado para hospedar e organizar um OTServer com servidor, cliente, launcher, auto-update, documentacao e arquivos necessarios para testes locais.

## Estrutura

```text
TibiaRemastered/
  Client/
  Server/
  Database_Template/
  UserData/
  Logs/
  Backup/
  Launcher/
  Docs/
  Tools/
  Scripts/
  manifest.json
  version.json
  CHANGELOG.md
  ROADMAP.md
  IDEIAS.md
```

## Objetivo

- Manter o servidor, cliente e launcher em um unico repositorio privado.
- Manter o runtime oficial em `Client/`, `Server/` e `Database_Template/`.
- Preparar a base para um launcher com verificacao de versao e auto-update.
- Separar arquivos de exemplo e templates dos dados reais de jogadores.
- Permitir testes locais sem versionar informacoes sensiveis.

## Regras de versionamento

Nao devem ser versionados:

- Dados reais de banco de dados.
- Contas reais.
- Personagens e saves reais.
- Senhas, tokens, chaves e arquivos `.env`.
- Logs, backups, cache e arquivos temporarios.

## Auto-update

O arquivo `version.json` guarda a versao atual do projeto. O arquivo `manifest.json` e usado pelo launcher para comparar arquivos locais com os arquivos publicados no GitHub.

Ao abrir, o Launcher consulta o `version.json` remoto sem usar cache como fonte principal. Se a versao oficial for diferente, ele entra automaticamente em `UPDATING`, baixa apenas arquivos ausentes/diferentes, valida SHA256 e recarrega ou reinicia o Launcher. Durante a aplicacao, os botoes de jogo ficam bloqueados; depois de `UPDATE_SUCCESS`, voltam a ser habilitados.

Os botoes abaixo permanecem como alternativas manuais e de recuperacao:

- `Atualizar`;
- `Atualizar e Jogar`;
- `Ver Novidades`.

`Atualizar` baixa apenas arquivos ausentes ou desatualizados, valida SHA256, cria backup antes de sobrescrever arquivos e preserva caminhos protegidos. `Atualizar e Jogar` executa a atualizacao e so abre o modo Offline se a atualizacao terminar com sucesso. Se o GitHub estiver indisponivel, o Launcher entra em `OFFLINE_AVAILABLE`, mostra o erro e mantem `Jogar Offline` disponivel.

`autoUpdateOnLauncherStart` e habilitado por padrao. O comando Play continua usando o runtime local; `autoUpdateBeforePlay` permanece independente para nao impedir o modo offline quando o GitHub estiver indisponivel. Diagnosticos detalhados do updater ficam em `Logs/UpdateTests/`.

Use `Database_Template/` para o banco modelo limpo e MariaDB portatil. Dados locais de execucao devem ficar em `UserData/` ou em pastas protegidas pelo `.gitignore`.

## Launcher profissional

O launcher fica em `Launcher/Launcher.ps1` e usa modulos em `Launcher/Modules/` para separar configuracao, update, validacao e inicializacao do jogo.

Comandos uteis:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Repair
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -AutoUpdate
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -SelfTest
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -MinimumQA
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Publish-Release.ps1 -Version 0.1.1
```

## Host Assistido

O Launcher possui opcoes principais claras:

- `Atualizar`;
- `Atualizar e Jogar`;
- `Ver Novidades`;
- `Jogar Offline`;
- `Hospedar Mundo`;
- `Entrar em Mundo`;
- `Diagnostico`;
- `Reparar Arquivos`;
- `Configuracoes`;
- `Ajuda`.

O modo Offline continua sendo o fluxo principal e nao depende de internet. Dados online ficam em `UserData/Online/`. `Entrar no Meu Mundo` usa exclusivamente `127.0.0.1`/`host-local`; `Copiar Convite para Amigos` usa exclusivamente o IP LAN/publico e `mode=remote`.

O Host Assistido gera diagnosticos em:

```text
Logs/OnlineDiagnostics/
Logs/ConnectionTests/
Logs/UpdateTests/
```

Detalhes:

```text
Docs/LAUNCHER_GUIDE.md
Docs/HOST_ASSISTIDO.md
Docs/MULTIPLAYER_TEST_GUIDE.md
Docs/ONLINE_MODE.md
Docs/NETWORK_DIAGNOSTICS.md
Docs/LAN_TEST_GUIDE.md
Docs/TROUBLESHOOTING_ONLINE.md
Docs/QA_MINIMO.md
```

Painel admin local de testes:

```powershell
$env:TRM_DEVELOPER_MODE='1'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1
```

Com o modo desenvolvedor habilitado, o painel `Admin / Testes` fica dentro de `Configuracoes`. Ele executa testes de XP, skill e loot pelo servidor e grava resultados em `Logs/BalanceTests/`.

A arquitetura completa esta documentada em `Docs/ARCHITECTURE_MAP.md`.
