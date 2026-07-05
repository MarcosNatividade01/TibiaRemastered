# Arquitetura de Distribuicao

## Fonte oficial

O repositorio `https://github.com/MarcosNatividade01/TibiaRemastered` e a fonte oficial dos arquivos distribuidos. O launcher consulta:

- `version.json` para descobrir a versao publicada.
- `manifest.json` para obter a lista de arquivos, hashes SHA256, tamanhos e URLs.

## Modulos do launcher

- `Launcher/Launcher.ps1`: entrada do launcher, GUI e comandos `-SelfTest`, `-Check`, `-Repair`, `-Play` e `-NoGui`.
- `Launcher/Modules/TibiaRemastered.Core.psm1`: paths, configuracao, logs, JSON, SHA256 e protecao de arquivos locais.
- `Launcher/Modules/TibiaRemastered.Update.psm1`: leitura remota, comparacao de hashes, download incremental, backup, restauracao e relatorio da ultima atualizacao.
- `Launcher/Modules/TibiaRemastered.Runtime.psm1`: inicializacao de banco, endpoint web, servidor e cliente.
- `Launcher/Modules/TibiaRemastered.Validation.psm1`: validacao pre-publicacao, JSON, XML, Lua, manifest, hashes, duplicados e arquivos obrigatorios.

## Fluxo ao clicar em Jogar

1. O launcher cria a estrutura local obrigatoria.
2. Le `Config/launcher-config.json`.
3. Verifica acesso ao `manifest.json` remoto.
4. Le `version.json` e `manifest.json`.
5. Calcula SHA256 de cada arquivo local listado no manifest.
6. Baixa somente arquivos ausentes, corrompidos, modificados ou desatualizados.
7. Valida o SHA256 do arquivo baixado antes de substituir o arquivo final.
8. Cria backup antes de substituir arquivos existentes.
9. Gera `Reports/last-update.json` com historico da atualizacao.
10. Inicia banco, endpoint web, servidor local e cliente.

## Arquivos protegidos

Os caminhos abaixo nunca sao sobrescritos automaticamente:

- `UserData/**`
- `Logs/**`
- `Backup/**`
- `Backups/**`
- `Saves/**`
- `Database/**`
- `Databases/**`
- `PrivateDatabase/**`
- `Config/launcher-config.json`
- `manifest.json`
- `version.json`

## Publicacao de uma nova versao

Execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Publish-Release.ps1 -Version 0.1.1
```

Esse comando gera `manifest.json` e `version.json`, valida o projeto e interrompe a publicacao se houver erro.

Para exigir que os executaveis reais de servidor e cliente existam na maquina de validacao:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Publish-Release.ps1 -Version 0.1.1 -StrictRuntime
```

## Validacoes obrigatorias

`Scripts/Test-Project.ps1` executa:

- estrutura do projeto;
- arquivos obrigatorios;
- JSON;
- XML;
- Lua, quando `lua` ou `luac` estiverem instalados;
- manifest;
- arquivos duplicados no manifest;
- hashes;
- tentativa de distribuir arquivos protegidos;
- presenca de servidor/cliente como aviso ou erro com `-StrictRuntime`.

Se houver erro, o script retorna codigo diferente de zero e a publicacao deve ser bloqueada.

## Testes de update

Execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-UpdateSimulation.ps1
```

O teste cria uma instalacao temporaria em `tmp/update-simulation`, simula instalacao limpa, arquivo corrompido, reparo e protecao de dados locais.
