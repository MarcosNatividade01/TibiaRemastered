# Targuna Map Fragment Validation

## Objetivo

Gerar `MapPatches/Targuna/map-fragment.otbm` real e seguro para Targuna/Aragonia, sem substituir `world.otbm` oficial.

## Resultado

`map-fragment.otbm` nao foi criado nesta etapa.

Motivo: OpenTibiaBR RME v4.0 agora validou abertura, Save As e reabertura de uma copia do mapa atual, e tambem abriu o mapa upstream apos descompactar a copia gzipada. Porem ainda nao ha um fluxo de crop/export automatizado e auditavel para gerar apenas a regiao Targuna como `map-fragment.otbm`.

## Ferramenta

Ferramenta usada para gerar fragmento:

- nenhuma.

Ferramentas verificadas anteriormente:

- `Tools/MapPatch/Invoke-MapPatch.ps1`: valida e aplica patches, mas nao interpreta nem recorta OTBM.
- `Tools/MapPatch/Test-MapPatchPipeline.ps1`: testa o pipeline, mas nao cria OTBM.
- busca local por Remere/RME em `C:\Users\marco\Downloads`: nenhum executavel encontrado.

O projeto referencia Remere's Map Editor como ferramenta de edicao de mapa, mas ela nao esta instalada ou embutida no repositorio.

Ferramentas verificadas em 2026-07-15:

| Ferramenta | Fonte | Hash | Resultado |
| --- | --- | --- | --- |
| RME v3.7 `RME_x64.zip` | `https://github.com/hampusborgos/rme/releases` | `A434D80DAD0ED833E3F537C3FBE20F4455FD785A08A1797ED047B3A040C84D9F` | Hash confere com release oficial, mas `clients.xml` vai apenas ate `10.100`; sem suporte 15.24 |
| OTAcademy/RME 4.2.0 `release_420_files.zip` | `https://github.com/OTAcademy/RME/releases` | `0CDA57E0DD597A08FF066B5B00D98A39FAEA4557AF623474B5CCB4BDFB2AAB83` | Inspecionado sem executar; `clients.xml` vai apenas ate `13.30`; sem checksum oficial publicado |
| OpenTibiaBR RME v4.0 `canary-map-editor-v4.0-windows.zip` | `https://github.com/opentibiabr/remeres-map-editor/releases/tag/v4.0` | `3B237C1ABE32B5FF2286E29FB1DB97AF3FD1B18DF44EC99D49AD6854D825245B` | Hash confere; suporta assets por `catalog-content.json`/protobuf; abertura inicial passou parcialmente; extracao ainda nao validada |

## Compatibilidade OTBM

Arquivos OTBM relevantes:

- runtime oficial: `Server/data-global/world/world.otbm`
- runtime crystal: `Server/data-crystal/world/world.otbm`
- upstream global: `Upstream/CrystalLatest/data-global/world/world.otbm`
- upstream crystal: `Upstream/CrystalLatest/data-crystal/world/world.otbm`

Como nao ha parser/editor OTBM confiavel disponivel para 15.24, a versao interna OTBM nao foi regravada nem convertida. Nenhum teste de leitura/escrita de OTBM foi executado para evitar falso positivo ou corrupcao silenciosa.

## Coordenadas

Origem upstream inventariada:

- `x=31920..33550`
- `y=31880..32760`
- `z=6..12`

Area sandbox reservada:

- `x=50000..51630`
- `y=50000..50880`
- `z=6..12`

Essa area foi mantida. Sem fragmento, nao ha tiles reais a validar contra colisao, walkability, stairs, ropes, holes, doors, quest doors ou zones.

## Validacoes Executadas

