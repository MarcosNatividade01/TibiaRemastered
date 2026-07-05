local ExampleModule = {
	id = "ExampleModule",
	version = "0.1.0",
}

function ExampleModule.initialize(self, remastered)
	remastered.Utilities.log(self.id .. " initialized without gameplay changes")
	return true
end

function ExampleModule.shutdown(self, remastered)
	remastered.Utilities.log(self.id .. " shutdown")
	return true
end

return ExampleModule
