local internalNpcName = "Yana"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2
npcConfig.outfit = { lookType = 471, lookHead = 0, lookBody = 57, lookLegs = 0, lookFeet = 68, lookAddons = 2 }
npcConfig.flags = { floorchange = false }
npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Trading tokens! First-class equipment available!" },
}
npcConfig.currency = 22721
npcConfig.shop = {
	{ name = "axe of desctruction", clientId = 27451, buy = 50 },
	{ name = "blade of desctruction", clientId = 27449, buy = 50 },
	{ name = "bow of desctruction", clientId = 27455, buy = 50 },
	{ name = "chopper of desctruction", clientId = 27452, buy = 50 },
	{ name = "crossbow of desctruction", clientId = 27456, buy = 50 },
	{ name = "hammer of desctruction", clientId = 27454, buy = 50 },
	{ name = "mace of desctruction", clientId = 27453, buy = 50 },
	{ name = "rod of desctruction", clientId = 27458, buy = 50 },
	{ name = "slayer of desctruction", clientId = 27450, buy = 50 },
	{ name = "wand of desctruction", clientId = 27457, buy = 50 },
}

npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end
npcType.onCheckItem = function(npc, player, clientId, subType) end

local goldTokenId = 22721
local tierPrices = { basic = 1, intricate = 2, powerful = 3 }
local menuText = "Choose a category:\n{Skills} - Skills / Habilidades\n{Elemental Damage} - Elemental Damage / Dano Elemental\n{Elemental Protection} - Elemental Protection / Protecao Elemental\n{Support} - Support / Suporte."
local categoryTexts = {
	skills = "Choose a skill imbuement:\n{Blockade} - Shielding / Defesa com Escudo\n{Chop} - Axe Fighting / Machado\n{Epiphany} - Magic Level / Nivel Magico\n{Precision} - Distance Fighting / Distancia\n{Slash} - Sword Fighting / Espada\n{Bash} - Club Fighting / Clava\n{Punch} - Fist Fighting / Combate com Punhos\n{Back} - Voltar.",
	["elemental damage"] = "Choose an elemental damage imbuement:\n{Reap} - Death Damage / Dano de Morte\n{Electrify} - Energy Damage / Dano de Energia\n{Venom} - Earth Damage / Dano de Terra\n{Frost} - Ice Damage / Dano de Gelo\n{Scorch} - Fire Damage / Dano de Fogo\n{Back} - Voltar.",
	["elemental protection"] = "Choose an elemental protection imbuement:\n{Cloud Fabric} - Energy Protection / Protecao contra Energia\n{Demon Presence} - Holy Protection / Protecao contra Sagrado\n{Dragon Hide} - Fire Protection / Protecao contra Fogo\n{Lich Shroud} - Death Protection / Protecao contra Morte\n{Quara Scale} - Ice Protection / Protecao contra Gelo\n{Snake Skin} - Earth Protection / Protecao contra Terra\n{Back} - Voltar.",
	support = "Choose a support imbuement:\n{Featherweight} - Capacity / Capacidade\n{Strike} - Critical Damage / Dano Critico\n{Swiftness} - Speed / Velocidade\n{Vampirism} - Life Leech / Roubo de Vida\n{Vibrancy} - Paralysis Protection / Protecao contra Paralisia\n{Void} - Mana Leech / Roubo de Mana\n{Back} - Voltar.",
}

