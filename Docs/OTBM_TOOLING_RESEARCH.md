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

## Decisao

Existe caminho seguro para gerar `map-fragment.otbm`, mas ele ainda depende de uma etapa manual/controlada:

- obter RME de fonte confiavel;
- validar round-trip;
- confirmar compatibilidade com assets 15.24;
- gerar fragmento em sandbox;
- validar spawns/NPCs/teleports/quest positions com offset.
