# Tibia Remastered 15.24 - Auditoria de Spells e Posturas por Vocacao

Data: 2026-07-18

Referencia usada: `Upstream/CrystalLatest/data/scripts/spells`

Runtime auditado: `Server/data/scripts/spells`

## Resumo

O runtime atual nao tinha ausencias nominais de spells registradas em relacao ao upstream local 15.24. O problema era operacional:

- posturas oficiais estavam presentes, mas algumas estavam registradas como suporte comum ou foco antigo, nao como stance operacional;
- 19 spells ofensivas de Sorcerer nao tinham as variantes elementais condicionadas por `getElementalStance()`;
- o upstream usa APIs que o binario atual nao expoe por string/metodo (`"stance"` textual e `spell:basePower()`), entao a integracao foi adaptada para o runtime atual;
- havia risco de multiplicador local duplicar o bonus Remastered de spells ofensivas. O bonus agora permanece centralizado em `Player:onCombat`.

## Matriz por Vocacao

| Vocacao | Total referencia | Presentes | Corrigidas | Ausentes restantes |
|---|---:|---:|---:|---:|
| Sorcerer | 84 | 84 | 22 | 0 |
| Master Sorcerer | 85 | 85 | 22 | 0 |
| Druid | 87 | 87 | 2 | 0 |
| Elder Druid | 87 | 87 | 2 | 0 |
| Knight | 38 | 38 | 2 | 0 |
| Elite Knight | 39 | 39 | 2 | 0 |
| Paladin | 51 | 51 | 2 | 0 |
| Royal Paladin | 52 | 52 | 2 | 0 |
| Monk | 41 | 42 | 0 | 0 |
| Exalted Monk | 41 | 42 | 0 | 0 |

Observacao: Monk/Exalted Monk tem 1 spell extra customizada no Remastered (`Mentor Other`). No upstream local, `mentor_other.lua` e um marcador de remocao, sem registro de spell.

## Posturas Oficiais 15.24

| Vocacao | Postura | Words | Level | Mana | Cooldown | Group cooldown | Status final |
|---|---|---|---:|---:|---|---|---|
| Sorcerer / Master Sorcerer | Master of Flames | `uteta flam` | 20 | 400 | 30s | 2s / 30s | PRESENT_WORKING |
| Sorcerer / Master Sorcerer | Master of Thunder | `uteta vis` | 20 | 400 | 30s | 2s / 30s | PRESENT_WORKING |
| Sorcerer / Master Sorcerer | Master of Decay | `uteta mort` | 20 | 400 | 30s | 2s / 30s | PRESENT_WORKING |
| Druid / Elder Druid | Shared Conservation | `utura sio` | 100 | 200 | 2s | 2s / 2s | PRESENT_WORKING |
| Druid / Elder Druid | Elemental Synthesis | `utito dru` | 100 | 200 | 2s | 2s / 2s | PRESENT_WORKING |
| Knight / Elite Knight | Blood Rage | `utito tempo` | 60 | 290 | 2s | 2s / 2s | PRESENT_WORKING |
| Knight / Elite Knight | Protector | `utamo tempo` | 55 | 200 | 2s | 2s / 2s | PRESENT_WORKING |
| Paladin / Royal Paladin | Sharpshooter | `utori con` | 60 | 450 | 10s | 2s / 10s | PRESENT_WORKING |
| Paladin / Royal Paladin | Divine Defiance | `utori hur` | 100 | 200 | 2s | 2s / 2s | PRESENT_WORKING |

Monk nao possui spell registrada como grupo `stance` na referencia local 15.24. Suas mecanicas equivalentes continuam como focus/virtue/aura customizadas.

## Correcoes Aplicadas

### Registro e comportamento de posturas

Corrigidas 9 posturas:

