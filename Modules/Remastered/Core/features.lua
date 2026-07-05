local Features = {
	_flags = {},
}

function Features.load(path)
	local loaded = dofile(path)
	if type(loaded) ~= "table" then
		error("Remastered feature flags must return a table: " .. path)
	end
	Features._flags = loaded
	return true
end

function Features.isEnabled(name)
	return Features._flags[name] == true
end

function Features.set(name, enabled)
	Features._flags[name] = enabled == true
	return Features._flags[name]
end

function Features.get(name, defaultValue)
	local value = Features._flags[name]
	if value == nil then
		return defaultValue
	end
	return value
end

function Features.all()
	return Features._flags
end

return Features
