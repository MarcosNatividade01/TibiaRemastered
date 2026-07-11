local Balance = {}

local function isEnabled()
	if Remastered.Features.isEnabled("enable_remastered_balance") then
		return true
	end
	return Remastered.Features.isEnabled("remasteredBalance")
end

local function sanitizeRate(value)
	local rate = tonumber(value) or 1.0
	if rate < 0 then
		return 1.0
	end
	return rate
end

function Balance.isEnabled()
	return isEnabled()
end

function Balance.getExperienceRate()
	return sanitizeRate(Remastered.Config.get("balance.experienceRate", 1.0))
end

function Balance.getSkillRate()
	return sanitizeRate(Remastered.Config.get("balance.skillRate", 1.0))
end

function Balance.getLootRate()
	return sanitizeRate(Remastered.Config.get("balance.lootRate", 1.0))
end

function Balance.getMagicRate()
	return sanitizeRate(Remastered.Config.get("balance.magicRate", 1.0))
end

function Balance.getSpawnRate()
	return sanitizeRate(Remastered.Config.get("balance.spawnRate", 1.0))
end

function Balance.getSpellDamageMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.spellDamageMultiplier", 1.0))
end

function Balance.getOffensiveRuneDamageMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.offensiveRuneDamageMultiplier", 1.0))
end

function Balance.applyExperienceRate(exp)
	if not isEnabled() then
		return exp
	end
	return math.floor(exp * Balance.getExperienceRate())
end

function Balance.applySkillRate(tries)
	if not isEnabled() then
		return tries
	end
	return tries * Balance.getSkillRate()
end

function Balance.applyLootFactor(factor)
	if not isEnabled() then
		return factor
	end
	return factor * Balance.getLootRate()
end

function Balance.getLootMessageSuffix()
	if not isEnabled() or Balance.getLootRate() == 1.0 then
		return ""
	end
	return "remastered loot x" .. tostring(Balance.getLootRate())
end

return Balance
