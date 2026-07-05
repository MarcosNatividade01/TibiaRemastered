# Feature Flags

## Arquivo principal

```text
Modules/Remastered/Config/features.lua
```

Flags iniciais:

| Flag | Padrao | Finalidade futura |
| --- | --- | --- |
| `remasteredBalance` | `false` | Balanceamento exclusivo |
| `enable_remastered_balance` | `true` | Ativa Remastered Balance Module |
| `enable_admin_balance_tests` | `true` | Ativa comandos God de validacao numerica do balanceamento |
| `remasteredEvents` | `false` | Eventos exclusivos |
| `talentSystem` | `false` | Sistema de talentos |
| `challengeSystem` | `false` | Sistema de desafios |
| `newBosses` | `false` | Bosses exclusivos |
| `interfaceImprovements` | `false` | Melhorias de interface |
| `networkExtensions` | `false` | Extensoes de rede |
| `debugCommands` | `false` | Comandos de debug |
| `exampleModule` | `true` | Modulo de exemplo sem gameplay |
| `disabledExampleModule` | `false` | Teste de skip por feature flag |
| `invalidExampleModule` | `false` | Teste controlado de erro de carregamento |
| `missingDependencyExampleModule` | `true` | Teste de dependencia ausente |

## API

```lua
Remastered.Features.isEnabled("talentSystem")
Remastered.Features.get("newBosses", false)
Remastered.Features.set("debugCommands", true)
Remastered.Features.all()
```

Atalho de gameplay:

```lua
Remastered.Gameplay.isFeatureEnabled("challengeSystem")
```

## Regras

- Toda funcionalidade nova deve possuir feature flag.
- Flags devem iniciar como `false`, exceto infraestrutura sem efeito de gameplay.
- Ativar uma flag nao deve exigir edicao de codigo.
- Modulos devem falhar de forma segura se uma flag estiver ausente.
- O Module Loader ignora modulos cuja feature flag esteja desligada.
- `enable_remastered_balance=false` desativa completamente XP, skill e loot Remastered.
- `enable_admin_balance_tests=false` desativa os comandos `/testbalance`, `/testxp`, `/testskill` e `/testloot`.

## Estado atual

`enable_remastered_balance` esta ativa para o primeiro modulo Remastered real.
`enable_admin_balance_tests` esta ativa para permitir validacao numerica por God/admin.
As demais flags de gameplay futuro continuam desativadas.
