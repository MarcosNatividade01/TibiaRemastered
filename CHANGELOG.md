# Changelog

Todas as alteracoes importantes do projeto serao documentadas aqui.

## [0.1.53-test] - Correcao dos portais da sala do GOD

- Identificados no mapa dois magic portals com destino invalido `0,0,0` em `32821,31533,10` e `32823,31533,10`.
- Adicionado fallback por posicao para levar o jogador ao templo de sua cidade, usando o templo de Thais como destino de seguranca.
- Os dois portais agora funcionam tanto ao pisar quanto ao clicar, sem alterar o mapa binario.
- Adicionado teste automatizado para preservar coordenadas, destino e as duas formas de ativacao.

## [0.1.52-test] - Treino triplo com exercise weapons

- Alterado o ganho de skill e magic level das exercise weapons de 1x para 3x por carga no pacote publicado.
- Mantidos inalterados o consumo de uma carga, o intervalo entre golpes e os bonus dos dummies.
- Adicionados fallback de runtime e teste automatizado para impedir que o multiplicador desapareca em atualizacoes futuras.

## [0.1.51-test] - Correcao definitiva das viagens de Buddel

- Corrigidos os cinco pontos de Buddel para sempre responder aos destinos clicados, sem depender de storage de quest no modo de exploracao livre.
- Os dialogos de passagem agora mostram explicitamente os destinos disponiveis e a confirmacao clicavel Yes/No.
- Corrigido o fallback aleatorio que reutilizava a condicao probabilistica e podia fazer o NPC ignorar a confirmacao.
- Mantidos o custo de 50 gold, o desconto do Postman e a mecanica de Buddel eventualmente levar o jogador ao destino errado.
- Reposta uma unica Cobra Club na backpack principal de Lionel Messi, com backup integral do banco e protecao contra duplicacao; o item de personagem nao faz parte do Git.

## [0.1.50-test] - Dialogos de NPC prioritariamente clicaveis

- Adicionada uma camada central de apresentacao que transforma keywords publicas e contextuais em opcoes curtas entre chaves, preservando a digitacao manual.
- Destinos de barcos e transportes, Trade, banco, quests, tasks, blessings, promotion, imbuement e confirmacoes Yes/No passam a ser apresentados por clique quando o fluxo atual permitir.
- Mantidas storages, rewards, compras, teleports e aceite de missoes na logica original; exibir ou clicar numa opcao apenas equivale a digitar a mesma keyword.
- Corrigido o fluxo de NPCs antigos que guardam a condicao de acesso no no pai e o destino no filho Yes, sem liberar rotas gratuitas baseadas em item.
- Corrigido o markup agrupado do Cassino para opcoes independentes e seguras.
- Auditados 1.113 arquivos do datapack ativo: 1.105 NPCs interativos cobertos, 508 ja clicaveis e 597 convertidos pela camada central.
- Adicionados relatorios antes/depois e teste automatizado para barcos, carpet, shop, bank, quest, task, Yana, blessing, submenus, Yes/No e isolamento por jogador.

## [0.1.49-test] - Modo exploracao livre sem concluir quests

- Adicionada configuracao central `gameplay.freeExploration` para separar acesso fisico de progresso, quest log e rewards.
- Liberadas quest doors, key doors, special tiles, teleports de quest e rotas condicionais de NPC sem conceder chaves, itens ou storages.
- Reduzidos em 50%, com arredondamento para cima, os requisitos de level e quantidades que ainda precisem ser mantidos para acesso.
- Liberadas passagens reais de Dream Courts, Demon Oak, Pits of Inferno, Inquisition, Wrath of the Emperor, Dangerous Depths, Blood Brothers, Children of the Revolution, Explorer Society, Beregar, Shattered Isles, Liquid Black e Targuna.
- Liberados mecanismos com item em Desert Dungeon, Chayenne Realm, Dream Courts e portais de carving da Explorer Society, sem consumir o item no caminho alternativo.
- Desativado o sistema legado `FreeQuests` durante a exploracao livre para impedir conclusao automatica de quest, alteracao de quest log e entrega indireta de progresso.
- Preservadas as verificacoes de reward, chest, kill tracking, cooldowns e mecanicas internas de boss; corrigidos bypasses antigos que ainda escreviam storage ao entrar antecipadamente.
- Adicionados relatorios completos antes/depois e quatro testes automatizados de acesso, reducao de requisito, uso de item e protecao contra duplicacao.
- O gerador de manifest agora aceita `-UseGitIndex`, permitindo publicar somente o conjunto selecionado mesmo com alteracoes locais validas fora da versao.

## [0.1.48-test] - Client com SAC desativado

- Ajustada a validacao do client para tratar `HashMismatch` como bloqueio apenas quando o Smart App Control esta ativo.
- Com o Smart App Control desativado, o launcher passa a tentar abrir o client local mesmo com assinatura invalida.

## [0.1.47-test] - Diagnostico de Smart App Control

- Adicionada validacao de assinatura do client antes da abertura para detectar `HashMismatch` com Smart App Control ativo.
- O launcher e os atalhos agora explicam que o bloqueio vem do Controle de Aplicativo do Windows e indicam o caminho correto em Seguranca do Windows.

## [0.1.46-test] - Desbloqueio global de quest doors e bosses

