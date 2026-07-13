# Login e personagens por conta

## Banco usado pelo runtime

O executavel MariaDB continua vindo de `Database_Template/mysql/bin`, mas o datadir real do jogo fica em `UserData/Database/mysql-data`.

Offline e Hospedar Mundo usam o mesmo banco local `UserData/Database/mysql-data/otserv`. O modo convidado remoto nao usa o banco local do convidado para contas; ele encaminha criacao/login ao endpoint web do host por `RemoteAccountBaseUrl`.

`Database_Template/schema.sql` permanece apenas como seed para banco novo. Ele nao deve substituir `UserData/Database`.

## Modelo de dados

O schema ja suporta uma conta com varios personagens:

- `accounts.id` identifica a conta.
- `accounts.name` guarda o account name tecnico.
- `accounts.email` guarda o login/email.
- `accounts.password` guarda a senha em SHA1 para compatibilidade com o servidor atual.
- `players.account_id` vincula cada personagem a uma conta.

## Login

O endpoint local aceita o identificador de conta nos campos enviados pelo client:

- `email`
- `EMail`
- `Email`
- `accountname`
- `AccountName`
- `sessionkey`

A busca compara `accounts.email` e `accounts.name` sem diferenciar caixa alta/baixa. Isso evita falha quando o client envia `email` vazio e preenche `accountname`, ou quando muda a capitalizacao do login.

## Criacao de personagem

`CreateAccountAndCharacter` agora tem dois caminhos:

1. Se a conta nao existe, cria `accounts` e o primeiro personagem.
2. Se a conta ja existe e a senha confere, cria somente mais um registro em `players` usando o mesmo `account_id`.

Nao e criado novo email para cada personagem. O endpoint tambem evita duplicar grupos padrao em `account_vipgroups`.

## Teste

Use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Scripts\Test-AccountCharacterList.ps1
```

O teste cria um banco temporario separado no MariaDB local, importa o schema, cria tres personagens na mesma conta e valida a lista de personagens por email e por account name.
