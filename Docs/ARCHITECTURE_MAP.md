# Architecture Map

Este documento mapeia a arquitetura atual do projeto TibiaRemastered na Fase 2.

Escopo desta auditoria:

- codigo e arquivos versionados no repositorio;
- configuracoes presentes em `Config/`;
- scripts PowerShell em `Launcher/` e `Scripts/`;
- artefatos temporarios apenas quando ajudam a explicar o estado local.

Fora do escopo:

- balanceamento;
- gameplay;
- novas mecanicas;
- refatoracoes grandes.

## Visao geral

O projeto atual e uma plataforma de distribuicao e execucao local para um OTServer. A parte versionada contem principalmente:

- launcher PowerShell;
- sistema de update por GitHub;
- validacao pre-publicacao;
- simulacao de update;
- preparacao de pacote do jogador;
- documentacao e estrutura base.

O cliente, servidor, banco modelo, scripts Lua e arquivos XML de gameplay agora estao presentes nas pastas oficiais `Client/`, `Server/` e `Database_Template/`. Alteracoes de gameplay continuam bloqueadas ate validacao manual de login, criacao de personagem e persistencia.

## Componentes principais

### Launcher

Nome do sistema: Launcher

Finalidade: iniciar a interface, executar self-test, verificar versao, reparar arquivos, aplicar update e iniciar o jogo.

Arquivos principais:

- `Launcher/Launcher.ps1`
- `Start Launcher.bat`

Arquivos auxiliares:

- `Launcher/Modules/TibiaRemastered.Core.psm1`
- `Launcher/Modules/TibiaRemastered.Update.psm1`
- `Launcher/Modules/TibiaRemastered.Runtime.psm1`
- `Launcher/Modules/TibiaRemastered.Validation.psm1`
- `Config/launcher-config.json`

Linguagem usada: PowerShell 5.x.

Onde fica configurado: `Config/launcher-config.json` e defaults em `TibiaRemastered.Core.psm1`.

Onde fica a logica principal:

- GUI e comandos CLI: `Launcher/Launcher.ps1`
- paths, config, logs, JSON e protecao: `TibiaRemastered.Core.psm1`
- update: `TibiaRemastered.Update.psm1`
- inicializacao do runtime: `TibiaRemastered.Runtime.psm1`
- self-test e validacao: `TibiaRemastered.Validation.psm1`

Dependencias:

- Windows PowerShell;
- `System.Windows.Forms` e `System.Drawing` para GUI;
- acesso HTTP ao GitHub para update;
- executaveis reais de servidor, cliente e MySQL para fluxo completo.

Riscos ao modificar:

- alterar ordem de importacao de modulos pode quebrar funcoes `*-Trm*`;
- alterar paths sem atualizar config/defaults pode quebrar update e runtime;
- mudar mensagens ou callbacks de progresso pode afetar GUI;
- iniciar processos sem `WorkingDirectory` correto pode quebrar servidor/cliente.

Como testar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -SelfTest
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -NoGui
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Check
```

Observacoes importantes:

- `-Play` depende do pacote real do jogador ou dos binarios reais ja presentes.
- a GUI so deve ser validada em ambiente Windows interativo.

### Sistema de atualizacao

Nome do sistema: Update via GitHub

Finalidade: comparar manifest remoto com arquivos locais, baixar arquivos ausentes/corrompidos, validar SHA256, criar backup e registrar relatorio.

Arquivos principais:

- `Launcher/Modules/TibiaRemastered.Update.psm1`
- `manifest.json`
- `version.json`

Arquivos auxiliares:

- `Launcher/Tools/Generate-Manifest.ps1`
- `Scripts/Publish-Release.ps1`
- `Scripts/Test-UpdateSimulation.ps1`
- `Reports/last-update.json`, gerado localmente e ignorado.

Linguagem usada: PowerShell e JSON.

Onde fica configurado:

- `Config/launcher-config.json`: `remoteVersionUrl`, `remoteManifestUrl`, `lastUpdateReport`.
- `manifest.json`: arquivos, hashes, tamanho, URL, categoria.
- `version.json`: versao publicada.

Onde fica a logica principal:

- `Invoke-TrmUpdateOrRepair`
- `Sync-TrmFromManifest`
- `Copy-TrmRemoteFile`
- `New-TrmUpdateBackup`
- `Restore-TrmBackup`

Dependencias:

- GitHub raw URLs;
- `Invoke-WebRequest`;
- SHA256 via `Get-FileHash`;
- permissao de escrita nas pastas locais.

Riscos ao modificar:

- sobrescrever arquivos protegidos;
- aceitar manifest sem hash valido;
- substituir arquivos sem backup;
- quebrar auto-update do proprio launcher;
- publicar manifest com arquivos temporarios ou dados locais.

Como testar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-UpdateSimulation.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
```

