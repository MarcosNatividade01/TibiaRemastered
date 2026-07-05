# Workflow Oficial

## Visao geral

O fluxo oficial do Tibia Remastered e:

```text
Desenvolvimento
↓
Correcoes
↓
Testes
↓
Checklist
↓
Release Candidate
↓
Validacao
↓
Publicacao
↓
GitHub
```

## Branches

### main

`main` contem somente versoes estaveis aprovadas.

Regras:

- nao receber desenvolvimento diario;
- nao receber versao incompleta;
- nao receber bug conhecido de release;
- nao receber Host Assistido quebrado;
- receber apenas publicacoes feitas pelo fluxo oficial.

### develop

`develop` contem o desenvolvimento diario.

Regras:

- implementar funcionalidades;
- corrigir bugs;
- testar localmente;
- preparar Release Candidates;
- manter alteracoes fora de `main` ate aprovacao completa.

## Desenvolvimento local

Durante desenvolvimento:

1. Trabalhar em `develop` ou em uma branch local derivada de `develop`.
2. Implementar a mudanca.
3. Rodar testes locais.
4. Corrigir falhas.
5. Repetir ate todos os fluxos afetados funcionarem.

Nao atualizar `version.json` nem `manifest.json` nesta fase.

## Release Candidate

Quando uma versao parece pronta, ela pode ser tratada como Release Candidate, por exemplo:

```text
0.1.3-rc1
0.1.3-rc2
```

Enquanto houver bug conhecido, a versao continua como RC.

RC serve para validacao local e controle interno. Uma RC nao deve ser publicada como estavel em `main`.

## Validacao

Antes de publicar:

1. Abrir Launcher.
2. Testar Offline.
3. Testar Host Assistido no host.
4. Testar entrada do proprio host.
5. Testar convidado em outro computador; se isso nao estiver disponivel, registrar diagnostico online claro com IP do convite, host acessivel e versao compativel.
6. Testar convite.
7. Testar conexao.
8. Verificar logs de runtime.
9. Verificar Module Loader.
10. Verificar Feature Flags.
11. Confirmar que `UserData` e banco local nao foram sobrescritos.
12. Registrar aprovacao local em `Logs/QAReports/official-release-approval.json`.

## Publicacao

Publicar apenas com:

```text
Tools/Publish/Publish.bat
```

O publicador cancela automaticamente se:

- checklist oficial falhar;
- branch atual nao for `main`;
- aprovacao manual local estiver ausente;
- Host Assistido nao estiver aprovado;
- runtime ou validacoes falharem;
- arquivos proibidos aparecerem no Git status.

## Depois da publicacao

Apos push bem-sucedido:

- `main` representa a versao estavel publicada;
- `develop` pode continuar recebendo mudancas;
- qualquer nova correcao volta ao ciclo de desenvolvimento local.