local imbuements = {
	bash = { name = "Bash", scrolls = { basic = 51815, intricate = 51724, powerful = 51444 } },
	blockade = { name = "Blockade", scrolls = { basic = 51819, intricate = 51725, powerful = 51445 } },
	chop = { name = "Chop", scrolls = { basic = 51814, intricate = 51726, powerful = 51446 } },
	epiphany = { name = "Epiphany", scrolls = { basic = 51818, intricate = 51731, powerful = 51451 } },
	precision = { name = "Precision", scrolls = { basic = 51816, intricate = 51735, powerful = 51455 } },
	punch = { name = "Punch", scrolls = { basic = 51817, intricate = 51736, powerful = 51456 } },
	slash = { name = "Slash", scrolls = { basic = 51820, intricate = 51740, powerful = 51460 } },
	electrify = { name = "Electrify", scrolls = { basic = 51803, intricate = 51730, powerful = 51450 } },
	frost = { name = "Frost", scrolls = { basic = 51805, intricate = 51733, powerful = 51453 } },
	reap = { name = "Reap", scrolls = { basic = 51801, intricate = 51738, powerful = 51458 } },
	scorch = { name = "Scorch", scrolls = { basic = 51804, intricate = 51739, powerful = 51459 } },
	venom = { name = "Venom", scrolls = { basic = 51802, intricate = 51745, powerful = 51465 } },
	["cloud fabric"] = { name = "Cloud Fabric", scrolls = { basic = 51808, intricate = 51727, powerful = 51447 } },
	["demon presence"] = { name = "Demon Presence", scrolls = { basic = 51810, intricate = 51728, powerful = 51448 } },
	["dragon hide"] = { name = "Dragon Hide", scrolls = { basic = 51809, intricate = 51729, powerful = 51449 } },
	["lich shroud"] = { name = "Lich Shroud", scrolls = { basic = 51806, intricate = 51734, powerful = 51454 } },
	["quara scale"] = { name = "Quara Scale", scrolls = { basic = 51811, intricate = 51737, powerful = 51457 } },
	["snake skin"] = { name = "Snake Skin", scrolls = { basic = 51807, intricate = 51741, powerful = 51461 } },
	featherweight = { name = "Featherweight", scrolls = { basic = 51822, intricate = 51732, powerful = 51452 } },
	strike = { name = "Strike", scrolls = { basic = 51800, intricate = 51742, powerful = 51462 } },
	swiftness = { name = "Swiftness", scrolls = { basic = 51821, intricate = 51743, powerful = 51463 } },
	vampirism = { name = "Vampirism", scrolls = { basic = 51812, intricate = 51744, powerful = 51464 } },
	vibrancy = { name = "Vibrancy", scrolls = { basic = 51823, intricate = 51746, powerful = 51466 } },
	void = { name = "Void", scrolls = { basic = 51813, intricate = 51747, powerful = 51467 } },
}

local slotAliases = {
	head = CONST_SLOT_HEAD, helmet = CONST_SLOT_HEAD, helm = CONST_SLOT_HEAD,
	armor = CONST_SLOT_ARMOR, armour = CONST_SLOT_ARMOR, chest = CONST_SLOT_ARMOR,
	left = CONST_SLOT_LEFT, weapon = CONST_SLOT_LEFT, mainhand = CONST_SLOT_LEFT, main = CONST_SLOT_LEFT,
	right = CONST_SLOT_RIGHT, shield = CONST_SLOT_RIGHT, spellbook = CONST_SLOT_RIGHT, offhand = CONST_SLOT_RIGHT,
	boots = CONST_SLOT_FEET, feet = CONST_SLOT_FEET,
	backpack = CONST_SLOT_BACKPACK, bp = CONST_SLOT_BACKPACK,
}
local slotNames = {
	[CONST_SLOT_HEAD] = "helmet",
	[CONST_SLOT_ARMOR] = "armor",
	[CONST_SLOT_LEFT] = "left hand",
	[CONST_SLOT_RIGHT] = "right hand",
	[CONST_SLOT_FEET] = "boots",
	[CONST_SLOT_BACKPACK] = "backpack",
}
local playerState = {}

