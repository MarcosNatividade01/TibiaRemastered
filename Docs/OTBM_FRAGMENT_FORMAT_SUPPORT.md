# OTBM Fragment Format Support

## Origem da Implementacao

A implementacao foi baseada na leitura local do codigo do OpenTibiaBR RME v4.0:

- `source/iomap_otbm.h`
- `source/iomap_otbm.cpp`
- `source/filehandle.cpp`
- `source/filehandle.h`

## Container OTBM

O extractor suporta:

- arquivo OTBM descompactado;
- arquivo OTBM gzipado com assinatura `1F 8B`;
- identificador inicial de 4 bytes;
- stream de nos OTBM com:
  - node start `0xFE`;
  - node end `0xFF`;
  - escape `0xFD`.

## Nos Processados

| No | ID | Suporte |
| --- | ---: | --- |
| `OTBM_ROOTV1` | 1 | le cabecalho e preserva |
| `OTBM_MAP_DATA` | 2 | le atributos conhecidos e preserva |
| `OTBM_TILE_AREA` | 4 | filtra por coordenadas |
| `OTBM_TILE` | 5 | filtra por coordenadas e preserva filhos |
| `OTBM_ITEM` | 6 | preserva bruto dentro de tile selecionado |
| `OTBM_TOWNS` | 12 | filtra towns por temple position |
| `OTBM_TOWN` | 13 | filtra por coordenadas |
| `OTBM_HOUSETILE` | 14 | filtra por coordenadas e registra house id |
| `OTBM_WAYPOINTS` | 15 | filtra por coordenadas |
| `OTBM_WAYPOINT` | 16 | filtra por coordenadas |
| `OTBM_TILE_ZONE` | 19 | preserva bruto dentro de tile selecionado |

Nos nao reconhecidos em `MAP_DATA` sao excluidos e reportados. Filhos de tile desconhecidos sao preservados e reportados como raw-preserved.

## Atributos Processados

| Atributo | ID | Suporte |
| --- | ---: | --- |
| `OTBM_ATTR_DESCRIPTION` | 1 | lido/preservado |
| `OTBM_ATTR_TELE_DEST` | 8 | lido para reportar referencia interna/externa |
| `OTBM_ATTR_EXT_SPAWN_MONSTER_FILE` | 11 | lido/preservado |
| `OTBM_ATTR_EXT_HOUSE_FILE` | 13 | lido/preservado |
| `OTBM_ATTR_EXT_SPAWN_NPC_FILE` | 23 | lido/preservado |
| `OTBM_ATTR_EXT_ZONE_FILE` | 24 | lido/preservado |

Outros atributos de tile sao preservados como bytes originais sem interpretacao completa.

## Referencias Externas

Teleports selecionados sao classificados no relatorio:

- `INTERNAL`: destino dentro de alguma caixa selecionada;
- `EXTERNAL_REFERENCE`: destino fora das caixas;
- `MISSING_DEPENDENCY`: reservado para validacoes futuras.

Na geracao de Targuna desta etapa, nenhum teleport externo foi reportado pelo parser.

## Limites de Confianca

O extractor e adequado para:

- dry-run;
- auditoria de tile count;
- extracao conservadora de tiles;
- preservacao de payloads ja existentes;
- gerar fragmentos que o proprio parser consegue reabrir.

Ainda nao e suficiente para promocao runtime porque falta:

- merge OTBM auditavel;
- relocacao de coordenadas;
- reescrita de XMLs externos relacionados;
- validacao visual do fragmento no RME4;
- teste de servidor com mapa patchado.
