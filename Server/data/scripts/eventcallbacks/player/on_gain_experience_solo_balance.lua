local callback = EventCallback("PlayerOnGainExperienceSoloBalance")

local function consumeStamina(player, isStaminaEnabled)
	if not player then
		return
	end

	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	if not playerId or not _G.NextUseStaminaTime[playerId] then
		return
	end

	local currentTime = os.time()
	local timePassed = currentTime - _G.NextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	local preyStaminaUsed = 0
	if timePassed > 60 then
		staminaMinutes = math.max(0, staminaMinutes - 2)
		_G.NextUseStaminaTime[playerId] = currentTime + 120
		preyStaminaUsed = 120
	else
		staminaMinutes = math.max(0, staminaMinutes - 1)
		_G.NextUseStaminaTime[playerId] = currentTime + 60
		preyStaminaUsed = 60
	end

	if preyStaminaUsed > 0 then
		player:removePreyStamina(preyStaminaUsed)
	end
	if isStaminaEnabled then
		player:setStamina(staminaMinutes)
	end
	player:save()
end

local function consumeXpBoost(player)
	if not player then
		return
	end

	local xpBoostMinutes = player:getXpBoostTime() / 60
	if xpBoostMinutes == 0 then
		return
	end

	local playerId = player:getId()
	if not playerId then
		return
	end

	local currentTime = os.time()
	if not _G.NextUseXpStamina[playerId] then
		_G.NextUseXpStamina[playerId] = currentTime + 60
		return
	end

	local timePassed = currentTime - _G.NextUseXpStamina[playerId]
	if timePassed <= 0 then
		return
	end

	local dailyRewardMinutes = player:kv():get("daily-reward-xp-boost") or 0
	if timePassed > 60 then
		if xpBoostMinutes > 2 then
			xpBoostMinutes = xpBoostMinutes - 2
			if dailyRewardMinutes > 2 then
				player:kv():set("daily-reward-xp-boost", dailyRewardMinutes - 2)
			end
		else
			xpBoostMinutes = 0
			player:kv():remove("daily-reward-xp-boost")
		end
		_G.NextUseXpStamina[playerId] = currentTime + 120
	else
		xpBoostMinutes = xpBoostMinutes - 1
		if dailyRewardMinutes > 0 then
			player:kv():set("daily-reward-xp-boost", dailyRewardMinutes - 1)
		end
		_G.NextUseXpStamina[playerId] = currentTime + 60
	end

	player:setXpBoostTime(xpBoostMinutes * 60)
	if xpBoostMinutes <= 0 then
		player:setXpBoostPercent(0)
	end
	player:save()
end

local function consumeConcoction(player)
	if not player then
		return
	end

	local playerId = player:getId()
	if not playerId or not _G.NextUseConcoctionTime or not _G.NextUseConcoctionTime[playerId] then
		return
	end

	local currentTime = os.time()
	local timePassed = currentTime - _G.NextUseConcoctionTime[playerId]
	if timePassed <= 0 then
		return
	end

	local deduction = 60
	if timePassed > 60 then
		_G.NextUseConcoctionTime[playerId] = currentTime + 120
		deduction = 120
	else
		_G.NextUseConcoctionTime[playerId] = currentTime + 60
	end

	if Concoction then
		Concoction.experienceTick(player, deduction)
	end
end

function callback.playerOnGainExperience(player, target, exp, rawExp)
	if not target or target:isPlayer() then
		return exp
	end

	local vocation = player:getVocation()
	if player:getSoul() < vocation:getMaxSoul() and exp >= player:getLevel() then
		local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
		soulCondition:setTicks(4 * 60 * 1000)
		soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks())
		player:addCondition(soulCondition)
	end

	local xpBoostPercent = player:getXpBoostTime() > 0 and player:getXpBoostPercent() or 0
	local staminaBonusXp = 1
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		staminaBonusXp = player:getFinalBonusStamina()
		player:setStaminaXpBoost(staminaBonusXp * 100)
	end

	if target:getName():lower() == Game.getBoostedCreature():lower() then
		exp = exp * 2
	end

	if configManager.getBoolean(configKeys.PREY_ENABLED) then
		local monsterType = target:getType()
		if monsterType and monsterType:raceId() > 0 then
			local preyExperiencePercent = player:getPreyExperiencePercentage(monsterType:raceId())
			if preyExperiencePercent > 100 then
				exp = math.ceil((exp * preyExperiencePercent) / 100)
			end
		end
	end

	consumeXpBoost(player)
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		consumeStamina(player, true)
	end
	consumeConcoction(player)

	if configManager.getBoolean(configKeys.VIP_SYSTEM_ENABLED) then
		local vipBonusExp = configManager.getNumber(configKeys.VIP_BONUS_EXP)
		if vipBonusExp > 0 and player:isVip() then
			exp = exp * (1 + math.min(vipBonusExp, 100) / 100)
		end
	end

	if target:getForgeStack() > 0 then
		local stack = target:getForgeStack()
		if stack >= 1 and stack <= 15 then
			exp = exp * (1 + math.min(stack * 10, 150) / 100)
		end
	end

	if SoulWarQuest then
		local monsterType = target:getType()
		if monsterType and monsterType:getName() and table.contains(SoulWarQuest.bagYouDesireMonsters, monsterType:getName()) then
			local taintLevel = player:getTaintLevel() or 0
			if taintLevel > 0 then
				local taintBoost = SoulWarQuest.taintExperienceBoostMap[taintLevel] and SoulWarQuest.taintExperienceBoostMap[taintLevel].boost or 0
				exp = exp * (1 + taintBoost / 100)
			end
		end
	end

	local lowLevelBonusExp = player:getFinalLowLevelBonus()
	local baseRateExp = player:getFinalBaseRateExperience()
	local finalExp = math.floor((exp * (1 + xpBoostPercent / 100 + lowLevelBonusExp / 100)) * staminaBonusXp * baseRateExp)
	if Remastered and Remastered.Balance and Remastered.Balance.applyExperienceRate then
		return Remastered.Balance.applyExperienceRate(finalExp)
	end
	return finalExp
end

callback:register()
