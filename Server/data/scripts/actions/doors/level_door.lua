local doorIds = {}
for index, value in ipairs(LevelDoorTable) do
	if not table.contains(doorIds, value.openDoor) then
		table.insert(doorIds, value.openDoor)
	end

	if not table.contains(doorIds, value.closedDoor) then
		table.insert(doorIds, value.closedDoor)
	end
end

local levelDoor = Action()
function levelDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for index, value in ipairs(LevelDoorTable) do
		if value.closedDoor == item.itemid then
			local requiredLevel = item.actionid > 0 and item.actionid - 1000 or 0
			if requiredLevel > 0 and Remastered and Remastered.Gameplay and Remastered.Gameplay.getReducedAccessLevel then
				requiredLevel = Remastered.Gameplay.getReducedAccessLevel(requiredLevel)
			end

			if requiredLevel <= 0 or player:getLevel() >= requiredLevel then
				item:transform(value.openDoor)
				item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
				player:teleportTo(toPosition, true)
				return true
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Only the worthy may pass.")
				return true
			end
		end
	end

	if Creature.checkCreatureInsideDoor(player, toPosition) then
		return true
	end
	return true
end

for index, value in ipairs(doorIds) do
	levelDoor:id(value)
end

levelDoor:register()
