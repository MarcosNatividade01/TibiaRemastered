# Roadmap

## Fase 1 - Base do repositorio

- [x] Criar estrutura inicial.
- [x] Adicionar arquivos de documentacao.
- [x] Configurar `.gitignore`.
- [ ] Adicionar templates seguros de configuracao.

## Fase 2 - Servidor e banco

- [ ] Organizar arquivos do servidor em `Server/`.
- [ ] Criar template de banco em `DatabaseTemplate/`.
- [ ] Documentar instalacao local em `Docs/`.

## Fase 3 - Cliente e launcher

- [ ] Organizar arquivos do cliente em `Client/`.
- [ ] Criar estrutura do launcher em `Launcher/`.
- [ ] Implementar leitura de `version.json`.
- [ ] Implementar comparacao com `manifest.json`.
- [ ] Implementar rotina de download e atualizacao.

## Fase 4 - Testes e distribuicao

- [ ] Criar scripts de validacao em `Scripts/`.
- [ ] Criar ferramentas auxiliares em `Tools/`.
- [ ] Documentar processo de release.

## Fase 9 - QA minimo e Host Assistido

- [x] Criar QA minimo para proteger modo Offline.
- [x] Gerar relatorios em `Logs/QAReports/`.
- [x] Adicionar opcoes `Jogar Offline`, `Hospedar Mundo` e `Entrar em Mundo`.
- [x] Separar estado online em `UserData/Online/`.
- [x] Evoluir Host Assistido com diagnostico LAN, teste de porta, versao e relatorio online.

## Fase 10 - Host Assistido Real

- [x] Validar porta local do servidor.
- [x] Diagnosticar host inacessivel.
- [x] Registrar possiveis bloqueios de firewall/NAT/CGNAT.
- [x] Validar versao quando o host disponibiliza `version.json`.
- [x] Preservar o modo Offline ao alternar endpoint local.
- [ ] Testar conexao real entre duas maquinas na mesma LAN.
