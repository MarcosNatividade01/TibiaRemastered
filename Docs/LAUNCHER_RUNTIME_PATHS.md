# Launcher Runtime Paths

Auditoria dos caminhos usados pelo launcher para iniciar o runtime.

## Configuracao atual

Arquivo:

```text
Config/launcher-config.json
```

## Caminhos principais

| Config | Valor | Tipo | Status |
| --- | --- | --- | --- |
| `serverExe` | `Server\\crystalserver.exe` | Relativo | Correto apos instalar pacote |
| `serverWorkingDirectory` | `Server` | Relativo | Correto apos instalar pacote |
| `clientExe` | `Client\\bin\\client-local.exe` | Relativo | Correto apos instalar pacote |
| `clientWorkingDirectory` | `Client` | Relativo | Correto apos instalar pacote |
| `databaseExe` | `Database_Template\\mysql\\bin\\mysqld.exe` | Relativo | Oficial |
| `databaseWorkingDirectory` | `Database_Template\\mysql\\bin` | Relativo | Oficial |
| `databaseSeedSql` | `Database_Template\\schema.sql` | Relativo | Oficial |
| `autoUpdateBeforePlay` | `false` | Booleano | Play usa runtime local por padrao |
| `webServerExe` | vazio | Relativo/neutro | usa endpoint portatil |
| `webServerWorkingDirectory` | vazio | Relativo/neutro | usa endpoint portatil |

## Portas

| Finalidade | Porta |
| --- | ---: |
| MySQL/MariaDB | 3306 |
| Endpoint web | 80 |
| Servidor login/game | 7171, 7172 |

## Fonte anterior do pacote

O launcher pode baixar o pacote completo usando:

- `playerPackageUrl`
- `playerPackageParts`
- `playerPackageSha256`

Pacote localizado nesta auditoria:

```text
tmp/player-package-download/TibiaRemastered-Player.zip
```

O pacote foi usado para oficializar as pastas:

- `Client/`
- `Server/`
- `Database_Template/`

## Fluxo esperado de `-Play`

1. Garante estrutura local.
2. Executa update/reparo via manifest remoto somente se `autoUpdateBeforePlay=true`.
3. Se servidor, cliente ou banco estiverem ausentes, baixa/extrai pacote do jogador.
4. Copia `Client/` e `Server/` do pacote para a raiz, e `Database/` para `Database_Template/`.
5. Inicia banco local.
6. Garante schema.
7. Inicia endpoint web local ou XAMPP se configurado e saudavel.
8. Inicia servidor.
9. Aguarda portas 7171/7172.
10. Inicia cliente.

## Verificacao do modo offline

Estado atual:

- `Start-TrmGame` nao executa update remoto antes do Play com `autoUpdateBeforePlay=false`;
- se `autoUpdateBeforePlay=true` e a atualizacao remota falhar, o Launcher registra aviso e continua com o runtime local ja instalado;
- o fluxo offline depende de `Client/`, `Server/` e `Database_Template/` estarem completos;
- `UserData/`, `Logs/` e `Backup/` continuam protegidos e nao sao usados como fonte de runtime.

Validacao automatica nesta fase:

- `StrictRuntime` confirma os executaveis locais e o seed SQL;
- `Launcher -SelfTest` confirma configuracao basica e protecao de `UserData`;
- login, criacao de personagem e persistencia continuam exigindo validacao interativa no cliente.

## Protecao de `UserData`

Protecoes configuradas:

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

Protecoes no codigo:

- `Test-TrmProtectedPath` bloqueia paths sensiveis no update.
- `Generate-Manifest.ps1` ignora dados locais, logs, backups, bancos e config local.
- `.gitignore` protege dados locais e segredos.

## Caminhos absolutos indevidos ou de risco

Estado atual:

- `webServerExe` esta vazio.
- `webServerWorkingDirectory` esta vazio.
- `Scripts/New-PlayerPackage.ps1` usa fontes relativas: `Client`, `Server` e `Database_Template\\mysql`.

Classificacao:

- nenhum caminho absoluto obrigatorio foi mantido no launcher/config atual.

## Resultado

O launcher aponta para caminhos relativos oficiais para servidor, cliente e banco.

O runtime real agora esta instalado nas pastas oficiais `Client/`, `Server/` e `Database_Template/`.
