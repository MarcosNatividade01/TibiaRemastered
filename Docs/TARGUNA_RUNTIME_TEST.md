# Targuna Runtime Test

## Escopo

Registrar o teste de runtime de Targuna em sandbox, sem alterar `world.otbm` oficial.

## Resultado

Status: `NOT_RUN`

Motivo: `MapPatches/Targuna/map-fragment.otbm` agora existe e valida pelo parser proprio, mas ainda nao ha mapa sandbox patchado. O Map Patch Pipeline atual nao faz merge/relocacao OTBM, entao ainda nao ha `world.otbm` de teste contendo Targuna para carregar no servidor.

## Pre-condicoes Obrigatorias

Antes de executar este teste:

1. Reabrir `MapPatches/Targuna/map-fragment.otbm` no RME4.
2. Validar visualmente tiles, floors, conexoes verticais, spawns, NPC positions e teleports.
3. Implementar merge/relocacao OTBM em copia sandbox.
4. Aplicar o fragmento a uma copia do mapa atual.
5. Reabrir a copia patchada no RME4.
6. Confirmar que o `world.otbm` oficial nao foi alterado.

## Checklist de Runtime

| Teste | Status | Observacao |
| --- | --- | --- |
| Configurar runtime de teste | NOT_RUN | depende do mapa patchado |
| Iniciar servidor com copia patchada | NOT_RUN | depende do mapa patchado |
| Validar logs de boot | NOT_RUN | depende do servidor |
| Teleportar personagem para Targuna | NOT_RUN | depende do servidor |
| Caminhar pela area | NOT_RUN | depende do servidor |
| Trocar floors | NOT_RUN | depende do servidor |
| Testar teleports | NOT_RUN | depende do servidor |
| Verificar NPCs | NOT_RUN | depende do servidor |
| Verificar spawns | NOT_RUN | depende do servidor |
| Matar monstros | NOT_RUN | depende do servidor |
| Validar XP | NOT_RUN | depende do servidor |
| Validar loot | NOT_RUN | depende do servidor |
| Validar corpses | NOT_RUN | depende do servidor |
| Testar Herald of Fire | NOT_RUN | depende do servidor |
| Logout/relogin | NOT_RUN | depende do servidor |
| Persistencia | NOT_RUN | depende do servidor |

## Resultado Esperado para READY_FOR_PROMOTION

Targuna so pode sair de `PARTIALLY_READY` quando:

- o fragmento existir;
- o fragmento reabrir no RME4;
- a copia patchada do mapa reabrir;
- o servidor de teste carregar a copia patchada;
- um personagem de teste entrar na area;
- NPCs e spawns essenciais funcionarem;
- nenhum erro critico de Lua/XML/mapa aparecer.

## Conclusao

Nenhum teste de runtime foi executado nesta etapa. O bloqueio nao e gameplay nem item definition; e a etapa faltante de merge/relocacao OTBM para produzir um mapa sandbox carregavel.

## Validacoes Executadas Antes do Runtime - 2026-07-15

| Validacao | Resultado |
| --- | --- |
| JSON `patch.json` | PASS |
| JSON reports do extractor | PASS |
| XML `monsters.xml` | PASS |
| XML `npcs.xml` | PASS |
| XML `teleports.xml` | PASS |
| Fragmento OTBM pelo parser proprio | PASS |
| Map Patch `Validate` | PASS |
| Map Patch `ApplySandbox/Rollback/Reapply` | PASS |

Proximo requisito para teste jogavel:

Implementar merge/relocacao OTBM em copia sandbox e gerar um `world.otbm` patchado de teste.

## Atualizacao - Merge Sandbox 2026-07-15

Merge/relocacao OTBM foi implementado e um mapa sandbox foi gerado:

- `UpstreamTesting/TargunaMerge/world/world.otbm`

Tambem foram gerados XMLs externos sandbox:

- `UpstreamTesting/TargunaMerge/world/world-monster.xml`
- `UpstreamTesting/TargunaMerge/world/world-npc.xml`
- `UpstreamTesting/TargunaMerge/world/world-house.xml`
- `UpstreamTesting/TargunaMerge/world/world-zones.xml`

Status dos testes de runtime:

