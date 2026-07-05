# Configuration

## Arquivo principal

```text
Modules/Remastered/Config/default.lua
```

Esse arquivo retorna uma tabela Lua com configuracoes centralizadas.

Categorias iniciais:

- `balance`
- `gameplay`
- `interface`
- `network`
- `systems`
- `development`
- `debug`

## Acesso

Use caminhos pontuados:

```lua
Remastered.Config.get("balance.experienceRate", 1.0)
Remastered.Config.get("development.strictModules", true)
```

Verificar existencia:

```lua
Remastered.Config.has("balance.lootRate")
```

Extender configuracao em runtime:

```lua
Remastered.Config.extend({
	systems = {
		exampleSystem = true,
	},
})
```

## Regras

- Evitar constantes espalhadas.
- Nao ler configuracoes diretamente de modulos que nao sejam `Remastered.Config`.
- Nao aplicar balanceamento automaticamente nesta fase.
- Valores padrao devem preservar o comportamento original do servidor.

## Estado atual

Os valores de balanceamento existem apenas como infraestrutura de leitura. Nenhum deles e aplicado ao servidor nesta fase.
