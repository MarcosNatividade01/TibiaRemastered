param(
    [ValidateSet('Before', 'After')]
    [string]$Phase = 'Before',
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$reportRoot = Join-Path $Root 'Scripts\Reports'
New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null

$scanRoots = @(
    'Server\data-global',
    'Server\data',
    'Server\data-crystal',
    'Modules',
    'Scripts'
)

$candidatePattern = '(?i)getStorageValue|setStorageValue|getLevel\s*\(|getItemCount|getItemById|removeItem|isPremium|getVocation|canEnter|canUse|onStepIn|onUse|teleportTo|doTeleportThing|actionid|uniqueid|requiredItems?|accessItem|keyItem'
$gatePattern = '(?i)^\s*(if|elseif)\b|require(d|ment)?\s*=|storage\s*=|level\s*=|need[A-Za-z]*\s*=|key\s*=|item\s*='
$accessContextPattern = '(?i)access|entrance|enter|door|teleport|portal|travel|passage|shortcut|wall|barrier|gate|lever|boat|ship|island|cave|dungeon|arena|boss|quest|mission'
$rewardContextPattern = '(?i)reward|chest|addItem|addExperience|achievement|outfit|mount|title|questpoint|quest point'
$bossMechanicPattern = '(?i)summon|phase|arena reset|participant|spectator|combat|health|damage|kill tracking|reward boss'
$normalToolPattern = '(?i)rope|shovel|machete|pick|scythe'
$bypassPattern = '(?i)isQuestAccessUnlocked|isBossAccessUnlocked|isDoorAccessUnlocked|FreeExploration|freeExploration'

function Convert-ToRelativePath([string]$Path) {
    $base = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $full = [System.IO.Path]::GetFullPath($Path)
    return $full.Substring($base.Length).TrimStart('\', '/') -replace '\\', '/'
}

function Get-FirstMatch([string]$Text, [string]$Pattern) {
    $match = [regex]::Match($Text, $Pattern)
    if ($match.Success) { return $match.Value }
    return ''
}

function Get-Classification([string]$Relative, [string]$Context, [string]$Line) {
    $combined = "$Relative $Context"
    if ($combined -match $rewardContextPattern) { return 'PRESERVE_REWARD_OR_PROGRESS' }
    if ($combined -match $bossMechanicPattern -and $combined -notmatch '(?i)entrance|access|teleport|portal') { return 'PRESERVE_BOSS_MECHANIC' }
    if ($combined -match $normalToolPattern -and $combined -notmatch '(?i)quest|mission|access|entrance') { return 'PRESERVE_NORMAL_TOOL' }
    if ($combined -match '(?i)key|chave|locked|lock') { return 'B_KEY_ACCESS' }
    if ($Line -match '(?i)getLevel\s*\(' -or $combined -match '(?i)level door|minimum level') { return 'G_LEVEL_ACCESS' }
    if ($Relative -match '(?i)/npc/' -or $combined -match '(?i)travel|boat|ship') { return 'D_NPC_ACCESS' }
    if ($combined -match '(?i)teleport|portal|onStepIn') { return 'E_TELEPORT_ACCESS' }
    if ($combined -match '(?i)door|wall|barrier|gate|stone|rock') { return 'F_DOOR_WALL_BARRIER' }
    if ($combined -match '(?i)lever|altar|statue|mechanism|onUse') { return 'H_USE_ITEM_OR_LEVER_ACCESS' }
    if ($Line -match '(?i)getItemCount|getItemById|removeItem|requiredItems?|accessItem') { return 'C_QUEST_ITEM_ACCESS' }
    return 'A_QUEST_ACCESS_GATE'
}

function Get-Proposal([string]$Classification, [bool]$HasBypass, [string]$Line) {
    if ($Classification -like 'PRESERVE_*') { return 'Preservar: nao e um gate puramente fisico ou envolve reward/mecanica.' }
    if ($HasBypass -and $Phase -eq 'After') { return 'Liberado pela camada central de exploracao livre; storage/progresso/reward preservados.' }
    switch ($Classification) {
        'B_KEY_ACCESS' { return 'Permitir passagem sem chave; nao entregar nem consumir chave.' }
        'C_QUEST_ITEM_ACCESS' { return 'Criar bypass somente de passagem, sem item e sem alterar storage.' }
        'D_NPC_ACCESS' { return 'Permitir transporte/entrada sem progresso anterior; preservar dialogo e quest.' }
        'E_TELEPORT_ACCESS' { return 'Permitir uso do teleport sem storage/item de acesso.' }
        'F_DOOR_WALL_BARRIER' { return 'Permitir passagem sem remover reward ou progresso da quest.' }
        'G_LEVEL_ACCESS' { return 'Reduzir apenas o level de entrada com ceil(original/2).' }
        'H_USE_ITEM_OR_LEVER_ACCESS' { return 'Bypass de acesso sem simular uso, consumir item ou avancar quest.' }
        default { return 'Ignorar requisito quando usado somente para acesso fisico.' }
    }
}

function Test-CentralCoverage([string]$Relative, [string]$Classification, [string]$WholeFile) {
    if ($Phase -ne 'After' -or $Classification -like 'PRESERVE_*') { return $false }
    if ($WholeFile -match $bypassPattern -or $WholeFile -match '(?i)canBypassAccess|getReducedAccess') { return $true }
    if ($Classification -eq 'D_NPC_ACCESS' -and $Relative -match '(?i)/npc/.+\.lua$' -and $WholeFile -match '(?i)StdModule\.travel|addTravelKeyword') { return $true }
    if ($Classification -in @('B_KEY_ACCESS', 'F_DOOR_WALL_BARRIER') -and $Relative -match '(?i)doors?.*\.lua$') { return $true }
    return $false
}

function Get-NewRequirement([string]$Classification, [bool]$HasBypass) {
    if ($Classification -like 'PRESERVE_*') { return 'Inalterado.' }
    if ($Classification -eq 'G_LEVEL_ACCESS') { return 'ceil(level original / 2), minimo 1.' }
    if ($HasBypass) { return 'Sem requisito de quest/storage/item para acesso fisico.' }
    return 'Preservado apos revisao: nao comprovado como gate puramente fisico.'
}

$rows = New-Object System.Collections.Generic.List[object]
$extensions = @('.lua', '.xml', '.ps1')

foreach ($relativeRoot in $scanRoots) {
    $fullRoot = Join-Path $Root $relativeRoot
    if (-not (Test-Path -LiteralPath $fullRoot)) { continue }
    Get-ChildItem -LiteralPath $fullRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch '[\\/]Scripts[\\/]Reports[\\/]' -and
        $_.Name -ne 'Build-AccessRestrictionReports.ps1'
    } | ForEach-Object {
        $file = $_
        $relative = Convert-ToRelativePath $file.FullName
        $lines = @(Get-Content -LiteralPath $file.FullName)
        $wholeFile = $lines -join "`n"
        $fileHasBypass = $wholeFile -match $bypassPattern

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = [string]$lines[$index]
            if ($line -notmatch $candidatePattern -or $line -notmatch $gatePattern) { continue }

            $start = [Math]::Max(0, $index - 2)
            $end = [Math]::Min($lines.Count - 1, $index + 3)
            $context = (($lines[$start..$end] | ForEach-Object { [string]$_ }) -join ' ').Trim()
            if ($context -notmatch $accessContextPattern -and $relative -notmatch '(?i)quest|door|movement|npc|teleport|access') { continue }

            $classification = Get-Classification -Relative $relative -Context $context -Line $line
            $storage = Get-FirstMatch -Text $context -Pattern 'Storage(?:\.[A-Za-z_][A-Za-z0-9_]*|\[[^\]]+\])+'
            $item = Get-FirstMatch -Text $context -Pattern '(?i)(?:getItemCount|getItemById|removeItem|itemid\s*==|getId\(\)\s*==)\s*\(?\s*\d+'
            $quantity = Get-FirstMatch -Text $line -Pattern '(?i)(?:getItemCount|removeItem)\s*\([^,\)]*(?:,\s*)?(\d+)?'
            $level = if ($line -match '(?i)getLevel\s*\(\)\s*(?:>=|>|==|<=|<)\s*(\d+)') { $Matches[1] } else { '' }
            $actionId = Get-FirstMatch -Text $context -Pattern '(?i)actionid\s*(?:==|=)\s*\d+'
            $uniqueId = Get-FirstMatch -Text $context -Pattern '(?i)(?:uniqueid|uid)\s*(?:==|=)\s*\d+'
            $hasBypass = $fileHasBypass -or $context -match $bypassPattern -or (Test-CentralCoverage -Relative $relative -Classification $classification -WholeFile $wholeFile)
            $proposal = Get-Proposal -Classification $classification -HasBypass $hasBypass -Line $line
            $consequence = if ($context -match '(?i)teleportTo|doTeleportThing') { 'Bloqueia ou permite teleport/passagem.' }
                elseif ($context -match '(?i)return\s+false|sendCancelMessage|not allowed|sealed|locked') { 'Nega uso ou passagem.' }
                else { 'Condiciona acesso/progresso; requer revisao contextual.' }

            $rows.Add([pscustomobject]@{
                Local = ($relative -replace '^Server/data-global/scripts/quests/', '' -replace '\.lua$', '')
                Quest = if ($relative -match '(?i)/quests/([^/]+)') { $Matches[1] } else { '' }
                Arquivo = $relative
                Linha = $index + 1
                Tipo = $classification
                Requisito = $line.Trim()
                Storage = $storage
                Item = $item
                Quantidade = $quantity
                Level = $level
                NPC = if ($relative -match '(?i)/npc/([^/]+)\.lua$') { $Matches[1] } else { '' }
                Teleport = [bool]($context -match '(?i)teleport|portal')
                Porta = [bool]($context -match '(?i)door|gate')
                Lever = [bool]($context -match '(?i)lever')
                ActionId = $actionId
                UniqueId = $uniqueId
                ConsequenciaAtual = $consequence
                BypassExistente = [bool]$hasBypass
                RequisitoNovo = Get-NewRequirement -Classification $classification -HasBypass $hasBypass
                Proposta = $proposal
                QuestPreservada = ($classification -notlike 'PRESERVE_*')
            }) | Out-Null
        }
    }
}