| Teste | Status | Observacao |
| --- | --- | --- |
| Mapa sandbox gerado | PASS | parser proprio reabriu |
| XMLs externos gerados | PASS | XML valido |
| RME4 visual | NOT_EXECUTED | requer acao GUI/manual |
| Round-trip RME4 | NOT_EXECUTED | depende do RME4 visual |
| Servidor de teste | BLOCKED | falta runtime isolado/config parametrizada para usar `UpstreamTesting/TargunaMerge/world` |
| Personagem entrar em Targuna | NOT_EXECUTED | depende do servidor |

Proximo requisito para teste jogavel:

Criar runtime de teste isolado, com config/datapack apontando para `UpstreamTesting/TargunaMerge/world`, sem trocar arquivos em `Server/data-global/world`.

## Atualizacao - Runtime Isolado 2026-07-15

Runtime criado em:

- `UpstreamTesting/TargunaRuntime/Server`

Arquivos de mapa usados pela copia isolada:

- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world.otbm`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-monster.xml`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-npc.xml`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-house.xml`
- `UpstreamTesting/TargunaRuntime/Server/data-global/world/world-zones.xml`

Configuracao isolada:

- `serverName = "TargunaSandbox"`
- `loginProtocolPort = 7271`
- `gameProtocolPort = 7272`
- `statusProtocolPort = 7271`
- `mysqlDatabase = "otserv_targuna_test"`

Banco de teste:

- `otserv_targuna_test`
- origem: `Database_Template/otserv.sql`
- contas importadas: `2`
- personagens importados: `7`

Validacoes automatizadas:

| Teste | Status | Observacao |
| --- | --- | --- |
| XML `world-monster.xml` | PASS | XML valido |
| XML `world-npc.xml` | PASS | XML valido |
| XML `world-house.xml` | PASS | XML valido |
| XML `world-zones.xml` | PASS | XML valido |
| Parser OTBM no mapa do runtime | PASS | 23.035 tiles Targuna encontrados nos bounds sandbox |
| SHA256 mapa runtime vs sandbox merge | PASS | hashes identicos |
| Boot inicial sem banco | BLOCKED | banco `otserv_targuna_test` ainda nao existia |
| Boot com banco template | PASS_WITH_ERRORS | servidor chegou a `TargunaSandbox server online` |
| Monstros/NPCs Targuna antes de aplicar scripts | FAIL | definicoes nao estavam no datapack isolado |
| Monstros/NPCs Targuna apos aplicar scripts | PASS | erros `Can not find` de Targuna removidos |
| Storage/Quest U15_24 antes de aplicar lib upstream | FAIL | `Storage.Quest.U15_24` ausente |
| Storage/Quest U15_24 apos aplicar lib upstream | PASS | erros U15_24 removidos |
| Spell `heraldoffirefields` | PASS | erro removido apos copiar spell upstream |
| Event callbacks de tarefas secundarias | FAIL | `eventcallbacks_secondary_tasks.lua` usa callbacks nao suportados pela engine atual |
| RME4 visual | NOT_EXECUTED | requer validacao GUI/manual |
| Round-trip RME4 | NOT_EXECUTED | depende da validacao GUI/manual |
| Entrada de personagem em Targuna | NOT_EXECUTED | depende de cliente/login in-game |
| NPC dialog in-game | NOT_EXECUTED | depende de cliente/login in-game |
| Spawns/loot/XP in-game | NOT_EXECUTED | depende de cliente/login in-game |
| Teleports in-game | NOT_EXECUTED | depende de cliente/login in-game |

Logs principais:

- `UpstreamTesting/TargunaRuntime/Logs/server-boot.stdout.log`
- `UpstreamTesting/TargunaRuntime/Logs/server-boot-2.stdout.log`
- `UpstreamTesting/TargunaRuntime/Logs/server-boot-3.stdout.log`
- `UpstreamTesting/TargunaRuntime/Logs/server-boot-4.stdout.log`

Resultado do boot mais recente:

- servidor iniciado: PASS
- mapa carregado o suficiente para ficar online: PASS
- `TargunaSandbox server online`: PASS
- erros fatais: nenhum observado
- processo encerrado manualmente apos janela de teste: esperado

Pendencia tecnica:

