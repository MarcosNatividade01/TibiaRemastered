# Systems Index

Indice dos sistemas conhecidos na arquitetura atual.

Status usados:

- Mapeado: existe implementacao versionada suficiente para entender fluxo, arquivos e testes.
- Parcial: existe referencia ou integracao, mas faltam arquivos reais para mapear completamente.
- Localizado no pacote: existe no pacote runtime encontrado em `tmp/`, mas ainda nao nas pastas oficiais versionadas.
- Ausente no snapshot: nao ha arquivos versionados que permitam mapear o sistema.

| Sistema | Status | Arquivos principais | Linguagem | Como testar |
| --- | --- | --- | --- | --- |
| Launcher | Mapeado | `Launcher/Launcher.ps1`, `Launcher/Modules/*.psm1` | PowerShell | `Launcher.ps1 -SelfTest`, `Launcher.ps1 -NoGui` |
| Update via GitHub | Mapeado | `TibiaRemastered.Update.psm1`, `manifest.json`, `version.json` | PowerShell/JSON | `Scripts/Test-UpdateSimulation.ps1` |
| Backup de update | Mapeado | `TibiaRemastered.Update.psm1`, `Backup/update_*` | PowerShell | `Scripts/Test-UpdateSimulation.ps1` |
| Rollback de update | Parcial | `Restore-TrmBackup` | PowerShell | simular hash mismatch em ambiente controlado |
| Logs | Mapeado | `Write-TrmLog`, `Logs/launcher_*.log` | PowerShell/texto | executar launcher e verificar `Logs/` |
| Manifest/release | Mapeado | `Generate-Manifest.ps1`, `Publish-Release.ps1` | PowerShell/JSON | `Publish-Release.ps1 -SkipGitPush` |
| Validacao | Mapeado | `TibiaRemastered.Validation.psm1`, `Test-Project.ps1` | PowerShell | `Scripts/Test-Project.ps1` |
| Runtime local | Parcial | `TibiaRemastered.Runtime.psm1` | PowerShell | `Test-Project.ps1 -StrictRuntime` com binarios reais |
| Banco de dados | Parcial | `Ensure-TrmDatabaseServer`, `UserData/Database`, `Database_Template` | PowerShell/SQL | iniciar runtime completo e verificar persistencia |
| Endpoint criacao/login | Parcial | `Write-TrmPortableWebEndpointScript` | PowerShell/SQL/HTTP | criar conta/personagem pelo cliente |
| Servidor | Localizado no pacote | `tmp/player-package-download/TibiaRemastered-Player.zip/Server/crystalserver.exe` | C++/Lua/XML | instalar runtime real e testar portas 7171/7172 |
| Cliente | Localizado no pacote | `tmp/player-package-download/TibiaRemastered-Player.zip/Client/bin/client-local.exe` | binario/JSON/assets | instalar runtime real e executar `-Play` |
| Scripts Lua | Localizado no pacote | `Server/data`, `Server/data-crystal`, `Server/data-global` no ZIP | Lua | `Scripts/Test-Project.ps1` com `lua` ou `luac` apos instalacao |
| Arquivos XML | Localizado no pacote | XML do servidor no ZIP | XML | `Scripts/Test-Project.ps1` apos instalacao |
| Configuracoes de servidor | Localizado no pacote | `Server/config.lua` | Lua/OT config | validar com servidor real |
| Experiencia | Parcial | `TibiaRemastered.Runtime.psm1` insere `experience=4200` | SQL via PowerShell | criar personagem e consultar `players` |
| Skills | Localizado no pacote | training/offline training scripts e config/rates | Lua/XML/SQL | depende do runtime real |
| Loot | Localizado no pacote | monster/boss/reward scripts | XML/Lua | depende do runtime real |
| Spells | Localizado no pacote | `Server/data/scripts/spells/` | Lua | testar cast sem alterar balanceamento |
| Runas | Localizado no pacote | `Server/data/scripts/runes/` | Lua | testar uso de runa sem alterar balanceamento |
| Store | Localizado no pacote | `Server/data/modules/scripts/gamestore/` | Lua | testar store em runtime controlado |
| Tibia coins | Localizado no pacote | `store_coins.lua`, gamestore e endpoint | Lua/SQL/PowerShell | criar conta e consultar `accounts` |
| Prey | Localizado no pacote | referencias em scripts/docs de runtime | Lua/SQL esperado | depende do runtime real |
| Forge | Localizado no pacote | `exaltation_forge.lua` | Lua | testar forge em runtime controlado |
| Bestiario | Localizado no pacote | `register_bestiary_charm.lua`, `bestiary_charms.lua` | Lua | testar em runtime controlado |
| Charms | Localizado no pacote | `register_bestiary_charm.lua`, `bestiary_charms.lua` | Lua | testar em runtime controlado |
| Imbuements | Localizado no pacote | `Server/data/XML/imbuements.xml`, shrine/actions | Lua/XML | testar em runtime controlado |
| Cooldowns | Localizado no pacote | disperso em spells/actions/events | Lua | depende do runtime real |
| Vocacoes | Parcial | endpoint insere `vocation=0` | SQL via PowerShell | criar personagem e consultar `players` |
| Monstros | Localizado no pacote | `Server/data-global/monster/`, `Server/data-crystal/monster/` | Lua/XML esperado | testar spawn em runtime controlado |
| NPCs | Localizado no pacote | `Server/data-global/npc/`, `Server/data-crystal/npc/`, `Server/data/npclib/` | Lua | testar dialogo em runtime controlado |
| Quests | Localizado no pacote | quest libs/scripts no ZIP | Lua | testar quest especifica em runtime controlado |
| Respawn | Localizado no pacote | `world/`, raids, respawn events | OTBM/Lua/XML | testar area especifica em runtime controlado |
| Saves | Parcial | `UserData/`, banco local | SQL/arquivos locais | jogar, fechar, abrir e validar persistencia |
| Login | Parcial | `Handle-Login` no endpoint gerado | PowerShell/SQL/HTTP | login pelo cliente |
| Criacao de personagem | Parcial | `Handle-ClientCreate` | PowerShell/SQL/HTTP | criar personagem pelo cliente |

## Ordem recomendada para mapeamento futuro

1. Decidir se o pacote localizado em `tmp/player-package-download/TibiaRemastered-Player.zip` sera extraido oficialmente ou mantido apenas como release.
2. Rodar `Scripts/Test-Project.ps1 -StrictRuntime`.
3. Inventariar arquivos Lua/XML/SQL reais.
4. Expandir este indice com caminhos especificos de spells, monsters, NPCs, quests, vocations e respawn.
5. Criar testes manuais por sistema de gameplay antes de alterar qualquer regra.
