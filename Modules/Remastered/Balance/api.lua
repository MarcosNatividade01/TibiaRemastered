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

function Balance.getBountyRewardMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.bountyRewardMultiplier", 1.0))
end

function Balance.getBestiaryRequiredKillsMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.bestiaryRequiredKillsMultiplier", 1.0))
end

function Balance.getBestiaryCompletionRewardMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.bestiaryCompletionRewardMultiplier", 1.0))
end

function Balance.getCharmCostMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.charmCostMultiplier", 1.0))
end

function Balance.getWeaponProficiencyRequirementMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.weaponProficiencyRequirementMultiplier", 1.0))
end

function Balance.getWeaponProficiencyExperienceMultiplier()
	return sanitizeRate(Remastered.Config.get("balance.weaponProficiencyExperienceMultiplier", 1.0))
end

function Balance.applyBountyReward(value)
	return math.floor((tonumber(value) or 0) * Balance.getBountyRewardMultiplier() + 0.5)
end

function Balance.applyBestiaryRequiredKills(value)
	return math.floor((tonumber(value) or 0) * Balance.getBestiaryRequiredKillsMultiplier() + 0.5)
end

function Balance.applyBestiaryCompletionReward(value)
	return math.floor((tonumber(value) or 0) * Balance.getBestiaryCompletionRewardMultiplier() + 0.5)
end

function Balance.applyCharmCost(value)
	return math.floor((tonumber(value) or 0) * Balance.getCharmCostMultiplier() + 0.5)
end

function Balance.applyWeaponProficiencyRequirement(value)
	return math.max(1, math.floor((tonumber(value) or 0) * Balance.getWeaponProficiencyRequirementMultiplier() + 0.5))
end

function Balance.applyWeaponProficiencyExperience(value)
	return math.max(1, math.floor((tonumber(value) or 0) * Balance.getWeaponProficiencyExperienceMultiplier() + 0.5))
end

function Balance.getBossTier(monster)
	local name = ""
	local maxHealth = 0
	local isBoss = false
	if type(monster) == "string" then
		name = monster:lower()
		isBoss = true
	elseif monster then
		name = monster.getName and monster:getName():lower() or ""
		maxHealth = monster.getMaxHealth and monster:getMaxHealth() or 0
		local monsterType = monster.getType and monster:getType() or nil
		isBoss = (monsterType and monsterType.isRewardBoss and monsterType:isRewardBoss()) or (monsterType and monsterType.bossRace and monsterType:bossRace() ~= nil) or false
	end

	if name:find("goshnar", 1, true) or name:find("ferumbras", 1, true) or name:find("world devourer", 1, true) or name:find("arbaziloth", 1, true) then
		return "endgame"
	end
	if maxHealth >= 1000000 or name:find("primal", 1, true) or name:find("rotten", 1, true) then
		return "endgame"
	end
	if not isBoss and maxHealth < 100000 then
		return nil
	end
	if maxHealth >= 350000 then
		return "strong"
	end
	if maxHealth >= 100000 then
		return "medium"
	end
	return "weak"
end

function Balance.getBossDifficultyMultiplier(monster)
	local tier = Balance.getBossTier(monster)
	if not tier then
		return 1.0
	end
	return sanitizeRate(Remastered.Config.get("balance.bossTiers." .. tier .. ".difficultyMultiplier", 1.0))
end

function Balance.applyBossHealth(monster)
	if not monster or not monster.getMaxHealth or not monster.setMaxHealth then
		return false
	end
	local multiplier = Balance.getBossDifficultyMultiplier(monster)
	if multiplier >= 1.0 then
		return false
	end
	local current = monster:getHealth()
	local scaled = math.max(1, math.floor(monster:getMaxHealth() * multiplier + 0.5))
	monster:setMaxHealth(scaled)
	if monster.addHealth and current > scaled then
		monster:addHealth(scaled - current)
	end
	return true
end

function Balance.scaleBossDamage(attacker, damage)
	if not attacker or not attacker.isMonster or not attacker:isMonster() then
		return damage
	end
	if not damage or damage <= 0 then
		return damage
	end
	local multiplier = Balance.getBossDifficultyMultiplier(attacker)
	if multiplier >= 1.0 then
		return damage
	end
	return math.floor(damage * multiplier + 0.5)
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
