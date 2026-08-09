local drumeEntrance = MoveEvent()
function drumeEntrance.onStepIn(creature, item, position, fromPosition)
	local bossAccessUnlocked = Remastered and Remastered.Gameplay and Remastered.Gameplay.isBossAccessUnlocked and Remastered.Gameplay.isBossAccessUnlocked()
	if not bossAccessUnlocked and creature:isPlayer() and not creature:canFightBoss("Drume") then
		creature:teleportTo(fromPosition, true)
		creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You've been into the skirmish in the last 10 hours.")
	end
	return true
end

drumeEntrance:aid(59601)
drumeEntrance:register()