- Adicionados `gameplay.unlockQuestAccess` e `gameplay.unlockBossAccess` como chaves globais Remastered para liberar portas, portais e entradas especiais sem depender de quest feita.
- Liberadas as portas centrais de quest, level e key door, alem de handlers especiais de Dream Courts, Annihilator, Svargrond Arena, Bigfoot/Warzones, Ferumbras, Inquisition, Demon Oak, Soul War, Rotten Blood, Order of the Lion e entradas de Galthen/Pirates.
- Flexibilizados `BossLever`, portais manuais de Feaster, Kilmaresh, Grimvale, Candia, Dangerous Depth, Soulpit, Drume e Dream Courts para ignorar level, time lock e sequencias previas quando o modo de boss global esta ativo.
- Corrigido o fluxo do Drume em Bounac para aceitar qualquer tile da fila da alavanca, liberar elevador/teleport e concluir a etapa ao matar Drume mesmo entrando pelo bypass global.
- Registrada a corda/alavanca do Drume tambem pelas posicoes da sala, evitando "Sorry, not possible" quando o mapa nao traz o action id esperado.
- Adicionado fallback no handler global da rope para iniciar o Drume diretamente quando o jogador estiver nos tiles do desafio em Bounac.
- Registrados IDs extras de rope (`7884`, `7895`, `20206`, `21375`, `31366`) para garantir que o client chame o handler mesmo usando variantes de corda.
- Corrigido o portal de saida do Drume em Bounac (`47404`, `32469,32503,7`) com MoveEvent dedicado e registro na tabela de teleports.
- Alterada a saida do Drume para a sala segura da corda (`32457,32508,6`) e adicionado fallback por clique no portal, evitando morte ao sair por tempo ou pelo portal.
- Corrigido o portal de saida do Drume para usar action id de teleporte valido (`39009`) e o handler generico agora aceita `actionid`, garantindo a saida ao pisar no portal.
- Adicionada recuperacao do Lionel Messi para reaplicar Mana Leech/Powerful Void no helmet no proximo login apos o rollback.
- Expandida a recuperacao do Lionel Messi para reaplicar na arma `7434` os imbuements Powerful Strike, Powerful Vampirism e Powerful Void apos o rollback.
- Mantido o bloqueio de sala ocupada para evitar sobrepor lutas enquanto outro jogador ainda esta dentro do boss.

## [0.1.45-test] - Acessos de quest e bosses sem espera

- Reaplicados os acessos gratuitos de quests para todos os personagens ao elevar `freeQuestStage` para 2.
- Mantido `bossCooldownDisabled` como regra global e removidos bloqueios de timers manuais em bosses de Forgotten Knowledge, Dream Courts e Prince Drazzak quando o modo Remastered esta ativo.
- Zerado no banco local o marcador antigo de free quests para forcar a reaplicacao dos acessos no proximo login.

## [0.1.44-test] - Imbuements ofensivos +35%

- Aumentados em 35% os efeitos de roubo de vida, roubo de mana e critico em `Server/data/XML/imbuements.xml`.
- Atualizadas as descricoes de Strike, Vampirism e Void para refletir os novos valores publicados.

## [0.1.43-test] - Reparo de login local

- Adicionado `Scripts/Repair-LocalLoginAccount.ps1` para recriar ou corrigir com seguranca uma conta local no banco `otserv`, gerar hash SHA1 compativel, garantir personagem ativo e testar `/login.php` sem expor sessionkey.
- Corrigida a conta local solicitada no banco em execucao, com personagem sorcerer ativo retornando na lista do client.

## [0.1.42-test] - Yana 100% clicavel

- Corrigido o fluxo clicavel da NPC Yana com estado isolado por jogador para categoria, imbuement, tier e confirmacao.
- Normalizadas keywords clicadas e aliases bilingues para evitar que o client envie texto visual e quebre o avanco do dialogo.
- Preservados Gold Token ID, precos, scrolls, efeitos, duracao, compatibilidade, slots, persistencia e a chamada real de aplicacao por scroll.

## [0.1.41-test] - Descricoes bilingues da Yana

- Adicionadas descricoes bilingues aos menus clicaveis da NPC Yana.
- Mantidas keywords curtas no dialogo NPC tradicional para reduzir risco de crash no client.
- Preservados precos, Gold Token ID, efeitos, duracao, materiais, compatibilidade e persistencia dos imbuements.

## [0.1.40-test] - Hotfix Santo Agostinho e Yana clicavel

- Restaurado seletivamente o personagem Santo Agostinho a partir do backup `YanaImbuements_20260801_103611`, sem restaurar o banco inteiro e sem alterar contas ou outros personagens.
- Convertida a NPC Yana novamente para o fluxo clicavel por categorias, imbuement, tier, slot equipado e confirmacao.
- Mantidos os novos imbuements por Gold Tokens e os bonus aumentados em 50% publicados na versao anterior.
- Atualizado o teste da Yana para validar categorias, tiers, slots e confirmacao clicaveis.

## [0.1.39-test] - Yana imbuements por Gold Tokens

- Expandida a NPC Yana para aplicar imbuements diretamente por Gold Tokens, mantendo o shop de equipamentos por tokens.
- Adicionados scrolls Basic para todos os imbuements e registrado o fluxo nativo de aplicacao por scroll para preservar compatibilidade, slots, duracao, persistencia e bloqueio de duplicidade.
- Corrigidos Strike, Vibrancy e os materiais oficiais do sistema normal de imbuements; Yana usa Gold Tokens e shrine continua usando materiais.
- Aumentados em 50% os bonus de todos os imbuements, com arredondamento para cima em valores inteiros.
- Removidas opcoes clicaveis da Yana para evitar fechamento do client ao conversar com a NPC; o fluxo agora usa texto simples.
- Adicionados testes PowerShell para Yana, valores, conversao elemental, protecoes, suporte, compatibilidade, persistencia, duracao e duplicidade.

## [0.1.38-test] - Runtime fix do servidor ativo

- Corrigido o problema em que `0.1.37-test` estava publicada, mas nao aparecia no jogo porque o processo `crystalserver.exe` real continuava iniciado antes do commit e precisava ser reiniciado.
- Corrigido `Client/ligar_servidor.ps1`, que apontava para `C:\otserv`; agora ele resolve o servidor pelo pacote atual (`../Server`) para evitar iniciar uma instalacao externa ou inexistente.
- Adicionada identificacao runtime permanente no log Remastered: versao, build, commit, core, datapack ativo e multiplicadores carregados.
- Expandido o teste administrativo runtime para mostrar spell `1.65`, runa `1.45`, cooldown de spell `0.5`, boss cooldown, Bestiary, Charms, Bounty e Hunting Shop dentro do processo do servidor.
- Confirmado em runtime que o servidor ativo usa `Server/crystalserver.exe`, datapack `data-global`, portas `7171/7172` e `Modules/Remastered/Config/default.lua`.

