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
9. permite copiar convite oficial;
10. permite abrir logs;
11. testa a porta local do servidor;
12. gera relatorio em `Logs/OnlineDiagnostics/`;
13. permite parar o processo do servidor.

## Convite

Formato oficial atual:

```text
Tibia Remastered Convite
Mundo: FazendoTibia
IP: 192.168.0.10
Porta: 7172
Versao: 0.1.0
Instrucao: no outro computador, abra o Launcher, clique em Entrar em Mundo, cole este convite e clique em Usar Convite.
```

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

O ultimo host, porta, mundo, versao e data de conexao ficam salvos em:

```text
UserData/Online/host-assisted.json
```

Antes de abrir o client, o Launcher testa o host informado. Se o host nao responder, o client nao e aberto e o diagnostico informa o motivo provavel.

Quando o host disponibiliza `version.json`, a versao local e comparada antes da conexao.

## Diagnostico

O Launcher possui botao `Diagnostico` na tela principal. Ele gera relatorios em:

```text
Logs/OnlineDiagnostics/
```

Use essa tela para testar host, porta, versao e mensagens de erro antes de abrir o client.

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

## Limitacoes

Sem VPN, servidor dedicado ou abertura de portas, conexoes pela internet podem nao funcionar dependendo de NAT, CGNAT, roteador e firewall.

Modo LAN tende a funcionar com mais facilidade.

Conexao externa pode exigir redirecionamento das portas do servidor no roteador.
