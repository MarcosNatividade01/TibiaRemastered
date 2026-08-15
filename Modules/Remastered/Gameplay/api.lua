local Gameplay = {}

function Gameplay.isFeatureEnabled(name)
	return Remastered.Features.isEnabled(name)
end

function Gameplay.getFeature(name, defaultValue)
	return Remastered.Features.get(name, defaultValue)
end

function Gameplay.isFreeExplorationEnabled()
	return Remastered.Config.get("gameplay.freeExploration.enabled", false) == true
end

local accessConfigByType = {
	quest = "ignoreQuestAccess",
	key = "ignoreQuestKeys",
	item = "ignoreQuestItems",
	npc = "ignoreNpcAccess",
	teleport = "ignoreTeleportAccess",
	useItem = "ignoreUseItemAccess",
}

function Gameplay.canBypassAccess(accessType)
	if not Gameplay.isFreeExplorationEnabled() then
		return false
	end

	local setting = accessConfigByType[accessType]
	if not setting then
		return false
	end

	return Remastered.Config.get("gameplay.freeExploration." .. setting, false) == true
end

local function reducePositiveRequirement(value, multiplier, minimum)
	local requirement = tonumber(value)
	if not requirement or requirement <= 0 then
		return value
	end

	local reduced = math.ceil(requirement * multiplier)
	return math.max(minimum, reduced)
end

function Gameplay.getReducedAccessRequirement(requirement)
	local multiplier = tonumber(Remastered.Config.get("gameplay.freeExploration.accessRequirementMultiplier", 0.50)) or 0.50
	local minimum = tonumber(Remastered.Config.get("gameplay.freeExploration.minimumItemRequirement", 1)) or 1
	return reducePositiveRequirement(requirement, multiplier, minimum)
end

function Gameplay.getReducedAccessLevel(level)
	local multiplier = tonumber(Remastered.Config.get("gameplay.freeExploration.levelRequirementMultiplier", 0.50)) or 0.50
	return reducePositiveRequirement(level, multiplier, 1)
end

function Gameplay.isQuestAccessUnlocked()
	return Remastered.Config.get("gameplay.unlockQuestAccess", true) == true or Gameplay.canBypassAccess("quest")
end

function Gameplay.isBossAccessUnlocked()
	return Remastered.Config.get("gameplay.unlockBossAccess", true) == true or Gameplay.canBypassAccess("quest")
end

function Gameplay.isDoorAccessUnlocked()
	return Remastered.Config.get("gameplay.unlockDoorAccess", true) == true or Gameplay.canBypassAccess("key") or Gameplay.canBypassAccess("quest")
end

return Gameplay
