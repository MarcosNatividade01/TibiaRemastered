# Auditoria XP, Skills, Loot, Prey e XP Boost - 2026-06-28

## Resumo

- Servidor reiniciado e online com `C:\otserv\crystalserver.exe`.
- Datapack ativo: `data-global`.
- Wolf ativo: `data-global/monster/mammals/wolf.lua`.
- XP base do Wolf: 18.
- RaceId do Wolf: 27.
- Boosted creature atual: Starving Wolf, raceId 723. O Wolf comum nao recebe boosted creature.

## Causas encontradas

1. O XP do Wolf retornava 54 porque havia um multiplicador antigo de 3x no carregamento dos monstros:
   - Arquivo: `data/scripts/lib/register_monster_type.lua`
   - Valor antigo: `SOLO_MONSTER_EXPERIENCE_MULTIPLIER = 3`
   - Novo valor: `SOLO_MONSTER_EXPERIENCE_MULTIPLIER = 1`
   - Efeito antigo: Wolf 18 era carregado como 54 antes do calculo final.

2. O XP base precisava ficar em um unico ponto efetivo.
   - `rateUseStages = true`, entao `data/stages.lua` controla a taxa real de XP e skills.
   - `config.lua` fica alinhado como fallback.

3. Prey e Store XP Boost eram consumidos antes de todos os bonus serem lidos/aplicados em alguns casos de borda.
   - Corrigido em `data/events/scripts/player.lua`.
   - Agora o XP Boost, stamina e Prey sao lidos/aplicados primeiro.
   - Depois os timers sao consumidos e salvos.

## Arquivos modificados

### `config.lua`

- `lowLevelBonusExp`: mantido em 0 para nao somar bonus oculto em personagem baixo.
- `rateExp`: 10.
- `rateSkill`: 3.
- `rateLoot`: 2.
- `rateUseStages`: true.
- `preySystemEnabled`: true.

### `data/stages.lua`

- `experienceStages`: stage unica com multiplicador 10.
- `skillsStages`: stage unica com multiplicador 3.
- `magicLevelStages`: preservado, sem alteracao de magic level.

### `data/scripts/lib/register_monster_type.lua`

- Removido multiplicador customizado de XP no carregamento dos monstros.
- `SOLO_MONSTER_EXPERIENCE_MULTIPLIER`: 3 -> 1.

### `data/events/scripts/player.lua`

- `Player:onGainExperience` agora aplica Prey XP antes de consumir stamina/prey time.
- Store XP Boost agora e lido antes do timer ser consumido.
- `useStamina` e `useStaminaXpBoost` salvam o jogador apos alterar timers.

## Valores finais esperados

### Wolf comum

- XP original/global: 18.
- XP base do servidor: 10x.
- Sem bonus: `18 * 10 = 180`.

### Personagem `Ancelotti`

- Premium: nao.
- Store XP Boost: 0.
- Prey ativo para Wolf: nao.
- XP esperado ao matar Wolf: 180.

### Personagem `Santoagostinho`

- Premium: sim.
- Stamina premium cheia: 1.5x.
- Store XP Boost: 50%.
- Prey XP para Wolf: 40%.
- XP esperado ao matar Wolf: `18 * 10 * 1.5 * 1.5 * 1.4 = 567`.

## Prey

### XP

- Aplicado em `data/events/scripts/player.lua`.
- Usa `player:getPreyExperiencePercentage(monsterType:raceId())`.
- Para Wolf, o raceId validado e 27.
- `Santoagostinho` tem Prey XP ativo para raceId 27 com 40%.

### Damage

- Aplicado em `src/creatures/combat/combat.cpp`.
- Quando jogador ataca monstro com raceId da Prey e bonus tipo Damage.

### Defense

- Aplicado em `src/creatures/combat/combat.cpp`.
- Quando monstro com raceId da Prey ataca o jogador e bonus tipo Defense.

### Loot

- Aplicado em `data/scripts/eventcallbacks/monster/ondroploot_prey.lua`.
- Usa `player:getPreyLootPercentage(mType:raceId())`.
- O bonus de loot adiciona uma rolagem extra conforme a chance da Prey.

## XP Boost da Store

