param(
    [ValidateSet('Before', 'After')]
    [string]$Phase = 'Before',
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$Output = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Output)) {
    $Output = Join-Path $Root "Scripts\Reports\NpcClickableAudit-$Phase.md"
}

$npcRoot = Join-Path $Root 'Server\data-global\npc'
if (-not (Test-Path -LiteralPath $npcRoot)) {
    throw "Active NPC directory not found: $npcRoot"
}

function Get-NpcCategory([string]$Content) {
    if ($Content -match '(?i)imbuement|imbuements|imbue') { return 'Imbuement' }
    if ($Content -match '(?i)Bank\.|bank_system|withdraw|deposit|balance') { return 'Bank' }
    if ($Content -match '(?i)TravelModule|StdModule\.travel|destination\s*=|teleportTo') {
        if ($Content -match '(?i)carpet|flying|femor hills') { return 'Carpet' }
        if ($Content -match '(?i)boat|sail|captain|ship') { return 'Boat' }
        return 'Travel/Transport'
    }
    if ($Content -match '(?i)npcConfig\.shop|addBuyableItem|addSellableItem|openShopWindow') { return 'Shop' }
    if ($Content -match '(?i)blessing|blessings|StdModule\.bless') { return 'Blessing' }
    if ($Content -match '(?i)promotion|promotePlayer') { return 'Promotion' }
    if ($Content -match '(?i)task|tasks|taskhunt') { return 'Task' }
    if ($Content -match '(?i)boss|arena') { return 'Boss' }
    if ($Content -match '(?i)mission|quest|Storage\.') { return 'Quest/Mission' }
    if ($Content -match '(?i)depot|inbox') { return 'Depot' }
    if ($Content -match '(?i)information|help|heal|utility') { return 'Utility/Information' }
    return 'Other'
}

function Escape-Markdown([string]$Value) {
    if ($null -eq $Value) { return '' }
    return ($Value -replace '\|', '\|') -replace "`r?`n", '<br>'
}

function Get-ManualInputReason([string]$Category, [string]$Content) {
    if ($Category -eq 'Bank') { return 'Valores, quantidades e nome do destinatario' }
    if ($Content -match '(?i)how many|how much|amount|quantity|player name|character name') {
        return 'Valor, quantidade ou nome solicitado pelo proprio fluxo'
    }
    return 'Somente texto livre quando o roteiro solicitar'
}

$rows = foreach ($file in Get-ChildItem -LiteralPath $npcRoot -File -Filter '*.lua' | Sort-Object Name) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $nameMatch = [regex]::Match($content, '(?m)^\s*npcConfig\.name\s*=\s*["'']([^"'']+)["'']')
    $npcName = if ($nameMatch.Success) { $nameMatch.Groups[1].Value } else { [IO.Path]::GetFileNameWithoutExtension($file.Name) }

    $keywordList = New-Object System.Collections.Generic.List[string]
    foreach ($match in [regex]::Matches($content, '(?s)addKeyword\s*\(\s*\{(?<body>.*?)\}')) {
        $parts = @([regex]::Matches($match.Groups['body'].Value, '["'']([^"'']+)["'']') | ForEach-Object { $_.Groups[1].Value })
        if ($parts.Count -gt 0) {
            $keyword = ($parts -join ' ')
            if (-not $keywordList.Contains($keyword)) { $keywordList.Add($keyword) }
        }
    }

    $clickableList = New-Object System.Collections.Generic.List[string]
    # Count only markup inside Lua string literals. Table constructors also use braces
    # and must not be mistaken for client-clickable dialogue.
    foreach ($stringMatch in [regex]::Matches($content, '(?s)(?<q>["''])(?<value>(?:\\.|(?!\k<q>).)*)\k<q>')) {
        foreach ($match in [regex]::Matches($stringMatch.Groups['value'].Value, '\{([^{}\r\n]{1,40})\}')) {
            $option = $match.Groups[1].Value.Trim()
            if ($option -and -not $clickableList.Contains($option)) { $clickableList.Add($option) }
        }
    }

    $usesHandler = $content -match 'NpcHandler:new\s*\('
    $hasInteraction = $usesHandler -or $content -match 'onCreatureSay|creatureSayCallback|addKeyword'
    $alreadyClickable = $clickableList.Count -gt 0
    $result = if (-not $hasInteraction) {
        'Sem dialogo interativo relevante'
    } elseif ($Phase -eq 'Before' -and $alreadyClickable) {
        'Ja clicavel; preservar'
    } elseif ($Phase -eq 'Before') {
        'Aplicar camada clicavel'
    } elseif ($usesHandler) {
        'PASS - camada central e markup existente'
    } elseif ($alreadyClickable) {
        'PASS - markup proprio preservado'
    } else {
        'N/A - arquivo auxiliar ou sem dialogo'
    }

    $category = Get-NpcCategory $content
    [pscustomobject]@{
        NPC = $npcName
        Category = $category
        Keywords = @($keywordList | Select-Object -First 16) -join ', '
        Clickable = @($clickableList | Select-Object -First 16) -join ', '
        AlreadyClickable = $alreadyClickable
        UsesHandler = $usesHandler
        HasInteraction = $hasInteraction
        ManualInput = Get-ManualInputReason $category $content
        Result = $result
        File = 'Server/data-global/npc/' + $file.Name
    }
}

