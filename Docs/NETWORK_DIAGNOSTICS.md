# Network Diagnostics

## Objetivo

Os diagnosticos online ajudam a entender falhas de LAN/internet sem alterar o modo Offline.

Relatorios sao gerados em:

```text
Logs/OnlineDiagnostics/
Logs/ConnectionTests/
```

## Itens verificados

- IP local detectado.
- IP publico, quando disponivel.
- porta do servidor em uso.
- porta web/local em uso.
- alcance TCP do host informado.
- versao local em `version.json`.
- versao do host em `http://HOST:WEB_PORT/version.json`, quando disponivel.
- avisos sobre firewall, NAT e CGNAT quando os sinais indicam risco.

## Diagnostico Multiplayer do host

Ao hospedar mundo, o Launcher executa um diagnostico especifico para o host:

- confirma processo do servidor;
- confirma `7171` em LISTENING para login/status;
- confirma `7172` em LISTENING para game;
- confirma porta web `80` usada pelo endpoint de conta/login;
- testa `127.0.0.1`;
- testa o IPv4 LAN detectado;
- tenta validar o IP publico quando disponivel;
- verifica se o bind ficou somente em `127.0.0.1`;
- lista regras de Firewall do Windows para TCP `7171`, `7172` e `80`;
- registra relay como `unavailable` quando nao houver infraestrutura real configurada;
- marca CGNAT como suspeito quando nao for possivel confirmar acesso direto.

O botao `Liberar Firewall` abre um script administrativo que cria regras TCP de entrada para `7171`, `7172` e `80`. Se a elevacao UAC for negada, nenhuma regra e criada.

## Resultado

Cada relatorio contem:

- `status`: `passed` ou `warning`;
- `targetReachable`: indica se o host respondeu na porta do servidor;
- `serverPort`: processos usando a porta do servidor;
- `webPortUsage`: processos usando a porta web local;
- `version`: resultado da comparacao de versao;
- `warnings`: avisos acionaveis;
- `reportPath`: caminho do arquivo gerado.

Nos relatorios de conexao do convidado, `TCP=False` com timeout em IP publico indica que a Conexao Direta nao chegou ao host. Isso normalmente exige port forwarding/firewall/IPv4 publico ou um relay real. Aumentar timeout para `8000ms` melhora o diagnostico, mas nao abre porta fechada.

## Limitacoes

O Launcher nao consegue confirmar sozinho todos os cenarios de rede externa. CGNAT, regras do roteador, firewall corporativo e bloqueios do provedor podem exigir validacao manual.

Nesta versao nao ha relay reverso configurado. Portanto:

- `Conexao Direta` exige LAN ou internet com firewall/port forwarding/IPv4 publico;
- `Conexao por Relay` aparece como indisponivel ate existir uma infraestrutura de relay real.

