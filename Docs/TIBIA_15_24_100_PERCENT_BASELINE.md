# Tibia Remastered 15.24 - 100 Percent Operational Baseline

Data: 2026-07-18
Base inicial: `0.1.32-test`

## Criterio

`FULL_OPERATIONAL` exige evidencia de carregamento, execucao, persistencia, integracao esperada e ausencia de regressao critica.

Arquivos, flags, tabelas e smoke tests isolados nao bastam para declarar 100%.

## Sistemas

| Sistema | Status honesto | Evidencia | Lacuna para 100% |
| --- | --- | --- | --- |
| Forge | PARTIAL_OPERATIONAL | Boot, scripts, actions, `forge_history`, dust/custos custom preservados. | Falta teste jogavel automatizado de fusion/transfer/tier com item real e persistencia pos logout/login. |
| Prey | PARTIAL_OPERATIONAL | Config ativa, `player_prey`, callbacks de XP/loot, store/prey data presentes. | Falta teste client de abrir slot, selecionar/reroll e validar bonus ativo em combate real. |
| Bestiary | PARTIAL_OPERATIONAL | Monster raceId/Bestiary, `player_charms`, talkactions admin, multiplicador Remastered. | Falta teste automatizado de kill real incrementando contador e unlock. |
| Bosstiary | PARTIAL_OPERATIONAL | `player_bosstiary`, boss points, reward chest e boosted boss presentes. | Falta boss kill automatizado com persistencia pos relogin. |
| Charms | PARTIAL_OPERATIONAL | `bestiary_charms.lua`, pontos/runes/admin actions e persistencia. | Falta unlock/assign/effect jogavel automatizado. |
| Imbuements | PARTIAL_OPERATIONAL | XML valido, shrine action, materiais 1/3 preservados. | Falta aplicar imbue em item real via client/server e verificar duracao/effect persistente. |
| Reward | PARTIAL_OPERATIONAL | Daily reward lib/module/shrine, `daily_reward_history`, `player_rewards`. | Falta claim/streak/cooldown automatizado com personagem real de teste. |
| Weapon Proficiency | PARTIAL_OPERATIONAL | Binario carrega itens com proficiency, JSON valido, coluna `weapon_proficiencies`, Lua catalyst e C++ upstream 15.24. | Falta prova client/server de UI, packet, progresso por uso, bonus e persistencia. |
| Wheel of Destiny | PARTIAL_OPERATIONAL | `wheelSystemEnabled`, `player_wheeldata`, spells chamam APIs de Wheel, C++ upstream 15.24. | Falta teste client de abrir wheel, aplicar node, bonus, reset e persistencia. |
| Animus Mastery | PARTIAL_OPERATIONAL | Config, coluna `animus_mastery`, APIs C++ upstream e SoulPit hooks. | Falta evento real de progresso/unlock, bonus de XP e packet/UI validados. |

## Conteudo 15.24

O conteudo estatico nominal esta em estado alto apos `0.1.31-test`: monsters, NPC Adrian, spells, items/equipments e Targuna foram integrados. O bloqueio restante para 100% nao e ausencia nominal conhecida, mas prova operacional jogavel automatizada das cadeias de quest/hunt/sistema.

## Bloqueios

- `BLOCKED_ENGINE`: nao existe arvore `src` local do runtime publicado; o upstream possui C++, mas trocar o binario sem pipeline de build/teste isolado e migracao controlada seria alto risco.
- `BLOCKED_PROTOCOL`: Weapon Proficiency, Wheel e Animus tem pontos de UI/packet/client que nao podem ser declarados 100% sem sessao client real confiavel.
- `BLOCKED_CLIENT_AUTOMATION`: nao ha evidencia automatizada suficiente de GUI para abrir janelas e confirmar estados visuais desses sistemas.

## Resultado

Resultado honesto desta baseline: `MAXIMUM_SAFE_15_24_COMPLETENESS`.

Meta tecnica para chegar a `100_PERCENT_OPERATIONAL`:

1. Criar sandbox de runtime completo com banco de teste e personagem descartavel.
2. Instrumentar probes Lua/C++ ou API admin para simular/validar cada fluxo.
3. Automatizar client real ou capturar packets confirmando UI/estado.
4. So entao promover binario/protocolo/client, se houver alteracao necessaria.
