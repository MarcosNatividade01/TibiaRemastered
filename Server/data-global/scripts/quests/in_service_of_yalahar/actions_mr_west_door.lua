local inServiceYalaharWest = Action()
function inServiceYalaharWest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local doorAccessUnlocked = Remastered and Remastered.Gameplay and Remastered.Gameplay.isDoorAccessUnlocked and Remastered.Gameplay.isDoorAccessUnlocked()
	local hasAccess = doorAccessUnlocked or player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline) >= 24
	if item.uid == 3081 then
		if hasAccess then
			if item.itemid == 5287 then
				player:teleportTo(toPosition, true)
				item:transform(5288)
				if not doorAccessUnlocked then
					player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor, 1)
				end
			end
		end
	elseif item.uid == 3082 then
		if hasAccess then
			if item.itemid == 6260 then
				player:teleportTo(toPosition, true)
				item:transform(6261)
				if not doorAccessUnlocked then
					player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor, 2)
				end
			end
		end
	end
	return true
end

inServiceYalaharWest:uid(3081, 3082)
inServiceYalaharWest:register()
