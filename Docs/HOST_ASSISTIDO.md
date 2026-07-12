# Host Assistido

## Objetivo

O Host Assistido e um modo online opcional do Launcher. Ele nao altera o modo Offline e nao move, apaga ou sobrescreve o banco local.

## Opcoes do Launcher

- `Jogar Offline`: mantem o fluxo atual.
- `Hospedar Mundo`: inicia servidor local e mostra mundo, jogadores, IP, porta e convite.
- `Entrar em Mundo`: aceita convite completo ou IP/porta manual, salva historico e abre o client.

## Hospedar Mundo

Ao clicar em `Hospedar Mundo`, o Launcher:

1. inicia o banco local se necessario;
2. inicia o servidor local;
3. verifica portas configuradas;
4. detecta IP local;
5. tenta detectar IP publico;
6. mostra nome do mundo;
7. mostra jogadores conectados;
8. mostra porta do servidor;
9. mostra a conexao local e o convite remoto em campos separados;
10. permite copiar e conferir no clipboard somente o convite oficial `mode=remote`;
11. permite abrir logs;
12. testa a porta local do servidor;
13. gera relatorios em `Logs/OnlineDiagnostics/` e `Logs/ConnectionTests/`;
14. permite parar o processo do servidor.

## Convite

Formato oficial atual:

```text
TIBIA_REMASTERED_INVITE
world=FazendoTibia
host=192.168.0.10
publicHost=177.192.12.76
port=7172
version=0.1.20-test
mode=remote
```

`Entrar no Meu Mundo` nao reutiliza esse convite. Ele constroi uma conexao separada com `host=127.0.0.1` e `mode=host-local`. O botao `Copiar Convite para Amigos` limpa um clipboard antigo quando o convite e invalido, grava apenas o bloco oficial acima e le o clipboard de volta para confirmar o conteudo.

O endpoint local do Launcher registra seu modo atual em:

```text
UserData/Runtime/portable-web-endpoint-state.json
```

Ao alternar entre Offline, Hospedar Mundo e Entrar em Mundo, o Launcher reinicia apenas o endpoint portatil quando o destino configurado muda.

## Entrar em Mundo

Campos:

- IP/endereco;
- porta.
- convite completo.

Ao carregar um convite, `Usar IP LAN` seleciona o campo `host` para computadores na mesma rede e `Usar IP Publico` seleciona `publicHost` para conexoes pela internet. `Testar Conexao`, `Entrar` e os logs usam exatamente o host selecionado e a mesma porta, sem conversao silenciosa para localhost.

O ultimo host, porta, mundo, versao e data de conexao ficam salvos em:

```text
UserData/Online/host-assisted.json
```

Antes de abrir o client, o Launcher testa o TCP direto no host e porta Tibia informados. Se essa porta nao responder, o client nao e aberto e o diagnostico informa o motivo provavel.

Quando o host disponibiliza `version.json`, a versao local e comparada antes da conexao. O endpoint web na porta 80 e apenas diagnostico secundario.

## Diagnostico

O Launcher possui botao `Diagnostico` na tela principal. Ele gera relatorios em:

```text
Logs/OnlineDiagnostics/
```

Use essa tela para testar host, porta Tibia, versao, modo e mensagens de erro antes de abrir o client.

## Separacao de dados

Estrutura reservada:

```text
UserData/
  Offline/
  Online/
  Shared/
```

O banco offline continua em `UserData/Database/` e nao e movido ou apagado pelo Host Assistido.

Relatorios online ficam em `Logs/OnlineDiagnostics/` e podem ser apagados sem impacto no save.
Eventos de geracao, parse, clipboard, TCP e abertura do client ficam em `Logs/ConnectionTests/`.

## Limitacoes

Sem VPN, servidor dedicado ou abertura de portas, conexoes pela internet podem nao funcionar dependendo de NAT, CGNAT, roteador e firewall.

Modo LAN tende a funcionar com mais facilidade.

Conexao externa pode exigir redirecionamento das portas do servidor no roteador.
