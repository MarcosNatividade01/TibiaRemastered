local Utilities = {}

local function appendLog(line)
	local candidates = {
		"../Logs/remastered-core.log",
		"Logs/remastered-core.log",
	}

	for _, path in ipairs(candidates) do
		local file = io.open(path, "a")
		if file ~= nil then
			file:write(line .. "\n")
			file:close()
			return
		end
	end
end

function Utilities.log(message, level)
	local resolvedLevel = level or "INFO"
	local line = "[Remastered] [" .. resolvedLevel .. "] " .. tostring(message)
	print(line)
	appendLog(line)
end

function Utilities.warn(message)
	Utilities.log(message, "WARN")
end

function Utilities.error(message)
	Utilities.log(message, "ERROR")
end

return Utilities
