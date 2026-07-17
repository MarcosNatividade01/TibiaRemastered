# OTBM Tooling Research

## Objetivo

Encontrar uma ferramenta confiavel para abrir, recortar, deslocar e validar fragmentos OTBM antes de gerar `MapPatches/Targuna/map-fragment.otbm`.

Nenhuma ferramenta foi instalada nesta etapa.

## Ferramenta Recomendada

| Campo | Resultado |
| --- | --- |
| Ferramenta | Remere's Map Editor / RME |
| Fonte primaria | `https://github.com/hampusborgos/rme` |
| Site oficial indicado pelo README | `https://remeresmapeditor.com/` |
| Ultima release observada | `v3.7` |
| Licenca | Verificar no repositorio antes de redistribuir binarios |
| Uso recomendado | Ferramenta local, manual/controlada, em copia sandbox do mapa |

Evidencias:

- O repositorio `hampusborgos/rme` se descreve como Remere's Map Editor e como editor de mapa para OpenTibia.
- O README aponta releases oficiais no site `remeresmapeditor.com`.
- A pagina de releases do GitHub mostra `v3.7` como latest e fornece checksums SHA-256 para builds Windows.

Fontes:

- https://github.com/hampusborgos/rme
- https://github.com/hampusborgos/rme/releases
- https://remeresmapeditor.com/

## Alternativa

| Campo | Resultado |
| --- | --- |
| Ferramenta | OTAcademy/RME |
| Fonte | `https://github.com/OTAcademy/RME` |
| Tipo | fork de RME |
| Uso recomendado | Avaliar somente se RME upstream nao abrir corretamente os mapas atuais |

Fonte:

- https://github.com/OTAcademy/RME

## Compatibilidade Esperada

| Capacidade | RME | Observacao |
| --- | --- | --- |
| abrir OTBM | Provavel | Deve ser confirmado com `Server/data-global/world/world.otbm` em copia |
| abrir mapa upstream | Provavel | Deve ser confirmado com `Upstream/CrystalLatest/data-global/world/world.otbm` em copia |
| crop/copiar area | Sim, via selecao/copiar/colar | Precisa procedimento manual documentado |
| deslocar coordenadas | Sim, via colar em nova posicao | Validar offsets de spawns/NPCs fora do OTBM separadamente |
| salvar | Sim | Exige round-trip antes de Targuna |
| merge | Parcial/manual | Nao usar para substituir mapa inteiro |
| automacao CLI | Nao confirmado | Tratar como ferramenta interativa |

## Riscos

- RME pode nao reconhecer corretamente assets/client 15.24 modernos sem dados compativeis.
- Salvar OTBM com versao errada pode corromper ou rebaixar metadados.
- Copiar area sem ajustar spawns, NPCs, teleports e quest positions deixa referencias em coordenadas upstream.
- Builds binarios devem ser baixados apenas de fonte oficial/confiavel e conferidos por SHA-256.

## Procedimento Seguro Recomendado

1. Baixar RME somente de `github.com/hampusborgos/rme/releases` ou do site oficial indicado pelo projeto.
2. Conferir SHA-256 do binario baixado contra o checksum publicado.
3. Abrir copia descartavel de `Server/data-global/world/world.otbm`.
4. Salvar sem alteracoes como round-trip.
5. Reabrir o arquivo salvo.
6. Validar boot do servidor com a copia.
7. Repetir com copia do mapa upstream.
8. Somente depois selecionar a area Targuna upstream e exportar/colar em coordenadas sandbox.
9. Nunca salvar diretamente sobre `Server/data-global/world/world.otbm`.

## Validacao RME v3.7 - 2026-07-15

Fonte usada:

- `https://github.com/hampusborgos/rme/releases/download/v3.7/RME_x64.zip`

Hash SHA-256 calculado localmente:

- `A434D80DAD0ED833E3F537C3FBE20F4455FD785A08A1797ED047B3A040C84D9F`

Resultado:

- O hash calculado confere com o checksum publicado na release oficial `v3.7`.
- O pacote foi extraido apenas para inspecao.
- O executavel nao foi usado para abrir ou salvar mapas.
- `data/clients.xml` do RME v3.7 lista clientes ate `10.100`.
- Nao ha suporte declarado para `15.24` ou `15.25`.

Decisao:

- RME v3.7 foi validado quanto a origem e hash.
- RME v3.7 nao foi validado quanto a compatibilidade com o mapa atual 15.24.
- Nao e seguro executar round-trip no `world.otbm` atual com essa versao.

