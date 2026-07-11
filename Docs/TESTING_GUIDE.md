# Testing Guide

## Runtime basico

1. Abrir o Launcher.
2. Executar Play.
3. Confirmar que servidor e cliente iniciam.
4. Entrar com um personagem.
5. Confirmar que nao ha erro critico no console.

## Remastered Balance Module

Com a flag ligada:

```lua
enable_remastered_balance = true
```

Executar como God:

```text
/testbalance
/testxp dragon
/testskill sword 100
/testloot dragon 100
```

Resultados esperados:

- XP Rate efetiva `x8`;
- Skill Rate efetiva `x3`;
- Magic Level Rate efetiva `x3`;
- intervalo base de ataque dos jogadores `1000 ms` (`2x`);
- a camada Remastered permanece em `1x`, evitando multiplicacao duplicada.

Validacao automatizada:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-BalanceConfig.ps1
```
- Skill Rate `x3`;
- Loot Rate `x2`;
- logs gerados em `Logs/BalanceTests/`.

Com a flag desligada:

```lua
enable_remastered_balance = false
```

Reiniciar o servidor e repetir os comandos. Os valores finais devem retornar ao comportamento base: XP `x1`, skill `x1` e loot factor `1.0`.

## Permissao

Entrar com um personagem comum e tentar:

```text
/testbalance
```

Resultado esperado: comando bloqueado por permissao, sem relatorio de admin.

## Painel Admin do Launcher

Habilitar temporariamente:

```powershell
$env:TRM_DEVELOPER_MODE='1'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Launcher.ps1
```

Fluxo:

1. clicar em `Jogar`;
2. aguardar servidor e cliente iniciarem;
3. abrir `Admin / Testes`;
4. executar `Testar Balanceamento`, `Testar XP`, `Testar Skill` e `Testar Loot`;
5. confirmar resultados no painel;
6. abrir `Logs/BalanceTests/` e confirmar os arquivos `admin-panel-result-*.log`.

## Observacoes

Os comandos de teste nao devem ser usados para alterar progresso. Eles apenas calculam e simulam valores.
