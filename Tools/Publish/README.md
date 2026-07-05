# Publicador GitHub

## Como usar

Abra com duplo clique:

```text
Tools/Publish/Publish.bat
```

O script prepara a versao, mostra os arquivos que serao enviados e pede confirmacao antes de `git commit` e `git push`.

## Etapas executadas

1. Verifica se Git esta instalado.
2. Inicializa o repositorio se `.git/` nao existir.
3. Garante que `origin` aponta para:

```text
https://github.com/MarcosNatividade01/TibiaRemastered.git
```

4. Valida `.gitignore`.
5. Atualiza `CHANGELOG.md`.
6. Gera `version.json`.
7. Gera `manifest.json` com URLs do GitHub.
8. Executa `git add -A`.
9. Remove do indice arquivos proibidos conhecidos.
10. Mostra `git status`.
11. Pede confirmacao.
12. Executa `git commit`.
13. Executa `git push`.

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
