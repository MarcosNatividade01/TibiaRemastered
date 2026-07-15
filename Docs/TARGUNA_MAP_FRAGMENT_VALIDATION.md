# Targuna Map Fragment Validation

## Objetivo

Gerar `MapPatches/Targuna/map-fragment.otbm` real e seguro para Targuna/Aragonia, sem substituir `world.otbm` oficial.

## Resultado

`map-fragment.otbm` nao foi criado nesta etapa.

Motivo: nao ha ferramenta OTBM confiavel disponivel no ambiente atual para recortar somente a area de Targuna/Aragonia do mapa upstream.

## Ferramenta

Ferramenta usada para gerar fragmento:

- nenhuma.

Ferramentas verificadas:

- `Tools/MapPatch/Invoke-MapPatch.ps1`: valida e aplica patches, mas nao interpreta nem recorta OTBM.
- `Tools/MapPatch/Test-MapPatchPipeline.ps1`: testa o pipeline, mas nao cria OTBM.
- busca local por Remere/RME em `C:\Users\marco\Downloads`: nenhum executavel encontrado.

O projeto referencia Remere's Map Editor como ferramenta de edicao de mapa, mas ela nao esta instalada ou embutida no repositorio.

## Compatibilidade OTBM

Arquivos OTBM relevantes:

- runtime oficial: `Server/data-global/world/world.otbm`
- runtime crystal: `Server/data-crystal/world/world.otbm`
- upstream global: `Upstream/CrystalLatest/data-global/world/world.otbm`
- upstream crystal: `Upstream/CrystalLatest/data-crystal/world/world.otbm`

Como nao ha parser/editor OTBM confiavel disponivel, a versao interna OTBM nao foi regravada nem convertida. Nenhum teste de leitura/escrita de OTBM foi executado para evitar falso positivo ou corrupcao silenciosa.

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
| Presenca de ferramenta OTBM | Falhou | Nenhum RME/extrator local encontrado |
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

## Proxima Acao Segura

1. Instalar ou fornecer Remere's Map Editor compativel com o mapa atual, ou outro parser/exporter OTBM confiavel.
2. Abrir somente copia sandbox do upstream `world.otbm`.
3. Exportar apenas a area `x=31920..33550`, `y=31880..32760`, `z=6..12`.
4. Salvar como `MapPatches/Targuna/map-fragment.otbm`.
5. Validar todos os tiles e item IDs contra o client/runtime atual.
6. Aplicar em `UpstreamTesting/MapPatches/Targuna/`.
7. Somente depois considerar promocao parcial.