## [0.1.37-test] - Gameplay rebalance e update do launcher

- Centralizado o balanceamento Remastered em runtime: spells ofensivas de jogadores `1.65x`, runas ofensivas `1.45x`, cooldowns de spells `0.50x`, Bounty Tasks `5x`, Bestiary `4x`, Charms `0.50x` e Hunting Tasks Shop `0.40x`.
- Atualizado o `Gold Token Broker` ao lado da Yana para vender Gold Token `22721` por `100000` gold e Silver Token `22516` por `50000` gold, preservando compra multipla.
- Flexibilizadas alavancas de bosses para aceitar de 1 jogador ate o limite original da sala, preservando acesso, level, itens, storages e sala ocupada.
- Neutralizados cooldowns pessoais de bosses no `BossLever`, helpers centrais e lockouts especificos encontrados em scripts customizados, mantendo o bloqueio apenas enquanto a sala estiver em uso.
- Aplicada reducao central auditavel de HP e dano para bosses fracos, medios e fortes: `0.65`, `0.50` e `0.25`, com hook em `Game.createMonster` e dano em `Creature:onDrainHealth`.
- Incluidos os arquivos de minimap no pacote de update e sincronizacao de primeiro uso/atualizacao do client, preservando marcadores pessoais quando possivel.
- Auditados assets da Store contra `assets.json`; ofertas com asset visual ausente continuam registradas para validacao manual, sem importar sprites sem fonte licenciada.
- Investigado o movimento de 1 SQM por toque: o cliente operacional 15.24 usa binario pre-compilado e nao contem fonte de movimento editavel neste pacote; a pendencia foi isolada para nao bloquear a publicacao das alteracoes server-side e launcher.
- Adicionados e atualizados testes PowerShell para multiplicadores, bosses, broker, Bestiary, Charms, Bounty, Hunting Shop, minimap, Store, personagens por conta e movimento.

## [0.1.36-test] - Hotfix spells, broker e proficiency

- Removidas dependencias de Stance Protocol experimental das player spells tradicionais em producao, preservando os sandboxes `UpstreamTesting/` para evolucao futura.
- Corrigida `Death Echo` para usar efeitos compativeis com o runtime 15.24 e manter cooldown/groupCooldown, mana, alvo e cast em producao.
- Adicionado `Scripts/Test-PlayerSpellsRuntimeCast.ps1` para validar caminhos de cast, mana, cooldown, dano central e ausencia de APIs stance nas spells tradicionais.
- Movido `Gold Token Broker` para o tile imediatamente ao lado da Yana em `32201,32304,6`, mantendo Yana em `32200,32304,6`.
- Adicionado `Scripts/Test-GoldTokenBrokerYana.ps1` para validar posicao lado a lado, Gold Token ID `22721`, preco `200000` e compra multipla via trade.
- Ajustada Weapon Proficiency para requisito efetivo de 1/3 da baseline: `rateWeaponProficiency = 3`, multiplicadores centrais e catalisadores usando ganho 3x sem alterar progresso salvo, perks ou recompensas.
- Adicionado `Scripts/Test-WeaponProficiencyBalance.ps1` para validar a regra 1/3, exemplos antes/depois, catalisadores e preservacao server-side.

## [0.1.35-test] - Mega gameplay update autonomo

- Corrigidas regressões de player spells causadas por chamadas experimentais de Stance Protocol no runtime principal, preservando o trabalho de `UpstreamTesting/` sem promover client/protocolo 15.25.
- Adicionado `Scripts/Test-AllPlayerSpells.ps1` para validar registro, cobertura por vocação, palavras duplicadas e guards de stance, com `PLAYER_SPELLS_REGRESSION = PASS`.
- Centralizado o balanceamento Remastered para Bounty Hunts +40%, Bestiary com kills -50%, recompensa final 4x, Charms -50% e tiers de bosses.
- Aplicado balanceamento central de bosses em HP e dano ofensivo sem alterar loot, recompensas, storages, cooldowns, fases ou summons.
- Removida composição obrigatória por vocação das alavancas de Desert Dungeon e Elemental Spheres, mantendo requisitos de itens, acesso e limite técnico de participantes.
- Adicionado NPC `Gold Token Broker` na Adventurers' Guild, com outfit visual de Rashid e venda de Gold Token por 200.000 gold.
- Adicionado calendário persistente de Global Events por data/hora real e `Scripts/Test-GlobalEventCalendar.ps1`.
- Auditados assets do client 15.24 sem importar placeholders ou assets 15.25 incompatíveis; relatório em `Docs/MISSING_ASSETS_AUDIT.md`.
- Atualizados testes estruturais e de gameplay para cobrir bounty, bestiary, charms, bosses, NPC, assets e calendário.

## [0.1.34-test] - Posturas e spells por vocacao 15.24

- Auditadas todas as spells e posturas por vocacao contra `Upstream/CrystalLatest` 15.24, com relatorio em `Docs/TIBIA_15_24_VOCATION_SPELLS_AND_STANCES_AUDIT.md`.
- Corrigidas 9 posturas oficiais para operar como stance: Sorcerer, Druid, Knight e Paladin; Monk permanece sem stance oficial no upstream local e com `Mentor Other` custom preservada.
- Integradas 19 variantes ofensivas de Sorcerer sensiveis a postura elemental, cobrindo strikes, waves, beams, UE e dano por condicao.
- Adaptado o grupo secundario de stance para o ID numerico `11`, compatibilizando com o binario atual sem recompilacao e sem warning `Unknown secondaryGroup: stance`.
- Removido multiplicador local duplicado de spells ofensivas; o +15% de spells e +30% de runas permanecem centralizados no balanceamento Remastered.
- Adicionada suíte `Scripts/Test-VocationSpellsAndStances.ps1` para validar cobertura por vocacao, posturas, variantes de Sorcerer e ausencia de duplicidade de multiplicador.