| Validacao | Resultado | Observacao |
| --- | --- | --- |
| Presenca de ferramenta OTBM | Parcial | OpenTibiaBR RME v4.0 e candidato condicional |
| Assets 15.24 | Parcial | `Client/assets/catalog-content.json` e `appearances-*.dat` existem; RME4 preservou config com `15.24.eb0021` |
| Abertura de copia crystal | Parcial | processo ficou estavel; sem validacao visual estruturada |
| Round-trip com mapa crystal | Inconclusivo | `Ctrl+S` manteve hash identico; nao prova reserializacao |
| Abertura do mapa global atual | Parcial | processo ficou estavel em copia descartavel |
| Abertura do mapa global upstream | Parcial | processo ficou estavel em copia descartavel |
| Boot do servidor com mapa round-trip | Nao executado | depende de round-trip reserializado e verificavel |
| Leitura/extracao da regiao Targuna | Nao executada | depende de controle visual/manual seguro ou automacao confiavel |
| Criacao de fragmento | Nao executada | Sem ferramenta confiavel |
| Validacao de tiles | Bloqueada | Depende do fragmento |
| Validacao de item IDs no fragmento | Bloqueada | Depende do fragmento |
| Validacao de teleports no mapa | Bloqueada | Depende do fragmento |
| Validacao de spawns candidatos | Parcial | 88 spawns preservados em `monsters.xml`, nao ativados |
| Validacao de NPC positions candidatas | Parcial | 9 posicoes preservadas em `npcs.xml`, nao ativadas |
| Rollback sandbox | Passou | Pipeline restaurou backups |
| Reaplicacao sandbox | Passou | Sem spawns/NPCs ativos |

## Sandbox

O patch continua aplicavel apenas como candidato bloqueado:

- `Validate`: passou.
- `ApplySandbox`: passou.
- `Rollback`: passou.
- `ReapplySandbox`: passou.

Como `map-fragment.otbm` nao existe, o teste jogavel real nao foi possivel.

## Atualizacao RME4 - 2026-07-15

Validacoes adicionais executadas somente em sandbox:

| Validacao | Resultado | Observacao |
| --- | --- | --- |
| Abrir `current-crystal-rt-real/world.otbm` | PASS | RME abriu com assets 15.24 e stubs minimos de criaturas |
| Validacao visual do mapa atual | PASS | `x=388 y=419 z=6` renderizou area ocupada com tiles/objetos/marcadores |
| Save As para novo OTBM | PASS | `world-roundtrip-rme4.otbm` criado |
| Reabrir OTBM salvo | PASS | arquivo reabriu no RME e renderizou `x=387 y=419 z=6` |
| Abrir upstream `.otbm` original | FAIL esperado | arquivo upstream esta gzipado apesar da extensao `.otbm` |
| Descompactar upstream em sandbox | PASS | `world-decompressed.otbm` criado |
| Abrir upstream descompactado | PASS | RME abriu `world-decompressed.otbm` |
| Localizar Targuna visualmente | PASS | hub confirmado perto de `x=31942..31973 y=31888..31920 z=6..7` |
| Criar fragmento OTBM | NOT_DONE | requer crop/export seguro; nao encontrado comando automatizado confiavel |
| Aplicar Map Patch Pipeline com fragmento real | NOT_RUN | depende de `map-fragment.otbm` |
| Servidor de teste com Targuna | NOT_RUN | depende de fragmento aplicado a copia |

Coordenadas reais confirmadas por NPCs:

| Elemento | Coordenada |
| --- | --- |
| Captain Indigo | `31973,31892,6` |
| Camilla | `31942,31902,6` |
| Emiliana | `31960,31901,6` e `32412,32687,12` |
| Leonora | `31951,31888,7` |
| Sterling | `31928,31903,7` |
| Aurelia | `31955,31916,7` |
| Lizzie | `31941,31920,7` |
| Morla | `33514,32748,8` |

Conclusao atual:

- Bounding box amplo continua valido: `x=31920..33550`, `y=31880..32760`, `z=6..12`.
- Hub/NPC inicial confirmado visualmente no canto noroeste do bounding box.
- O mapa upstream precisa ser descompactado antes de uso no RME4.
- `map-fragment.otbm` ainda nao existe.
- Status: `PARTIALLY_READY`.

## Proxima Acao Segura

