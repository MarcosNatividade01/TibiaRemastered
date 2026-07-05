# Project Guidelines

Este documento define as regras de estabilidade da base v0.1.0 do TibiaRemastered.

## Escopo da v0.1.0

A v0.1.0 e a base de plataforma para:

- organizar cliente, servidor, launcher, scripts e documentacao;
- validar manifest, hashes e arquivos obrigatorios;
- proteger dados locais do jogador durante atualizacoes;
- preparar futuras releases automaticas pelo GitHub.

Nao fazem parte da estabilidade da v0.1.0 novas mecanicas de jogo, mudancas de conteudo, balanceamento ou novas telas.

## Estrutura canonica

```text
Client/
Server/
Launcher/
UserData/
Logs/
Backup/
Docs/
Database_Template/
manifest.json
version.json
```

`Database_Template/` e o nome canonico para modelos de banco seguros. O launcher ainda cria `DatabaseTemplate/` por compatibilidade com versoes antigas, mas novos documentos e manifests devem usar `Database_Template/`.

## Dados que nunca devem ser versionados

- contas reais;
- personagens reais;
- banco de dados real do usuario;
- saves;
- configuracoes pessoais;
- logs;
- backups;
- tokens, chaves, senhas e arquivos `.env`.

## Regras de atualizacao

O launcher deve tratar os caminhos abaixo como protegidos e nunca sobrescreve-los automaticamente:

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

Qualquer arquivo novo que contenha dado pessoal deve ficar dentro de uma dessas areas protegidas ou ser adicionado explicitamente a regra de protecao antes de uma release.

## Politica oficial de release

O GitHub deve armazenar apenas versoes aprovadas.

O desenvolvimento diario acontece fora de `main`, preferencialmente em `develop`. A branch `main` deve conter somente versoes estaveis publicadas pelo fluxo oficial.

Durante desenvolvimento local, nao atualizar:

- `version.json`;
- `manifest.json`;
- `CHANGELOG.md` de release;
- GitHub.

O Host Assistido precisa estar completamente funcional antes de qualquer release oficial.

Documentos oficiais:

- `Docs/RELEASE_POLICY.md`
- `Docs/WORKFLOW.md`
- `Docs/VERSIONING.md`

## Criterio tecnico de release

Antes de publicar uma versao:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-UpdateSimulation.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-OfficialReleaseChecklist.ps1
```

Para declarar uma versao estavel com runtime completo:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
```

O modo estrito exige os executaveis reais de servidor e cliente.

`Tools/Publish/Publish.bat` executa a checklist oficial automaticamente e cancela a publicacao se qualquer item falhar.
