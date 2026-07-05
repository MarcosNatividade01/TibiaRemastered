# Publicador GitHub

## Como usar

Abra com duplo clique:

```text
Tools/Publish/Publish.bat
```

O script prepara a versao, mostra os arquivos que serao enviados e pede confirmacao antes de `git commit` e `git push`.

Antes de qualquer alteracao de release, o publicador executa a Checklist Oficial de Release. Se algum item falhar, a publicacao e cancelada antes de atualizar `version.json`, `manifest.json`, commit ou push.

## Etapas executadas

1. Executa `Scripts/Test-OfficialReleaseChecklist.ps1`.
2. Verifica se Git esta instalado.
3. Inicializa o repositorio se `.git/` nao existir.
4. Garante que `origin` aponta para:

```text
https://github.com/MarcosNatividade01/TibiaRemastered.git
```

5. Valida `.gitignore`.
6. Atualiza `CHANGELOG.md`.
7. Gera `version.json`.
8. Gera `manifest.json` com URLs do GitHub.
9. Executa `git add -A`.
10. Remove do indice arquivos proibidos conhecidos.
11. Mostra `git status`.
12. Pede confirmacao.
13. Executa `git commit`.
14. Executa `git push`.

## Checklist obrigatoria

O publicador exige aprovacao local em:

```text
Logs/QAReports/official-release-approval.json
```

Esse arquivo deve registrar todos os testes manuais descritos em `Docs/RELEASE_POLICY.md`. Sem essa aprovacao, `Publish.bat` falha e nao envia nada ao GitHub.

## Arquivos protegidos

O publicador bloqueia publicacao de:

- `UserData/`
- `Logs/`
- `Backup/`
- `Backups/`
- `Saves/`
- `Save/`
- banco real e dumps privados
- tokens, senhas e chaves
- arquivos temporarios
- arquivos grandes distribuidos pelo Player Package/Release

## Git nao instalado

Instale com:

```powershell
winget install --id Git.Git -e
```

Depois feche e abra o terminal/Explorer novamente.

## Teste sem publicar

Para validar sem commit/push:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Tools\Publish\Publish.ps1 -DryRun
```

## Restaurar se houver erro

Se o script falhar antes do commit, corrija o erro e rode novamente.

Se o commit for criado mas o push falhar, rode novamente depois de corrigir login/rede/remoto.

Para desfazer o ultimo commit local antes do push:

```powershell
git reset --soft HEAD~1
```

Use esse comando somente se tiver certeza de que o commit ainda nao foi enviado.
