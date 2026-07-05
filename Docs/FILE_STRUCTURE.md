# File Structure

Mapa da estrutura atual do projeto.

## Raiz

```text
TibiaRemastered/
  Assets/
  Client/
  Config/
  Database_Template/
  Docs/
  Launcher/
  Scripts/
  Server/
  Tools/
  .gitignore
  CHANGELOG.md
  IDEIAS.md
  manifest.json
  PROJECT_GUIDELINES.md
  README.md
  ROADMAP.md
  Start Launcher.bat
  version.json
```

Pastas locais geradas e ignoradas:

```text
Backup/
Logs/
Reports/
tmp/
UserData/
Database/
Databases/
PrivateDatabase/
Saves/
Save/
```

## Pastas versionadas

### `Assets/`

Finalidade: assets versionaveis pequenos e seguros.

Estado atual: apenas `.gitkeep`.

Risco: nao colocar arquivos temporarios, cache, dumps ou dados pessoais.

### `Client/`

Finalidade: cliente distribuido.

Estado atual: apenas `.gitkeep` no snapshot versionado.

Runtime oficial instalado em `Client/`.

Arquivos esperados futuramente:

- `Client/bin/client-local.exe`
- assets e configuracoes do cliente.

Risco: cliente e assets precisam ser compativeis com servidor, endpoint e manifest.

### `Config/`

Finalidade: configuracao do launcher.

Arquivos:

- `launcher-config.json`

Campos criticos:

- URLs remotas de version/manifest;
- caminhos de servidor, cliente e banco;
- portas;
- pacote do jogador;
- caminhos preservados.

Risco: `Config/launcher-config.json` e protegido e nao deve ser sobrescrito automaticamente.

### `Database_Template/`

Finalidade: templates seguros de banco, sem dados reais.

Estado atual: apenas `.gitkeep`.

Schema real instalado em:

- `Database_Template/schema.sql`
- `Database_Template/otserv.sql`
- `Database_Template/mysql/`

Arquivos esperados futuramente:

- schema SQL limpo;
- seeds publicos e seguros;
- instrucoes de migracao.

Risco: nunca colocar banco real, contas reais ou personagens reais.

### `Docs/`

Finalidade: documentacao tecnica e operacional.

Arquivos atuais:

- `ARCHITECTURE.md`
- `ARCHITECTURE_MAP.md`
- `SYSTEMS_INDEX.md`
- `FILE_STRUCTURE.md`
- `CHANGE_IMPACT_GUIDE.md`
- `RUNTIME_FILES_AUDIT.md`
- `LUA_XML_SQL_AUDIT.md`
- `LAUNCHER_RUNTIME_PATHS.md`

Risco: documentacao desatualizada pode induzir alteracoes perigosas no runtime.

### `Launcher/`

Finalidade: launcher, GUI, modulos e ferramentas auxiliares.

Arquivos:

```text
Launcher/
  Launcher.ps1
  Modules/
    TibiaRemastered.Core.psm1
    TibiaRemastered.Update.psm1
    TibiaRemastered.Runtime.psm1
    TibiaRemastered.Validation.psm1
  Tools/
    Generate-Manifest.ps1
```

Responsabilidades:

- `Launcher.ps1`: entrada, GUI e comandos.
- `Core`: paths, config, logs, JSON, hash, protecao.
- `Update`: manifest remoto, download, backup, rollback.
- `Runtime`: pacote, banco, endpoint, servidor e cliente.
- `Validation`: testes de integridade.
- `Generate-Manifest`: gera manifest/version.

Risco: `Runtime` e o modulo mais acoplado.

### `Scripts/`

Finalidade: automacao de validacao, release e pacote.

Arquivos:

- `Test-Project.ps1`
- `Test-UpdateSimulation.ps1`
- `Publish-Release.ps1`
- `New-PlayerPackage.ps1`

Risco: scripts de pacote podem incluir dados sensiveis se exclusoes forem alteradas sem revisao.

### `Server/`

Finalidade: servidor distribuido.

Estado atual: apenas `.gitkeep` no snapshot versionado.

Runtime oficial instalado em `Server/`.

Arquivos esperados futuramente:

- `crystalserver.exe`
- `schema.sql`
- scripts Lua;
- arquivos XML;
- mapa;
- configs de monsters, NPCs, spells, vocations, quests e respawns.

Risco: sem esses arquivos nao e possivel validar gameplay.

### `Tools/`

Finalidade: ferramentas auxiliares gerais.

Estado atual: apenas `.gitkeep`.

## Arquivos criticos da raiz

### `.gitignore`

Protege dados locais, segredos, banco real, logs, backups, temporarios e pacotes.

### `manifest.json`

Lista arquivos distribuiveis, hashes SHA256, tamanho, URL e categoria.

Nao deve conter:

- `UserData/`
- `Logs/`
- `Backup/`
- `Reports/`
- `tmp/`
- `Config/launcher-config.json`
- `version.json`
- `manifest.json`
- bancos reais;
- dumps;
- secrets.

### `version.json`

Define versao, canal, data e versao minima do launcher.

### `PROJECT_GUIDELINES.md`

Define regras de seguranca, release e estabilidade.

### `Start Launcher.bat`

Entrada simples para usuarios Windows iniciarem o launcher.

## Artefatos locais observados

Durante testes anteriores, `tmp/player-package-download/` recebeu o pacote real do jogador. Como `tmp/` e ignorado, esse conteudo nao e tratado como fonte oficial versionada.

Usos permitidos:

- diagnostico local;
- comparacao manual;
- validacao temporaria.

Usos proibidos sem revisao:

- promover arquivos de `tmp/` para fonte oficial;
- gerar manifest com `tmp/`;
- publicar pacote contendo dados pessoais.

## Estrutura minima para runtime completo

Para testar o jogo de ponta a ponta, o projeto precisa conter ou baixar:

```text
Client/bin/client-local.exe
Server/crystalserver.exe
Database_Template/mysql/bin/mysqld.exe
Database_Template/mysql/bin/mysql.exe
Database_Template/schema.sql
```

Com esses arquivos presentes, executar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```
