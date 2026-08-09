local rope = Action()

function rope.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return onUseRope(player, item, fromPosition, target, toPosition, isHotkey)
end

rope:id(3003, 646, 7884, 7895, 20206, 21375, 31366)
rope:register()
