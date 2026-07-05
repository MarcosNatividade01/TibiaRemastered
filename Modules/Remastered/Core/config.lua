local Config = {
	_values = {},
}

local function merge(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			merge(target[key], value)
		else
			target[key] = value
		end
	end
end

local function readPath(source, dottedPath)
	local current = source
	for segment in string.gmatch(dottedPath, "[^%.]+") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[segment]
		if current == nil then
			return nil
		end
	end
	return current
end

function Config.load(path)
	local loaded = dofile(path)
	if type(loaded) ~= "table" then
		error("Remastered config must return a table: " .. path)
	end
	Config._values = {}
	merge(Config._values, loaded)
	return true
end

function Config.extend(values)
	if type(values) ~= "table" then
		error("Config.extend expects a table")
	end
	merge(Config._values, values)
	return true
end

function Config.get(key, defaultValue)
	if key == nil or key == "" then
		return Config._values
	end
	local value = readPath(Config._values, key)
	if value == nil then
		return defaultValue
	end
	return value
end

function Config.has(key)
	return readPath(Config._values, key) ~= nil
end

return Config
