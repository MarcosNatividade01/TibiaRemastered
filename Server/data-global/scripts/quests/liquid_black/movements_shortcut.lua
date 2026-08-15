local enterPosition = { x = 33478, y = 31314, z = 7 }

local shortcut = MoveEvent()

function shortcut.onStepIn(creature, item, toPosition, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local questAccessUnlocked = Remastered and Remastered.Gameplay and Remastered.Gameplay.isQuestAccessUnlocked and Remastered.Gameplay.isQuestAccessUnlocked()
	if questAccessUnlocked or player:getStorageValue(Storage.Quest.U9_4.LiquidBlackQuest.Visitor) >= 4 then
		if not questAccessUnlocked then
			player:setStorageValue(Storage.Quest.U9_4.LiquidBlackQuest.Visitor, 5)
		end
		player:teleportTo(enterPosition)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	else
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end

shortcut:aid(57746)
shortcut:register()
