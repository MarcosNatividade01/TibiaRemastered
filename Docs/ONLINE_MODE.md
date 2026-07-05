# Online Mode

## Estado atual

O modo online atual e uma base assistida, nao uma plataforma online completa.

## Preservacao do Offline

O botao `Jogar Offline` continua usando o mesmo fluxo local:

```text
Start-TrmGame
```

O auto-update antes do Play continua desligado por padrao:

```json
"autoUpdateBeforePlay": false
```

## Dados online

Dados de preferencia online sao salvos em:

```text
UserData/Online/
```

Eles nao substituem `UserData/Database/`.

## Hospedagem

O host assistido inicia o servidor local e mostra:

- status;
- nome do mundo;
- jogadores conectados;
- IP local;
- IP publico quando disponivel;
- porta;
- convite oficial;
- teste da porta local;
- caminho do relatorio de diagnostico.

## Entrada em mundo

O Launcher aceita convite completo ou IP/endereco e porta. Ele testa a conexao, salva o historico e abre o cliente somente quando o host responde.

Historico:

```text
UserData/Online/host-assisted.json
```

## Teste multiplayer

Checklist manual:

1. Host clica em `Hospedar Mundo`.
2. Host clica em `Iniciar Mundo`.
3. Host clica em `Copiar Convite`.
4. Convidado abre `Entrar em Mundo`.
5. Convidado cola o convite.
6. Convidado clica em `Usar Convite`.
7. Convidado clica em `Testar Conexao`.
8. Se passar, convidado clica em `Entrar`.

Guia completo: `Docs/MULTIPLAYER_TEST_GUIDE.md`.

O endpoint local do client e configurado para apontar para o host informado. Ao voltar para `Jogar Offline`, o endpoint e recolocado em `127.0.0.1:7172`.

## Validacao de versao

Se o host responder em `/version.json`, a versao e comparada com o `version.json` local. Versoes diferentes bloqueiam a conexao.

Se a versao do host nao estiver disponivel, o Launcher registra aviso e continua assumindo compatibilidade local.

## Limitacoes conhecidas

- Nao instala VPN.
- Nao configura roteador.
- Nao contorna CGNAT.
- Nao cria servidor dedicado.
- Internet externa pode exigir port forwarding e firewall liberado.
