# Module Standard

## Estrutura oficial

```text
Modules/Remastered/<Category>/<ModuleName>/
  module.json
  main.lua
  config.lua
  README.md
  tests/
```

`config.lua` e `tests/` sao opcionais enquanto o modulo for simples.

## `module.json`

Padrao atual:

```json
{
  "id": "ExampleModule",
  "name": "Example Module",
  "version": "0.1.0",
  "author": "Tibia Remastered",
  "description": "Infrastructure module for loader validation",
  "category": "features",
  "enabled": true,
  "featureFlag": "exampleModule",
  "dependencies": [],
  "main": "main.lua",
  "loadOrder": 10
}
```

## Campos

| Campo | Obrigatorio | Descricao |
| --- | --- | --- |
| `id` | Sim | identificador unico usado pelo Registry |
| `name` | Sim | nome humano |
| `version` | Sim | versao do modulo |
| `author` | Sim | autor ou grupo |
| `description` | Sim | descricao curta |
| `category` | Sim | area do modulo |
| `enabled` | Sim | habilita ou desabilita o modulo |
| `featureFlag` | Nao | flag exigida para carregar |
| `dependencies` | Sim | lista de ids exigidos |
| `main` | Sim | arquivo Lua principal |
| `loadOrder` | Sim | ordem numerica de carregamento |

## `main.lua`

Padrao:

```lua
local Module = {
	id = "ExampleModule",
	version = "0.1.0",
}

function Module.initialize(self, remastered)
	remastered.Utilities.log(self.id .. " initialized")
	return true
end

function Module.shutdown(self, remastered)
	return true
end

return Module
```

## Regras

- `main.lua` deve retornar uma tabela.
- `initialize` deve ser idempotente sempre que possivel.
- Modulos nao devem alterar gameplay se a feature flag estiver desligada.
- Dependencias devem apontar para `id` de modulos registrados.
- Modulos devem ter README proprio.
- Erros devem ser claros e registrados via `Remastered.Utilities`.
