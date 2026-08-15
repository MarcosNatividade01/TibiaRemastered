local theThievesDoor = Action()
function theThievesDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local doorAccessUnlocked = Remastered and Remastered.Gameplay and Remastered.Gameplay.isDoorAccessUnlocked and Remastered.Gameplay.isDoorAccessUnlocked()
	if doorAccessUnlocked or (player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06) == 3 and player:getItemCount(7936) > 0) then
		player:say("You slip through the door.", TALKTYPE_MONSTER_SAY)
		player:teleportTo(Position(32359, 32786, 6))
	else
		player:say("The fish must be somewhere in this room.", TALKTYPE_MONSTER_SAY)
	end
	return true
end

theThievesDoor:aid(41714)
theThievesDoor:register()
