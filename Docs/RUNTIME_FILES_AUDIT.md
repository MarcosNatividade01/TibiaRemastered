# Runtime Files Audit

Auditoria da Fase 3 sobre os arquivos reais de runtime.

## Resultado executivo

O runtime real foi localizado originalmente no pacote temporario:

```text
tmp/player-package-download/TibiaRemastered-Player.zip
```

Esse pacote foi extraido para as pastas oficiais:

- `Client/`
- `Server/`
- `Database_Template/`

Como `tmp/` e uma pasta ignorada e temporaria, o ZIP continua sendo apenas a fonte anterior. O runtime oficial agora e a estrutura extraida na raiz do projeto.

## Arquivos oficiais esperados pelo Launcher

| Tipo | Caminho esperado | Status nas pastas oficiais | Status no pacote |
| --- | --- | --- | --- |
| Client | `Client/bin/client-local.exe` | Encontrado | Encontrado |
| Client alternativo | `Client/bin/client.exe` | Encontrado | Encontrado |
| Server | `Server/crystalserver.exe` | Encontrado | Encontrado |
| Banco | `Database_Template/mysql/bin/mysqld.exe` | Encontrado | Encontrado |
| Cliente MySQL | `Database_Template/mysql/bin/mysql.exe` | Encontrado | Encontrado |
| Schema | `Database_Template/schema.sql` | Encontrado | Encontrado |
| Dump/base | `Database_Template/otserv.sql` | Encontrado | Encontrado |
| Config servidor | `Server/config.lua` | Encontrado | Encontrado |

## Client real

Localizacao oficial:

```text
Client/
```

Arquivos importantes:

- `Client/bin/client-local.exe`
- `Client/bin/client.exe`
- `Client/assets.json`
- `Client/package.json`
- `Client/assets/`
- `Client/storeimages/`

Tipos encontrados no pacote:

- executaveis;
- DLLs;
- assets `.dat`, `.lzma`, `.png`, `.ogg`;
- arquivos Qt/QML;
- scripts `.bat` e `.ps1`;
- metadados JSON.

Riscos:

- assets e binario precisam permanecer sincronizados;
- scripts dentro do pacote nao devem ser promovidos sem revisao.

## Server real

Localizacao oficial:

```text
Server/
```

Arquivos importantes:

- `Server/crystalserver.exe`
- `Server/config.lua`
- `Server/schema.sql`
- `Server/otserv.sql`
- `Server/data/`
- `Server/data-crystal/`
- `Server/data-global/`

Raizes de dados:

| Raiz | Finalidade inferida | Arquivos |
| --- | --- | ---: |
| `Server/data` | Core/base comum | 735 |
| `Server/data-crystal` | Datapack Crystal | 2430 |
| `Server/data-global` | Datapack global selecionado em config | 5016 |

Configuracao observada em `Server/config.lua`:

- `dataPackDirectory = "data-global"`
- `coreDirectory = "data"`
- `ip = "127.0.0.1"`
- `worldType = "pvp"`

Riscos:

- `dataPackDirectory` aponta para `data-global`; alteracoes em `data-crystal` podem nao afetar o jogo se essa config continuar assim.
- ha documentos de auditoria e build dentro de `Server/` no pacote; nem tudo e runtime essencial.
- alterar `config.lua` pode mudar PvP, rates, conexao, banco e comportamento global.

## Banco real e modelo

Localizacao oficial:

```text
Database_Template/mysql/
Database_Template/schema.sql
Database_Template/otserv.sql
```

Interpretacao:

- o runtime usa MariaDB/MySQL portatil em `Database_Template/mysql`;
- o launcher usa `Database_Template/schema.sql` como seed configurado por `databaseSeedSql`;
- `otserv.sql` foi preservado como base adicional para auditoria, sem ser aplicado automaticamente.

Riscos:

- `Database/` e protegido e ignorado por design; nao deve ser versionado com dados reais.
- `Database_Template/` deve receber apenas schema limpo, sem contas, personagens ou progresso real.
- o endpoint local assume tabelas `accounts`, `players`, `account_vipgroups` e `towns`.

## Recomendacao

Antes de mudanças de gameplay:

1. executar `Test-Project.ps1 -StrictRuntime`;
2. validar `Launcher.ps1 -Play`;
3. testar criacao de conta, personagem, login e persistencia;
4. revisar qualquer alteracao Lua/XML/SQL antes de aplicar.