$ordered = @($rows | Sort-Object Arquivo, Linha -Unique)
$csvPath = Join-Path $reportRoot ("AccessRestrictions-{0}.csv" -f $Phase)
$mdPath = Join-Path $reportRoot ("AccessRestrictions-{0}.md" -f $Phase)
$ordered | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8

$counts = $ordered | Group-Object Tipo | Sort-Object Name
$accessRows = @($ordered | Where-Object { $_.Tipo -notlike 'PRESERVE_*' })
$preservedRows = @($ordered | Where-Object { $_.Tipo -like 'PRESERVE_*' })
$bypassedRows = @($accessRows | Where-Object { $_.BypassExistente })
$itemAccessRows = @($accessRows | Where-Object { $_.Item -or $_.Tipo -in @('B_KEY_ACCESS', 'C_QUEST_ITEM_ACCESS', 'H_USE_ITEM_OR_LEVER_ACCESS') })
$bypassedItemRows = @($itemAccessRows | Where-Object { $_.BypassExistente })

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Auditoria de Restricoes de Acesso - $Phase")
$md.Add('')
$md.Add("Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$md.Add('')
$md.Add("- Achados classificados: $($ordered.Count)")
$md.Add("- Potenciais gates fisicos: $($accessRows.Count)")
$md.Add("- Casos preservados por reward/progresso/mecanica: $($preservedRows.Count)")
$md.Add("- Arquivos com bypass central/contextual: $($bypassedRows.Count)")
$md.Add("- Passagens/condicoes com item encontradas: $($itemAccessRows.Count)")
$md.Add("- Passagens/condicoes com item cobertas: $($bypassedItemRows.Count)")
$md.Add('')
$md.Add('## Totais por classificacao')
$md.Add('')
$md.Add('| Tipo | Quantidade |')
$md.Add('|---|---:|')
foreach ($count in $counts) { $md.Add("| $($count.Name) | $($count.Count) |") }
$md.Add('')
$md.Add('## Restricoes auditadas')
$md.Add('')
$md.Add('| Local | Tipo | Requisito anterior | Requisito novo | Quest preservada | Storage | Item | Qtd. | Level | NPC | Teleport | Porta | Lever | Arquivo |')
$md.Add('|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|')
foreach ($row in $ordered) {
    $values = @(
        $row.Local, $row.Tipo, $row.Requisito, $row.RequisitoNovo, $row.QuestPreservada,
        $row.Storage, $row.Item, $row.Quantidade, $row.Level, $row.NPC,
        $row.Teleport, $row.Porta, $row.Lever, ("{0}:{1}" -f $row.Arquivo, $row.Linha)
    ) | ForEach-Object { ([string]$_).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ') }
    $md.Add('| ' + ($values -join ' | ') + ' |')
}

$md.Add('')
$md.Add('## Itens usados para acesso')
$md.Add('')
$md.Add('| Local | Item exigido | Quantidade original | Como era usado | Novo comportamento | Quest preservada | Arquivo |')
$md.Add('|---|---|---:|---|---|---|---|')
foreach ($row in $itemAccessRows) {
    $values = @(
        $row.Local, $row.Item, $row.Quantidade, $row.Requisito,
        $row.RequisitoNovo, $row.QuestPreservada, ("{0}:{1}" -f $row.Arquivo, $row.Linha)
    ) | ForEach-Object { ([string]$_).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ') }
    $md.Add('| ' + ($values -join ' | ') + ' |')
}

$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($mdPath, $md, $encoding)

[pscustomobject]@{
    Phase = $Phase
    Markdown = $mdPath
    Csv = $csvPath
    Findings = $ordered.Count
    AccessCandidates = $accessRows.Count
    Preserved = $preservedRows.Count
    WithBypass = $bypassedRows.Count
    ItemAccessFound = $itemAccessRows.Count
    ItemAccessBypassed = $bypassedItemRows.Count
}
