-- Click-first presentation layer for the classic keyword-based NPC system.
-- It only formats outgoing text; keyword processing and gameplay callbacks stay unchanged.

NpcClickable = NpcClickable or {
	maxKeywordLength = 32,
	maxLinksPerMessage = 12,
	maxGreetingOptions = 8,
}

local ignoredKeywords = {
	["hi"] = true,
	["hello"] = true,
	["greetings"] = true,
	["greet"] = true,
	["bye"] = true,
	["farewell"] = true,
}

local explicitPublicKeywords = {
	"elemental protection",
	"elemental damage",
	"information",
	"imbuement",
	"blessings",
	"promotion",
	"withdraw",
	"transfer",
	"deposit",
	"balance",
	"mission",
	"rewards",
	"travel",
	"passage",
	"trade",
	"tasks",
	"quest",
	"task",
	"help",
	"back",
}

local greetingKeywordPriority = {
	"help",
	"information",
	"job",
	"name",
	"passage",
	"mission",
	"quest",
	"rewards",
	"blessings",
	"promotion",
	"tasks",
	"task",
	"imbuement",
}

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

local function isWordCharacter(value)
	return value ~= "" and value:match("[%w']") ~= nil
end

local function isSafeKeyword(value)
	if type(value) ~= "string" then
		return false
	end
	value = trim(value):lower()
	if #value < 2 or #value > NpcClickable.maxKeywordLength or ignoredKeywords[value] then
		return false
	end
	if value:find("%", 1, true) or value:find("|", 1, true) or value:find("{", 1, true) or value:find("}", 1, true) then
		return false
	end
	return value:match("[%a]") ~= nil
end

local function nodeLeadsToTravel(node)
	if not node then
		return false
	end
	if node.parameters and node.parameters.destination and node.parameters.cost ~= nil then
		return true
	end
	for _, child in pairs(node.children or {}) do
		if nodeLeadsToTravel(child) then
			return true
		end
	end
	return false
end

local function addCandidate(candidates, seen, keyword, node, player)
	keyword = type(keyword) == "string" and trim(keyword) or nil
	if not keyword or not isSafeKeyword(keyword) then
		return
	end

	local normalized = keyword:lower()
	if node and node.checkMessage then
		local ok, available = pcall(node.checkMessage, node, player, normalized)
		if not ok or not available then
			return
		end
	end
	if seen[normalized] then
		return
	end
	seen[normalized] = true
	candidates[#candidates + 1] = {
		keyword = keyword,
		normalized = normalized,
		node = node,
		isTravel = nodeLeadsToTravel(node),
	}
end

