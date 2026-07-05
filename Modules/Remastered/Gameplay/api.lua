local Gameplay = {}

function Gameplay.isFeatureEnabled(name)
	return Remastered.Features.isEnabled(name)
end

function Gameplay.getFeature(name, defaultValue)
	return Remastered.Features.get(name, defaultValue)
end

return Gameplay
