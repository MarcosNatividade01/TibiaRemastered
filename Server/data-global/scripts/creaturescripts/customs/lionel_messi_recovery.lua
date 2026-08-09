local lionelMessiRecovery = CreatureEvent("LionelMessiRecovery")

local playerName = "Lionel Messi"
local helmetRecoveryStorage = 910252
local weaponRecoveryStorage = 910253
local powerfulStrikeScrollId = 51462
local powerfulVampirismScrollId = 51464
local powerfulVoidScrollId = 51467

local function applyScrollToItem(player, item, scrollId)
	if not item or not item.getImbuementSlot or item:getImbuementSlot() <= 0 then
		return false
	end

	local scrollCountBefore = player:getItemCount(scrollId)
	local scroll = player:addItem(scrollId, 1, true)
	if not scroll then
		return false
	end

	player:applyImbuementScrollToItem(scrollId, item)
	local scrollCountAfter = player:getItemCount(scrollId)
	if scrollCountAfter > scrollCountBefore then
		player:removeItem(scrollId, scrollCountAfter - scrollCountBefore)
	end
	return true
end

function lionelMessiRecovery.onLogin(player)
	if player:getName() ~= playerName then
		return true
	end

	if player:getStorageValue(helmetRecoveryStorage) ~= 1 then
		local helmet = player:getSlotItem(CONST_SLOT_HEAD)
		if helmet and helmet:getId() == 3392 then
			applyScrollToItem(player, helmet, powerfulVoidScrollId)
		end
		player:setStorageValue(helmetRecoveryStorage, 1)
	end

	if player:getStorageValue(weaponRecoveryStorage) ~= 1 then
		local weapon = player:getSlotItem(CONST_SLOT_LEFT) or player:getSlotItem(CONST_SLOT_RIGHT)
		if weapon and weapon:getId() == 7434 then
			applyScrollToItem(player, weapon, powerfulStrikeScrollId)
			applyScrollToItem(player, weapon, powerfulVampirismScrollId)
			applyScrollToItem(player, weapon, powerfulVoidScrollId)
		end
		player:setStorageValue(weaponRecoveryStorage, 1)
	end

	player:save()
	return true
end

lionelMessiRecovery:register()