local tierEffects = {
	bash = { basic = "+1 Club Fighting / Clava", intricate = "+2 Club Fighting / Clava", powerful = "+4 Club Fighting / Clava" },
	blockade = { basic = "+1 Shielding / Defesa com Escudo", intricate = "+2 Shielding / Defesa com Escudo", powerful = "+4 Shielding / Defesa com Escudo" },
	chop = { basic = "+1 Axe Fighting / Machado", intricate = "+2 Axe Fighting / Machado", powerful = "+4 Axe Fighting / Machado" },
	epiphany = { basic = "+1 Magic Level / Nivel Magico", intricate = "+2 Magic Levels / Niveis Magicos", powerful = "+4 Magic Levels / Niveis Magicos" },
	precision = { basic = "+1 Distance Fighting / Distancia", intricate = "+2 Distance Fighting / Distancia", powerful = "+4 Distance Fighting / Distancia" },
	punch = { basic = "+1 Fist Fighting / Combate com Punhos", intricate = "+2 Fist Fighting / Combate com Punhos", powerful = "+4 Fist Fighting / Combate com Punhos" },
	slash = { basic = "+1 Sword Fighting / Espada", intricate = "+2 Sword Fighting / Espada", powerful = "+4 Sword Fighting / Espada" },
	electrify = { basic = "10% Energy Damage / Dano de Energia", intricate = "25% Energy Damage / Dano de Energia", powerful = "50% Energy Damage / Dano de Energia" },
	frost = { basic = "10% Ice Damage / Dano de Gelo", intricate = "25% Ice Damage / Dano de Gelo", powerful = "50% Ice Damage / Dano de Gelo" },
	reap = { basic = "10% Death Damage / Dano de Morte", intricate = "25% Death Damage / Dano de Morte", powerful = "50% Death Damage / Dano de Morte" },
	scorch = { basic = "10% Fire Damage / Dano de Fogo", intricate = "25% Fire Damage / Dano de Fogo", powerful = "50% Fire Damage / Dano de Fogo" },
	venom = { basic = "10% Earth Damage / Dano de Terra", intricate = "25% Earth Damage / Dano de Terra", powerful = "50% Earth Damage / Dano de Terra" },
	["cloud fabric"] = { basic = "3% Energy Protection / Protecao contra Energia", intricate = "8% Energy Protection / Protecao contra Energia", powerful = "15% Energy Protection / Protecao contra Energia" },
	["demon presence"] = { basic = "3% Holy Protection / Protecao contra Sagrado", intricate = "8% Holy Protection / Protecao contra Sagrado", powerful = "15% Holy Protection / Protecao contra Sagrado" },
	["dragon hide"] = { basic = "3% Fire Protection / Protecao contra Fogo", intricate = "8% Fire Protection / Protecao contra Fogo", powerful = "15% Fire Protection / Protecao contra Fogo" },
	["lich shroud"] = { basic = "2% Death Protection / Protecao contra Morte", intricate = "5% Death Protection / Protecao contra Morte", powerful = "10% Death Protection / Protecao contra Morte" },
	["quara scale"] = { basic = "3% Ice Protection / Protecao contra Gelo", intricate = "8% Ice Protection / Protecao contra Gelo", powerful = "15% Ice Protection / Protecao contra Gelo" },
	["snake skin"] = { basic = "3% Earth Protection / Protecao contra Terra", intricate = "8% Earth Protection / Protecao contra Terra", powerful = "15% Earth Protection / Protecao contra Terra" },
	featherweight = { basic = "+3% Capacity / Capacidade", intricate = "+8% Capacity / Capacidade", powerful = "+15% Capacity / Capacidade" },
	strike = { basic = "10% Critical Chance, +15% Critical Damage / Dano Critico", intricate = "10% Critical Chance, +25% Critical Damage / Dano Critico", powerful = "10% Critical Chance, +50% Critical Damage / Dano Critico" },
	swiftness = { basic = "+10 Speed / Velocidade", intricate = "+15 Speed / Velocidade", powerful = "+30 Speed / Velocidade" },
	vampirism = { basic = "5% Life Leech / Roubo de Vida", intricate = "10% Life Leech / Roubo de Vida", powerful = "25% Life Leech / Roubo de Vida" },
	vibrancy = { basic = "15% Paralysis Protection / Protecao contra Paralisia", intricate = "25% Paralysis Protection / Protecao contra Paralisia", powerful = "50% Paralysis Protection / Protecao contra Paralisia" },
	void = { basic = "3% Mana Leech / Roubo de Mana", intricate = "5% Mana Leech / Roubo de Mana", powerful = "8% Mana Leech / Roubo de Mana" },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval) npcHandler:onThink(npc, interval) end