1. Usar OpenTibiaBR RME v4.0 apenas em sandbox.
2. Fazer validacao visual/manual da abertura do mapa global atual e upstream.
3. Executar `Save As` para novo arquivo em copia descartavel, nao apenas `Ctrl+S`.
4. Confirmar boot do servidor de teste com o arquivo salvo.
5. Abrir copia do mapa upstream e localizar Targuna.
6. Exportar apenas a area `x=31920..33550`, `y=31880..32760`, `z=6..12`.
7. Salvar como `MapPatches/Targuna/map-fragment.otbm`.
8. Validar todos os tiles e item IDs contra o client/runtime atual.
9. Aplicar em `UpstreamTesting/MapPatches/Targuna/`.
10. Somente depois considerar promocao parcial.

## Tentativa de Extracao Segura - 2026-07-15

Metodo avaliado:

| Metodo | Resultado | Decisao |
| --- | --- | --- |
| Crop/export manual controlado no RME4 | Parcial | RME4 suporta selecao/copy/paste e `Import Map`, mas nao foi encontrado export/crop OTBM por bounding box |
| Ferramenta propria/auditavel para extrair bounding box OTBM | Rejeitado nesta etapa | exigiria implementar parser/escritor OTBM complexo sem tempo de validacao suficiente |
| Importar mapa upstream inteiro com offset | Rejeitado | copiaria conteudo demais e violaria a regra de nao importar world inteiro |

Decisao:

- O metodo mais seguro continua sendo RME4 em sandbox, com selecao por coordenadas e criacao de um mapa-fragmento separado.
- A etapa de criacao do arquivo ainda depende de um procedimento interativo/manual seguro ou de uma extensao do tooling.
- Nao foi gerado `MapPatches/Targuna/map-fragment.otbm` para evitar um fragmento incompleto ou nao auditavel.

Inspecao tecnica do RME4:

- `Import Map` existe e aceita offset X/Y/Z.
- `Import Map` tem opcoes para houses, monster spawns e NPC spawns.
- O editor possui `CopyBuffer` para copiar tiles selecionados, incluindo itens, monstros, spawns e NPCs selecionados.
- A API Lua interna permite obter `app.map`, acessar `map:getTile(x,y,z)` e adicionar tiles a `app.selection`.
- A API Lua interna permite `app.copy()` e `app.paste()`.
- A API Lua interna nao expoe `Save As`, criacao de mapa novo ou abertura/salvamento de arquivo OTBM.
- Nao foi encontrado comando nativo para exportar uma selecao como OTBM.

Validacao executada nesta etapa:

| Validacao | Resultado | Observacao |
| --- | --- | --- |
| XML `monsters.xml` | PASS | XML carregou corretamente |
| XML `npcs.xml` | PASS | XML carregou corretamente |
| XML `teleports.xml` | PASS | XML carregou corretamente |
| `Invoke-MapPatch.ps1 -Mode Validate` | PASS | `patchId=targuna`, `status=passed`, sem issues |
| Existencia de `map-fragment.otbm` | FAIL esperado | arquivo ainda nao existe |
| Aplicacao com fragmento | NOT_RUN | nao executar sem fragmento real |
| Servidor de teste com Targuna | NOT_RUN | depende de mapa patchado |

Hashes dos arquivos candidatos:

| Arquivo | Tamanho | SHA-256 |
| --- | ---: | --- |
| `MapPatches/Targuna/monsters.xml` | 13,491 | `DCDCCC3E02227BD2639D6447A94E4862A9E3C97F0213A3C1940BB0C27561C600` |
| `MapPatches/Targuna/npcs.xml` | 1,262 | `06973948BFD539AA126AC5C71454F4F3FDF3BA3F76B80516CA3F3675A0E3BC3B` |
| `MapPatches/Targuna/teleports.xml` | 753 | `F54C1F9F60EF68C31DF67743F4D317D6954963980BF402BA3B52E104ACA3B15E` |
| `MapPatches/Targuna/patch.json` | 2,000 | `3F24A20A9C402074C95AFA64B4F6D46342DA130BC0FB5C5C32A8D6AEE2DEFA65` |

