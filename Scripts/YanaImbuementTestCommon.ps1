$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ImbuementsPath = Join-Path $ProjectRoot "Server\data\XML\imbuements.xml"
$ItemsPath = Join-Path $ProjectRoot "Server\data\items\items.xml"
$YanaPath = Join-Path $ProjectRoot "Server\data-global\npc\yana.lua"
$ScrollActionPath = Join-Path $ProjectRoot "Server\data\scripts\actions\items\imbuement_scrolls.lua"

function Write-Result {
	param(
		[ValidateSet("STATIC_PASS", "RUNTIME_PASS", "MANUAL_REQUIRED", "BLOCKED")]
		[string]$Status,
		[string]$Check,
		[string]$Detail = ""
	)
	if ($Detail) {
		Write-Output "$Status | $Check | $Detail"
	} else {
		Write-Output "$Status | $Check"
	}
}

function Read-XmlFile([string]$Path) {
	[xml](Get-Content -LiteralPath $Path)
}

function Get-ImbuementNodes([string]$Name) {
	$xml = Read-XmlFile $ImbuementsPath
	@($xml.imbuements.imbuement | Where-Object { $_.name -eq $Name } | Sort-Object { [int]$_.base })
}

function Assert-Equal($Actual, $Expected, [string]$Check) {
	if ("$Actual" -ne "$Expected") {
		Write-Result BLOCKED $Check "expected=$Expected actual=$Actual"
		return
	}
	Write-Result STATIC_PASS $Check "value=$Actual"
}

function Assert-ImbuementEffects([string]$Name, [string]$Type, [string]$EffectValue, [int[]]$ExpectedValues, [string]$AttributeName = "bonus") {
	$nodes = Get-ImbuementNodes $Name
	if ($nodes.Count -ne 3) {
		Write-Result BLOCKED "$Name tiers" "expected=3 actual=$($nodes.Count)"
		return
	}
	for ($i = 0; $i -lt 3; $i++) {
		$node = $nodes[$i]
		$effect = @($node.attribute | Where-Object { $_.key -eq "effect" })[0]
		if (-not $effect) {
			Write-Result BLOCKED "$Name base $($i + 1)" "missing effect"
			continue
		}
		Assert-Equal $effect.type $Type "$Name base $($i + 1) effect type"
		if ($EffectValue) {
			Assert-Equal $effect.value $EffectValue "$Name base $($i + 1) effect value"
		}
		Assert-Equal $effect.$AttributeName $ExpectedValues[$i] "$Name base $($i + 1) $AttributeName"
	}
}

function Get-ServerProcess {
	Get-Process -Name "crystalserver" -ErrorAction SilentlyContinue
}

function Get-ImbuementItemCategories {
	$text = Get-Content -LiteralPath $ItemsPath -Raw
	$rows = foreach ($match in [regex]::Matches($text, '(?s)<item\s+id="(?<id>\d+)"(?<attrs>[^>]*)>(?<body>.*?)</item>')) {
		if ($match.Groups["attrs"].Value -notmatch 'name="(?<name>[^"]+)"') { continue }
		$slot = [regex]::Match($match.Groups["body"].Value, '(?s)<attribute\s+key="imbuementslot"\s+value="(?<slot>\d+)"\s*>(?<body>.*?)</attribute>')
		if (-not $slot.Success) { continue }
		foreach ($attr in [regex]::Matches($slot.Groups["body"].Value, '<attribute\s+key="(?<key>[^"]+)"\s+value="(?<value>[^"]+)"\s*/>')) {
			[pscustomobject]@{
				ItemId = $match.Groups["id"].Value
				Name = $Matches["name"]
				Slot = $slot.Groups["slot"].Value
				ImbuementType = $attr.Groups["key"].Value
				MaxTier = $attr.Groups["value"].Value
			}
		}
	}
	$rows
}

$ExpectedScrolls = [ordered]@{
	Strike = @(51800, 51742, 51462)
	Reap = @(51801, 51738, 51458)
	Venom = @(51802, 51745, 51465)
	Electrify = @(51803, 51730, 51450)
	Scorch = @(51804, 51739, 51459)
	Frost = @(51805, 51733, 51453)
	"Lich Shroud" = @(51806, 51734, 51454)
	"Snake Skin" = @(51807, 51741, 51461)
	"Cloud Fabric" = @(51808, 51727, 51447)
	"Dragon Hide" = @(51809, 51729, 51449)
	"Demon Presence" = @(51810, 51728, 51448)
	"Quara Scale" = @(51811, 51737, 51457)
	Vampirism = @(51812, 51744, 51464)
	Void = @(51813, 51747, 51467)
	Chop = @(51814, 51726, 51446)
	Bash = @(51815, 51724, 51444)
	Precision = @(51816, 51735, 51455)
	Punch = @(51817, 51736, 51456)
	Epiphany = @(51818, 51731, 51451)
	Blockade = @(51819, 51725, 51445)
	Slash = @(51820, 51740, 51460)
	Swiftness = @(51821, 51743, 51463)
	Featherweight = @(51822, 51732, 51452)
	Vibrancy = @(51823, 51746, 51466)
}
