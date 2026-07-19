Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$worldNpcPath = Join-Path $root 'Server\data-global\world\world-npc.xml'
$brokerPath = Join-Path $root 'Server\data-global\npc\gold_token_broker.lua'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-EffectiveNpcPosition {
    param([xml]$Xml, [string]$NpcName)

    $nodes = @($Xml.SelectNodes("//npc[@name='$NpcName']"))
    Assert-True ($nodes.Count -eq 1) "Esperado exatamente 1 spawn de $NpcName, encontrado $($nodes.Count)."

    $node = $nodes[0]
    $parent = $node.ParentNode
    $centerX = [int]$parent.centerx
    $centerY = [int]$parent.centery
    $centerZ = [int]$parent.centerz
    $offsetX = [int]$node.x
    $offsetY = [int]$node.y
    $z = [int]$node.z

    [pscustomobject]@{
        Name = $NpcName
        X = $centerX + $offsetX
        Y = $centerY + $offsetY
        Z = $z
        CenterZ = $centerZ
        Direction = $node.GetAttribute('direction')
    }
}

Assert-True (Test-Path -LiteralPath $worldNpcPath) 'world-npc.xml ausente.'
Assert-True (Test-Path -LiteralPath $brokerPath) 'Script do Gold Token Broker ausente.'

[xml]$worldNpc = Get-Content -LiteralPath $worldNpcPath -Raw
$yana = Get-EffectiveNpcPosition -Xml $worldNpc -NpcName 'Yana'
$broker = Get-EffectiveNpcPosition -Xml $worldNpc -NpcName 'Gold Token Broker'

$distance = [math]::Abs($yana.X - $broker.X) + [math]::Abs($yana.Y - $broker.Y)
Assert-True ($yana.Z -eq $broker.Z) "Yana e Broker estao em andares diferentes: $($yana.Z) vs $($broker.Z)."
Assert-True ($distance -eq 1) "Broker nao esta em tile imediatamente adjacente a Yana. Distancia=$distance."
Assert-True ($yana.CenterZ -eq $yana.Z) 'Yana tem centerz/z inconsistente.'
Assert-True ($broker.CenterZ -eq $broker.Z) 'Broker tem centerz/z inconsistente.'

$brokerScript = Get-Content -LiteralPath $brokerPath -Raw
Assert-True ($brokerScript -match 'local internalNpcName\s*=\s*"Gold Token Broker"') 'Nome interno do Broker incorreto.'
Assert-True ($brokerScript -match 'lookType\s*=\s*146') 'Broker nao usa visual base do Rashid.'
Assert-True ($brokerScript -match 'clientId\s*=\s*22721') 'Gold Token clientId/item ID incorreto.'
Assert-True ($brokerScript -match 'buy\s*=\s*200000') 'Preco unitario do Gold Token incorreto.'
Assert-True ($brokerScript -match 'npc:openShopWindow\(creature\)') 'Trade window nao abre no dialogo.'
Assert-True ($brokerScript -match 'npc:sellItem\(player,\s*itemId,\s*amount') 'Compra multipla nao usa amount no sellItem.'
Assert-True ($brokerScript -notmatch '22720|22722') 'Script referencia ID vizinho suspeito de Gold Token.'

[pscustomobject]@{
    status = 'GOLD_TOKEN_BROKER_NEXT_TO_YANA = PASS'
    trade = 'GOLD_TOKEN_BROKER_TRADE = PASS'
    yana = $yana
    broker = $broker
    distance = $distance
    goldTokenId = 22721
    unitPrice = 200000
    multiplePurchaseExamples = @(
        [pscustomobject]@{ amount = 1; totalCost = 200000 },
        [pscustomobject]@{ amount = 10; totalCost = 2000000 }
    )
} | ConvertTo-Json -Depth 5
