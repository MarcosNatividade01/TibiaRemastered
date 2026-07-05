local AdminBalanceTests = {
	_remastered = nil,
	_metadata = {},
}

local function trim(value)
	value = tostring(value or "")
	value = string.gsub(value, "^%s+", "")
	value = string.gsub(value, "%s+$", "")
	return value
end

local function splitWords(value)
	local words = {}
	for word in string.gmatch(trim(value), "%S+") do
		table.insert(words, word)
	end
	return words
end

local function appendLog(line)
	local candidates = {
		"../Logs/BalanceTests/balance-tests.log",
		"Logs/BalanceTests/balance-tests.log",
		"../Logs/remastered-balance-tests.log",
		"Logs/remastered-balance-tests.log",
	}

	for _, path in ipairs(candidates) do
		local file = io.open(path, "a")
		if file ~= nil then
			file:write(line .. "\n")
			file:close()
			return path
		end
	end
	return nil
end

local function sendLines(player, lines)
	local message = table.concat(lines, "\n")
	if player and player.sendTextMessage then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	end
	print(message)

	local stamp = os.date("%Y-%m-%d %H:%M:%S")
	local name = player and player.getName and player:getName() or "console"
	appendLog(string.format("[%s] [%s] %s", stamp, name, message))
	return lines
end

local function cancel(player, message)
	if player and player.sendCancelMessage then
		player:sendCancelMessage(message)
	else
		sendLines(nil, { "[Remastered Admin Test Error]", message })
	end
	return true, { "[Remastered Admin Test Error]", message }
end

local function isAdmin(player)
	return player and player.getGroup and player:getGroup() and player:getGroup():getAccess()
end

local function balance()
	return AdminBalanceTests._remastered and AdminBalanceTests._remastered.Balance or nil
end

local function features()
	return AdminBalanceTests._remastered and AdminBalanceTests._remastered.Features or nil
end

local function moduleStatus(moduleId)
	local loader = AdminBalanceTests._remastered and AdminBalanceTests._remastered.ModuleLoader
	if not loader or not loader.getStatus then
		return "unknown"
	end
	local status = loader.getStatus(moduleId)
	if not status then
		return "not registered"
	end
	return tostring(status.status) .. (status.reason ~= "" and " (" .. tostring(status.reason) .. ")" or "")
end

local function isBalanceEnabled()
	local api = balance()
	return api and api.isEnabled and api.isEnabled() == true
end

local function multiplier(kind)
	local api = balance()
	if not api then
		return 1.0
	end
	if kind == "xp" and api.getExperienceRate then
		return api.getExperienceRate()
	end
	if kind == "skill" and api.getSkillRate then
		return api.getSkillRate()
	end
	if kind == "loot" and api.getLootRate then
		return api.getLootRate()
	end
	return 1.0
end

local function apply(kind, value)
	local api = balance()
	if kind == "xp" and api and api.applyExperienceRate then
		return api.applyExperienceRate(value)
	end
	if kind == "skill" and api and api.applySkillRate then
		return api.applySkillRate(value)
	end
	if kind == "loot" and api and api.applyLootFactor then
		return api.applyLootFactor(value)
	end
	return value
end

local function getMonsterType(name)
	if not name or name == "" then
		return nil
	end
	local ok, result = pcall(MonsterType, name)
	if ok then
		return result
	end
	return nil
end

local function getMonsterExperience(monsterType)
	if not monsterType then
		return nil
	end
	if monsterType.getExperience then
		local ok, value = pcall(monsterType.getExperience, monsterType)
		if ok and value then
			return value
		end
	end
	if monsterType.experience then
		local ok, value = pcall(monsterType.experience, monsterType)
		if ok and value then
			return value
		end
	end
	return nil
end

local function getItemName(itemId)
	local ok, itemType = pcall(ItemType, itemId)
	if not ok or not itemType then
		return tostring(itemId)
	end
	if itemType.getName then
		local nameOk, name = pcall(itemType.getName, itemType)
		if nameOk and name and name ~= "" then
			return name
		end
	end
	return tostring(itemId)
end

local function summarizeLoot(lootTable, summary)
	for itemId, item in pairs(lootTable or {}) do
		if not summary[itemId] then
			summary[itemId] = {
				count = 0,
				hits = 0,
				name = getItemName(itemId),
			}
		end
		summary[itemId].count = summary[itemId].count + (item.count or 0)
		summary[itemId].hits = summary[itemId].hits + 1
	end
end