Observacoes importantes:

- `manifest.json`, `version.json` e `Config/launcher-config.json` sao protegidos contra overwrite automatico.
- `tmp/`, `Logs/`, `Reports/`, `Backup/` e `UserData/` sao ignorados pelo Git.

### Runtime local

Nome do sistema: Runtime local

Finalidade: garantir pacote do jogador, iniciar banco, endpoint web local, servidor e cliente.

Arquivos principais:

- `Launcher/Modules/TibiaRemastered.Runtime.psm1`

Arquivos auxiliares:

- `Config/launcher-config.json`
- pacote remoto definido por `playerPackageUrl` ou `playerPackageParts`
- `Database_Template/schema.sql`.

Linguagem usada: PowerShell.

Onde fica configurado:

- `serverExe`
- `serverWorkingDirectory`
- `serverPorts`
- `clientExe`
- `clientWorkingDirectory`
- `databaseExe`
- `databasePort`
- `databaseName`
- `databaseSeedSql`
- `webServerExe`
- `webServerPort`

Onde fica a logica principal:

- `Start-TrmGame`
- `Ensure-TrmPlayerPackage`
- `Ensure-TrmDatabaseServer`
- `Ensure-TrmDatabaseSchema`
- `Ensure-TrmWebEndpoint`
- `Start-TrmPortableWebEndpoint`

Dependencias:

- pacote do jogador hospedado em GitHub Releases;
- MySQL/MariaDB portatil;
- `mysql.exe` e `mysqld.exe`;
- servidor configurado em `Server/crystalserver.exe`;
- cliente configurado em `Client/bin/client-local.exe`;
- portas locais 3306, 80, 7171 e 7172, por padrao.

Riscos ao modificar:

- conflitar com MySQL, Apache, IIS ou outro processo local;
- gravar dados persistentes fora de `UserData/`;
- quebrar fluxo de criacao de conta/login;
- baixar pacote grande durante testes automatizados;
- acoplar regras de banco ao launcher.

Como testar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```

Observacoes importantes:

- no snapshot versionado, os binarios reais nao estao presentes.
- `-Play` pode baixar pacote grande e deve ser testado em ambiente controlado.

### Endpoint web portatil

Nome do sistema: Endpoint web local

Finalidade: responder chamadas de criacao de conta/personagem e login usadas pelo cliente.

Arquivos principais:

- bloco gerador em `Launcher/Modules/TibiaRemastered.Runtime.psm1`
- script gerado em `UserData/Runtime/portable-web-endpoint.ps1`, local e ignorado.

Arquivos auxiliares:

- `mysql.exe`
- banco `otserv`
- tabelas `accounts`, `players`, `account_vipgroups`, `towns`.

Linguagem usada: PowerShell, HTTP simples via `TcpListener`, SQL via `mysql.exe`.

Onde fica configurado:

- `webServerPort`
- `databasePort`
- `databaseName`
- `databaseExe`

Onde fica a logica principal:

- `Write-TrmPortableWebEndpointScript`
- `Start-TrmPortableWebEndpoint`
- `Handle-ClientCreate`
- `Handle-Login`

Dependencias:

- MySQL acessivel em `127.0.0.1`;
- schema compativel com as queries existentes;
- porta HTTP livre.

Riscos ao modificar:

- queries SQL assumem colunas especificas;
- senha e gravada como SHA1 para compatibilidade, nao como desenho de seguranca moderno;
- mudancas no protocolo do cliente podem quebrar login/criacao;
- conflitos de porta podem impedir endpoint.

Como testar:

- iniciar `Launcher.ps1 -Play` com runtime completo;
- criar conta pelo cliente;
- criar personagem;
- logar;
- verificar registros em `accounts` e `players`.

Observacoes importantes:

- o endpoint e uma ponte local de compatibilidade, nao um webserver publico.
- nao deve ser exposto fora de `127.0.0.1`.

### Banco de dados

Nome do sistema: Banco de dados local

Finalidade: armazenar contas, personagens, progresso e dados persistentes do servidor.

Arquivos principais:

- `Database_Template/`, reservado para templates seguros.
- `UserData/Database/`, usado em runtime para dados locais.

Arquivos auxiliares:

- `Database_Template/schema.sql`.
- `Database_Template/mysql/bin/mysqld.exe`.

Linguagem usada: SQL e PowerShell.

Onde fica configurado:

- `Config/launcher-config.json`
- defaults em `TibiaRemastered.Core.psm1`

Onde fica a logica principal:

- inicializacao: `Ensure-TrmDatabaseServer`
- schema: `Ensure-TrmDatabaseSchema`
- comandos SQL: `Invoke-TrmMysql`

Dependencias:

- MySQL/MariaDB portatil;
- schema compativel com Crystal Server/Tibia;
- permissao de escrita em `UserData/Database`.

Riscos ao modificar:

- perda de contas/personagens se dados reais forem versionados ou sobrescritos;
- incompatibilidade entre schema e queries do endpoint;
- conflitos de porta;
- importacao incompleta de schema.

Como testar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```

