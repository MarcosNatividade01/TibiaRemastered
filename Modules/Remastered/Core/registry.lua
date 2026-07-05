local Registry = {
	_modules = {},
}

function Registry.register(name, module)
	if type(name) ~= "string" or name == "" then
		error("Registry.register requires a module name")
	end
	if type(module) ~= "table" then
		error("Registry.register requires a module table for " .. name)
	end
	Registry._modules[name] = module
	return module
end

function Registry.get(name)
	return Registry._modules[name]
end

function Registry.has(name)
	return Registry._modules[name] ~= nil
end

function Registry.all()
	return Registry._modules
end

return Registry
