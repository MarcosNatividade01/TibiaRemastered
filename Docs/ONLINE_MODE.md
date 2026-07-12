# Online Mode

## Estado atual

O modo online atual usa Conexao Direta. Ele inicia o servidor local, gera convite remoto e valida portas/rede, mas ainda nao possui relay reverso hospedado.

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

O host inicia o servidor local e mostra:

- status;
- nome do mundo;
- jogadores conectados;
- IP local;
- IP publico somente para diagnostico/convite quando validado;
- porta de login `7171`;
- porta de game `7172`;
- porta web `80`;
- convite oficial;
- teste da porta local e LAN;
- teste do IP publico quando disponivel;
- estado do Firewall;
- relay indisponivel quando nao houver infraestrutura real;
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

## Modos de conexao

- `Conexao Direta LAN`: usa o IPv4 local do host, como `192.168.x.x`.
- `Conexao Direta Internet`: exige firewall liberado, port forwarding TCP `7171/7172` e IPv4 publico acessivel. `publicHost` so e publicado no convite quando o teste externo passa.
- `Conexao por Relay`: nao esta disponivel nesta versao porque nao ha servidor relay configurado.

## Limitacoes conhecidas

- Nao instala VPN.
- Nao configura roteador.
- Nao contorna CGNAT.
- Nao possui relay reverso ativo nesta versao.
- Nao cria servidor dedicado.
- Internet externa pode exigir port forwarding e firewall liberado.
