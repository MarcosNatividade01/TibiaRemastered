# Auditoria e correcao de balanceamento

Data: 2026-06-28

## Sistemas analisados

- Sistema de Prey: ativacao, persistencia, carregamento, calculo de XP, loot, dano e defesa.
- Experiencia do servidor: config.lua, stages.lua, Player:onGainExperience e Player.getFinalBaseRateExperience.
- Velocidade de ataque: config.lua, vocations.xml e Vocation::getAttackSpeed.
- Ganho de skills: stages.lua e Player:onGainSkillTries.

## Problemas encontrados

### Prey

- Os efeitos dependem de slot ocupado: `selectedRaceId != 0` e `bonusTimeLeft > 0`.
- O banco atual nao tinha nenhum Prey ativo para os personagens testados: slots em selecao/travados, `raceid = 0`, `bonus_time = 0`.
- O consumo/expiracao do tempo de Prey via `player:removePreyStamina()` nao salvava imediatamente o player. Em servidor local com reinicios frequentes isso pode fazer o cliente parecer sincronizado em um momento, mas o banco ficar desatualizado.
- Dano, defesa, XP e loot de Prey ja estavam conectados ao combate/drop. A correcao feita foi de persistencia do consumo/expiracao, sem duplicar o calculo.

### Experiencia

- `rateUseStages = true`, entao a taxa real vinha de `data/stages.lua`.
- Antes os stages eram 7x/6x/5x/4x/2x por faixa de level.
- `lowLevelBonusExp = 50` adicionava bonus extra ate level 50, impedindo uma taxa base limpa de 4x.

### Attack Speed

- Ja estava correto: `rateAttackSpeed = 2.0`.
- As vocacoes continuam com `attackspeed = 2000`, e o C++ divide pelo rate, resultando em 1000 ms efetivos.

### Skills

- `rateUseStages = true`, entao a taxa real vinha de `skillsStages`.
- Antes os stages eram 75x/50x/30x/20x/10x.
- Foi ajustado para 2.5x fixo nos skills fisicos/fishing.

## Arquivos modificados

- `C:\otserv\config.lua`
- `C:\otserv\data\stages.lua`
- `C:\otserv\data\events\scripts\player.lua`

## Valores antes e depois

| Sistema | Antes | Depois |
|---|---:|---:|
| XP stages | 7/6/5/4/2 | 5 fixo |
| Low level bonus XP | 50% | 0% |
| rateExp fallback | 1 | 5 |
| Skill stages | 75/50/30/20/10 | 2.5 fixo |
| Attack speed rate | 2.0 | 2.0, sem alteracao |
| Vocations attackspeed | 2000 ms | 2000 ms base, 1000 ms efetivo pelo rate 2.0 |
| Prey stamina save | sem save imediato | salva player apos consumir/expirar Prey stamina |

## Como testar

### Prey

1. Entrar no jogo e abrir a janela de Prey.
2. Selecionar uma criatura em um slot.
3. Conferir no banco se o slot ficou ativo:
   `SELECT player_id,slot,state,raceid,bonus_type,bonus_percentage,bonus_time FROM player_prey WHERE player_id=ID;`
4. Esperado para ativo: `state = 2`, `raceid > 0`, `bonus_time > 0`.
5. Para bonus XP, matar exatamente a criatura selecionada e comparar o XP recebido.
6. Para bonus damage, atacar a criatura selecionada e comparar dano medio.
7. Para bonus defense, receber dano da criatura selecionada e comparar reducao.
8. Para bonus loot, matar a criatura selecionada e verificar loot extra/mensagem `active prey bonus`.
9. Relogar ou reiniciar servidor e confirmar que `bonus_time` e `raceid` continuam salvos.

### Experiencia 5x

1. Matar um monstro conhecido sem Prey/Store/VIP/boosted creature.
2. Comparar XP base do monstro com XP recebido.
3. Esperado: XP base * 5. Se o personagem estiver com XP Boost da Store ativo, o resultado esperado vira XP base * 5 * 1.5.

### Attack Speed 2x

1. Usar melee/distance/wand/rod.
2. Comparar intervalo entre ataques.
3. Esperado: vocacao base 2000 ms vira 1000 ms efetivo.

### Skills 2.5x

1. Treinar sword/axe/club/distance/shielding/fishing.
2. Comparar ganho de tries com servidor padrao.
3. Esperado: tries * 2.5.

## Verificacao final

- Servidor reiniciado.
- Processo ativo: `crystalserver.exe`.
- Portas abertas: `7171` e `7172`.

## Backups criados

- `C:\otserv\data\stages.lua.bak-balance-audit-*`
- `C:\otserv\data\events\scripts\player.lua.bak-balance-audit-*`
- `C:\otserv\config.lua.bak-balance-audit-*`

## Observacoes

- Nao alterei C++ porque nao ha ferramenta de build local disponivel nesta maquina (`msbuild`, `cmake`, `ninja` e `devenv` nao foram encontrados).
- A auditoria C++ mostrou que os calculos de Prey damage/defense e as funcoes Lua de Prey XP/loot ja usam o `raceId` da Bestiary/Prey.
- Se um Prey aparecer ativo no cliente mas o banco nao tiver `state=2`, `raceid>0` e `bonus_time>0`, o problema restante esta na ativacao/comunicacao do slot, nao no calculo de combate.