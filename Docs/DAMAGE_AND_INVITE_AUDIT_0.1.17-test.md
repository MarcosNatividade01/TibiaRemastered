# Auditoria de dano e convite - 0.1.17-test

## Escopo e conclusoes

- Os valores 200, 400 e 1000 da tabela anterior eram exemplos ilustrativos; nao existem como dano fixo por vocacao no codigo.
- Cada spell/runa conserva sua formula original. O multiplicador e aplicado uma unica vez no retorno ofensivo de `Player:onCombat`.
- Antes desta correcao, os multiplicadores centrais eram 1.50 para spell e 1.35 para runa.
- Todas as vocacoes e promocoes passam pelo mesmo callback `Player`; nenhuma lista de vocacoes excluia Knight ou Monk.
- Monstros nao usam `Player:onCombat`. Cura e valores nao ofensivos nao sao escalados.
- A classificacao antiga considerava qualquer item `WEAPON_NONE` como runa. Agora exige `ItemType:isRune()`.

## Amostra numerica real

As faixas abaixo usam as formulas reais dos arquivos indicados, com nivel 100, magic level 50, skill 100, attack 50 e, para Swift Jab, `attackValue=100`. A engine trabalha com dano negativo e aplica `math.floor`; a tabela mostra magnitudes positivas.

| Vocacao | Magia/Runa | Tipo | Dano base | Multiplicador | Dano final | Resultado |
|---|---|---:|---:|---:|---:|---|
| Sorcerer / Master Sorcerer | Flame Strike | Spell | 98,15-143,15 | 1.15 | 113-165 | PASS |
| Druid / Elder Druid | Ice Wave | Spell | 64,50-132,00 | 1.15 | 75-152 | PASS |
| Knight / Elite Knight | Brutal Strike | Spell | 158,72-293,12 | 1.15 | 183-338 | PASS |
| Paladin / Royal Paladin | Ethereal Spear | Spell | 61,67-145,00 | 1.15 | 71-167 | PASS |
| Monk / Exalted Monk | Swift Jab | Spell | 73,80-90,20 | 1.15 | 85-104 | PASS |
| Todas as vocacoes/promocoes tecnicamente aptas | Sudden Death Rune | Rune | 278,25-435,75 | 1.30 | 362-567 | PASS |

Fontes: `Server/data/scripts/spells/attack/*.lua`, `Server/data/scripts/runes/sudden_death.lua` e `Scripts/Test-DamageMultipliers.ps1`.

## Convite

O texto do convite ficava numa variavel simples capturada por handlers WinForms na mesma tela que tambem manipula novidades. A correcao usa um estado proprio da sessao hospedada e `Get-TrmCopyableWorldInvite`, que faz parse, rejeita loopback e reconstrói somente as seis linhas oficiais antes do clipboard.

O host local continua usando `127.0.0.1` apenas em `JoinOwnHostedWorld`. O convite remoto e criado a partir do IP LAN real; `publicHost` usa o IP publico quando disponivel e volta ao IP LAN se a consulta publica falhar. Parser, teste TCP e inicializacao remota preservam o host e a porta extraidos do convite.