local function addNodeCandidate(candidates, seen, node, player)
	local keys = node and node.keywords
	if type(keys) ~= "table" then
		return
	end

	local stringKeys = {}
	for _, key in ipairs(keys) do
		if type(key) == "string" then
			stringKeys[#stringKeys + 1] = key
		end
	end
	if #stringKeys == 0 then
		return
	end

	if keys.callback then
		for _, key in ipairs(stringKeys) do
			addCandidate(candidates, seen, key, node, player)
		end
	else
		addCandidate(candidates, seen, table.concat(stringKeys, " "), node, player)
	end
end

local function addChildren(candidates, seen, node, player)
	for _, child in pairs(node and node.children or {}) do
		addNodeCandidate(candidates, seen, child, player)
	end
end

local function collectCandidates(npcHandler, player)
	local candidates = {}
	local seen = {}
	local keywordHandler = npcHandler and npcHandler.keywordHandler
	if keywordHandler then
		local root = keywordHandler:getRoot()
		addChildren(candidates, seen, root, player)

		local current = keywordHandler:getLastNode(player)
		if current and current ~= root then
			addChildren(candidates, seen, current, player)
			addChildren(candidates, seen, current:getParent(), player)
		end
	end

	for _, keyword in ipairs(explicitPublicKeywords) do
		addCandidate(candidates, seen, keyword, nil, player)
	end

	table.sort(candidates, function(first, second)
		return #first.normalized > #second.normalized
	end)
	return candidates
end

local function countLinks(message)
	local count = 0
	for _ in message:gmatch("{[^{}]+}") do
		count = count + 1
	end
	return count
end

local function containsLink(message, keyword)
	return message:lower():find("{" .. keyword:lower() .. "}", 1, true) ~= nil
end

local function linkPlainSegment(segment, candidates, budget)
	if budget <= 0 or segment == "" then
		return segment, 0
	end

	local result = {}
	local lower = segment:lower()
	local index = 1
	local links = 0
	while index <= #segment do
		local match = nil
		if links < budget then
			for _, candidate in ipairs(candidates) do
				local finish = index + #candidate.normalized - 1
				if lower:sub(index, finish) == candidate.normalized then
					local before = index > 1 and lower:sub(index - 1, index - 1) or ""
					local after = finish < #lower and lower:sub(finish + 1, finish + 1) or ""
					local startsAsWord = isWordCharacter(candidate.normalized:sub(1, 1))
					local endsAsWord = isWordCharacter(candidate.normalized:sub(-1))
					if (not startsAsWord or not isWordCharacter(before)) and (not endsAsWord or not isWordCharacter(after)) then
						match = candidate
						break
					end
				end
			end
		end

		if match then
			result[#result + 1] = "{" .. segment:sub(index, index + #match.normalized - 1) .. "}"
			index = index + #match.normalized
			links = links + 1
		else
			result[#result + 1] = segment:sub(index, index)
			index = index + 1
		end
	end
	return table.concat(result), links
end

local function linkMentionedKeywords(message, candidates)
	local existingLinks = countLinks(message)
	local budget = math.max(0, NpcClickable.maxLinksPerMessage - existingLinks)
	if budget == 0 then
		return message
	end

	local result = {}
	local position = 1
	while position <= #message do
		local openBrace = message:find("{", position, true)
		if not openBrace then
			local linked, used = linkPlainSegment(message:sub(position), candidates, budget)
			result[#result + 1] = linked
			budget = budget - used
			break
		end

		local closeBrace = message:find("}", openBrace + 1, true)
		if not closeBrace then
			-- Preserve malformed legacy text exactly; adding more markup could crash old clients.
			return message
		end

		local linked, used = linkPlainSegment(message:sub(position, openBrace - 1), candidates, budget)
		result[#result + 1] = linked
		result[#result + 1] = message:sub(openBrace, closeBrace)
		budget = budget - used
		position = closeBrace + 1
	end
	return table.concat(result)
end

local function addOption(options, seen, keyword)
	local normalized = keyword:lower()
	if not seen[normalized] and #options < NpcClickable.maxGreetingOptions then
		seen[normalized] = true
		options[#options + 1] = keyword
	end
end

local function appendGreetingOptions(message, candidates, npc)
	if countLinks(message) >= 4 then
		return message
	end

	local options = {}
	local seen = {}
	for existing in message:gmatch("{([^{}]+)}") do
		seen[trim(existing):lower()] = true
	end

	if npc and npc.isMerchant and npc:isMerchant() then
		addOption(options, seen, "Trade")
	end

	local lower = message:lower()
	if lower:find("bank account", 1, true) or lower:find("deposit", 1, true) or lower:find("withdraw", 1, true) then
		addOption(options, seen, "Balance")
		addOption(options, seen, "Deposit")
		addOption(options, seen, "Withdraw")
		addOption(options, seen, "Transfer")
	end

	for _, candidate in ipairs(candidates) do
		if candidate.isTravel then
			addOption(options, seen, candidate.keyword)
		end
	end

	for _, preferred in ipairs(greetingKeywordPriority) do
		for _, candidate in ipairs(candidates) do
			if candidate.normalized == preferred and candidate.node then
				addOption(options, seen, candidate.keyword:gsub("^%l", string.upper))
				break
			end
		end
	end

	if #options == 0 then
		return message
	end

	local rendered = {}
	for _, option in ipairs(options) do
		rendered[#rendered + 1] = "{" .. option .. "}"
	end
	return message .. " Options: " .. table.concat(rendered, ", ") .. "."
end

local function appendConfirmationOptions(message)
	-- Keyword linking may already have changed "go" into "{go}".
	-- Strip presentation braces before classifying the sentence.
	local lower = message:lower():gsub("[{}]", "")
	local isOpenTravelQuestion = lower:find("where do you want to go", 1, true)
		or lower:find("where do you wish to go", 1, true)
		or lower:find("where would you like to go", 1, true)
	local isConfirmation = not isOpenTravelQuestion and (lower:find("do you want", 1, true)
		or lower:find("would you like", 1, true)
		or lower:find("are you sure", 1, true)
		or lower:find("shall i ", 1, true)
		or lower:find("please confirm", 1, true))
	if not isConfirmation or countLinks(message) >= NpcClickable.maxLinksPerMessage then
		return message
	end

	local hasYes = containsLink(message, "yes")
	local hasNo = containsLink(message, "no")
	if hasYes and hasNo then
		return message
	end
	if not hasYes and not hasNo then
		return message .. " {Yes} / {No}"
	elseif not hasYes then
		return message .. " {Yes}"
	end
	return message .. " {No}"
end

local function appendTravelPromptOptions(message, candidates)
	local lower = message:lower():gsub("[{}]", "")
	local isOpenTravelQuestion = lower:find("where do you want to go", 1, true)
		or lower:find("where do you wish to go", 1, true)
		or lower:find("where would you like to go", 1, true)
	if not isOpenTravelQuestion then
		return message
	end

	local options = {}
	local seen = {}
	for existing in message:gmatch("{([^{}]+)}") do
		seen[trim(existing):lower()] = true
	end
	for _, candidate in ipairs(candidates) do
		if candidate.isTravel then
			addOption(options, seen, candidate.keyword)
		end
	end
	if #options == 0 then
		return message
	end

	local rendered = {}
	for _, option in ipairs(options) do
		rendered[#rendered + 1] = "{" .. option .. "}"
	end
	return message .. " Destinations: " .. table.concat(rendered, ", ") .. "."
end

function NpcClickable.format(npcHandler, message, npc, player, isGreeting)
	if type(message) ~= "string" or not player or message == "" then
		return message
	end

	local candidates = collectCandidates(npcHandler, player)
	local formatted = linkMentionedKeywords(message, candidates)
	formatted = appendTravelPromptOptions(formatted, candidates)
	formatted = appendConfirmationOptions(formatted)
	if isGreeting then
		formatted = appendGreetingOptions(formatted, candidates, npc)
	end
	return formatted
end
