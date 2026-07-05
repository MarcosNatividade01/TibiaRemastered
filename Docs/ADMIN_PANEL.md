# Admin Panel

## Objetivo

O painel `Admin / Testes` do Launcher executa os testes administrativos do Remastered Balance Module sem depender de comandos manuais no chat.

## Acesso

Por seguranca, o painel fica oculto por padrao.

Para habilitar de forma persistente em ambiente local:

```json
"developerMode": true,
"adminPanelEnabled": true
```

Arquivo:

```text
Config/launcher-config.json
```

Para habilitar temporariamente em uma sessao PowerShell:

```powershell
$env:TRM_DEVELOPER_MODE='1'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1
```

## Fluxo tecnico

1. O Launcher grava uma requisicao em `Logs/BalanceTests/admin-panel-request.txt`.
2. O servidor processa a requisicao pelo `GlobalEvent` `RemasteredAdminPanelTests`.
3. A API `Remastered.AdminBalanceTests` executa o mesmo calculo usado pelos comandos da Fase 7.
4. O resultado e salvo em `Logs/BalanceTests/admin-panel-result-<id>.log`.
5. O Launcher mostra o resultado no painel.

## Botoes

- `Testar Balanceamento`;
- `Testar XP`;
- `Testar Skill`;
- `Testar Loot`;
- `Abrir Logs`;
- `Limpar Logs`.

## Garantias

- nao adiciona XP;
- nao adiciona skill tries;
- nao cria itens reais;
- nao altera banco de dados;
- nao substitui os comandos `/testbalance`, `/testxp`, `/testskill` e `/testloot`;
- exige servidor aberto para executar os testes.
