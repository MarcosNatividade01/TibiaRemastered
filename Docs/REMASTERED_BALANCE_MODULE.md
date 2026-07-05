# Remastered Balance Module

## Objetivo

Primeiro modulo Remastered real. Ele aplica apenas:

- Experience Rate: 10x
- Skill Rate: 3x
- Loot Rate: 2x

Nenhum outro sistema e alterado nesta fase.

## Feature flag

Arquivo:

```text
Modules/Remastered/Config/features.lua
```

Flag:

```lua
enable_remastered_balance = true
```

Rollback:

```lua
enable_remastered_balance = false
```

Com a flag desligada, as funcoes de balanceamento retornam os valores originais recebidos dos callbacks.

## Configuracao

Arquivo:

```text
Modules/Remastered/Config/default.lua
```

Valores:

```lua
balance = {
	experienceRate = 10.0,
	skillRate = 3.0,
	lootRate = 2.0,
}
```

## Pontos de aplicacao

XP:

```text
Server/data/scripts/eventcallbacks/player/on_gain_experience_solo_balance.lua
```

Aplicado no valor final calculado pelo callback.

Skill:

```text
Server/data/scripts/eventcallbacks/player/on_gain_skill_tries_solo_balance.lua
```

Aplicado no valor final de tries.

Loot:

```text
Server/data/scripts/eventcallbacks/monster/ondroploot__base.lua
```

Aplicado no fator do loot base antes de `generateLootRoll`.

## Sistemas nao alterados

- spells;
- runas;
- cooldowns;
- prey;
- store XP boost;
- forge;
- bestiario;
- imbuements;
- vocacoes;
- monstros individuais;
- quests;
- banco de dados;
- combate.

## Como testar

Com ferramentas admin:

```text
/testbalance
/testxp dragon
/testskill sword 100
/testloot dragon 100
```

Esses comandos ficam documentados em `Docs/ADMIN_TEST_TOOLS.md` e nao alteram progresso real.

Com flag ligada:

1. iniciar o servidor;
2. confirmar no log `RemasteredBalanceModule initialized`;
3. matar monstro de XP conhecida e comparar XP final com 10x adicional;
4. treinar skill e comparar tries com 3x adicional;
5. matar monstros com loot conhecido e observar aumento efetivo por fator 2x;
6. reiniciar e confirmar que os valores permanecem.

Com flag desligada:

1. alterar `enable_remastered_balance = false`;
2. reiniciar o servidor;
3. confirmar que `RemasteredBalanceModule` e ignorado por feature flag;
4. repetir XP, skill e loot;
5. confirmar comportamento original.
