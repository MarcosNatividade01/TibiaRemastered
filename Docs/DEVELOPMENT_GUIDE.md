# Development Guide

## Principio central

Preferir extensao a alteracao direta. O codigo exclusivo do Tibia Remastered deve viver em `Modules/Remastered`.

## Fluxo recomendado para novas funcionalidades

1. Definir objetivo e escopo.
2. Mapear arquivos originais impactados.
3. Criar modulo proprio em `Modules/Remastered`.
4. Adicionar configuracao centralizada.
5. Adicionar feature flag desativada por padrao.
6. Criar `module.json` seguindo `Docs/MODULE_STANDARD.md`.
7. Declarar o modulo em `modules.available`.
8. Integrar usando o menor ponto de contato possivel.
9. Testar com flag desligada.
10. Testar com flag ligada em ambiente local.
11. Documentar impacto e rollback.

## Pontos de contato permitidos

Arquivos originais podem receber pontes pequenas quando nao existir mecanismo nativo de extensao. Toda ponte deve:

- ser pequena;
- ter responsabilidade unica;
- delegar para `Modules/Remastered`;
- preservar comportamento original quando o modulo nao existir;
- ser documentada.

Ponte atual:

```text
Server/data/global.lua -> Server/data/remastered_bootstrap.lua -> Modules/Remastered/bootstrap.lua
```

## Proibido nesta camada

- Alterar gameplay sem feature flag.
- Misturar balanceamento com inicializacao.
- Escrever regras novas diretamente em scripts originais.
- Criar constantes locais duplicadas.
- Criar dependencias externas sem justificativa.

## Testes minimos por mudanca

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-Project.ps1 -StrictRuntime
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -SelfTest
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1 -Play
```

Quando a mudanca envolver gameplay, validar tambem dentro do cliente.

## Debug do Module Loader

Verifique:

```text
Logs/remastered-core.log
```

Procure por:

- `Module found`
- `Module loaded`
- `Module skipped`
- `Module failed`
- `missing dependency`
