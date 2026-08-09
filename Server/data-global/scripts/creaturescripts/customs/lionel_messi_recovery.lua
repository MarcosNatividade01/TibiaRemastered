local lionelMessiRecovery = CreatureEvent("LionelMessiRecovery")

local playerName = "Lionel Messi"
local recoveryStorage = 910252
local powerfulVoidScrollId = 51467

function lionelMessiRecovery.onLogin(player)
	if player:getName() ~= playerName or player:getStorageValue(recoveryStorage) == 1 then
		return true
	end

	local helmet = player:getSlotItem(CONST_SLOT_HEAD)
	if helmet and helmet:getId() == 3392 and helmet.getImbuementSlot and helmet:getImbuementSlot() > 0 then
		local scrollCountBefore = player:getItemCount(powerfulVoidScrollId)
		local scroll = player:addItem(powerfulVoidScrollId, 1, true)
		if scroll then
			player:applyImbuementScrollToItem(powerfulVoidScrollId, helmet)
			local scrollCountAfter = player:getItemCount(powerfulVoidScrollId)
			if scrollCountAfter > scrollCountBefore then
				player:removeItem(powerfulVoidScrollId, scrollCountAfter - scrollCountBefore)
			end
		end
	end

	player:setStorageValue(recoveryStorage, 1)
	player:save()
	return true
end

lionelMessiRecovery:register()