## Validacao OTAcademy/RME 4.2.0 - 2026-07-15

Fonte inspecionada:

- `https://github.com/OTAcademy/RME/releases`
- asset `release_420_files.zip`

Hash SHA-256 calculado localmente:

- `0CDA57E0DD597A08FF066B5B00D98A39FAEA4557AF623474B5CCB4BDFB2AAB83`

Observacao:

- Nao foi localizado checksum oficial publicado na release para comparar com o hash local.
- O pacote foi extraido apenas para inspecao.
- Nenhum executavel foi executado.
- `data/clients.xml` lista clientes ate `13.30`.
- Nao ha suporte declarado para `15.24` ou `15.25`.

Decisao:

- OTAcademy/RME 4.2.0 nao deve ser usado automaticamente para salvar mapas 15.24 neste projeto sem uma etapa adicional de compatibilidade.
- A falta de checksum publicado tambem impede tratar o binario como baseline verificavel nesta etapa.

## Decisao Atual

OpenTibiaBR RME v4.0 reabriu a investigacao como candidato condicional, mas ainda nao existe caminho totalmente validado para gerar `MapPatches/Targuna/map-fragment.otbm` automaticamente.

O fluxo deve permanecer bloqueado ate que exista uma das condicoes abaixo:

- ferramenta OTBM com suporte explicito ao formato/client 15.24 usado pelo projeto;
- build confiavel do RME com dados 15.24/15.25 compativeis e checksum verificavel;
- parser/exporter OTBM open-source auditavel, executado primeiro em copias descartaveis;
- procedimento manual com RME somente depois de round-trip aprovado em copia e boot do servidor de teste.

Enquanto isso:

- nao abrir/salvar `Server/data-global/world/world.otbm` com RME v3.7;
- nao abrir/salvar o mapa upstream com RME v3.7 para gerar conteudo final;
- nao criar `map-fragment.otbm` por conversao incerta;
- nao promover Targuna ao runtime.

## Validacao OpenTibiaBR RME v4.0 - 2026-07-15

Fonte oficial:

- repositorio: `https://github.com/opentibiabr/remeres-map-editor`
- release: `https://github.com/opentibiabr/remeres-map-editor/releases/tag/v4.0`
- tag/commit: `v4.0` -> `2a28ef8b2c96ac84945a49088cf0dd0b85933640`
- pacote Windows: `canary-map-editor-v4.0-windows.zip`

Hash SHA-256:

- esperado pela release/API GitHub: `3b237c1abe32b5ff2286e29fb1db97af3fd1b18df44ec99d49ad6854d825245b`
- calculado localmente: `3B237C1ABE32B5FF2286E29FB1DB97AF3FD1B18DF44EC99D49AD6854D825245B`

Licenca:

- cabecalhos do codigo e `LICENSE.rtf` indicam GPL, versao 3 ou posterior.

Auditoria tecnica:

- `data/clients.xml` define um cliente generico `Client 11` usando `data_directory="materials"` e OTBM `version="3"`.
- O codigo contem carregador moderno em `source/client_assets.cpp`, com `ClientAssets::loadAppearanceProtobuf`.
- O carregador exige uma pasta de client contendo `package.json` e `assets/catalog-content.json`.
- O projeto Tibia Remastered possui essa estrutura em `Client/package.json` e `Client/assets/catalog-content.json`.
- O catalogo ativo do client 15.24 aponta para `appearances-ee339aff5b3cb38289287ff25cec261d8d2790e6e146938d4dfd9f138b065980.dat` e sprites `*.bmp.lzma`.
- Foi criado `rme.cfg` local somente na sandbox do RME4 apontando para `Client` com versao `15.24.eb0021`.

Testes executados:

| Teste | Resultado | Observacao |
| --- | --- | --- |
| download oficial | passou | asset da release oficial |
| SHA-256 | passou | hash local igual ao digest da release |
| extracao sandbox | passou | em `UpstreamTesting/OTBMTooling/RME4/` |
| config assets 15.24 | passou parcialmente | `ASSETS_DATA_DIRS` com path do `Client` foi preservado usando barras `/` |
| abrir copia `data-crystal/world.otbm` | passou parcialmente | processo ficou estavel por 25s; sem prova visual estruturada |
| round-trip por `Ctrl+S` em copia crystal | inconclusivo | hash permaneceu identico; pode indicar save sem mudanca ou comando sem reserializacao |
| abrir copia `data-global/world.otbm` atual | passou parcialmente | processo ficou estavel por 60s |
| abrir copia upstream `data-global/world.otbm` | passou parcialmente | processo ficou estavel por 60s |
| UIAutomation | falhou | COM retornou `RPC_E_SERVERFAULT`; nao foi usado para decisao de mapa |
| extracao Targuna | nao executada | depende de validacao visual/manual ou automacao confiavel |

