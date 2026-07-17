# OTBM Fragment Extractor

## Objetivo

`Tools/OTBMFragmentExtractor` extrai fragmentos OTBM por coordenadas, sem alterar o mapa oficial.

Uso principal nesta etapa:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\OTBMFragmentExtractor\Extract-OTBMFragment.ps1 `
  -Input Upstream\CrystalLatest\data-global\world\world.otbm `
  -Output MapPatches\Targuna\map-fragment.otbm `
  -BoundsFile MapPatches\Targuna\targuna-fragment.bounds.csv `
  -Report UpstreamTesting\OTBMFragmentExtractor\targuna-fragment-extract.json
```

## Arquitetura

- `Extract-OTBMFragment.ps1`: wrapper PowerShell. Compila o extractor C# em `UpstreamTesting/OTBMFragmentExtractor/bin/`.
- `OTBMFragmentExtractor.cs`: parser/serializer C# auditavel, sem dependencia externa.
- O binario gerado nao e versionado e fica apenas em sandbox.

O wrapper compila para um nome versionado por timestamp do fonte para evitar falha de sobrescrita quando o Windows mantem lock temporario no executavel anterior.

## Entradas

Modos suportados:

- caixa unica: `-XMin -XMax -YMin -YMax -ZMin -ZMax`;
- multiplas caixas: `-BoundsFile`;
- `-DryRun`: nao escreve OTBM;
- `-ValidateOnly`: valida leitura sem extrair;
- `-Margin`: expande X/Y de cada caixa;
- `-Report`: grava JSON com estatisticas.

Formato de `BoundsFile`:

```text
# xMin,xMax,yMin,yMax,zMin,zMax
31915,31985,31875,31935,6,8
33475,33560,32680,32760,7,8
32390,32430,32670,32700,12,12
```

## Politica de Seguranca

- Nao escreve em `Server/data-global/world/world.otbm`.
- Nao escreve em `Server/data-crystal/world/world.otbm`.
- Nao executa merge no mapa de runtime.
- Nao altera banco, client, protocolo ou core C++.
- Recusa gerar fragmento com zero tiles.
- Gera relatorio JSON para auditoria antes/depois.

## Resultado Targuna

Dry-run amplo original:

- `x=31920..33550 y=31880..32760 z=6..12`
- `5,788,347` tiles selecionados.
- Incluia muitas cidades e foi rejeitado como recorte final.

Dry-run composto aprovado:

- 3 caixas controladas.
- `23,035` tiles selecionados.
- `514` tile areas.
- floors: z6 `959`, z7 `11,297`, z8 `9,544`, z12 `1,235`.
- houses selecionadas: `3701`, `3702`.
- towns selecionadas: `Dawnport Tutorial`, `Targuna`.

Fragmento gerado:

- `MapPatches/Targuna/map-fragment.otbm`
- tamanho: `245,702` bytes
- SHA-256: `B617D0E95C7F5F66015FC150086E49C95BAF9FCD33E69E1D6514CEF035171202`

## Limitacoes Atuais

- Nao faz merge OTBM em outro mapa.
- Nao reloca coordenadas.
- Nao reescreve teleport destinations.
- Nao filtra/gera `world-monster.xml`, `world-npc.xml`, `world-house.xml` ou `world-zones.xml`.
- Preserva atributos e filhos de tile de forma bruta quando nao precisa interpreta-los.
- A validacao visual no RME4 ainda precisa ser feita manualmente.
- O servidor de teste ainda nao foi iniciado com mapa patchado real, porque o pipeline atual nao insere o fragmento no mapa sandbox.