Depois, criar conta/personagem e verificar persistencia apos reiniciar.

Observacoes importantes:

- dados reais devem permanecer em `UserData/Database` ou outra pasta protegida.

### Servidor

Nome do sistema: Servidor OT

Finalidade: executar o mundo do jogo e aceitar conexoes do cliente.

Arquivos principais esperados:

- `Server/crystalserver.exe`
- `Database_Template/schema.sql`.

Arquivos auxiliares esperados:

- scripts Lua;
- arquivos XML;
- mapa;
- configuracoes do servidor;
- dados de monsters, NPCs, spells, vocations, quests e respawns.

Linguagem usada esperada: C++ no binario, Lua/XML/SQL/configs nos dados do servidor.

Onde fica configurado:

- `Config/launcher-config.json`
- arquivos do servidor quando forem adicionados.

Onde fica a logica principal:

- nao mapeavel no snapshot versionado; `Server/` contem apenas `.gitkeep`.

Dependencias:

- banco de dados;
- portas 7171 e 7172;
- arquivos reais do servidor.

Riscos ao modificar:

- qualquer mudanca em scripts/dados do servidor pode afetar gameplay, persistencia e login;
- falta de schema impede validar criacao de conta/personagem de ponta a ponta.

Como testar:

- validar runtime real instalado;
- executar `Launcher.ps1 -Play`;
- verificar portas 7171/7172 abertas;
- entrar no jogo e validar persistencia.

Observacoes importantes:

- os sistemas de gameplay listados nesta fase dependem dos arquivos reais do servidor.

### Cliente

Nome do sistema: Cliente Tibia local

Finalidade: interface grafica do jogador e conexao com servidor local.

Arquivos principais esperados:

- `Client/bin/client-local.exe`
- assets do cliente.

Arquivos auxiliares observados apenas em `tmp/player-package-download/extract/Client`:

- `assets.json`
- `package.json`
- scripts `.ps1` e `.bat`
- assets de mapa/minimap/catalogo

Linguagem usada esperada: binario cliente e assets/configs JSON.

Onde fica configurado:

- `Config/launcher-config.json`: `clientExe`, `clientWorkingDirectory`.
- arquivos reais do cliente, quando estiverem em `Client/`.

Onde fica a logica principal:

- nao mapeavel no snapshot versionado; `Client/` contem apenas `.gitkeep`.

Dependencias:

- servidor local;
- endpoint de login/criacao;
- assets compativeis;
- variaveis Qt ajustadas pelo launcher.

Riscos ao modificar:

- incompatibilidade entre cliente, assets e protocolo do servidor;
- problemas de renderizacao Qt;
- scripts temporarios em `tmp/` nao devem virar fonte oficial sem revisao.

Como testar:

- executar `Launcher.ps1 -Play` com runtime completo;
- criar conta/personagem;
- logar;
- validar mapa, movimento e fechamento/reabertura.

Observacoes importantes:

- o conteudo em `tmp/` e ignorado e nao representa a estrutura oficial versionada.

### Validacao e publicacao

Nome do sistema: Validacao pre-publicacao

Finalidade: bloquear release com JSON/XML/Lua invalidos, manifest inconsistente, hashes errados, arquivos duplicados ou arquivos protegidos distribuiveis.

Arquivos principais:

- `Launcher/Modules/TibiaRemastered.Validation.psm1`
- `Scripts/Test-Project.ps1`
- `Scripts/Publish-Release.ps1`

Arquivos auxiliares:

- `Launcher/Tools/Generate-Manifest.ps1`
- `Reports/prepublish-report.json`, gerado localmente e ignorado.

Linguagem usada: PowerShell.

Onde fica configurado:

- parametros dos scripts;
- `Config/launcher-config.json`;
- manifest/version.

Onde fica a logica principal:

- `Invoke-TrmPrePublishValidation`
- `Test-TrmProjectIntegrity`
- `Test-TrmJsonFiles`
- `Test-TrmXmlFiles`
- `Test-TrmLuaFiles`

Dependencias:

- `lua` ou `luac` no PATH apenas se houver arquivos Lua;
- PowerShell;
- manifest atualizado.

Riscos ao modificar:

- validacao permissiva pode publicar dados sensiveis;
- validacao excessiva pode bloquear releases validas;
- gerar manifest antes de limpar temporarios pode incluir lixo se filtros forem alterados.

