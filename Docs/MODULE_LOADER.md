# Module Loader

## Objetivo

O Module Loader e o carregador oficial de modulos do Remastered Core. Ele localiza, valida, carrega, inicializa e registra modulos exclusivos do Tibia Remastered sem alterar sistemas originais do OTServer.

## Localizacao

```text
Modules/Remastered/Core/ModuleLoader/init.lua
```

## Fluxo

1. `Remastered.Core.initialize()` carrega configuracoes e feature flags.
2. O Core registra modulos internos.
3. `Remastered.ModuleLoader.loadAll()` le `modules.available`.
4. Para cada modulo configurado:
   - le `module.json`;
   - valida campos obrigatorios;
   - verifica `enabled`;
   - verifica feature flag;
   - verifica dependencias;
   - executa `main.lua` com `pcall`;
   - chama `initialize(self, Remastered)` se existir;
   - registra status e logs.

## Configuracao de descoberta

Arquivo:

```text
Modules/Remastered/Config/default.lua
```

Campo:

```lua
modules = {
	available = {
		"Features/ExampleModule",
	}
}
```

## Status possiveis

| Status | Significado |
| --- | --- |
| `loaded` | modulo carregado e inicializado |
| `skipped` | modulo ignorado por flag, disabled ou dependencia ausente |
| `failed` | erro ao carregar ou inicializar |

## Logs

Arquivo:

```text
Logs/remastered-core.log
```

Eventos registrados:

- modulo encontrado;
- modulo ignorado;
- feature flag desativada;
- dependencia ausente;
- erro de carregamento;
- modulo carregado;
- tempo total do loader.

## Protecao do modo offline

O loader usa `pcall` para carregar e inicializar modulos. Falhas de modulo sao registradas como `failed`, mas nao devem derrubar o servidor quando o erro acontece dentro do fluxo do loader.
