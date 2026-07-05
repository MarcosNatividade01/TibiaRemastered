# Remastered Core

## Objetivo

O Remastered Core e a camada proprietaria do Tibia Remastered. Ele concentra a inicializacao, configuracao, registro de modulos, feature flags e APIs internas usadas por futuras funcionalidades exclusivas do projeto.

Esta fase nao altera gameplay. Nenhum rate, spell, monster, NPC, quest, item, cooldown, banco ou combate foi modificado.

## Arquitetura escolhida

Camada principal:

```text
Modules/Remastered/
  Core/
  Balance/
  Gameplay/
  Features/
  Network/
  Utilities/
  Config/
  Documentation/
```

Ponte minima no servidor:

```text
Server/data/remastered_bootstrap.lua
Server/data/global.lua
```

`Server/data/global.lua` carrega apenas `Server/data/remastered_bootstrap.lua`. A ponte localiza `Modules/Remastered/bootstrap.lua` e entrega a inicializacao ao Remastered Core.

## Fluxo de inicializacao

1. O servidor carrega `Server/data/global.lua`.
2. `global.lua` carrega bibliotecas originais e startup original.
3. `global.lua` chama `Server/data/remastered_bootstrap.lua`.
4. A ponte procura `Modules/Remastered/bootstrap.lua`.
5. `bootstrap.lua` define `REMASTERED_ROOT`.
6. `Core/init.lua` carrega Config, Features, Registry, Utilities, Balance e Gameplay.
7. `Remastered.Core.initialize()` registra os modulos internos.
8. `Remastered.ModuleLoader.loadAll()` localiza e carrega modulos declarados em `modules.available`.

## API global

O Core disponibiliza a tabela global:

```lua
Remastered
```

APIs iniciais:

```lua
Remastered.Core.getVersion()
Remastered.Core.isInitialized()
Remastered.Core.registerModule(name, module)
Remastered.Core.getModule(name)
Remastered.Core.getModules()

Remastered.Config.get(key, defaultValue)
Remastered.Config.has(key)
Remastered.Config.extend(values)

Remastered.Features.isEnabled(name)
Remastered.Features.get(name, defaultValue)
Remastered.Features.set(name, enabled)
Remastered.Features.all()

Remastered.Balance.getExperienceRate()
Remastered.Balance.getSkillRate()
Remastered.Balance.getLootRate()
Remastered.Balance.getMagicRate()
Remastered.Balance.getSpawnRate()

Remastered.Gameplay.isFeatureEnabled(name)
Remastered.Gameplay.getFeature(name, defaultValue)

Remastered.Utilities.log(message, level)
Remastered.Utilities.warn(message)
Remastered.Utilities.error(message)

Remastered.ModuleLoader.loadAll()
Remastered.ModuleLoader.discover()
Remastered.ModuleLoader.getStatus(id)
Remastered.ModuleLoader.getStatuses()
Remastered.ModuleLoader.getLoadedModules()
```

## Regras

- Futuras funcionalidades devem ser criadas em `Modules/Remastered`.
- Arquivos originais do OTServer so devem receber pontes pequenas e justificadas.
- Toda funcionalidade nova deve passar por feature flag.
- Toda configuracao nova deve entrar em `Modules/Remastered/Config/default.lua` ou arquivo dedicado dentro de `Config/`.
- Nenhum modulo deve alterar gameplay ao ser carregado sem feature flag explicita.
- Todo modulo futuro deve seguir `Docs/MODULE_STANDARD.md`.

## Observacao de runtime

`Client/conf/clientoptions.json` e tratado como configuracao local do jogador. Ele nao deve entrar no manifest de update, porque o cliente pode altera-lo ao abrir.
