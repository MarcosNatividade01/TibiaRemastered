local drumeExit = MoveEvent()

local exitPosition = Position(32457, 32508, 6)
local exitPortalPosition = Position(32469, 32503, 7)

local function leaveDrumeRoom(player)
	if not player then
		return true
	end

	player:teleportTo(exitPosition)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

function drumeExit.onStepIn(creature, item, position, fromPosition)
	return leaveDrumeRoom(creature:getPlayer())
end

drumeExit:aid(47404)
drumeExit:position(exitPortalPosition)
drumeExit:position(Position(32468, 32503, 7))
drumeExit:position(Position(32469, 32502, 7))
drumeExit:position(Position(32469, 32504, 7))
drumeExit:position(Position(32470, 32503, 7))
drumeExit:type("stepin")
drumeExit:register()

local drumeExitAction = Action()

function drumeExitAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return leaveDrumeRoom(player)
end

drumeExitAction:aid(47404)
drumeExitAction:position(exitPortalPosition)
drumeExitAction:id(2824)
drumeExitAction:register()
