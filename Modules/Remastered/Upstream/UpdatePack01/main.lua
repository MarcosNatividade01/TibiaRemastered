local UpdatePack01 = {
	id = "upstream_update_pack_01",
	imported = {},
	skipped = {},
}

local function joinPath(left, right)
	if string.sub(left, -1) == "/" or string.sub(left, -1) == "\\" then
		return left .. right
	end
	return left .. "/" .. right
end

local function loadScript(remastered, modulePath, relativePath, featureFlag)
	if not remastered.Features.isEnabled(featureFlag) then
		table.insert(UpdatePack01.skipped, {
			path = relativePath,
			reason = "feature flag disabled: " .. featureFlag,
		})
		return false
	end

	local scriptPath = joinPath(modulePath, relativePath)
	local ok, errorMessage = pcall(dofile, scriptPath)
	if not ok then
		error("UpdatePack01 failed to load " .. scriptPath .. ": " .. tostring(errorMessage))
	end

	table.insert(UpdatePack01.imported, relativePath)
	return true
end

function UpdatePack01.initialize(self, remastered)
	local modulePath = self.metadata.path

	loadScript(
		remastered,
		modulePath,
		"Scripts/actions/items/usable_singeing_steed_items.lua",
		"enable_upstream_pack_01_items"
	)

	remastered.Utilities.log(
		"Update Pack 01 ready: imported=" .. tostring(#self.imported) .. " skipped=" .. tostring(#self.skipped)
	)
end

return UpdatePack01
