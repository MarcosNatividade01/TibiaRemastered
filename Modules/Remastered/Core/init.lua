local root = _G.REMASTERED_ROOT or "Modules/Remastered"

local function path(relative)
	return root .. "/" .. relative
end

local Remastered = _G.Remastered or {}
_G.Remastered = Remastered

Remastered.Config = dofile(path("Core/config.lua"))
Remastered.Features = dofile(path("Core/features.lua"))
Remastered.Registry = dofile(path("Core/registry.lua"))
Remastered.Utilities = dofile(path("Utilities/api.lua"))
Remastered.Balance = dofile(path("Balance/api.lua"))
Remastered.Gameplay = dofile(path("Gameplay/api.lua"))
Remastered.ModuleLoader = dofile(path("Core/ModuleLoader/init.lua"))

Remastered.Core = {
	_initialized = false,
}

function Remastered.Core.getVersion()
	return Remastered.Config.get("version", "0.1.0")
end

function Remastered.Core.registerModule(name, module)
	return Remastered.Registry.register(name, module)
end

function Remastered.Core.getModule(name)
	return Remastered.Registry.get(name)
end

function Remastered.Core.getModules()
	return Remastered.Registry.all()
end

function Remastered.Core.isInitialized()
	return Remastered.Core._initialized == true
end

function Remastered.Core.initialize()
	if Remastered.Core._initialized then
		return true
	end

	Remastered.Config.load(path("Config/default.lua"))
	Remastered.Features.load(path("Config/features.lua"))

	Remastered.Core.registerModule("Core", Remastered.Core)
	Remastered.Core.registerModule("Config", Remastered.Config)
	Remastered.Core.registerModule("Features", Remastered.Features)
	Remastered.Core.registerModule("Utilities", Remastered.Utilities)
	Remastered.Core.registerModule("Balance", Remastered.Balance)
	Remastered.Core.registerModule("Gameplay", Remastered.Gameplay)
	Remastered.Core.registerModule("ModuleLoader", Remastered.ModuleLoader)
	Remastered.ModuleLoader.loadAll()

	Remastered.Core._initialized = true
	Remastered.Utilities.log("Remastered Core initialized v" .. Remastered.Core.getVersion())
	return true
end

return Remastered.Core
