local portalNightmareBeast = MoveEvent()

function portalNightmareBeast.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	local bossAccessUnlocked = Remastered and Remastered.Gameplay and Remastered.Gameplay.isBossAccessUnlocked and Remastered.Gameplay.isBossAccessUnlocked()
	if not bossAccessUnlocked and player:getLevel() < 250 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need at least level 250 to enter.")
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return false
	end

	if not bossAccessUnlocked and player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.DreamScar.BossCount) < 5 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You still need to defeat the five bosses of the Dream Scar.")
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return false
	end

	return true
end

portalNightmareBeast:type("stepin")
portalNightmareBeast:position({ x = 32211, y = 32081, z = 15 })
portalNightmareBeast:register()
