local drumeExit = MoveEvent()

local exitPosition = Position(32453, 32503, 7)
local exitPortalPosition = Position(32469, 32503, 7)

function drumeExit.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	player:teleportTo(exitPosition)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

drumeExit:aid(47404)
drumeExit:position(exitPortalPosition)
drumeExit:type("stepin")
drumeExit:register()
