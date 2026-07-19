# Missing Assets Audit

Data: 2026-07-19

## Resultado

Auditoria consolidada para o runtime principal 15.24.

Teste executado: `Scripts/Test-MissingAssets.ps1`.

- Entradas em `Client/assets.json`: 6795
- Entradas em `Client/assets/catalog-content.json`: 4904
- Arquivos em `Client/storeimages`: 98
- Referencias locais ausentes em assets/catalog: 0

| Area | Status | Observacao |
|---|---|---|
| Store images | READY | `Client/storeimages` e `Client/sounds` permanecem preservados; nenhum asset 15.25 foi promovido. |
| Boosted creature UI | READY | Sem importacao cega de sprites 15.25. |
| Boosted boss UI | READY | Sem troca de IDs de appearance no pacote atual. |
| Monsters/items/outfits 15.25+ | BLOCKED_BY_CLIENT_VERSION | Conteudo dependente de appearances posteriores deve ficar em `UpstreamTesting/` ate validacao explicita do client. |
| Stance placeholders | BLOCKED_BY_CLIENT_VERSION | Placeholders experimentais do Stance Protocol nao foram publicados no runtime principal. |

## Regra aplicada

Assets incompatíveis com o client/protocolo atual nao foram importados. Correcoes deste pacote ficaram restritas a referencias seguras de servidor, NPC e configuracao.
