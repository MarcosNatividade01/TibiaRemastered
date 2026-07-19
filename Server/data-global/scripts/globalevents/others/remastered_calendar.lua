local remasteredCalendar = GlobalEvent("RemasteredCalendar")

local function getConfig()
	if not Remastered or not Remastered.Config then
		return {}
	end
	return Remastered.Config.get("gameplay.globalEvents", {}) or {}
end

local function eventWindowForYear(eventConfig, year)
	local start = os.time({
		year = year,
		month = eventConfig.startMonth,
		day = eventConfig.startDay,
		hour = 0,
		min = 0,
		sec = 0,
	})
	local finish = start + ((eventConfig.durationDays or 1) * 24 * 60 * 60)
	return start, finish
end

local function isActive(eventConfig, timestamp)
	local now = os.date("*t", timestamp)
	for year = now.year - 1, now.year + 1 do
		local start, finish = eventWindowForYear(eventConfig, year)
		if timestamp >= start and timestamp < finish then
			return true, start, finish
		end
	end
	return false
end

local function evaluate(timestamp)
	local active = {}
	local upcoming = {}
	for _, eventConfig in ipairs(getConfig().events or {}) do
		if eventConfig.status == "READY" or eventConfig.status == "READY_AFTER_IMPORT" then
			local activeNow, startTime, endTime = isActive(eventConfig, timestamp)
			if activeNow then
				active[#active + 1] = { id = eventConfig.id, name = eventConfig.name, startsAt = startTime, endsAt = endTime }
			else
				local now = os.date("*t", timestamp)
				local nextStart, nextEnd = eventWindowForYear(eventConfig, now.year)
				if nextEnd <= timestamp then
					nextStart, nextEnd = eventWindowForYear(eventConfig, now.year + 1)
				end
				upcoming[#upcoming + 1] = { id = eventConfig.id, name = eventConfig.name, startsAt = nextStart, endsAt = nextEnd }
			end
		end
	end
	return active, upcoming
end

RemasteredCalendar = {
	evaluate = evaluate,
}

function remasteredCalendar.onStartup()
	local active = evaluate(os.time())
	for _, eventInfo in ipairs(active) do
		logger.info("[RemasteredCalendar] active event: {}", eventInfo.id)
	end
	return true
end

remasteredCalendar:register()
