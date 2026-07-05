local function joinPath(left, right)
	if string.sub(left, -1) == "/" or string.sub(left, -1) == "\\" then
		return left .. right
	end
	return left .. "/" .. right
end

local function fileExists(path)
	local file = io.open(path, "r")
	if file == nil then
		return false
	end
	file:close()
	return true
end

local function getBasePath()
	local candidates = {
		"../Modules/Remastered",
		"Modules/Remastered",
		"Server/../Modules/Remastered",
	}

	for _, candidate in ipairs(candidates) do
		if fileExists(joinPath(candidate, "Core/init.lua")) then
			return candidate
		end
	end

	return nil
end

local basePath = getBasePath()
if basePath == nil then
	print("[Remastered] bootstrap skipped: Modules/Remastered/Core/init.lua not found")
	return
end

_G.REMASTERED_ROOT = basePath
dofile(joinPath(basePath, "Core/init.lua"))

if Remastered and Remastered.Core and Remastered.Core.initialize then
	Remastered.Core.initialize()
end
