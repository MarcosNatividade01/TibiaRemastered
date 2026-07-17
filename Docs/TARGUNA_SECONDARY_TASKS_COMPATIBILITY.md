# Targuna Secondary Tasks Compatibility

## Escopo

Registrar a causa e a correcao aplicada somente no runtime sandbox para `eventcallbacks_secondary_tasks.lua`.

Producao nao foi alterada.

## Arquivo Sandbox

- `UpstreamTesting/TargunaRuntime/Server/data-global/scripts/quests/targuna/eventcallbacks_secondary_tasks.lua`

## Causa do Erro

O script upstream registrava tres callbacks:

| Callback | Funcao | Suporte no runtime 15.24 atual | Resultado |
| --- | --- | --- | --- |
| `playerOnStorageUpdate` | concluir tarefa de daily reward por mudanca de storage | Sim | mantido |
| `playerOnStowItem` | concluir tarefa "stash an item" | Nao | desativado no sandbox |
| `playerOnStashWithdraw` | concluir tarefa "take from stash" | Nao | desativado no sandbox |

O primeiro erro observado foi `Invalid EventCallback with name: {}` porque o script nao definia explicitamente o tipo do callback antes de `:register()`.

Depois de adicionar `:type(...)`, o runtime aceitou `playerOnStorageUpdate`, mas rejeitou:

- `playerOnStowItem`
- `playerOnStashWithdraw`

com:

- `No valid event name: playerOnStowItem`
- `No valid event name: playerOnStashWithdraw`

Isso confirma que esses hooks pertencem a uma engine mais nova/upstream e nao existem na engine atual do Tibia Remastered 15.24.

## Correcao Aplicada no Sandbox

Foi mantida a tarefa compatível:

- Daily reward via `playerOnStorageUpdate`

Foram desativadas explicitamente as duas tarefas incompatíveis:

- Stash an Item
- Take from Stash

O script preserva os IDs de storage das tarefas desativadas em uma tabela local chamada `TARGUNA_STASH_TASKS_DISABLED`, com o motivo documentado.

## Impacto Funcional

| Funcionalidade | Status | Impacto |
| --- | --- | --- |
| Tarefa daily reward | PASS | deve funcionar se o storage `14899` for atualizado |
| Tarefa stash item | BLOCKED | nao progride automaticamente na engine atual porque falta `playerOnStowItem` |
| Tarefa take from stash | BLOCKED | nao progride automaticamente na engine atual porque falta `playerOnStashWithdraw` |
| Boot do servidor | PASS | erro de callback removido |

## Resultado do Boot

Log:

- `UpstreamTesting/TargunaRuntime/Logs/server-boot-6-secondary-tasks-adapted.stdout.log`

Resultado:

| Teste | Status |
| --- | --- |
| `Invalid EventCallback` removido | PASS |
| `No valid event name` removido | PASS |
| servidor chegou a `TargunaSandbox server online` | PASS |
| novo erro critico de Targuna | PASS, nenhum observado |

Erros restantes nao especificos de Targuna:

- `key.pem` ausente, servidor usa chave RSA padrao.
- `Wes the Blacksmith` ausente em NpcByTime.
- world changes dinamicos apontam para mapas auxiliares ausentes na pasta `world` isolada.

## Recomendacao

Para promover Targuna no runtime 15.24, manter essas duas tarefas secundarias desativadas ou substituir por mecanismo compatível existente. Nao portar `playerOnStowItem` / `playerOnStashWithdraw` para a engine sem tratar como alteracao de core.

## Atualizacao - Validacao Final Automatizavel 2026-07-16

| Teste | Status | Observacao |
| --- | --- | --- |
| Boot apos ajuste | PASS | servidor sandbox ficou ativo e portas `7271`/`7272` responderam |
| Erro `Invalid EventCallback` | PASS | ausente no boot ajustado |
| Erro `No valid event name` | PASS | ausente no boot ajustado |
| Funcionalidade stash in-game | BLOCKED | depende de hooks ausentes na engine atual |
| Teste real de progresso da tarefa | BLOCKED | depende de personagem conectado em client/protocolo |
