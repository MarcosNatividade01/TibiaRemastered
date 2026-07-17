# OTBM Merger

## Objetivo

`Tools/OTBMMerger` aplica um fragmento OTBM em um mapa base, com offset explicito, deteccao de conflitos e saida somente em sandbox.

Nesta etapa, a ferramenta foi usada para gerar:

- `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`
- `UpstreamTesting/TargunaMerge/world/`

Nenhum `world.otbm` oficial foi alterado.

## Arquitetura

Arquivos:

- `Tools/OTBMMerger/Merge-OTBMFragment.ps1`
- `Tools/OTBMMerger/OTBMMerger.cs`
- `Tools/OTBMMerger/README.md`

Tecnologia:

- PowerShell wrapper;
- C# compilado localmente via `csc.exe`;
- parser/serializer OTBM proprio, seguindo a mesma abordagem auditavel do extractor.

O parser foi reimplementado nesta ferramenta com a mesma semantica basica do `OTBMFragmentExtractor`: leitura gzip, node stream OTBM, writer com escape e relatorios JSON. Ainda nao foi extraido para biblioteca compartilhada.

## Suporte

Suporta:

- leitura de mapa base;
- leitura de fragmento;
- offset X/Y/Z;
- dry-run;
- validate-only;
- geracao de novo OTBM;
- expansao opcional de root width/height via `-ExpandMapBounds`;
- conflitos de tile;
- house tile e house id;
- towns duplicadas;
- waypoints duplicados;
- teleport destination interno, quando a origem e o destino estao no fragmento;
- teleport destination externo como warning;
- ACTION_ID e UNIQUE_ID em atributos de tile, quando encontrados antes de atributos desconhecidos.

## Politica de Conflitos

Classificacoes:

- `BLOCKING`: impede escrita quando `ConflictPolicy=Fail`;
- `WARNING`: registrado, mas nao bloqueia;
- `SAFE`: reservado para futuras validacoes positivas.

Conflitos implementados:

| Tipo | Classificacao |
| --- | --- |
| tile destino ja existe | `BLOCKING` |
| dois tiles do fragmento vao para mesma coordenada | `BLOCKING` |
| coordenada destino fora de `0..65535` ou z fora de `0..15` | `BLOCKING` |
| house id ja existe no mapa base | `BLOCKING` |
| root width/height insuficiente sem `-ExpandMapBounds` | `BLOCKING` |
| town id/nome ja existe | `WARNING`, town pulada |
| waypoint ja existe | `WARNING`, waypoint pulado |
| teleport para fora do fragmento | `WARNING` |
| unique id encontrado | `WARNING`, exige validacao externa |

## Limitacoes

- Nao mescla automaticamente arquivos externos XML.
- Nao copia scripts.
- Nao valida visualmente no RME4.
- Nao inicia servidor.
- Nao verifica atributos internos de todos os item nodes.
- Nao resolve conflito automaticamente.
- Nao altera producao.

## Uso Targuna

Offset usado:

- `OffsetX = 18070`
- `OffsetY = 18120`
- `OffsetZ = 0`

Motivo:

- source min `x=31915` vira `49985`;
- source max `x=33560` vira `51630`;
- source min `y=31875` vira `49995`;
- source max `y=32760` vira `50880`;
- encaixa dentro da reserva sandbox do patch.

Com `-ExpandMapBounds`, o root do mapa sandbox foi expandido de `35143x34812` para `51631x50881`.
