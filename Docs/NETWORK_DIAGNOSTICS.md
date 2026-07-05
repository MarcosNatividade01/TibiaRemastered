# Network Diagnostics

## Objetivo

Os diagnosticos online ajudam a entender falhas de LAN/internet sem alterar o modo Offline.

Relatorios sao gerados em:

```text
Logs/OnlineDiagnostics/
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

## Resultado

Cada relatorio contem:

- `status`: `passed` ou `warning`;
- `targetReachable`: indica se o host respondeu na porta do servidor;
- `serverPort`: processos usando a porta do servidor;
- `webPortUsage`: processos usando a porta web local;
- `version`: resultado da comparacao de versao;
- `warnings`: avisos acionaveis;
- `reportPath`: caminho do arquivo gerado.

## Limitacoes

O Launcher nao consegue confirmar sozinho todos os cenarios de rede externa. CGNAT, regras do roteador, firewall corporativo e bloqueios do provedor podem exigir validacao manual.

