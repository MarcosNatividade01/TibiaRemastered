local DisabledExampleModule = {
	id = "DisabledExampleModule",
	version = "0.1.0",
}

function DisabledExampleModule.initialize(self, remastered)
	remastered.Utilities.log(self.id .. " should only initialize when its feature flag is enabled")
	return true
end

return DisabledExampleModule