Classificacao:

- RME v4.0: `CONDITIONALLY_COMPATIBLE`.
- Motivo: a ferramenta e verificavel, reconhece a estrutura de assets 15.24 do projeto e nao crashou em abertura controlada de copias, mas ainda falta prova de carregamento completo, round-trip reserializado e workflow confiavel de crop/export.

### Atualizacao de teste conclusivo parcial - 2026-07-15

Novos achados:

- O RME v4.0 abriu uma copia descartavel do mapa atual `data-crystal/world.otbm`.
- Foi necessario manter basename `world.otbm` junto de `world-house.xml`, `world-monster.xml`, `world-npc.xml` e `world-zones.xml`; o RME deriva nomes auxiliares do basename.
- Diretórios Lua completos do projeto fizeram o RME abrir sem janela principal utilizavel. A alternativa segura foi gerar stubs Lua minimos somente em `UpstreamTesting/OTBMTooling/RME4/CreatureStubs/`.
- O round-trip por `Save As` criou `world-roundtrip-rme4.otbm`, que reabriu e renderizou area ocupada.
- O upstream `data-global/world/world.otbm` esta gzipado apesar da extensao `.otbm`; o RME rejeita esse arquivo direto.
- A descompactacao em copia sandbox gerou `world-decompressed.otbm`, que o RME abriu corretamente.
- Targuna foi localizada visualmente no upstream descompactado.

Status revisado:

| Capacidade | Resultado |
| --- | --- |
| abrir mapa atual em copia | PASS |
| Save As mapa atual para novo OTBM | PASS |
| reabrir OTBM salvo | PASS |
| abrir upstream `.otbm` original | FAIL, arquivo gzipado |
| abrir upstream descompactado | PASS |
| localizar Targuna | PASS |
| crop/export automatizado de fragmento | BLOQUEADO |
| iniciar servidor de teste com mapa reserializado | NOT_RUN |

Decisao revisada:

- RME v4.0 permanece `CONDITIONALLY_COMPATIBLE`.
- Ja existe caminho seguro para leitura e reabertura em sandbox.
- Ainda nao existe caminho seguro e automatizavel para gerar `MapPatches/Targuna/map-fragment.otbm`.
- A proxima etapa deve ser um procedimento manual controlado no RME ou desenvolvimento de ferramenta propria para crop/export OTBM, sempre em copia sandbox.

### Extracao/Crop - 2026-07-15

Inspecao adicional do codigo do RME4:

| Capacidade | Evidencia | Resultado |
| --- | --- | --- |
| Importar mapa com offset | `ImportMapWindow`, `Editor::importMap` | existe |
| Merge de monster spawns | `Editor::importMap` | existe |
| Merge de NPC spawns | `Editor::importMap` | existe |
| Merge/insert de houses | `Editor::importMap` | existe |
| Copy/paste de selecao | `CopyBuffer::copy`, `CopyBuffer::paste` | existe |
| Selecionar tiles por Lua | `app.map:getTile`, `app.selection:add` | existe |
| Copiar/colar via Lua | `app.copy`, `app.paste` | existe |
| Criar novo mapa por Lua | nao encontrado | ausente |
| Abrir/salvar OTBM por Lua | nao encontrado | ausente |
| Exportar selecao como OTBM | nao encontrado | ausente |
| CLI de crop/export OTBM | nao encontrado | ausente |

Decisao de metodo:

- O RME4 e o metodo preferido para round-trip, validacao visual e importacao de mapa com offset.
- O RME4 nao fornece, pela auditoria local atual, um crop/export OTBM automatizado por bounding box.
- Uma ferramenta propria de crop OTBM continua possivel, mas nao deve ser criada apressadamente porque precisa preservar blocos OTBM, tile areas, attributes, houses, spawns, NPCs, zones e metadados.
- Importar o mapa upstream inteiro com offset foi rejeitado porque violaria o escopo de fragmento minimo.

Status:

- RME4: `CONDITIONALLY_COMPATIBLE`.
- Targuna: `PARTIALLY_READY`.
- Proximo passo seguro: criar um procedimento manual assistido no RME4 ou uma extensao/tooling auditavel que adicione export de selecao OTBM, testado primeiro em mapa pequeno descartavel.