Status:

`PARTIALLY_READY`

Motivo: todos os metadados e XMLs candidatos validam, mas nao existe fragmento OTBM real e o servidor de teste nao pode carregar Targuna sem mapa patchado.

## OTBM Fragment Extractor - 2026-07-15

Foi criada uma ferramenta propria e auditavel em `Tools/OTBMFragmentExtractor/`.

Arquivos:

- `Tools/OTBMFragmentExtractor/Extract-OTBMFragment.ps1`
- `Tools/OTBMFragmentExtractor/OTBMFragmentExtractor.cs`
- `Tools/OTBMFragmentExtractor/README.md`
- `MapPatches/Targuna/targuna-fragment.bounds.csv`

Metodo escolhido:

- parser/serializer C# proprio;
- sem dependencia externa;
- leitura de OTBM gzipado ou descompactado;
- filtro por uma ou varias caixas de coordenadas;
- preservacao bruta de payloads de tiles selecionados;
- relatorio JSON por dry-run/extract.

O bounding box amplo foi testado e rejeitado como fragmento final:

| Recorte | Resultado |
| --- | --- |
| `x=31920..33550 y=31880..32760 z=6..12` | `5,788,347` tiles; inclui muitas cidades e conteudo nao relacionado |

Recortes compostos usados:

| Area | Coordenadas | Tiles |
| --- | --- | ---: |
| Hub Targuna | `x=31915..31985 y=31875..31935 z=6..8` | `9,147` |
| Aragonia pirates | `x=33475..33560 y=32680..32760 z=7..8` | `12,653` |
| Crimson Court staging | `x=32390..32430 y=32670..32700 z=12` | `1,235` |

Dry-run composto:

- status: `passed`;
- tiles selecionados: `23,035`;
- tile areas: `514`;
- selected floors: z6 `959`, z7 `11,297`, z8 `9,544`, z12 `1,235`;
- house IDs: `3701`, `3702`;
- towns: `Dawnport Tutorial`, `Targuna`;
- unsupported nodes: nenhum;
- errors: nenhum.

Fragmento criado:

| Arquivo | Tamanho | SHA-256 |
| --- | ---: | --- |
| `MapPatches/Targuna/map-fragment.otbm` | `245,702` | `B617D0E95C7F5F66015FC150086E49C95BAF9FCD33E69E1D6514CEF035171202` |

Validacao do fragmento pelo extractor:

- status: `passed`;
- tiles reabertos: `23,035`;
- tile areas reabertas: `514`;
- house tiles: `294`;
- selected floors preservados;
- errors: nenhum.

Limitacao importante:

O fragmento preserva coordenadas upstream. O `patch.json` ainda aponta para area sandbox `x=50000..51630 y=50000..50880 z=6..12`. Antes de promover para runtime, e obrigatorio implementar e validar merge/relocacao OTBM ou ajustar a estrategia de coordenadas.

Status revisado:

`PARTIALLY_READY`

Motivo: o fragmento real existe e valida pelo parser, mas ainda nao foi aberto visualmente no RME4, nao passou por round-trip RME4 e nao foi mesclado em copia de mapa para boot do servidor.

## Merge Sandbox - 2026-07-15

O fragmento foi mesclado em mapa sandbox por `Tools/OTBMMerger/`:

- saida: `UpstreamTesting/TargunaMerge/world-targuna-test.otbm`;
- offset: `X=18070`, `Y=18120`, `Z=0`;
- SHA-256: `07485F182DAA05761D8DC3F8F65B07AB73267E3328280F79F60A6BD9C0906697`;
- tiles mesclados: `23,035`;
- tile areas mescladas: `6`;
- parser proprio reabriu o mapa e encontrou `23,035` tiles nos bounds sandbox.

Status segue `PARTIALLY_READY` porque ainda faltam RME4 visual, round-trip RME4, servidor de teste e teste jogavel.