local function sortedLootLines(summary, limit)
	local rows = {}
	for itemId, item in pairs(summary) do
		table.insert(rows, {
			id = itemId,
			name = item.name,
			count = item.count,
			hits = item.hits,
		})
	end
	table.sort(rows, function(left, right)
		if left.count == right.count then
			return tostring(left.name) < tostring(right.name)
		end
		return left.count > right.count
	end)

	local lines = {}
	for index, item in ipairs(rows) do
		if index > limit then
			break
		end
		table.insert(lines, string.format("- %s (%s): count=%s hits=%s", item.name, tostring(item.id), tostring(item.count), tostring(item.hits)))
	end
	if #lines == 0 then
		table.insert(lines, "- no loot generated in this sample")
	end
	return lines
end

function AdminBalanceTests.initialize(remastered, metadata)
	AdminBalanceTests._remastered = remastered
	AdminBalanceTests._metadata = metadata or {}
	return true
end

function AdminBalanceTests.isEnabled()
	local flags = features()
	return flags and flags.isEnabled and flags.isEnabled("enable_admin_balance_tests") == true
end

function AdminBalanceTests.requireAccess(player)
	if not AdminBalanceTests.isEnabled() then
		if player then
			player:sendCancelMessage("Remastered admin balance tests are disabled.")
		end
		return false
	end
	if not isAdmin(player) then
		if player then
			player:sendCancelMessage("You are not allowed to use Remastered admin balance tests.")
		end
		return false
	end
	return true
end

function AdminBalanceTests.testBalance(player)
	local flags = features()
	local lines = {
		"[Remastered Balance Test]",
		"Admin tools flag: " .. tostring(flags and flags.get and flags.get("enable_admin_balance_tests", false)),
		"Balance feature flag: " .. tostring(flags and flags.get and flags.get("enable_remastered_balance", false)),
		"Balance module status: " .. moduleStatus("RemasteredBalanceModule"),
		"Admin test module status: " .. moduleStatus("RemasteredAdminBalanceTests"),
		"XP Rate: x" .. tostring(multiplier("xp")),
		"Skill Rate: x" .. tostring(multiplier("skill")),
		"Loot Rate: x" .. tostring(multiplier("loot")),
		"Multiplier source: Remastered.Balance API",
		"Config: " .. tostring(AdminBalanceTests._metadata.configPath),
		"Feature flags: " .. tostring(AdminBalanceTests._metadata.featurePath),
	}
	return true, sendLines(player, lines)
end

function AdminBalanceTests.testXp(player, param)
	local subject = trim(param)
	local base = tonumber(subject)
	local source = "fixed value"

	if not base then
		local monsterType = getMonsterType(subject)
		if not monsterType then
			return cancel(player, "Usage: /testxp <monster name|base xp>")
		end
		base = getMonsterExperience(monsterType)
		source = "MonsterType(" .. subject .. "):getExperience()"
	end

	if not base then
		return cancel(player, "Could not resolve base XP.")
	end

	local final = apply("xp", base)
	return true, sendLines(player, {
		"[Remastered XP Test]",
		"Subject: " .. subject,
		"Base XP: " .. tostring(base),
		"Multiplier: x" .. tostring(isBalanceEnabled() and multiplier("xp") or 1.0),
		"Final XP: " .. tostring(final),
		"Feature flag active: " .. tostring(isBalanceEnabled()),
		"Source: " .. source,
		"Config: " .. tostring(AdminBalanceTests._metadata.configPath),
	})
end

function AdminBalanceTests.testSkill(player, param)
	local words = splitWords(param)
	local skillName = words[1] or "fist"
	local base = tonumber(words[2]) or tonumber(words[1]) or 100
	local final = apply("skill", base)

	return true, sendLines(player, {
		"[Remastered Skill Test]",
		"Skill: " .. tostring(skillName),
		"Base tries: " .. tostring(base),
		"Multiplier: x" .. tostring(isBalanceEnabled() and multiplier("skill") or 1.0),
		"Final tries: " .. tostring(final),
		"Feature flag active: " .. tostring(isBalanceEnabled()),
		"Source: Remastered.Balance.applySkillRate",
		"Config: " .. tostring(AdminBalanceTests._metadata.configPath),
	})
end

