# QA Minimo

## Objetivo

Validacao rapida para proteger o modo Offline antes de alteracoes maiores.

## Como executar

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -MinimumQA
```

Ou pelo Launcher:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -MinimumQA
```

## Relatorios

Os relatorios sao gerados em:

```text
Logs/QAReports/
```

## Checks atuais

- Launcher existe.
- Runtime oficial existe.
- `Client/` existe.
- `Server/` existe.
- `Database_Template/` existe.
- `UserData/` continua protegido.
- Feature flags existem.
- Module Loader nao possui erro critico recente no log.
- Offline continua configurado com `autoUpdateBeforePlay=false`.
- Arquivos protegidos continuam protegidos.

## Escopo

Este QA nao substitui uma suite completa. Ele existe apenas para impedir regressao basica do modo Offline.