`MapPatches/Targuna/scripts/quests/eventcallbacks_secondary_tasks.lua` precisa de adaptacao para a engine atual ou deve ser removido/desativado no pacote de promocao. Ele nao bloqueia o servidor de ficar online, mas impede classificar todos os scripts Targuna como validados.

Status:

`PARTIALLY_READY`

## Atualizacao - Secondary Tasks 2026-07-16

`eventcallbacks_secondary_tasks.lua` foi corrigido somente no runtime sandbox.

Resultado:

| Teste | Status | Observacao |
| --- | --- | --- |
| Analise do erro original | PASS | callbacks sem `:type(...)` geravam `Invalid EventCallback with name: {}` |
| `playerOnStorageUpdate` | PASS | suportado pela engine atual, mantido |
| `playerOnStowItem` | BLOCKED | hook nao existe na engine atual |
| `playerOnStashWithdraw` | BLOCKED | hook nao existe na engine atual |
| Tarefas stash/take from stash | DISABLED | desativadas explicitamente no sandbox |
| Boot apos ajuste | PASS | servidor chegou a `TargunaSandbox server online` |
| Erro de callback apos ajuste | PASS | removido |
| Novo erro critico de Targuna | PASS | nenhum observado |

Log:

- `UpstreamTesting/TargunaRuntime/Logs/server-boot-6-secondary-tasks-adapted.stdout.log`

Detalhes:

- `Docs/TARGUNA_SECONDARY_TASKS_COMPATIBILITY.md`

## Checklist Manual RME4

A validacao visual ainda nao foi executada porque a automacao de Windows nao esta disponivel nesta sessao.

Arquivo para abrir:

- `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`

Validar visualmente:

1. abrir o arquivo no RME4;
2. confirmar que o mapa abre sem erro;
3. ir para `x=49985, y=49995, z=6`;
4. verificar o hub Targuna em `x=49985..50055, y=49995..50055, z=6..8`;
5. ir para `x=51545, y=50800, z=7`;
6. verificar Aragonia pirates em `x=51545..51630, y=50800..50880, z=7..8`;
7. ir para `x=50460, y=50790, z=12`;
8. verificar Crimson Court staging em `x=50460..50500, y=50790..50820, z=12`;
9. conferir floors z6, z7, z8 e z12;
10. conferir bordas, escadas, buracos, teleports e houses;
11. procurar areas vazias inesperadas ou corrupcao visual;
12. se tudo estiver correto, usar Save As para `UpstreamTesting/TargunaMerge/world-targuna-rme4-roundtrip.otbm`;
13. fechar o RME4;
14. reabrir `world-targuna-rme4-roundtrip.otbm`;
15. repetir os checks das tres regioes.

## Atualizacao - Testes Pendentes 2026-07-16

Tentativas automatizadas adicionais foram executadas sem alterar producao.

| Teste | Status | Observacao |
| --- | --- | --- |
| Automacao RME4 via Computer Use | BLOCKED | pipe nativo indisponivel nesta sessao |
| Automacao RME4 via PowerShell/UIAutomation | BLOCKED | RME4 nao chegou a estado de Save As automatizavel de forma confiavel |
| Config local de assets do RME4 | PASS | `ASSETS_DATA_DIRS` corrigido para o Client 15.24 local |
| Save As RME4 | BLOCKED | `world-targuna-rme4-roundtrip.otbm` nao foi criado |
| Round-trip RME4 | NOT_EXECUTED | depende do Save As |
| Validacao headless de NPCs | PASS | 9 posicoes, 8 NPCs esperados, scripts encontrados |
| Validacao headless de spawns | PASS | 88 spawns nos bounds sandbox |
| Validacao headless de scripts | PASS | 15 scripts de quest encontrados; sem erro Targuna no boot ajustado |
| Boot curto do runtime isolado | PASS | processo permaneceu ativo apos 20s |
| Porta login `7271` | PASS | TCP local aceitou conexao |
| Porta game `7272` | PASS | TCP local aceitou conexao |
| Login/headless protocolar | BLOCKED | nao ha cliente/headless protocol client confiavel existente |
| Entrada real de personagem | BLOCKED | depende de client GUI ou automacao de protocolo |

O status permanece `PARTIALLY_READY`.