## [0.1.33-test] - Baseline operacional maxima 15.24

- Criada baseline `Docs/TIBIA_15_24_100_PERCENT_BASELINE.md` com criterio honesto para `FULL_OPERATIONAL`, `PARTIAL_OPERATIONAL` e bloqueios de engine/protocolo/client.
- Adicionada suíte `Scripts/Test-15_24-FullOperational.ps1`, cobrindo boot real, validação pre-publish, QA mínimo, sistemas estruturais, login/lista de personagens, Offline, Multiplayer, proxy remoto, updater, balanceamento, multiplicadores e preservação de contas/personagens.
- Confirmado carregamento de itens com Weapon Proficiency no boot, schema/persistência dos sistemas 15.24 e preservação de Targuna sem alterar mapa ou banco real.
- Mantido resultado honesto como `MAXIMUM_SAFE_15_24_COMPLETENESS`: ainda falta prova automatizada de UI/packets client para declarar 100% operacional em Weapon Proficiency, Wheel of Destiny e Animus Mastery.

## [0.1.32-test] - Auditoria estrutural 15.24

- Auditados Forge, Prey, Bestiary, Bosstiary, Charms, Imbuements, Weapon Proficiency, Reward, Wheel e Animus Mastery contra o runtime atual e o upstream local 15.24.
- Confirmado banco real em `db_version=63`, com tabelas e colunas estruturais presentes para os sistemas auditados, sem executar migrations destrutivas.
- Adicionada suíte `Scripts/Test-StructuralSystems15_24.ps1` para validar flags, arquivos, XML/JSON, schema e contagens de accounts/players.
- Preservadas customizacoes Remastered: Forge sem custo de dust, imbuements com materiais reduzidos, Bestiary acelerado, proficiencies ajustadas, XP 8x, Skills 3x, Magic Level 3x, Attack Speed 1.3x, spells +15% e runas +30%.
- Mantidas como alto risco quaisquer trocas profundas de binario/protocolo/client para Wheel, Animus Mastery e Weapon Proficiency alem do suporte ja existente no runtime 15.24.

## [0.1.31-test] - Complementacao acelerada 15.24

- Adicionados conteudos ausentes de baixo e medio risco da auditoria 15.24: 11 monsters, Adrian, 5 spells de monster/quest, 16 spells de jogador, 36 item definitions e 6 equipamentos/ammo.
- Integrado spawn de Adrian no mundo principal e mantida Newhaven como implementacao custom existente, sem duplicar scripts de quest.
- Adaptadas spells novas para a API runtime atual, preservando o bonus Remastered de +15% em spells ofensivas e sem alterar runas ofensivas +30%.
- Corrigidos conflitos de item IDs `43786..43790` conforme base upstream 15.24.
- Mantidos como adiados os sistemas complexos que exigem mudancas estruturais de engine/client: Forge, Prey, Bestiary, Bosstiary, Charms, Imbuements, Weapon Proficiency, Reward, Wheel e Animus Mastery.
- Validado boot do servidor, QA minimo, preservacao de accounts/players e protecoes de update para UserData, saves, banco, logs e backups.

## [0.1.30-test] - Robustez do updater para mapa Targuna

- Adicionado `Data/large-files.json` para registrar arquivos grandes montados localmente a partir de partes publicadas.
- O Launcher agora monta arquivos grandes pendentes na checagem de versao, cobrindo instalacoes que baixaram as partes com um updater anterior.
- Mantida a promocao de Targuna publicada em `0.1.29-test`, com `0.1.30-test` como versao recomendada para garantir que o mapa chegue pela atualizacao automatica.

## [0.1.29-test] - Promocao controlada de Targuna

- Promovido Targuna/Aragonia para o runtime principal local apos validacao GUI real: login, entrada, navegacao, floors, barco/rotas, NPC essencial, spawns de piratas, combate, morte de monstros, corpos, loot/coleta e morte do personagem.
- Expandido e validado o mapa de Targuna para remover areas pretas/intransponiveis observadas no teste manual.
- Alinhados NPCs, spawns, Herald, floors e scripts de Targuna as coordenadas originais efetivas do runtime principal.
- Corrigido `Unknown house id 3701` no sandbox antes da promocao e confirmado boot de producao sem esse erro.
- Adicionado suporte de update para montar arquivos grandes por partes, publicando o mapa como partes verificadas por SHA256 e mantendo `world.otbm` direto fora do Git Raw.
- Preservados UserData, saves, banco real, Launcher, Offline, Multiplayer, Auto Update, Remastered Core, Module Loader, Feature Flags e customizacoes de balanceamento existentes.

## [0.1.28-test] - Consolidacao Targuna 15.24

- Consolidados os 18 item definitions exigidos por Targuna/Aragonia Pirates na base 15.24, sem trocar client, protocolo, banco ou core C++.
- Adicionadas feature flags de Targuna, todas desligadas por padrao.
- Mantido Targuna como patch sandbox `PARTIALLY_READY`, sem `map-fragment.otbm` real e sem promocao ao `world.otbm` oficial.
- Atualizada a documentacao de compatibilidade, validacao de assets, status do patch e pesquisa de ferramenta OTBM.
- Preservados Launcher, Offline, Multiplayer, Auto Update, UserData, saves, banco real e balanceamento Remastered.

## [0.1.27-test] - Pipeline seguro de patch de mapa

