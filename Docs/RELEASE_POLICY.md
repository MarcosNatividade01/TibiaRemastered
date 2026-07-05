# Politica Oficial de Releases

## Regra principal

O GitHub armazena apenas versoes aprovadas do Tibia Remastered.

Nenhuma versao incompleta, quebrada, com bug critico conhecido ou com Host Assistido sem validacao completa pode ser publicada.

## Etapas oficiais

### 1. Desenvolvimento Local

Toda implementacao, correcao e teste inicial acontece apenas na maquina local.

Durante desenvolvimento local:

- implementar funcionalidades;
- corrigir bugs;
- testar;
- repetir ate funcionar.

Nesta etapa e proibido:

- atualizar `version.json`;
- atualizar `manifest.json`;
- publicar no GitHub;
- executar `Tools/Publish/Publish.bat`;
- fazer push de versao incompleta para `main`.

### 2. Release Oficial

Uma release oficial so pode ser publicada depois que todos os criterios da checklist oficial forem aprovados.

O publicador oficial executa `Scripts/Test-OfficialReleaseChecklist.ps1` antes de alterar arquivos de release. Se qualquer item falhar, a publicacao e cancelada antes de `version.json`, `manifest.json`, commit ou push.

## Checklist obrigatoria

Antes de publicar, estes itens precisam estar aprovados:

- Launcher abre corretamente.
- Jogar Offline funciona.
- Host consegue criar mundo.
- Host consegue entrar no proprio mundo.
- Convidado consegue entrar no mundo, ou o diagnostico online registra conexao clara com `targetReachable=true` e versao compativel quando nao houver segundo computador disponivel.
- Convite funciona.
- Testar Conexao funciona.
- Runtime sem erros criticos.
- Module Loader carrega todos os modulos esperados.
- Feature Flags funcionam corretamente.
- Nenhum save foi perdido.
- Nenhum banco foi sobrescrito.
- `manifest.json` valido.
- `version.json` valido.

## Aprovacao local

Os testes manuais completos devem ser registrados localmente em:

```text
Logs/QAReports/official-release-approval.json
```

`Logs/` nao e publicado. Esse arquivo e apenas uma autorizacao local para o publicador oficial.

Modelo:

```json
{
  "version": "0.1.3",
  "approved": true,
  "approvedAt": "2026-07-05T12:00:00",
  "checks": {
    "launcherOpens": true,
    "offlineWorks": true,
    "hostCreatesWorld": true,
    "hostJoinsOwnWorld": true,
    "guestJoinsWorld": false,
    "onlineDiagnosticClear": true,
    "inviteWorks": true,
    "testConnectionWorks": true,
    "noCriticalRuntimeErrors": true,
    "moduleLoaderOk": true,
    "featureFlagsOk": true,
    "userDataPreserved": true,
    "databaseNotOverwritten": true,
    "manifestValid": true,
    "versionValid": true,
    "hostAssistedFullyFunctional": true
  }
}
```

Nao marque um item como `true` sem executar o teste correspondente.

## Bloqueio atual

Enquanto o Host Assistido nao estiver completamente funcional, nenhuma release oficial deve ser publicada.

Se houver falha em host, convidado, convite, Login Server, Game Server ou versionamento entre maquinas, a versao permanece local ou Release Candidate, mas nao vira release estavel.

## Publicacao

Somente depois da checklist aprovada:

1. `Publish.bat` executa a checklist oficial.
2. `Publish.ps1` atualiza `version.json`.
3. `Publish.ps1` gera `manifest.json`.
4. `Publish.ps1` atualiza `CHANGELOG.md`.
5. `Publish.ps1` valida arquivos proibidos.
6. `Publish.ps1` cria commit.
7. `Publish.ps1` envia push para GitHub.

Se qualquer etapa falhar, o push nao acontece.
