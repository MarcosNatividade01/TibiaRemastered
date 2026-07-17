# Changelog

## 0.1.29-test - Promocao controlada de Targuna

- Promovido Targuna/Aragonia para o runtime principal local apos validacao GUI real.
- Publicacao preparada com mapa em partes verificadas por SHA256, sem versionar `world.otbm` diretamente.
- Mantidas as protecoes de `UserData`, logs, backups, bancos locais e configuracoes privadas.
- Herald, Crimson Court e storages avancados permanecem como conteudo non-blocking para validacao incremental.

## 0.1.28-test - Consolidacao Targuna 15.24

- Portados os 18 item definitions de Targuna/Aragonia para `Server/data/items/items.xml`.
- Mantidas as flags de Targuna desligadas por padrao.
- Mantido `world.otbm` oficial inalterado.
- Documentada a recomendacao de ferramenta OTBM para a proxima etapa.

## 0.1.0 - Fase 6

- Criado Remastered Balance Module.
- Adicionada feature flag `enable_remastered_balance`.
- Configurados rates Remastered iniciais: XP 10x, skill 3x, loot 2x.
- Integrados multiplicadores nos callbacks Lua existentes de XP, skill e loot base.
