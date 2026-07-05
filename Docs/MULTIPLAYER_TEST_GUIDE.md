# Multiplayer Test Guide

## Objetivo

Validar o fluxo LAN basico do Host Assistido usando apenas o Launcher.

## Computador Host

1. Abra o Launcher.
2. Clique em `Hospedar Mundo`.
3. Clique em `Iniciar Mundo`.
4. Aguarde o status `Servidor online`.
5. Confira IP local, porta e versao.
6. Clique em `Copiar Convite`.
7. Envie o convite para o outro computador.

## Computador Convidado

1. Abra o Launcher.
2. Clique em `Entrar em Mundo`.
3. Cole o convite no campo `Colar convite`.
4. Clique em `Usar Convite`.
5. Confira se IP, porta e versao foram preenchidos.
6. Clique em `Testar Conexao`.
7. Se aparecer `Servidor encontrado`, clique em `Entrar`.
8. Confirme se o client abre apontando para o host.

## Convite esperado

```text
Tibia Remastered Convite
Mundo: FazendoTibia
IP: 192.168.0.10
Porta: 7172
Versao: 0.1.0
Instrucao: no outro computador, abra o Launcher, clique em Entrar em Mundo, cole este convite e clique em Usar Convite.
```

## Se falhar

- Confirme se os dois computadores estao na mesma rede.
- Confirme se o Windows Firewall liberou o servidor no host.
- Use o IP local mostrado no host, nao `127.0.0.1`.
- Confira se a porta e `7172`.
- Abra `Diagnostico` no Launcher e teste o host.
- Veja relatorios em `Logs/OnlineDiagnostics/`.

## Criterio de aprovado

- Host inicia mundo.
- Convite e copiado.
- Convidado cola convite.
- IP e porta sao preenchidos.
- Teste de conexao encontra o servidor.
- Client do convidado abre.
- `Jogar Offline` continua funcionando depois do teste.