npcType.onAppear = function(npc, creature) npcHandler:onAppear(npc, creature) end
npcType.onDisappear = function(npc, creature) npcHandler:onDisappear(npc, creature) end
npcType.onMove = function(npc, creature, fromPosition, toPosition) npcHandler:onMove(npc, creature, fromPosition, toPosition) end
npcType.onSay = function(npc, creature, type, message) npcHandler:onSay(npc, creature, type, message) end
npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
	playerState[creature:getId()] = nil
end

local function clearState(playerId)
	playerState[playerId] = nil
	npcHandler:setTopic(playerId, 0)
end

local function tierText(imbuementKey)
	local effects = tierEffects[imbuementKey] or {}
	return "Choose level:\n{Basic} - " .. (effects.basic or "Basic") .. " - 1 Gold Token\n{Intricate} - " .. (effects.intricate or "Intricate") .. " - 2 Gold Tokens\n{Powerful} - " .. (effects.powerful or "Powerful") .. " - 3 Gold Tokens\n{Back} - Voltar."
end

local function itemName(item)
	return item and ItemType(item:getId()):getName() or "item"
end

local function applyGoldTokenImbuement(player, state)
	local item = player:getSlotItem(state.slot)
	if not item then
		return false, "You are not wearing an item in your " .. slotNames[state.slot] .. " slot."
	end
	if not item.getImbuementSlot or item:getImbuementSlot() <= 0 then
		return false, "That item is not imbuable."
	end
	if player:getItemCount(goldTokenId) < state.price then
		return false, "You need " .. state.price .. " Gold Token" .. (state.price == 1 and "" or "s") .. " for that imbuement."
	end

	local scrollCountBefore = player:getItemCount(state.scrollId)
	local scroll = player:addItem(state.scrollId, 1, true)
	if not scroll then
		return false, "You need enough capacity and room for the imbuing process."
	end

	player:applyImbuementScrollToItem(state.scrollId, item)
	local scrollCountAfter = player:getItemCount(state.scrollId)
	if scrollCountAfter > scrollCountBefore then
		player:removeItem(state.scrollId, scrollCountAfter - scrollCountBefore)
		return false, "I could not apply that imbuement to your " .. itemName(item) .. ". Check item compatibility, free slots and duplicate imbuements."
	end

	if not player:removeItem(goldTokenId, state.price) then
		return false, "The imbuement was applied, but I could not remove the Gold Tokens. Please contact an administrator."
	end

	player:save()
	return true, "Your " .. itemName(item) .. " has been imbued with " .. state.tierName .. " " .. state.imbuement.name .. "."
end

