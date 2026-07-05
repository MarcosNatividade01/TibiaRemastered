# Changelog

Todas as alteracoes importantes do projeto serao documentadas aqui.

## [0.1.8] - Publicacao GitHub

- Publicada versao 0.1.8 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.7] - Publicacao GitHub

- Publicada versao 0.1.7 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.7] - Diagnostico definitivo de conexao remota

- Criado log dedicado em `Logs/ConnectionTests/` para `Testar Conexao` e `Entrar em Mundo`.
- O log registra convite bruto, IP final, porta final, teste TCP direto, login server, versao, endpoint portatil, comando do client e motivo real da falha.
- Convites remotos com `127.0.0.1`, `localhost` ou `::1` agora falham com mensagem explicita.
- O preflight remoto usa TCP direto e nao troca IP de convidado por `127.0.0.1`.
- A tela de Host Assistido agora mostra motivo real da falha em vez de apenas erro generico.
- Adicionado teste automatizado para convite valido, IP invalido, porta errada, convite localhost, host local e Offline.

## [0.1.6] - Publicacao GitHub

- Publicada versao 0.1.6 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.6] - Launcher Update UX

- Adicionada area de status de atualizacao na tela inicial do Launcher, com versao instalada, versao disponivel e mensagem quando a versao local ja esta atualizada.
- Adicionados botoes `Atualizar`, `Atualizar e Jogar` e `Ver Novidades`.
- O botao `Atualizar` executa o fluxo incremental por manifest, validando SHA256, preservando arquivos protegidos e registrando acoes por arquivo nos logs.
- O botao `Atualizar e Jogar` so inicia o modo Offline quando a atualizacao termina com sucesso.
- `Ver Novidades` busca o `CHANGELOG.md` remoto e mostra a secao da versao disponivel quando encontrada.
- Adicionado teste local de update UX cobrindo versao local menor, versao local igual, arquivo protegido, hash invalido e manifest indisponivel.

## [0.1.5] - Publicacao GitHub

- Publicada versao 0.1.5 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.3-test] - Publicacao GitHub

- Publicada versao 0.1.3-test como versao de teste para validacao multiplayer em dois computadores.
- Separado o fluxo `Entrar no Meu Mundo`, que usa `127.0.0.1`, do fluxo `Entrar em Mundo`, que preserva o IP do convite para convidados.
- Adicionados logs temporarios antes de abrir o client com modo, IP usado, porta, configuracao aplicada e comando de abertura.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.

## [0.1.4] - Publicacao GitHub

- Removidos dados locais do client do indice Git (`Client/characterdata/` e `Client/minimap/`) sem apagar os arquivos da maquina do usuario.
- Reforcadas as protecoes do `.gitignore` e do publicador oficial para impedir publicacao de dados locais do client.
- Mantida a correcao do host entrando no proprio mundo publicada na versao anterior.

## [0.1.3] - Publicacao GitHub

- Corrigido o fluxo em que o host nao conseguia entrar no proprio mundo usando o convite com IP local.
- O Launcher agora reconhece enderecos da propria maquina e usa `127.0.0.1` internamente para abrir o client local do host.
- Mantido o convite com IP de LAN para outros computadores, sem alterar o modo Offline, saves, banco local ou dados do jogador.

## [0.1.2] - Publicacao GitHub

- Publicada versao 0.1.2 para testes online/LAN.
- Atualizados `version.json` e `manifest.json` para o Launcher baixar arquivos pelo GitHub.
- Mantidas protecoes para `UserData`, logs, backups, saves, banco local e arquivos pessoais.
## [0.1.2] - Publicador GitHub

- Criado publicador em `Tools/Publish/` para preparar commit e push com duplo clique.
- Adicionadas validacoes de Git, repositorio, remote origin, `.gitignore` e arquivos proibidos.
- Adicionado modo `-DryRun` para testar o fluxo sem commit/push.
- Documentado uso, restauracao e publicacao futura em `Tools/Publish/README.md`.

## [0.1.1] - Publicacao GitHub

- Consolidada versao para publicacao no GitHub como fonte oficial de atualizacao.
- Incluidos no Launcher principal os botoes `Jogar Offline`, `Hospedar Mundo`, `Entrar em Mundo`, `Diagnostico`, `Reparar Arquivos`, `Configuracoes` e `Ajuda`.
- Confirmado fluxo de convite online com `Copiar Convite`, `Usar Convite`, IP, porta e versao.
- Mantida protecao de `UserData`, saves, logs, backups e banco local.

## [0.1.0] - Fase 11

- Padronizada a tela principal do Launcher com `Jogar Offline`, `Hospedar Mundo`, `Entrar em Mundo`, `Configuracoes` e `Ajuda`.
- Expostos `Diagnostico` e `Reparar Arquivos` como botoes principais.
- Aplicado visual proprio inspirado em fantasia medieval/RPG, sem artes oficiais de terceiros.
- Criado formato oficial de convite do Tibia Remastered.
- Adicionado suporte para colar convite completo e preencher IP/porta automaticamente.
- Expandido historico online com mundo, host, porta, versao e data de conexao.
- Adicionada secao de ajuda no Launcher e guia `Docs/LAUNCHER_GUIDE.md`.
- Movidas acoes tecnicas para `Configuracoes`, reduzindo a exposicao da estrutura interna.
- Criado checklist multiplayer em `Docs/MULTIPLAYER_TEST_GUIDE.md`.

## [0.1.0] - Fase 10

- Consolidado Host Assistido com diagnosticos de porta, IP local/publico, host acessivel e versao.
- Adicionados relatorios online em `Logs/OnlineDiagnostics/`.
- Adicionado controle de estado do endpoint web portatil para alternar com seguranca entre Offline, Hospedar Mundo e Entrar em Mundo.
- O fluxo `Entrar em Mundo` agora testa a conexao antes de abrir o client.
- Criados guias de diagnostico, teste LAN e troubleshooting online.

## [0.1.0] - Fase 9

- Criado QA minimo obrigatorio com relatorios em `Logs/QAReports/`.
- Adicionado parametro `-MinimumQA` ao Launcher e ao script de teste.
- Adicionadas opcoes principais no Launcher: `Jogar Offline`, `Hospedar Mundo` e `Entrar em Mundo`.
- Criada base do Host Assistido com IP local/publico, porta, teste de conexao, historico de host e estado online separado.
- Reservada estrutura `UserData/Offline`, `UserData/Online` e `UserData/Shared`.
- Documentadas limitacoes de LAN, NAT, CGNAT, firewall e port forwarding.

## [0.1.0] - Fase 6

- Criado Remastered Balance Module.
- Adicionada feature flag `enable_remastered_balance`.
- Configurados rates Remastered iniciais: XP 10x, skill 3x, loot 2x.
- Integrados multiplicadores nos callbacks Lua existentes de XP, skill e loot base.

## [0.1.0] - 2026-06-29

- Criada a estrutura inicial do repositorio.
- Adicionados arquivos base para README, roadmap, ideias, versao e manifest.
- Adicionado `.gitignore` para proteger dados reais e arquivos sensiveis.