- Criado o Remastered Map Patch Pipeline para validar patches de mapa/spawns/NPCs/teleports em sandbox antes de qualquer promocao ao runtime.
- Adicionados `Tools/MapPatch/Invoke-MapPatch.ps1` e `Tools/MapPatch/Test-MapPatchPipeline.ps1`.
- Adicionado patch artificial `MapPatches/TestRoom`, desligado por `enable_map_patch_test_room = false`, para validar o fluxo sem importar Targuna.
- Criada documentacao em `Docs/MAP_PATCH_PIPELINE.md`, `Docs/MAP_PATCH_FORMAT.md`, `Docs/MAP_PATCH_ROLLBACK.md` e `Docs/MAP_PATCH_TESTING.md`.
- Validado backup, rollback, reaplicacao e falhas controladas para conflito de coordenadas, monstro inexistente, NPC inexistente e teleport invalido.
- Preservados `world.otbm`, arquivos de mundo de producao, protocolo, client, banco, core C++, Launcher, Offline, Multiplayer, UserData e saves.

## [0.1.26-test] - Update Pack 01 upstream seguro

- Adicionado `Modules/Remastered/Upstream/UpdatePack01` com conteudo upstream de baixo risco, modular e desligado por padrao.
- Criadas feature flags `enable_upstream_pack_01` e subflags de itens, monstros, NPCs, quests e mapas, todas inicialmente `false`.
- Importada apenas a acao compatível do item `36938` para Singeing Steed, sem alterar `Server/data`, banco, mapa, protocolo, client ou core C++.
- Rejeitados/adicionados ao backlog conteudos dependentes de 15.25, como storm arrows, Rotten Blood, Targuna, Newhaven, Cursor Aim, Monster AI e Weapon Proficiency.
- Corrigido o fluxo de release para ignorar `/Upstream/` e `/UpstreamTesting/` na validacao/manifest e registrar aprovacao formal por versao de teste.
- Auditados e restaurados caches locais corrompidos em `Client/storeimages` antes de regenerar o manifest.

## [0.1.25-test] - Publicacao GitHub

- Publicada versao 0.1.25-test para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.24-test] - Diagnostico de conexao direta e firewall multiplayer

- Corrigida a leitura operacional do erro `TCP=False timeout` em IP publico: o Launcher agora deixa claro que Conexao Direta externa exige porta realmente acessivel, firewall liberado, port forwarding e IPv4 publico sem CGNAT impeditivo.
- O timeout TCP de diagnostico foi aumentado de `2500ms` para `8000ms`, sem mascarar porta fechada.
- Adicionado diagnostico multiplayer do host verificando processo do servidor, portas `7171`/`7172` em LISTENING, porta web `80`, bind externo, teste em `127.0.0.1`, teste no IPv4 LAN, teste no IP publico, regras de Firewall, relay e suspeita de CGNAT.
- A hospedagem deixa de tratar portas abertas por outra copia do servidor como servidor valido desta instalacao.
- `Copiar Convite para Amigos` agora depende do diagnostico LAN aprovado e nao publica `publicHost` quando a porta externa nao foi validada.
- A tela `Diagnostico` ganhou relatorio multiplayer visual e botao administrativo `Liberar Firewall` para criar regras TCP de entrada em `7171`, `7172` e `80`.
- Documentada a separacao entre `Conexao Direta` e `Conexao por Relay`; relay reverso permanece indisponivel nesta versao ate existir infraestrutura real.
- Relatorios de `Logs/ConnectionTests/` passam a registrar IP local/publico, modo de conexao, relay indisponivel e suspeita de CGNAT no lado convidado.
- Preservados Jogar Offline, Entrar no Meu Mundo, convites remotos, proxy remoto de conta/login, auto-update, UserData, banco e saves.

## [0.1.23-test] - Autenticação remota no banco do host

- Corrigida a causa raiz do erro `Your email or password is not correct` ao selecionar personagem em outro computador.
- No modo convidado remoto, o endpoint local do client agora atua como proxy para o endpoint web do host, em vez de criar/autenticar contas no banco local do convidado.
- Criação de conta, criação de personagem, login e lista de personagens passam a vir do banco oficial do host hospedado.
- O convite remoto passa a incluir `webPort=80` para que o convidado saiba qual endpoint do host deve receber criação/login.
- Relatórios técnicos passam a mostrar o modo do endpoint de conta (`direct-db` ou `remote-proxy`) e a URL remota usada.
- Mantidos separados os fluxos Offline/Entrar no Meu Mundo (`direct-db` local) e Convidado Remoto (`remote-proxy` para o host).
- Adicionado teste automatizado de proxy remoto de conta/login, validando que o convidado encaminha chamadas ao host e recebe o game server `192.168.x.x:7172`.

## [0.1.22-test] - Correção pós-TCP do convite remoto

- Corrigido o fluxo em que `TCP=True` com erro vazio ainda era mostrado como `Falha de conexao`.
- O teste TCP remoto agora valida somente conectividade com o game server; o endpoint web/login remoto permanece diagnóstico opcional.
- O Launcher passa a validar separadamente o endpoint local usado pelo client e confirma que ele anuncia exatamente o host e a porta do convite remoto.
- Convites remotos agora incluem `loginPort=7171` e `gamePort=7172`, mantendo `port` para compatibilidade com versões anteriores.
- Relatórios em `Logs/ConnectionTests/` passam a registrar `failureStage`, `tcpSuccess`, `tcpElapsedMs`, `loginPort`, `gamePort`, host/porta efetivos do client e game server anunciado.
- A interface de diagnóstico mostra conectividade TCP, web/login remoto opcional, endpoint local e etapa real da falha, em vez de uma mensagem genérica.
- O gerador de release passa a gravar `version.json` e `manifest.json` em UTF-8 sem BOM, evitando falha de parse em validadores PowerShell 5.1.
- Preservados Offline, Host Assistido, Entrar no Meu Mundo, Copiar/Usar Convite, auto-update, `UserData`, banco e saves.