$total = @($rows).Count
$interactive = @($rows | Where-Object HasInteraction).Count
$alreadyClickable = @($rows | Where-Object { $_.HasInteraction -and $_.AlreadyClickable }).Count
$handlerCount = @($rows | Where-Object UsesHandler).Count
$withoutRelevantInteraction = $total - $interactive
$converted = if ($Phase -eq 'After') { @($rows | Where-Object { $_.UsesHandler -and -not $_.AlreadyClickable }).Count } else { 0 }
$clickableAfter = if ($Phase -eq 'After') { @($rows | Where-Object { $_.HasInteraction -and ($_.UsesHandler -or $_.AlreadyClickable) }).Count } else { $alreadyClickable }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Auditoria de NPCs Clicaveis - $Phase")
$lines.Add('')
$lines.Add("Gerado em: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
$lines.Add('')
$lines.Add('- Datapack ativo: data-global')
$lines.Add("- NPCs/arquivos auditados: $total")
$lines.Add("- Dialogos interativos: $interactive")
$lines.Add("- NPCs usando NpcHandler central: $handlerCount")
$lines.Add("- Ja continham opcoes entre chaves: $alreadyClickable")
$lines.Add("- Convertidos pela camada central: $converted")
$lines.Add("- Com suporte clicavel apos a implementacao: $clickableAfter")
$lines.Add("- Sem interacao relevante/arquivos auxiliares: $withoutRelevantInteraction")
$lines.Add('')
if ($Phase -eq 'Before') {
    $lines.Add('| NPC | Categoria | Keywords atuais | Opcoes clicaveis explicitas | Ja clicavel | Alterar/Resultado | Arquivo |')
    $lines.Add('|---|---|---|---|---|---|---|')
    foreach ($row in $rows) {
        $lines.Add("| $(Escape-Markdown $row.NPC) | $($row.Category) | $(Escape-Markdown $row.Keywords) | $(Escape-Markdown $row.Clickable) | $($row.AlreadyClickable) | $($row.Result) | $($row.File) |")
    }
} else {
    $lines.Add('| NPC | Categoria | Opcoes clicaveis | Digitacao ainda necessaria | Resultado | Arquivo |')
    $lines.Add('|---|---|---|---|---|---|')
    foreach ($row in $rows) {
        $options = if ($row.Clickable) { $row.Clickable } elseif ($row.UsesHandler) { 'Camada central: opcoes publicas do contexto atual' } else { 'N/A' }
        $manual = if ($row.HasInteraction) { $row.ManualInput } else { 'N/A' }
        $lines.Add("| $(Escape-Markdown $row.NPC) | $($row.Category) | $(Escape-Markdown $options) | $(Escape-Markdown $manual) | $($row.Result) | $($row.File) |")
    }
}

$outputDirectory = Split-Path -Parent $Output
if (-not (Test-Path -LiteralPath $outputDirectory)) { New-Item -ItemType Directory -Path $outputDirectory | Out-Null }
[IO.File]::WriteAllLines($Output, $lines, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    Phase = $Phase
    Output = $Output
    Total = $total
    Interactive = $interactive
    Handler = $handlerCount
    AlreadyClickable = $alreadyClickable
    Converted = $converted
    ClickableAfter = $clickableAfter
    WithoutRelevantInteraction = $withoutRelevantInteraction
}
