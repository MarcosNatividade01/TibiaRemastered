local callback = EventCallback("PlayerOnGainSkillTriesSoloBalance")

function callback.playerOnGainSkillTries(player, skill, tries)
	if IsRunningGlobalDatapack() and isSkillGrowthLimited(player, skill) then
		return 0
	end

	if not APPLY_SKILL_MULTIPLIER then
		return tries
	end

	local rateSkillStages = configManager.getBoolean(configKeys.RATE_USE_STAGES) and skillsStages or nil
	local currentSkillLevel = player:getSkillLevel(skill)
	local baseRate = configManager.getNumber(configKeys.RATE_SKILL)

	if skill == SKILL_MAGLEVEL then
		rateSkillStages = configManager.getBoolean(configKeys.RATE_USE_STAGES) and magicLevelStages or nil
		currentSkillLevel = player:getBaseMagicLevel()
		baseRate = configManager.getNumber(configKeys.RATE_MAGIC)
	end

	local skillRate = getRateFromTable(rateSkillStages, currentSkillLevel, baseRate)
	skillRate = (SCHEDULE_SKILL_RATE ~= 100) and (skillRate * SCHEDULE_SKILL_RATE / 100) or skillRate

	if configManager.getBoolean(configKeys.VIP_SYSTEM_ENABLED) and player:isVip() then
		local vipBonusSkill = math.min(configManager.getNumber(configKeys.VIP_BONUS_SKILL), 100)
		skillRate = skillRate + (skillRate * (vipBonusSkill / 100))
	end

	local finalTries = tries * skillRate
	if Remastered and Remastered.Balance and Remastered.Balance.applySkillRate then
		return Remastered.Balance.applySkillRate(finalTries)
	end
	return finalTries
end

callback:register()
