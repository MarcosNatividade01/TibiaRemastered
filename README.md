# TibiaRemastered

Projeto privado para hospedar e organizar um OTServer com servidor, cliente, launcher, auto-update, documentacao e arquivos necessarios para testes locais.

## Estrutura

```text
TibiaRemastered/
  Client/
  Server/
  Launcher/
  Assets/
  DatabaseTemplate/
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

O arquivo `version.json` guarda a versao atual do projeto. O arquivo `manifest.json` sera usado pelo launcher para comparar arquivos locais com os arquivos publicados no GitHub.

