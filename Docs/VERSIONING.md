# Versionamento Oficial

## Formato

Versoes estaveis usam SemVer simples:

```text
MAJOR.MINOR.PATCH
```

Exemplos:

```text
0.1.3
0.1.4
0.2.0
```

## Release Candidate

Release Candidates usam sufixo `-rcN`:

```text
0.1.3-rc1
0.1.3-rc2
```

Use RC quando a versao ainda esta em validacao ou possui bugs conhecidos.

Enquanto existir bug conhecido, a versao nao pode virar estavel.

## Regras de incremento

### PATCH

Incrementar PATCH para:

- correcao de bug;
- ajuste de Launcher;
- ajuste de Host Assistido;
- correcao de publicador;
- documentacao operacional relevante.

Exemplo:

```text
0.1.3 -> 0.1.4
```

### MINOR

Incrementar MINOR para:

- nova funcionalidade relevante;
- novo modulo;
- mudanca maior no fluxo de jogo;
- mudanca de compatibilidade controlada.

Exemplo:

```text
0.1.4 -> 0.2.0
```

### MAJOR

Incrementar MAJOR para:

- quebra de compatibilidade;
- troca estrutural de runtime;
- mudanca que exige migracao manual.

## Arquivos de versao

Durante desenvolvimento local:

- nao alterar `version.json`;
- nao alterar `manifest.json`.

Durante release oficial:

- `Publish.ps1` atualiza `version.json`;
- `Publish.ps1` gera `manifest.json`;
- `Publish.ps1` atualiza `CHANGELOG.md`.

Esses arquivos so mudam depois que a checklist oficial esta aprovada.

## Branch e versao

`develop` pode conter trabalho em andamento e RCs locais.

`main` deve conter apenas versoes estaveis como:

```text
0.1.3
```

Nao publique em `main` versoes como:

```text
0.1.3-dev
0.1.3-test
0.1.3-rc1
```

## Promocao de RC para release

Uma versao passa de RC para estavel quando:

1. todos os bugs conhecidos da RC foram corrigidos;
2. Launcher foi validado;
3. Offline foi validado;
4. Host Assistido foi validado em host e convidado;
5. checklist oficial foi aprovada;
6. aprovacao local foi registrada;
7. publicacao oficial foi executada.

Exemplo:

```text
0.1.3-rc2 -> 0.1.3
```
