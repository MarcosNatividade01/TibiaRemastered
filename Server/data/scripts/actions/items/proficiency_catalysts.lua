local config = {
	[51588] = { baseWeaponProficiencyExperience = 25000 },
	[51589] = { baseWeaponProficiencyExperience = 100000 },
}

local function getWeaponProficiencyExperience(baseExperience)
	if Remastered and Remastered.Balance and Remastered.Balance.applyWeaponProficiencyExperience then
		return Remastered.Balance.applyWeaponProficiencyExperience(baseExperience)
	end
	return baseExperience
end

local proficiencyCatalysts = Action()

function proficiencyCatalysts.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or type(target) ~= "userdata" or not target:isItem() then
		return false
	end

	local targetType = target:getType()
	if not targetType then
		return false
	end

	if targetType:getWeaponType() == WEAPON_SWORD or targetType:getWeaponType() == WEAPON_CLUB or targetType:getWeaponType() == WEAPON_AXE or targetType:getWeaponType() == WEAPON_DISTANCE or targetType:getWeaponType() == WEAPON_WAND or targetType:getWeaponType() == WEAPON_MISSILE or targetType:getWeaponType() == WEAPON_FIST then
		local configData = config[item.itemid]
		if not configData then
			return false
		end

		player:sendWeaponProficiencyExperience(target.itemid, getWeaponProficiencyExperience(configData.baseWeaponProficiencyExperience))

		item:remove(1)
		return true
	end

	return false
end

proficiencyCatalysts:id(51588, 51589)
proficiencyCatalysts:register()
