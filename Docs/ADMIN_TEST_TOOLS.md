# Admin Test Tools

## Objetivo

Ferramentas administrativas para validar numericamente XP, skill e loot do Remastered Balance Module sem alterar progresso real do personagem.

## Feature flag

Arquivo:

```text
Modules/Remastered/Config/features.lua
```

Flag:

```lua
enable_admin_balance_tests = true
```

Para desativar:

```lua
enable_admin_balance_tests = false
```

## Permissao

Os comandos ficam em:

```text
Server/data/scripts/talkactions/god/remastered_balance_tests.lua
```

Eles usam `groupType("god")` e a API tambem valida `player:getGroup():getAccess()`. Personagens comuns nao devem conseguir executar.

## Comandos

### /testbalance

Mostra:

- status da feature flag de testes;
- status da feature flag de balanceamento;
- status dos modulos;
- XP Rate, Skill Rate e Loot Rate atuais;
- arquivos de configuracao usados.

### /testxp

Uso:

```text
/testxp dragon
/testxp 700
```

Mostra XP base, multiplicador aplicado, XP final, origem do valor base e arquivo de configuracao.

### /testskill

Uso:

```text
/testskill sword 100
/testskill 100
```

Mostra skill testada, tries base, multiplicador e tries finais. O comando nao chama `addSkillTries`.

### /testloot

Uso:

```text
/testloot dragon 100
```

Simula loot com `MonsterType:generateLootRoll` em memoria, sem criar itens nem adicionar loot a corpse. Mostra fator base, fator final e resumo dos itens mais frequentes.

## Logs

Os comandos tentam gravar em:

```text
Logs/BalanceTests/balance-tests.log
```

Fallbacks seguros:

```text
Logs/remastered-balance-tests.log
```

## Painel no Launcher

O Launcher possui uma area `Admin / Testes`, documentada em:

```text
Docs/ADMIN_PANEL.md
```

Ela aciona a mesma API `Remastered.AdminBalanceTests` por uma ponte local em `Logs/BalanceTests/`, sem depender de chat.

## Garantias

- nao adiciona experiencia;
- nao adiciona skill tries;
- nao cria itens reais;
- nao altera banco de dados;
- pode ser desligado por feature flag;
- se o modulo nao carregar, o servidor continua funcionando.