function AdminBalanceTests.testLoot(player, param)
	local words = splitWords(param)
	local simulations = tonumber(words[#words]) or 100
	local monsterNameEnd = tonumber(words[#words]) and #words - 1 or #words
	local monsterName = table.concat(words, " ", 1, monsterNameEnd)
	if monsterName == "" then
		return cancel(player, "Usage: /testloot <monster name> [simulations]")
	end
	simulations = math.max(1, math.min(simulations, 1000))

	local monsterType = getMonsterType(monsterName)
	if not monsterType then
		return cancel(player, "Monster '" .. monsterName .. "' not found.")
	end

	local baseSummary = {}
	local remasteredSummary = {}
	local baseFactor = 1.0
	local remasteredFactor = apply("loot", baseFactor)

	for _ = 1, simulations do
		local baseOk, baseLoot = pcall(monsterType.generateLootRoll, monsterType, { factor = baseFactor, gut = false }, {}, player)
		if baseOk then
			summarizeLoot(baseLoot, baseSummary)
		end
		local remasteredOk, remasteredLoot = pcall(monsterType.generateLootRoll, monsterType, { factor = remasteredFactor, gut = false }, {}, player)
		if remasteredOk then
			summarizeLoot(remasteredLoot, remasteredSummary)
		end
	end

	local lines = {
		"[Remastered Loot Test]",
		"Monster: " .. monsterName,
		"Simulations: " .. tostring(simulations),
		"Base factor: " .. tostring(baseFactor),
		"Multiplier: x" .. tostring(isBalanceEnabled() and multiplier("loot") or 1.0),
		"Final factor: " .. tostring(remasteredFactor),
		"Feature flag active: " .. tostring(isBalanceEnabled()),
		"Source: MonsterType:generateLootRoll, no items created",
		"Top base loot:",
	}
	for _, line in ipairs(sortedLootLines(baseSummary, 5)) do
		table.insert(lines, line)
	end
	table.insert(lines, "Top Remastered loot:")
	for _, line in ipairs(sortedLootLines(remasteredSummary, 5)) do
		table.insert(lines, line)
	end
	table.insert(lines, "Config: " .. tostring(AdminBalanceTests._metadata.configPath))
	return true, sendLines(player, lines)
end

local function readFile(path)
	local file = io.open(path, "r")
	if file == nil then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function writeFile(path, content)
	local file = io.open(path, "w")
	if file == nil then
		return false
	end
	file:write(content)
	file:close()
	return true
end

local function parseRequest(content)
	local request = {}
	for line in string.gmatch(content or "", "[^\r\n]+") do
		local key, value = string.match(line, "^([^=]+)=(.*)$")
		if key then
			request[trim(key)] = trim(value)
		end
	end
	return request
end

local function panelPaths(id)
	local safeId = tostring(id or os.time()):gsub("[^%w%-_]", "")
	return {
		request = "../Logs/BalanceTests/admin-panel-request.txt",
		result = "../Logs/BalanceTests/admin-panel-result-" .. safeId .. ".log",
	}
end

function AdminBalanceTests.runPanelTest(command, param)
	if not AdminBalanceTests.isEnabled() then
		return false, { "[Remastered Admin Panel]", "Admin balance tests feature flag is disabled." }
	end
	if command == "balance" then
		return AdminBalanceTests.testBalance(nil)
	end
	if command == "xp" then
		return AdminBalanceTests.testXp(nil, param)
	end
	if command == "skill" then
		return AdminBalanceTests.testSkill(nil, param)
	end
	if command == "loot" then
		return AdminBalanceTests.testLoot(nil, param)
	end
	return false, { "[Remastered Admin Panel]", "Unknown command: " .. tostring(command) }
end

function AdminBalanceTests.processPanelRequest()
	local requestPath = "../Logs/BalanceTests/admin-panel-request.txt"
	local content = readFile(requestPath)
	if content == nil or content == "" then
		return false
	end

	local request = parseRequest(content)
	local id = request.id or tostring(os.time())
	local paths = panelPaths(id)
	local ok, linesOrError = pcall(function()
		local _, lines = AdminBalanceTests.runPanelTest(request.command, request.param)
		return lines or { "[Remastered Admin Panel]", "No output." }
	end)

	local lines = nil
	if ok then
		lines = linesOrError
	else
		lines = { "[Remastered Admin Panel Error]", tostring(linesOrError) }
	end
	table.insert(lines, 1, "Request: " .. id)
	table.insert(lines, 2, "Command: " .. tostring(request.command))
	table.insert(lines, 3, "Param: " .. tostring(request.param or ""))
	table.insert(lines, 4, "Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(lines, 5, "")

	writeFile(paths.result, table.concat(lines, "\n") .. "\n")
	os.remove(requestPath)
	return true
end

function AdminBalanceTests.handleCommand(player, words, param)
	if not AdminBalanceTests.requireAccess(player) then
		return true
	end
	if words == "/testbalance" then
		return AdminBalanceTests.testBalance(player)
	end
	if words == "/testxp" then
		return AdminBalanceTests.testXp(player, param)
	end
	if words == "/testskill" then
		return AdminBalanceTests.testSkill(player, param)
	end
	if words == "/testloot" then
		return AdminBalanceTests.testLoot(player, param)
	end
	if player then
		player:sendCancelMessage("Unknown Remastered admin balance test command.")
	end
	return true
end

return AdminBalanceTests