## [0.1.21-test] - Diagnostico remoto de conexao

- O erro de conexao remota agora mostra host, porta, resultado TCP, timeout, tempo decorrido, erro de socket e caminho do relatorio.
- Convites remotos que chegam como `127.0.0.1`/`localhost` informam que o convidado deve usar o convite oficial `mode=remote` com IP LAN ou `publicHost`.
- Adicionados `Tools/NetworkDiagnostics/Test-RemoteHost.ps1` e `.bat` para diagnosticar no segundo computador resolucao de host, ping informativo, TCP, rota, versao local e recomendacao.
- Relatorios de conexao passam a diferenciar timeout, conexao recusada, host local indevido, possivel firewall, NAT/CGNAT ou IP fora da LAN.
- Preservados Offline, Host Assistido, convite remoto, auto-update, `UserData`, saves e banco local.

## [0.1.20-test] - Auto-update e convite remoto imutavel

- O Launcher agora executa automaticamente `CHECKING -> UPDATE_AVAILABLE -> UPDATING -> UPDATE_SUCCESS` ao abrir, sem depender do clique em `Atualizar`.
- Botoes de jogo sao controlados pelo estado canonico; ficam bloqueados durante a aplicacao e voltam apos validacao, enquanto `OFFLINE_AVAILABLE` preserva o modo Offline quando o GitHub falha.
- Qualquer update que altere arquivos reinicia o Launcher, impedindo que uma versao nova em disco continue usando handlers antigos carregados em memoria.
- Comparacao de versoes passa a ordenar `dev < test < rc < stable` sem rebaixar uma versao estavel por causa do campo `channel`.
- Adicionados logs estruturados em `Logs/UpdateTests/` com estado, versoes, URLs, etapa e erro completo.
- Separados os fluxos `BuildHostLocalConnection`, `BuildRemoteInvite`, `ParseRemoteInvite`, `JoinOwnHostedWorld` e `JoinRemoteWorld`.
- A tela de hospedagem mostra a conexao `127.0.0.1/host-local` separada do convite para amigos `mode=remote`.
- `Copiar Convite para Amigos` valida o convite, limpa clipboard antigo em caso de falha, grava somente o convite remoto e le o clipboard de volta para confirmar.
- Removido o fallback que podia testar um IP remoto como `127.0.0.1`; teste TCP, client e logs preservam exatamente o host/porta selecionados.
- Adicionados seletores explicitos `Usar IP LAN` e `Usar IP Publico` e validacao estrita das chaves `world`, `host`, `port`, `version` e `mode`.
- Ampliados os testes automatizados para auto-update, estados, hashes, clipboard real, parser, host-local, TCP remoto simulado e protecao de dados locais.

## [0.1.19-test] - Máquina de estados do Launcher Update

- Criada máquina de estados explícita para o Launcher Update: `CHECKING`, `UPDATE_AVAILABLE`, `UP_TO_DATE`, `UPDATING`, `UPDATE_SUCCESS`, `UPDATE_ERROR` e `OFFLINE_CHECK`.
- Removida a dependência de strings soltas da interface para decidir se `Atualizar`, `Atualizar e Jogar` e `Ver Novidades` ficam habilitados.
- Corrigida a abertura do Launcher para sair obrigatoriamente de `verificacao pendente` após sucesso ou falha da consulta remota.
- O botão `Atualizar e Jogar` passa a virar `Jogar` quando o Launcher está atualizado ou quando a verificação remota falha, preservando o modo Offline.
- Adicionado botão principal `Verificar Atualizacoes` para repetir a consulta remota sem abrir configurações.
- Ajustada a área de exibição de `Versao disponivel` para evitar texto cortado/sobreposto.
- Ajustada a aparência dos botões desabilitados para manter texto legível.
- Ampliados os testes automatizados de estado para versão antiga, versões iguais, falha remota, update concluído e preservação de arquivos protegidos.

## [0.1.18-test] - Correção do Launcher Update

- Corrigida a leitura da versão local oficial a partir de `version.json` na raiz instalada.
- Corrigida a validação de `version.json` e `manifest.json` remotos com mensagens claras de etapa, URL e erro.
- Corrigida a comparação de versões com sufixos como `-test` e `-rc1`.
- Os botões `Atualizar` e `Atualizar e Jogar` deixam de ficar permanentemente desabilitados quando a verificação automática ainda não terminou ou falha.
- O update passa a salvar localmente o `version.json` remoto oficial após sincronização concluída.
- Ampliados os testes do fluxo de atualização, versão local ausente, JSON remoto inválido, manifest indisponível, hashes e preservação de `UserData`.

## [0.1.17-test] - Convite remoto e auditoria completa de dano

- Auditadas formulas reais de spells e runas para Sorcerer, Druid, Knight, Paladin, Monk e respectivas promocoes; os multiplicadores centrais 1.15/1.30 da versao anterior foram confirmados sem duplicidade.
- O botao `Copiar Convite para Amigos` usa estado isolado da hospedagem e copia somente um convite oficial reconstruido e validado.
- Gerador e parser rejeitam `localhost`, `127.0.0.1` e `::1` em convites `mode=remote`; `Entrar no Meu Mundo` permanece separado em `127.0.0.1`.
- `Testar Conexao` e `Entrar` reaplicam os campos do convite validado, sem substituir o host remoto por localhost.
- Logs de conexao registram host extraido, `publicHost` e modo extraido.
- Adicionados testes numericos por vocacao/promocao, teste de isolamento Offline e cobertura ampliada do formato/clipboard de convite.
## [0.1.16-test] - Dano centralizado de spells e runas

