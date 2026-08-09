local Gameplay = {}

function Gameplay.isFeatureEnabled(name)
	return Remastered.Features.isEnabled(name)
end

function Gameplay.getFeature(name, defaultValue)
	return Remastered.Features.get(name, defaultValue)
end

function Gameplay.isQuestAccessUnlocked()
	return Remastered.Config.get("gameplay.unlockQuestAccess", true) == true
end

function Gameplay.isBossAccessUnlocked()
	return Remastered.Config.get("gameplay.unlockBossAccess", true) == true
end

return Gameplay
