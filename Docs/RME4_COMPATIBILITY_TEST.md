# RME4 Compatibility Test

## Escopo

Validar o OpenTibiaBR Remere's Map Editor v4.0 como candidato para gerar `MapPatches/Targuna/map-fragment.otbm` sem alterar o `world.otbm` oficial.

## Ferramenta

| Campo | Resultado |
| --- | --- |
| Repositorio | `https://github.com/opentibiabr/remeres-map-editor` |
| Release | `https://github.com/opentibiabr/remeres-map-editor/releases/tag/v4.0` |
| Tag | `v4.0` |
| Commit | `2a28ef8b2c96ac84945a49088cf0dd0b85933640` |
| Pacote | `canary-map-editor-v4.0-windows.zip` |
| SHA-256 esperado | `3b237c1abe32b5ff2286e29fb1db97af3fd1b18df44ec99d49ad6854d825245b` |
| SHA-256 local | `3B237C1ABE32B5FF2286E29FB1DB97AF3FD1B18DF44EC99D49AD6854D825245B` |
| Licenca observada | GPL v3 ou posterior nos cabecalhos do codigo e `LICENSE.rtf` |
| Executavel | `canary-map-editor-x64.exe` |

## Suporte a Assets 15.24

O RME4 usa carregamento moderno de assets:

- `source/client_assets.cpp`
- `ClientAssets::loadAppearanceProtobuf`
- `source/sprite_appearances.cpp`
- `SpriteAppearances::loadCatalogContent`
- `source/protobuf/appearances.proto`

Requisitos do loader:

- pasta de client valida;
- `package.json`;
- `assets/catalog-content.json`;
- arquivo `appearances-*.dat`;
- sprites `*.bmp.lzma`.

O client atual do Tibia Remastered atende a esses requisitos:

- `Client/package.json` com `version = 15.24.eb0021`;
- `Client/assets/catalog-content.json`;
- `Client/assets/appearances-ee339aff5b3cb38289287ff25cec261d8d2790e6e146938d4dfd9f138b065980.dat`;
- sprites `Client/assets/sprites-*.bmp.lzma`.

Foi criado `rme.cfg` local somente na sandbox do RME4 com:

```ini
[Version]
ASSETS_DATA_DIRS=[{"id":"15.24.eb0021","path":"C:/Users/marco/Downloads/TibiaRemastered-main/TibiaRemastered-main/Client"}]
```

Usar barras `/` foi necessario. Com barras `\`, o JSON ficava invalido e o RME salvava `id/path` vazios.

## Mapas Copiados para Sandbox

| Arquivo | Origem | SHA-256 |
| --- | --- | --- |
| `current-data-crystal-world.otbm` | `Server/data-crystal/world/world.otbm` | `3021FA0CD15A0A34CB805571F783DA0F852441A6BBE98FED99AD277787710817` |
| `current-data-global-world.otbm` | `Server/data-global/world/world.otbm` | `74144A405C79A98B22B9AA3F4C01811592401BE966BAA579F969C2A3FEB118CD` |
| `upstream-data-crystal-world.otbm` | `Upstream/CrystalLatest/data-crystal/world/world.otbm` | `3021FA0CD15A0A34CB805571F783DA0F852441A6BBE98FED99AD277787710817` |
| `upstream-data-global-world.otbm` | `Upstream/CrystalLatest/data-global/world/world.otbm` | `3BD40D14FEFEC41F24C4B3AE879E420BE1A831EF55B95DCBEC721E587A09B034` |

## Testes

| Teste | Resultado | Evidencia |
| --- | --- | --- |
| Download oficial | PASS | GitHub release oficial |
| SHA-256 | PASS | hash local igual ao digest publicado |
| Extracao | PASS | pacote extraido em `UpstreamTesting/OTBMTooling/RME4/` |
| Inspecao de codigo | PASS | loader protobuf/catalog encontrado |
| Configurar assets 15.24 | PARTIAL_PASS | `ASSETS_DATA_DIRS` preservado apos usar path com `/` |
| Abrir copia crystal | PARTIAL_PASS | processo vivo apos 25s, janela `Canary's Map Editor` |
| Round-trip crystal por `Ctrl+S` | INCONCLUSIVE | hash identico antes/depois; nao prova reserializacao |
| Abrir mapa global atual | PARTIAL_PASS | processo vivo apos 60s |
| Abrir mapa global upstream | PARTIAL_PASS | processo vivo apos 60s |
| UIAutomation | FAIL | `RPC_E_SERVERFAULT`; metodo descartado |
| Localizar Targuna visualmente | NOT_RUN | depende de controle GUI/manual |
| Criar `map-fragment.otbm` | NOT_RUN | depende de extracao validada |
| Map Patch Pipeline | NOT_RUN | depende do fragmento |
| Servidor de teste | NOT_RUN | depende de round-trip real ou fragmento |