Como testar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Publish-Release.ps1 -Version 0.1.0 -SkipGitPush
```

Observacoes importantes:

- `-StrictRuntime` deve ser usado para declarar estabilidade com servidor/cliente reais.

## Sistemas de gameplay

Os sistemas abaixo foram solicitados para mapeamento. No snapshot versionado atual, nenhum deles possui arquivos Lua/XML/SQL proprios em `Server/`, `Client/` ou `Database_Template/`.

| Sistema | Status no snapshot versionado | Evidencia |
| --- | --- | --- |
| experiencia | Parcialmente referenciado | endpoint insere `experience=4200` ao criar player |
| skills | Nao mapeavel | sem arquivos de servidor |
| loot | Nao mapeavel | sem arquivos de servidor |
| spells | Nao mapeavel | sem Lua/XML de spells |
| runas | Nao mapeavel | sem Lua/XML de runas |
| store | Nao mapeavel | sem arquivos do sistema |
| tibia coins | Parcialmente referenciado | endpoint cria conta com `coins=999999` |
| prey | Nao mapeavel | sem arquivos do sistema |
| forge | Nao mapeavel | sem arquivos do sistema |
| bestiario | Nao mapeavel | sem arquivos do sistema |
| charms | Nao mapeavel | sem arquivos do sistema |
| imbuements | Nao mapeavel | sem arquivos do sistema |
| cooldowns | Nao mapeavel | sem arquivos do sistema |
| vocacoes | Parcialmente referenciado | endpoint cria personagem com `vocation=0` |
| monstros | Nao mapeavel | sem XML/Lua de monsters |
| NPCs | Nao mapeavel | sem XML/Lua de NPCs |
| quests | Nao mapeavel | sem XML/Lua de quests |
| respawn | Nao mapeavel | sem mapa/spawn |
| saves | Parcialmente mapeado | dados devem ficar em `UserData/` e banco local |
| login | Parcialmente mapeado | endpoint local implementa resposta de login |
| criacao de personagem | Parcialmente mapeado | endpoint insere em `accounts` e `players` |
| launcher | Mapeado | PowerShell em `Launcher/` |
| update via GitHub | Mapeado | manifest/version/update module |
| backup | Mapeado | backup antes de update |
| rollback | Parcialmente mapeado | restore de backup em falha de update |
| logs | Mapeado | `Logs/launcher_yyyy-MM-dd.log` |

## Dependencias gerais

- Windows PowerShell;
- Windows Forms para GUI;
- GitHub raw content;
- GitHub Releases para pacote do jogador;
- MySQL/MariaDB portatil;
- Crystal Server ou servidor OT compativel;
- cliente Tibia compativel;
- portas locais 80, 3306, 7171 e 7172;
- opcional: `gh` CLI para token GitHub;
- opcional: `lua` ou `luac` para validar scripts Lua.

## Arquivos criticos

- `Launcher/Launcher.ps1`
- `Launcher/Modules/TibiaRemastered.Core.psm1`
- `Launcher/Modules/TibiaRemastered.Update.psm1`
- `Launcher/Modules/TibiaRemastered.Runtime.psm1`
- `Launcher/Modules/TibiaRemastered.Validation.psm1`
- `Config/launcher-config.json`
- `manifest.json`
- `version.json`
- `.gitignore`
- `Scripts/Test-Project.ps1`
- `Scripts/Test-UpdateSimulation.ps1`
- `Scripts/Publish-Release.ps1`
- `Launcher/Tools/Generate-Manifest.ps1`

## Atualizacao da Fase 3.1

O runtime real foi localizado originalmente em:

```text
tmp/player-package-download/TibiaRemastered-Player.zip
```

Esse pacote foi extraido para `Client/`, `Server/` e `Database_Template/`, incluindo cliente, Crystal Server, MariaDB portatil, `Database_Template/schema.sql`, `Database_Template/otserv.sql` e datapacks Lua/XML.

Documentos detalhados:

- `Docs/RUNTIME_FILES_AUDIT.md`
- `Docs/LUA_XML_SQL_AUDIT.md`
- `Docs/LAUNCHER_RUNTIME_PATHS.md`

Importante: `UserData/`, `Logs/` e `Backup/` continuam reservados para dados locais e nao foram usados como fonte de runtime.

## Problemas conhecidos

- `TibiaRemastered.Runtime.psm1` concentra muitas responsabilidades.
- o endpoint local assume schema especifico sem contrato SQL versionado.
- `-Play` usa runtime local por padrao porque `autoUpdateBeforePlay=false`.
- update/reparo via GitHub continua disponivel no fluxo proprio do Launcher.
- login e persistencia ainda exigem validacao interativa no cliente.