- `blood_rage.lua`
- `protector.lua`
- `sharpshooter.lua`
- `divine_defiance.lua`
- `shared_conservation.lua`
- `elemental_synthesis.lua`
- `master_of_flames.lua`
- `master_of_thunder.lua`
- `master_of_decay.lua`

Adaptacao de compatibilidade: o runtime publicado nao reconhece `spell:group("support", "stance")` por string. Foi usado o secondary group numerico `11`, que corresponde a `SPELLGROUP_STANCE` no upstream 15.24.

### Variantes ofensivas por postura de Sorcerer

Corrigidas 19 spells ofensivas de Sorcerer para selecionar elemento/efeito por postura:

- `buzz.lua`
- `curse.lua`
- `death_strike.lua`
- `electrify.lua`
- `energy_beam.lua`
- `energy_wave.lua`
- `fire_wave.lua`
- `flame_strike.lua`
- `great_death_beam.lua`
- `great_energy_beam.lua`
- `great_fire_wave.lua`
- `hells_core.lua`
- `ignite.lua`
- `rage_of_the_skies.lua`
- `scorch.lua`
- `strong_energy_strike.lua`
- `strong_flame_strike.lua`
- `ultimate_energy_strike.lua`
- `ultimate_flame_strike.lua`

`death_echo.lua` ja tinha suporte a `getElementalStance()` e foi preservada.

### Balanceamento Remastered

O +15% de spells ofensivas e o +30% de runas ofensivas permanecem centralizados em:

- `Modules/Remastered/Config/default.lua`
- `Modules/Remastered/Balance/api.lua`
- `Server/data/events/scripts/player.lua`

Foi removido multiplicador local de spells ofensivas para evitar aplicacao duplicada. Cura, buffs, suporte e posturas sem dano nao recebem o bonus de spell ofensiva.

## Duplicidades e Customizacoes

- Nao foram detectadas duplicidades por par `spell:name` + `spell:words`.
- `Mentor Other` foi preservada como customizacao Monk/Exalted Monk do Remastered.
- O upstream local marca `Mentor Other` como removida, portanto ela nao foi tratada como ausencia ou erro.

## Evidencias de Teste

| Teste | Resultado | Evidencia |
|---|---|---|
| `Scripts/Test-VocationSpellsAndStances.ps1` | PASS | 217 spells registradas no runtime, 216 upstream, 0 ausentes, 9 posturas validadas |
| Boot real do server | PASS | servidor online, 0 warnings `Unknown secondaryGroup: stance`, 0 erros Lua em spells |
| `Scripts/Test-DamageMultipliers.ps1` | PASS | spells +15%, runas +30%, sem duplicidade de multiplicador |
| `Scripts/Test-BalanceConfig.ps1` | PASS | XP 8x, Skills 3x, ML 3x, Attack Speed 1.3x, spells/runas preservadas |
| `Scripts/Test-AccountCharacterList.ps1` | PASS | conta descartavel e 3 personagens descartaveis listados |
| `Scripts/Test-OfflineIsolation.ps1` | PASS | Offline em 127.0.0.1, porta 7172, UserData preservado |
| `Scripts/Test-MultiplayerHostDiagnostics.ps1` | PASS | bind multiplayer e diagnostico de host validado |
| `Scripts/Test-UpdateSimulation.ps1` | PASS | update, repair e montagem de large file validados |
| `Tools/TargunaSandbox/Run-Targuna-Full-Test.ps1 -NoClient -ManualWindowSeconds 15` | PASS | sandbox automatizado concluido |

## Resultado Final

Classificacao final das spells/posturas por vocacao:

- Sorcerer / Master Sorcerer: PRESENT_WORKING
- Druid / Elder Druid: PRESENT_WORKING
- Knight / Elite Knight: PRESENT_WORKING
- Paladin / Royal Paladin: PRESENT_WORKING
- Monk / Exalted Monk: PRESENT_WORKING com customizacao preservada (`Mentor Other`)

Ausencias restantes de spells/posturas contra a referencia local 15.24: 0.
