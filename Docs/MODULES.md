# Modules

## Estrutura

```text
Modules/
  Remastered/
    Core/
    Balance/
    Gameplay/
    Features/
    Network/
    Utilities/
    Config/
    Documentation/
```

## Responsabilidades

| Modulo | Responsabilidade |
| --- | --- |
| `Core` | Inicializacao, registro de modulos e API central |
| `Config` | Arquivos declarativos de configuracao |
| `Features` | Estado das feature flags |
| `Balance` | API futura para leitura de parametros de balanceamento |
| `Gameplay` | API futura para consulta de funcionalidades ativas |
| `Network` | Reservado para extensoes de protocolo/endpoint futuras |
| `Utilities` | Logging e utilitarios compartilhados |
| `Documentation` | Documentacao local da camada modular |

## Registro de modulos

Todo modulo deve ser registrado por:

```lua
Remastered.Core.registerModule("ModuleName", ModuleTable)
```

Modulos registrados podem ser obtidos por:

```lua
Remastered.Core.getModule("ModuleName")
```

## Como adicionar um novo modulo

1. Criar uma pasta em `Modules/Remastered/<Area>/<Nome>/` ou um arquivo de API dentro da area correta.
2. Retornar uma tabela Lua.
3. Adicionar configuracoes em `Modules/Remastered/Config/`.
4. Adicionar uma feature flag em `Modules/Remastered/Config/features.lua`.
5. Registrar o modulo no fluxo de inicializacao do Core ou em um loader dedicado.
6. Documentar o modulo antes de ativar gameplay.

## Regras de compatibilidade

- Nao alterar arquivos originais se uma extensao resolver.
- Nao duplicar sistemas originais.
- Nao adicionar dependencias externas sem necessidade clara.
- Nao ativar comportamento novo por padrao.