- Centralizados no Remastered Balance Module os multiplicadores `spellDamageMultiplier = 1.15` e `offensiveRuneDamageMultiplier = 1.30`.
- Corrigidos os valores anteriores efetivos de spells 1.50 e runas 1.35.
- Runas agora sao identificadas explicitamente por `ItemType:isRune()`, evitando aplicar bonus a outros itens sem arma.
- Mantidas curas, potions, monstros, melee, distance, wands/rods, cooldowns e regeneracao sem alteracao.
- Ajustado o intervalo base de ataque dos jogadores para 1538 ms, equivalente a aproximadamente 1,3x.
- Ampliados os testes numericos para spells e runas em diferentes vocacoes e tipos de dano.

## [0.1.15-test] - Correcao Offline e rates de teste

- Removida a consulta remota sincrona da abertura do Launcher, que bloqueava o acesso ao modo Offline quando GitHub ou autenticacao estavam indisponiveis.
- Mantidos os fluxos Hospedar Mundo, Entrar no Meu Mundo, convites e Entrar em Mundo sem alteracao de arquitetura.
- Centralizados os rates efetivos em `Server/data/stages.lua`: XP 8x, Skills 3x e Magic Level 3x.
- Neutralizada a segunda camada de XP/Skills do modulo Remastered para impedir multiplicadores duplicados.
- Configurado intervalo base de ataque das vocacoes em 1000 ms, equivalente a velocidade 2x.
- Adicionado teste automatizado dos rates efetivos, duplicacao e velocidade de ataque.
- Publicada como teste porque a validacao final Host + Convidado ainda depende de duas maquinas fisicas.

## [0.1.14] - Teste TCP do Host Assistido

- Criada `GetCurrentVersion` como funcao oficial de versao baseada em `version.json`.
- O Host Assistido passa a usar `GetCurrentVersion` no status, convite, diagnostico e validacao.
- O teste de conexao deixa de bloquear por `clientcreateaccount.php` na porta 80.
- A porta 80 passa a ser mostrada apenas como diagnostico web/login opcional.
- O bloqueio principal de `Testar Conexao` e `Entrar em Mundo` passa a ser o TCP direto no host e porta Tibia do convite.
- Adicionado teste para garantir que TCP acessivel passa mesmo com web/login indisponivel.

## [0.1.13] - Separacao definitiva entre version e mode

- Centralizado o uso de `Get-TrmLocalVersion` como fonte oficial de versao baseada em `version.json`.
- O convite oficial passa a incluir `publicHost` e mantem `version` e `mode` como campos separados.
- O diagnostico online passa a registrar `currentVersion` e `connectionMode` separadamente.
- Removido o texto de modo local do campo/mensagem de versao do diagnostico.
- A tela do Launcher passa a exibir `version=` e `mode=` separadamente nos relatorios.
- Ampliado o teste de convites para cobrir ordem livre de campos, `publicHost`, diagnostico host-local e convite malformado.

## [0.1.12] - Convite oficial do Host Assistido

- Criado formato oficial de convite com `TIBIA_REMASTERED_INVITE`, `world`, `host`, `port`, `version` e `mode`.
- O parser passa a ler campos por chave e nao por posicao ou por qualquer linha `Versao:` da tela.
- Convites remotos sempre usam `mode=remote` e versao real do projeto.
- Convites `mode=host-local` sao rejeitados em `Entrar em Mundo` com mensagem clara.
- O botao de copia agora copia somente o convite para amigos, nunca o texto completo da tela de diagnostico.
- Adicionado teste automatizado para convite remoto, host-local, legado com diagnostico e convite malformado.

## [0.1.11] - Manifest sem URLs 404

- Corrigido o gerador de manifest para incluir apenas arquivos publicaveis pelo Git.
- Arquivos ignorados por `.gitignore` ou `.gitignore` internos, como binarios locais do servidor e mapas nao rastreados, nao entram mais no manifest.
- O Publish agora valida que cada entrada do manifest e publicavel antes do commit.
- Apos o push, o Publish baixa o manifest publicado e valida todas as URLs Raw.
- O Launcher agora mostra arquivo, URL, etapa e causa provavel quando um download falha com 404 ou outro erro HTTP.

## [0.1.10] - Hash do GitHub Raw

- Corrigido o calculo de SHA256 do manifest para usar os bytes normalizados que o Git publica no GitHub Raw.
- Corrigido o tamanho registrado no manifest para refletir o conteudo publicado, nao apenas o arquivo local do Windows.
- A validacao final do Publish passa a usar a mesma regra de normalizacao antes de permitir commit e push.
- Confirmada a causa do mismatch: `CHANGELOG.md` local tinha finais de linha diferentes dos bytes servidos pelo GitHub Raw.

## [0.1.9] - Correcao de hash do manifest

- Corrigido o fluxo de publicacao para validar todos os SHA256 do `manifest.json` antes de `git add`, commit e push.
- O `version.json` passa a ser atualizado antes da varredura dos arquivos do manifest.
- As URLs de arquivos no `manifest.json` passam a incluir versao e SHA esperado para evitar cache antigo do GitHub Raw.
- O atualizador passa a resolver URL com cache buster tambem no download dos arquivos finais.
- A publicacao agora e cancelada imediatamente se qualquer arquivo final divergir do hash gravado no manifest.

## [0.1.8] - Publicacao GitHub

- Publicada versao 0.1.8 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.7] - Publicacao GitHub

- Publicada versao 0.1.7 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.7] - Diagnostico definitivo de conexao remota

- Criado log dedicado em `Logs/ConnectionTests/` para `Testar Conexao` e `Entrar em Mundo`.
- O log registra convite bruto, IP final, porta final, teste TCP direto, login server, versao, endpoint portatil, comando do client e motivo real da falha.
- Convites remotos com `127.0.0.1`, `localhost` ou `::1` agora falham com mensagem explicita.
- O preflight remoto usa TCP direto e nao troca IP de convidado por `127.0.0.1`.
- A tela de Host Assistido agora mostra motivo real da falha em vez de apenas erro generico.
- Adicionado teste automatizado para convite valido, IP invalido, porta errada, convite localhost, host local e Offline.