local function greetCallback(npc, creature)
	clearState(creature:getId())
	npcHandler:setTopic(creature:getId(), 1)
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local msg = message:lower()
	if MsgContains(msg, "back") then
		playerState[playerId] = {}
		npcHandler:setTopic(playerId, 1)
		npcHandler:say(menuText, npc, creature)
		return true
	end
	if MsgContains(msg, "cancel") or MsgContains(msg, "no") then
		clearState(playerId)
		npcHandler:say("Very well. No Gold Tokens were used.", npc, creature)
		return true
	end
	if MsgContains(msg, "information") then
		npcHandler:say("Tokens are small objects made of metal or other materials. I can trade equipment for them, or imbue your equipped items with them.", npc, creature)
		return true
	end
	if MsgContains(msg, "worth") then
		npcHandler:say("Disrupt the Heart of Destruction, fell the World Devourer to prove your worth and you will be granted the power to imbue powerful equipment.", npc, creature)
		return true
	end
	if MsgContains(msg, "tokens") then
		npc:openShopWindow(creature)
		npcHandler:say("If you have any Gold Tokens with you, let's have a look! These are my equipment offers.", npc, creature)
		return true
	end
	if MsgContains(msg, "trade") or MsgContains(msg, "imbue") or MsgContains(msg, "imbuement") then
		playerState[playerId] = {}
		npcHandler:setTopic(playerId, 1)
		npcHandler:say(menuText, npc, creature)
		return true
	end

	if npcHandler:getTopic(playerId) == 1 then
		if msg == "skill" then
			msg = "skills"
		end
		if categoryTexts[msg] then
			npcHandler:say(categoryTexts[msg], npc, creature)
			return true
		end
		local imbuement = imbuements[msg]
		if imbuement then
			playerState[playerId] = { imbuement = imbuement, imbuementKey = msg }
			npcHandler:setTopic(playerId, 2)
			npcHandler:say("You chose " .. imbuement.name .. ". " .. tierText(msg), npc, creature)
			return true
		end
		npcHandler:say(menuText, npc, creature)
		return true
	end

	if npcHandler:getTopic(playerId) == 2 then
		local state = playerState[playerId]
		local price = tierPrices[msg]
		if state and price and state.imbuement.scrolls[msg] then
			state.tier = msg
			state.tierName = msg:gsub("^%l", string.upper)
			state.price = price
			state.scrollId = state.imbuement.scrolls[msg]
			npcHandler:setTopic(playerId, 3)
			local effectText = tierEffects[state.imbuementKey] and tierEffects[state.imbuementKey][msg] or "imbuement effect"
			npcHandler:say(state.tierName .. " " .. state.imbuement.name .. " grants " .. effectText .. " and costs " .. state.price .. " Gold Token" .. (state.price == 1 and "" or "s") .. ".\nChoose item: {Helmet}, {Armor}, {Left}, {Right}, {Boots}, {Backpack} or {Back}.", npc, creature)
			return true
		end
		npcHandler:say(tierText(state and state.imbuementKey), npc, creature)
		return true
	end

	if npcHandler:getTopic(playerId) == 3 then
		local state = playerState[playerId]
		local slot = slotAliases[msg]
		if state and slot then
			local item = player:getSlotItem(slot)
			if not item then
				npcHandler:say("You are not wearing an item in your " .. slotNames[slot] .. " slot.", npc, creature)
				return true
			end
			state.slot = slot
			npcHandler:setTopic(playerId, 4)
			local effectText = tierEffects[state.imbuementKey] and tierEffects[state.imbuementKey][state.tier] or "imbuement effect"
			npcHandler:say(state.tierName .. " " .. state.imbuement.name .. " grants " .. effectText .. " and costs " .. state.price .. " Gold Token" .. (state.price == 1 and "" or "s") .. ". Apply it to your " .. itemName(item) .. "? {Yes} - Sim {No} - Nao.", npc, creature)
			return true
		end
		npcHandler:say("Choose item: {Helmet}, {Armor}, {Left}, {Right}, {Boots}, {Backpack} or {Back}.", npc, creature)
		return true
	end

	if npcHandler:getTopic(playerId) == 4 and MsgContains(msg, "yes") then
		local state = playerState[playerId]
		if not state then
			clearState(playerId)
			npcHandler:say("Please choose an imbuement again.", npc, creature)
			return true
		end
		local success, resultMessage = applyGoldTokenImbuement(player, state)
		clearState(playerId)
		npcHandler:say(resultMessage, npc, creature)
		return true
	end

	npcHandler:say(menuText, npc, creature)
	return true
end

npcHandler:setCallback(CALLBACK_SET_INTERACTION, onAddFocus)
npcHandler:setCallback(CALLBACK_REMOVE_INTERACTION, onReleaseFocus)
npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Hello |PLAYERNAME|. I can trade equipment for {tokens} or imbue your equipment using Gold Tokens. " .. menuText)
npcHandler:setMessage(MESSAGE_WALKAWAY, "See you later.")
npcHandler:setMessage(MESSAGE_FAREWELL, "See you later.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, false)

npcType:register(npcConfig)
