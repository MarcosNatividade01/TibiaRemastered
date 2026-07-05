local MissingDependencyExampleModule = {
	id = "MissingDependencyExampleModule",
	version = "0.1.0",
}

function MissingDependencyExampleModule.initialize(self, remastered)
	remastered.Utilities.log(self.id .. " should not initialize when dependency is missing")
	return true
end

return MissingDependencyExampleModule
