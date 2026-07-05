# LAN Test Guide

## Pre-requisitos

- As duas maquinas devem estar na mesma rede local.
- O host deve liberar o servidor no firewall do Windows.
- O convidado deve usar a mesma versao do projeto sempre que possivel.

## Host

1. Abra o Launcher.
2. Clique em `Hospedar Mundo`.
3. Copie o IP local e a porta exibidos.
4. Confirme que o diagnostico mostra `Host alvo acessivel: True` para o proprio host.

## Convidado

1. Abra o Launcher na outra maquina.
2. Clique em `Entrar em Mundo`.
3. Informe o IP local do host.
4. Informe a porta exibida pelo host, normalmente `7172`.
5. Clique em `Testar Conexao`.
6. Se o teste passar, clique em `Conectar`.

## Falhas comuns

- Host inacessivel: IP incorreto, firewall bloqueando ou servidor parado.
- Versao indisponivel: o host nao expos o endpoint web; a conexao TCP ainda pode funcionar se a porta do jogo estiver aberta.
- Versao incompativel: atualize uma das instalacoes antes de conectar.

## O que nao deve mudar

O teste LAN nao deve alterar `UserData/Database/`, saves offline ou progresso offline.