## Decisao

OpenTibiaBR RME v4.0 e classificado como:

`CONDITIONALLY_COMPATIBLE`

Motivo:

- origem e hash foram verificados;
- ha suporte real a assets modernos via `catalog-content.json` e protobuf;
- o client 15.24 do projeto possui a estrutura esperada;
- o editor abriu copias de mapas sem crash aparente;
- ainda falta validar visualmente que os mapas foram carregados corretamente;
- ainda falta um `Save As` para arquivo novo e boot do servidor com essa copia;
- ainda falta localizar Targuna e extrair a area.

## Status de Targuna

`PARTIALLY_READY`

O conteudo server-side e os 18 itens continuam prontos, mas o mapa real ainda esta bloqueado por falta de fragmento OTBM validado.

## Proxima Acao Segura

1. Abrir o RME4 v4.0 manualmente na sandbox.
2. Confirmar visualmente que o mapa global atual carrega com tiles/itens/houses/spawns.
3. Usar `Save As` para novo arquivo descartavel.
4. Validar boot do servidor de teste com o arquivo salvo.
5. Abrir o mapa upstream global.
6. Localizar Targuna no bounding box `x=31920..33550`, `y=31880..32760`, `z=6..12`.
7. Copiar/exportar somente a area necessaria.
8. Gerar `MapPatches/Targuna/map-fragment.otbm`.
9. Executar o Remastered Map Patch Pipeline.

Nenhuma promocao ao runtime deve ocorrer antes desses passos.

## Round-trip real - 2026-07-15

Teste executado somente em sandbox:

- mapa: `UpstreamTesting/OTBMTooling/RME4/RoundTripSets/current-crystal-rt-real/world.otbm`
- XMLs companheiros preservados com basename `world-*`
- stubs Lua minimos gerados em `UpstreamTesting/OTBMTooling/RME4/CreatureStubs/current-crystal/`
- cobertura dos stubs: 181 monstros e 28 NPCs

Resultado:

| Verificacao | Resultado | Observacao |
| --- | --- | --- |
| Abrir copia descartavel do mapa atual | PASS | janela `world.otbm - Canary's Map Editor` |
| Carregar assets 15.24 | PASS | `Client/package.json`, `catalog-content.json`, `appearances-*.dat` e sprites carregados |
| Carregar spawns/NPCs sem prompt critico | PASS com stubs | diretorios Lua completos do projeto deixaram o RME sem janela principal; stubs minimos foram usados |
| Validacao visual de area ocupada | PASS | area `x=388 y=419 z=6` renderizou tiles, luz, objetos e marcadores |
| Save As para novo OTBM | PASS | `world-roundtrip-rme4.otbm` criado |
| Reabrir OTBM salvo | PASS | janela `world-roundtrip-rme4.otbm - Canary's Map Editor` |
| Validacao visual apos reabrir | PASS | area `x=387 y=419 z=6` renderizada corretamente |
| Modificacao minima de tile | NOT_DONE | edicao automatizada de tile foi considerada arriscada sem comando/script confiavel |
| XMLs auxiliares no Save As | PARTIAL | o OTBM salvo continuou usando os XMLs externos carregados; nao foram criados XMLs com basename `world-roundtrip-rme4-*` |

Hashes:

| Arquivo | Tamanho | SHA-256 |
| --- | ---: | --- |
| `world.otbm` original da copia | 11,373,094 | `3021FA0CD15A0A34CB805571F783DA0F852441A6BBE98FED99AD277787710817` |
| `world-roundtrip-rme4.otbm` salvo | 11,373,094 | `D1C8C204B7550BA6D7740317613CE0ECF9FA781AD65D262800D4868AAACC98A9` |

Estrutura externa preservada na copia:

| Arquivo | Elementos XML |
| --- | ---: |
| `world-house.xml` | 144 |
| `world-monster.xml` | 7,157 |
| `world-npc.xml` | 218 |
| `world-zones.xml` | 1 |

## Mapa upstream - 2026-07-15

O arquivo upstream `Upstream/CrystalLatest/data-global/world/world.otbm` copiado para sandbox possui assinatura gzip (`1F 8B`) apesar da extensao `.otbm`.

Resultado:

| Verificacao | Resultado | Observacao |
| --- | --- | --- |
| Abrir upstream `.otbm` original no RME | FAIL | RME retornou "not a valid OTBM file or it does not exist" |
| Hash da copia upstream | PASS | igual ao inventario: `3BD40D14FEFEC41F24C4B3AE879E420BE1A831EF55B95DCBEC721E587A09B034` |
| Descompactar copia gzip em sandbox | PASS | gerado `world-decompressed.otbm` |
| Abrir `world-decompressed.otbm` no RME | PASS | janela `world-decompressed.otbm - Canary's Map Editor` |
| Validar visualmente bounding box inicial | PASS parcial | `x=31920 y=31880 z=6` cai em mar/borda da regiao |
| Localizar hub por NPCs | PASS | NPCs Targuna localizados visualmente em `x~31942..31973 y~31888..31920 z=6..7` |

Arquivo descompactado:

| Arquivo | Tamanho | SHA-256 |
| --- | ---: | --- |
| `world-decompressed.otbm` | 186,660,172 | `4B2099F38DF05D4BE68D1BA1265754E9FD6DA09742025D92644FA4B1A12EB120` |

Coordenadas confirmadas por `world-npc.xml`:

| NPC | Coordenada |
| --- | --- |
| Captain Indigo | `31973,31892,6` |
| Camilla | `31942,31902,6` |
| Emiliana | `31960,31901,6` e `32412,32687,12` |
| Leonora | `31951,31888,7` |
| Sterling | `31928,31903,7` |
| Aurelia | `31955,31916,7` |
| Lizzie | `31941,31920,7` |
| Morla | `33514,32748,8` |

## Classificacao atualizada

RME v4.0 permanece:

`CONDITIONALLY_COMPATIBLE`

Motivo:

- round-trip real do mapa atual em sandbox passou para abertura, Save As e reabertura;
- o mapa upstream abre corretamente quando a copia gzipada e descompactada;
- Targuna foi localizada visualmente;
- ainda nao ha fluxo automatizado seguro para crop/export de uma selecao OTBM;
- a edicao minima de tile nao foi executada porque a automacao de GUI seria arriscada;
- o servidor de teste ainda nao foi iniciado com o OTBM reserializado.

Targuna permanece:

`PARTIALLY_READY`

`MapPatches/Targuna/map-fragment.otbm` foi criado posteriormente por ferramenta propria, mas ainda nao foi validado visualmente no RME4 nem mesclado em mapa sandbox.

## Extracao de Targuna - 2026-07-15

Objetivo da etapa: criar `MapPatches/Targuna/map-fragment.otbm` e aplicar em sandbox.

Resultado: bloqueio de crop/export do RME4 confirmado. A extracao foi resolvida posteriormente com ferramenta propria auditavel em `Tools/OTBMFragmentExtractor/`.

Achados novos:

- O codigo do RME4 confirma `Import Map` com offset X/Y/Z e opcoes de importacao de houses, monster spawns e NPC spawns.
- `CopyBuffer` preserva tiles selecionados, itens selecionados, monstros selecionados, monster spawns selecionados, NPCs e NPC spawns selecionados.
- A API Lua permite selecionar tiles por coordenada usando `app.map:getTile(x,y,z)` e `app.selection:add(tile)`.
- A API Lua permite `app.copy()` e `app.paste()`.
- A API Lua nao expoe salvar arquivo, criar mapa novo, abrir arquivo ou exportar selecao como OTBM.
- Nao ha CLI documentada no pacote para crop/export de OTBM.

Classificacao revisada do RME:

`CONDITIONALLY_COMPATIBLE`

Motivo: o RME4 e adequado para abrir, visualizar, salvar e importar mapas em sandbox, mas ainda nao fornece um caminho automatizavel e auditavel para extrair somente Targuna como fragmento OTBM.

## Complemento - Extractor Proprio 2026-07-15

O bloqueio de crop/export do RME4 foi contornado parcialmente com uma ferramenta propria:

- `Tools/OTBMFragmentExtractor/Extract-OTBMFragment.ps1`
- `Tools/OTBMFragmentExtractor/OTBMFragmentExtractor.cs`

Resultado:

- o fragmento real `MapPatches/Targuna/map-fragment.otbm` foi criado;
- o fragmento valida pelo parser proprio;
- o fragmento ainda nao foi aberto visualmente no RME4;
- ainda nao houve round-trip RME4 do fragmento;
- ainda nao houve merge do fragmento no mapa sandbox.

Classificacao revisada de Targuna:

`PARTIALLY_READY`

Motivo: metadados, scripts, XMLs e fragmento OTBM candidato validam pelo tooling proprio, mas o servidor de teste nao foi iniciado com mapa patchado.
