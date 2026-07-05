local AdminBalanceTests = {
	id = "RemasteredAdminBalanceTests",
	version = "0.1.0",
}

local function joinPath(left, right)
	if string.sub(left, -1) == "/" or string.sub(left, -1) == "\\" then
		return left .. right
	end
	return left .. "/" .. right
end

function AdminBalanceTests.initialize(self, remastered)
	local apiPath = joinPath(self.metadata.path, "api.lua")
	local api = dofile(apiPath)
	api.initialize(remastered, {
		moduleId = self.id,
		version = self.version,
		apiPath = apiPath,
		configPath = joinPath(_G.REMASTERED_ROOT or "Modules/Remastered", "Config/default.lua"),
		featurePath = joinPath(_G.REMASTERED_ROOT or "Modules/Remastered", "Config/features.lua"),
	})

	remastered.AdminBalanceTests = api
	remastered.Core.registerModule("AdminBalanceTests", api)
	remastered.Utilities.log(self.id .. " initialized")
	return true
end

function AdminBalanceTests.shutdown(self, remastered)
	remastered.Utilities.log(self.id .. " shutdown")
	return true
end

return AdminBalanceTests
