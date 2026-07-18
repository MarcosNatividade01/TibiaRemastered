# Tibia Remastered 15.24 Structural Systems Audit

Data: 2026-07-18
Base: runtime 0.1.31-test / upstream local `Upstream/CrystalLatest`

## Resultado

O pacote estrutural 15.24 foi auditado em modo acelerado. Nao foi identificada lacuna segura de Lua/XML/schema a importar: os scripts, tabelas e colunas dos sistemas estruturais ja estao presentes no runtime atual e o banco real esta em `db_version=63`.

As diferencas encontradas contra o upstream sao customizacoes Remastered intencionais e foram preservadas:

- Forge: custos de dust de fusion/transfer/convergence mantidos em `0`.
- Imbuements: materiais reduzidos em aproximadamente 1/3.
- Bestiary: `bestiaryKillMultiplier = 4`.
- Weapon Proficiency: `proficiencies.json` mantem ajustes Remastered menores que o upstream em alguns bonus Sanguine/Grand Sanguine.

## Classificacao

| Sistema | Classe | Status final |
| --- | --- | --- |
| Forge | E - CUSTOMIZED_ALREADY | Ativo no servidor, com scripts, tabela `forge_history`, colunas `forge_dusts`/`forge_dust_level` e balanceamento Remastered preservado. |
| Prey | A - READY_TO_ENABLE | Ativo por config, tabela `player_prey` populada e callbacks de XP/loot presentes. |
| Bestiary | E - CUSTOMIZED_ALREADY | Ativo, charms carregados, tabela `player_charms` presente e multiplicador Remastered preservado. |
| Bosstiary | A - READY_TO_ENABLE | Ativo, tabela `player_bosstiary`, `boss_points`, boosted boss e reward chest presentes. |
| Charms | E - CUSTOMIZED_ALREADY | Ativo, `bestiary_charms.lua` e talkactions admin presentes, precos/multiplicadores Remastered preservados. |
| Imbuements | E - CUSTOMIZED_ALREADY | Ativo, XML valido, shrine action presente e materiais reduzidos preservados. |
| Weapon Proficiency | C - CLIENT_SERVER_ADAPTATION | JSON e coluna `weapon_proficiencies` presentes. Sem troca de protocolo nesta etapa; mantido como suporte server/client atual. |
| Reward | A - READY_TO_ENABLE | Daily reward lib/modulo/shrine e tabelas `daily_reward_history`/`player_rewards` presentes. |
| Wheel | C - CLIENT_SERVER_ADAPTATION | `wheelSystemEnabled = true` e `player_wheeldata` presente. Dados principais dependem da integracao client/binario atual. |
| Animus Mastery | C - CLIENT_SERVER_ADAPTATION | Config e coluna `animus_mastery` presentes. Sem troca de engine/protocolo nesta etapa. |

## Decisao de Implementacao

Implementado neste pacote:

- Suíte automatizada `Scripts/Test-StructuralSystems15_24.ps1`.
- Documentacao de auditoria estrutural e classificacao dos sistemas.

Nao implementado cegamente:

- Alteracoes C++/protocolo/client para Wheel, Animus Mastery e Weapon Proficiency alem do suporte ja existente no runtime.
- Migrações destrutivas ou reexecucao de migrations no banco real.
- Substituicao de scripts customizados por upstream quando a diferenca era balanceamento Remastered.

## Validacao Esperada

O teste estrutural valida:

- flags de config dos sistemas;
- preservacao das customizacoes Remastered;
- presenca dos arquivos Lua/XML/JSON estruturais;
- parse de `imbuements.xml`;
- parse de `proficiencies.json`;
- existencia das tabelas e colunas de persistencia no banco real;
- contagens de `accounts`, `players` e `players_online`.

Sistemas que exigirem mudancas profundas de binario/protocolo devem continuar como `DEFERRED_HIGH_RISK` ate existir uma rodada separada de build e validacao do client/server.
