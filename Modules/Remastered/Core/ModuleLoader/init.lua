local ModuleLoader = {
	_modules = {},
	_statuses = {},
	_scanPaths = {
		"Features",
		"Balance",
		"Gameplay",
		"Network",
		"Utilities",
	},
}

local function now()
	if os and os.clock then
		return os.clock()
	end
	return 0
end

local function joinPath(left, right)
	if string.sub(left, -1) == "/" or string.sub(left, -1) == "\\" then
		return left .. right
	end
	return left .. "/" .. right
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

local function splitList(value)
	local items = {}
	if value == nil or value == "" then
		return items
	end
	for item in string.gmatch(value, "[^,]+") do
		item = string.gsub(item, "^%s+", "")
		item = string.gsub(item, "%s+$", "")
		if item ~= "" then
			table.insert(items, item)
		end
	end
	return items
end

local function parseScalar(raw)
	if raw == nil then
		return nil
	end
	raw = string.gsub(raw, "^%s+", "")
	raw = string.gsub(raw, "%s+$", "")
	if raw == "true" then
		return true
	end
	if raw == "false" then
		return false
	end
	if string.sub(raw, 1, 1) == '"' then
		return string.match(raw, '^"(.*)"$') or ""
	end
	local numberValue = tonumber(raw)
	if numberValue ~= nil then
		return numberValue
	end
	return raw
end

local function parseJsonObject(content)
	local object = {}
	content = string.gsub(content, "[\r\n]", " ")

	for key, rawArray in string.gmatch(content, '"([%w_%-]+)"%s*:%s*%[(.-)%]') do
		local values = {}
		for value in string.gmatch(rawArray, '"(.-)"') do
			table.insert(values, value)
		end
		object[key] = values
	end

	for key, rawValue in string.gmatch(content, '"([%w_%-]+)"%s*:%s*([^,%}]+)') do
		if object[key] == nil then
			object[key] = parseScalar(rawValue)
		end
	end

	return object
end

local function getRoot()
	return _G.REMASTERED_ROOT or "Modules/Remastered"
end

local function getConfiguredModules()
	local configured = Remastered.Config.get("modules.available", "")
	if type(configured) == "table" then
		return configured
	end
	return splitList(configured)
end

local function setStatus(id, status, reason, metadata)
	ModuleLoader._statuses[id] = {
		id = id,
		status = status,
		reason = reason or "",
		metadata = metadata,
	}
end

local function hasDependency(id)
	return Remastered.Registry.has(id) or ModuleLoader._modules[id] ~= nil
end

function ModuleLoader.discover()
	local root = getRoot()
	local modules = {}
	for _, relativePath in ipairs(getConfiguredModules()) do
		local moduleRoot = joinPath(root, relativePath)
		local manifestPath = joinPath(moduleRoot, "module.json")
		local manifestContent = readFile(manifestPath)
		if manifestContent == nil then
			Remastered.Utilities.warn("Module manifest not found: " .. manifestPath)
		else
			local metadata = parseJsonObject(manifestContent)
			metadata.path = moduleRoot
			metadata.manifest = manifestPath
			metadata.main = metadata.main or "main.lua"
			metadata.loadOrder = metadata.loadOrder or 100
			table.insert(modules, metadata)
			Remastered.Utilities.log("Module found: " .. tostring(metadata.id) .. " at " .. relativePath)
		end
	end
	table.sort(modules, function(left, right)
		if left.loadOrder == right.loadOrder then
			return tostring(left.id) < tostring(right.id)
		end
		return left.loadOrder < right.loadOrder
	end)
	return modules
end

function ModuleLoader.validate(metadata)
	if type(metadata.id) ~= "string" or metadata.id == "" then
		return false, "missing id"
	end
	if metadata.enabled == false then
		return false, "module disabled"
	end
	if type(metadata.featureFlag) == "string" and metadata.featureFlag ~= "" then
		if not Remastered.Features.isEnabled(metadata.featureFlag) then
			return false, "feature flag disabled: " .. metadata.featureFlag
		end
	end
	if type(metadata.dependencies) == "table" then
		for _, dependency in ipairs(metadata.dependencies) do
			if not hasDependency(dependency) then
				return false, "missing dependency: " .. dependency
			end
		end
	end
	return true, ""
end

function ModuleLoader.load(metadata)
	local startedAt = now()
	local valid, reason = ModuleLoader.validate(metadata)
	if not valid then
		setStatus(metadata.id or metadata.manifest, "skipped", reason, metadata)
		Remastered.Utilities.warn("Module skipped: " .. tostring(metadata.id) .. " (" .. reason .. ")")
		return false
	end

	local mainPath = joinPath(metadata.path, metadata.main)
	local ok, moduleOrError = pcall(dofile, mainPath)
	if not ok then
		setStatus(metadata.id, "failed", tostring(moduleOrError), metadata)
		Remastered.Utilities.error("Module failed to load: " .. metadata.id .. " file=" .. mainPath .. " error=" .. tostring(moduleOrError))
		return false
	end

	if type(moduleOrError) ~= "table" then
		setStatus(metadata.id, "failed", "main file did not return a table", metadata)
		Remastered.Utilities.error("Module failed validation: " .. metadata.id .. " main file did not return a table")
		return false
	end

	moduleOrError.metadata = metadata
	if type(moduleOrError.initialize) == "function" then
		local initOk, initError = pcall(moduleOrError.initialize, moduleOrError, Remastered)
		if not initOk then
			setStatus(metadata.id, "failed", tostring(initError), metadata)
			Remastered.Utilities.error("Module failed to initialize: " .. metadata.id .. " error=" .. tostring(initError))
			return false
		end
	end

	ModuleLoader._modules[metadata.id] = moduleOrError
	Remastered.Core.registerModule(metadata.id, moduleOrError)
	setStatus(metadata.id, "loaded", "loaded in " .. tostring(now() - startedAt) .. "s", metadata)
	Remastered.Utilities.log("Module loaded: " .. metadata.id)
	return true
end

function ModuleLoader.loadAll()
	local startedAt = now()
	local discovered = ModuleLoader.discover()
	for _, metadata in ipairs(discovered) do
		ModuleLoader.load(metadata)
	end
	Remastered.Utilities.log("ModuleLoader finished in " .. tostring(now() - startedAt) .. "s")
	return ModuleLoader._statuses
end

function ModuleLoader.getStatus(id)
	return ModuleLoader._statuses[id]
end

function ModuleLoader.getStatuses()
	return ModuleLoader._statuses
end

function ModuleLoader.getLoadedModules()
	return ModuleLoader._modules
end

return ModuleLoader
