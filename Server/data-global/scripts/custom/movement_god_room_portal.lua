local fallbackDestination = Position(32369, 32241, 7) -- Thais temple
local portalPositions = {
	Position(32821, 31533, 10),
	Position(32823, 31533, 10),
}

local function getTempleDestination(player)
	local town = player:getTown()
	if not town then
		return fallbackDestination
	end

	local destination = town:getTemplePosition()
	if destination.x == 0 or destination.y == 0 then
		return fallbackDestination
	end
	return destination
end

local function leaveGodRoom(player)
	local sourcePosition = player:getPosition()
	local destination = getTempleDestination(player)
	sourcePosition:sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(destination, true)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

local godRoomPortalMovement = MoveEvent()

function godRoomPortalMovement.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	return leaveGodRoom(player)
end

local godRoomPortalAction = Action()

function godRoomPortalAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return leaveGodRoom(player)
end

for _, position in ipairs(portalPositions) do
	godRoomPortalMovement:position(position)
	godRoomPortalAction:position(position)
end

godRoomPortalMovement:register()
godRoomPortalAction:register()