## [0.1.6] - Publicacao GitHub

- Publicada versao 0.1.6 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.6] - Launcher Update UX

- Adicionada area de status de atualizacao na tela inicial do Launcher, com versao instalada, versao disponivel e mensagem quando a versao local ja esta atualizada.
- Adicionados botoes `Atualizar`, `Atualizar e Jogar` e `Ver Novidades`.
- O botao `Atualizar` executa o fluxo incremental por manifest, validando SHA256, preservando arquivos protegidos e registrando acoes por arquivo nos logs.
- O botao `Atualizar e Jogar` so inicia o modo Offline quando a atualizacao termina com sucesso.
- `Ver Novidades` busca o `CHANGELOG.md` remoto e mostra a secao da versao disponivel quando encontrada.
- Adicionado teste local de update UX cobrindo versao local menor, versao local igual, arquivo protegido, hash invalido e manifest indisponivel.

## [0.1.5] - Publicacao GitHub

- Publicada versao 0.1.5 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.3-test] - Publicacao GitHub

- Publicada versao 0.1.3-test como versao de teste para validacao multiplayer em dois computadores.
- Separado o fluxo `Entrar no Meu Mundo`, que usa `127.0.0.1`, do fluxo `Entrar em Mundo`, que preserva o IP do convite para convidados.
- Adicionados logs temporarios antes de abrir o client com modo, IP usado, porta, configuracao aplicada e comando de abertura.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.

## [0.1.4] - Publicacao GitHub

- Removidos dados locais do client do indice Git (`Client/characterdata/` e `Client/minimap/`) sem apagar os arquivos da maquina do usuario.
- Reforcadas as protecoes do `.gitignore` e do publicador oficial para impedir publicacao de dados locais do client.
- Mantida a correcao do host entrando no proprio mundo publicada na versao anterior.

## [0.1.3] - Publicacao GitHub

- Corrigido o fluxo em que o host nao conseguia entrar no proprio mundo usando o convite com IP local.
- O Launcher agora reconhece enderecos da propria maquina e usa `127.0.0.1` internamente para abrir o client local do host.
- Mantido o convite com IP de LAN para outros computadores, sem alterar o modo Offline, saves, banco local ou dados do jogador.

## [0.1.2] - Publicacao GitHub

- Publicada versao 0.1.2 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.2] - Publicador GitHub

- Criado publicador em `Tools/Publish/` para preparar commit e push com duplo clique.
- Adicionadas validacoes de Git, repositorio, remote origin, `.gitignore` e arquivos proibidos.
- Adicionado modo `-DryRun` para testar o fluxo sem commit/push.
- Documentado uso, restauracao e publicacao futura em `Tools/Publish/README.md`.

## [0.1.1] - Publicacao GitHub

- Consolidada versao para publicacao no GitHub como fonte oficial de atualizacao.
- Incluidos no Launcher principal os botoes `Jogar Offline`, `Hospedar Mundo`, `Entrar em Mundo`, `Diagnostico`, `Reparar Arquivos`, `Configuracoes` e `Ajuda`.
- Confirmado fluxo de convite online com `Copiar Convite`, `Usar Convite`, IP, porta e versao.
- Mantida protecao de `UserData`, saves, logs, backups e banco local.

## [0.1.0] - Fase 11

- Padronizada a tela principal do Launcher com `Jogar Offline`, `Hospedar Mundo`, `Entrar em Mundo`, `Configuracoes` e `Ajuda`.
- Expostos `Diagnostico` e `Reparar Arquivos` como botoes principais.
- Aplicado visual proprio inspirado em fantasia medieval/RPG, sem artes oficiais de terceiros.
- Criado formato oficial de convite do Tibia Remastered.
- Adicionado suporte para colar convite completo e preencher IP/porta automaticamente.
- Expandido historico online com mundo, host, porta, versao e data de conexao.
- Adicionada secao de ajuda no Launcher e guia `Docs/LAUNCHER_GUIDE.md`.
- Movidas acoes tecnicas para `Configuracoes`, reduzindo a exposicao da estrutura interna.
- Criado checklist multiplayer em `Docs/MULTIPLAYER_TEST_GUIDE.md`.

## [0.1.0] - Fase 10

- Consolidado Host Assistido com diagnosticos de porta, IP local/publico, host acessivel e versao.
- Adicionados relatorios online em `Logs/OnlineDiagnostics/`.
- Adicionado controle de estado do endpoint web portatil para alternar com seguranca entre Offline, Hospedar Mundo e Entrar em Mundo.
- O fluxo `Entrar em Mundo` agora testa a conexao antes de abrir o client.
- Criados guias de diagnostico, teste LAN e troubleshooting online.

## [0.1.0] - Fase 9

- Criado QA minimo obrigatorio com relatorios em `Logs/QAReports/`.
- Adicionado parametro `-MinimumQA` ao Launcher e ao script de teste.
- Adicionadas opcoes principais no Launcher: `Jogar Offline`, `Hospedar Mundo` e `Entrar em Mundo`.
- Criada base do Host Assistido com IP local/publico, porta, teste de conexao, historico de host e estado online separado.
- Reservada estrutura `UserData/Offline`, `UserData/Online` e `UserData/Shared`.
- Documentadas limitacoes de LAN, NAT, CGNAT, firewall e port forwarding.

## [0.1.0] - Fase 6

- Criado Remastered Balance Module.
- Adicionada feature flag `enable_remastered_balance`.
- Configurados rates Remastered iniciais: XP 10x, skill 3x, loot 2x.
- Integrados multiplicadores nos callbacks Lua existentes de XP, skill e loot base.

## [0.1.0] - 2026-06-29

- Criada a estrutura inicial do repositorio.
- Adicionados arquivos base para README, roadmap, ideias, versao e manifest.
- Adicionado `.gitignore` para proteger dados reais e arquivos sensiveis.
