# Launcher Guide

## Tela principal

O Launcher mostra apenas as acoes principais:

- `Jogar Offline`
- `Hospedar Mundo`
- `Entrar em Mundo`
- `Diagnostico`
- `Reparar Arquivos`
- `Configuracoes`
- `Ajuda`

Nenhuma opcao tecnica e obrigatoria para jogar.

## Jogar Offline

Inicia o banco local, o servidor local e o client local. Esse fluxo nao depende da internet.

## Hospedar Mundo

Inicia o servidor local e mostra:

- status do servidor;
- nome do mundo;
- jogadores conectados;
- IP local;
- porta;
- versao;
- convite completo para copiar.

Botoes:

- `Iniciar Mundo`
- `Parar Mundo`
- `Copiar Convite`
- `Abrir Logs`

## Convite oficial

Formato atual:

```text
Tibia Remastered Convite
Mundo: FazendoTibia
IP: 192.168.0.10
Porta: 7172
Versao: 0.1.0
```

O botao `Copiar Convite` copia apenas esse bloco.

## Entrar em Mundo

O jogador pode:

- colar o convite completo e clicar em `Usar Convite`;
- ou preencher IP e porta manualmente.

Antes de abrir o client, o Launcher testa a conexao e mostra uma mensagem clara caso o servidor nao responda.

## Diagnostico

Permite testar:

- diagnostico do host local;
- conexao com IP e porta informados;
- abertura dos relatorios em `Logs/OnlineDiagnostics/`.

## Reparar Arquivos

Executa reparo/update dos arquivos do projeto sem alterar `UserData`, `Logs` ou `Backup`.

## Historico

O historico fica em:

```text
UserData/Online/host-assisted.json
```

Ele salva ultimos mundos, host, porta, versao e data da ultima conexao.

## Ajuda

A secao `Ajuda` explica Offline, Host Assistido, LAN, internet e limitacoes conhecidas.