- Compra/ativacao: `data/modules/scripts/gamestore/init.lua`.
- Persistencia: colunas `players.xpboost_stamina` e `players.xpboost_value`.
- Carregamento/salvamento: `src/io/functions/iologindata_load_player.cpp` e `src/io/functions/iologindata_save_player.cpp`.
- Aplicacao final: `data/events/scripts/player.lua`.

## Loot

- `rateLoot = 2`.
- Aplicado por `data/libs/functions/functions.lua` em `getLootRandom`.
- `MonsterType:generateLootRoll` usa esse random ajustado.
- Resultado esperado: media de loot 2x, sem duplicar configuracao em outro ponto.

## Skills

- `rateUseStages = true`.
- Skills fisicas e fishing usam `skillsStages`, multiplicador 3.
- Magic level usa `magicLevelStages` separado e nao foi alterado por este pedido.

## Testes realizados

- Servidor reiniciado apos as alteracoes.
- Processo ativo: `C:\otserv\crystalserver.exe`.
- Wolf validado no datapack ativo: XP 18, raceId 27.
- Configuracao validada:
  - `rateExp = 10`
  - `rateSkill = 3`
  - `rateLoot = 2`
  - `lowLevelBonusExp = 0`
  - `SOLO_MONSTER_EXPERIENCE_MULTIPLIER = 1`
- Banco validado:
  - `Ancelotti`: sem premium, sem Store Boost, sem Prey Wolf, esperado 180 XP.
  - `Santoagostinho`: premium, Store Boost 50%, Prey Wolf 40%, esperado 567 XP.

## Como testar no jogo

1. Entrar com `Ancelotti`.
2. Matar um Wolf comum.
3. Confirmar que a mensagem de XP mostra 180.
4. Entrar com `Santoagostinho`.
5. Confirmar que existe Store XP Boost ativo e Prey XP ativa para Wolf.
6. Matar um Wolf comum.
7. Confirmar que a mensagem de XP mostra 567.
8. Para testar apenas Store Boost, use um personagem sem Prey para Wolf e com boost 50% ativo:
   - sem premium: `18 * 10 * 1.5 = 270`.
   - com premium stamina cheia: `18 * 10 * 1.5 * 1.5 = 405`.
9. Para testar apenas Prey XP 40%, use um personagem sem Store Boost:
   - sem premium: `18 * 10 * 1.4 = 252`.
   - com premium stamina cheia: `18 * 10 * 1.5 * 1.4 = 378`.
10. Para loot 2x, matar muitos Wolves e comparar media de drops. Loot e probabilidade, entao um kill isolado nao prova a taxa.
11. Para skills 3x, atacar monstros e comparar o aumento de tries com `rateSkill = 1` em ambiente de teste.

## Observacoes

- Se usar personagem premium com stamina acima de 39h, o servidor aplica bonus de stamina 1.5x. Isso e separado do XP base 10x.
- Se o monstro for o boosted creature do dia, o XP recebe mais 2x. O boosted atual e Starving Wolf, nao Wolf.
- Alteracoes em Lua/config exigem reinicio do servidor, ja realizado.
- Nao foi necessario alterar C++ para esta correcao.

## Correcao adicional apos teste de 18 XP

Sintoma reportado: `Santoagostinho` passou a receber 18 XP ao matar Wolf.

Causa: o executavel atual estava efetivamente usando o XP cru do monstro. O multiplicador antigo no loader tinha sido removido corretamente, mas o callback XML antigo `data/events/events.xml` nao estava aplicando o calculo final no runtime observado.

Correcao aplicada:

- Criado `data/scripts/eventcallbacks/player/on_gain_experience_solo_balance.lua`.
- Criado `data/scripts/eventcallbacks/player/on_gain_skill_tries_solo_balance.lua`.
- Desativados no XML antigo para evitar duplicidade:
  - `Player:onGainExperience`
  - `Player:onGainSkillTries`

Motivo tecnico: `Player::addExperience` chama primeiro o sistema novo `EventCallback`. Esse e o caminho ativo e mais confiavel deste servidor. O XML antigo esta marcado no proprio arquivo como sistema em desuso.

Servidor reiniciado apos essa correcao. Portas confirmadas:

- Login: 7171
- Game: 7172

Resultado esperado apos esta correcao:

- `Ancelotti` matando Wolf comum: 180 XP.
- `Santoagostinho` matando Wolf comum com premium stamina, Store XP Boost 50% e Prey XP 40%: 567 XP.
