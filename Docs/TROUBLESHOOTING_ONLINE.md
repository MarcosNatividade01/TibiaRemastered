# Troubleshooting Online

## Host inacessivel

Verifique:

- IP/endereco digitado.
- porta do servidor.
- se o host clicou em `Hospedar Mundo`.
- firewall do Windows no host.
- se as maquinas estao na mesma rede, no caso de LAN.

## Porta ocupada

O diagnostico mostra qual porta esta em uso e, quando possivel, o processo responsavel.

Portas principais:

- `7171`: login/game protocol auxiliar do servidor.
- `7172`: porta principal usada pelo client.
- `80`: endpoint local usado pelo Launcher para login/criacao/playdata.

## Internet externa nao conecta

Sem VPN ou servidor dedicado, a conexao pela internet pode exigir:

- redirecionamento de porta no roteador;
- firewall liberado no host;
- IP publico real;
- ausencia de CGNAT.

O Launcher apenas diagnostica sinais provaveis. Ele nao altera roteador, nao instala VPN e nao promete contornar CGNAT.

## Versao incompativel

Quando o host expoe `version.json`, o Launcher compara com a versao local. Se as versoes forem diferentes, a conexao e bloqueada para evitar cliente/servidor incompativeis.

## Offline

Se o Host Assistido falhar, use `Jogar Offline`. O Offline nao depende da internet e nao usa `UserData/Online/`.
