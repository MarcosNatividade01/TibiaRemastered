local BalanceModule = {
	id = "RemasteredBalanceModule",
	version = "0.1.0",
}

function BalanceModule.initialize(self, remastered)
	remastered.Utilities.log(string.format(
		"%s initialized: exp x%s skill x%s loot x%s",
		self.id,
		tostring(remastered.Balance.getExperienceRate()),
		tostring(remastered.Balance.getSkillRate()),
		tostring(remastered.Balance.getLootRate())
	))
	return true
end

function BalanceModule.shutdown(self, remastered)
	remastered.Utilities.log(self.id .. " shutdown")
	return true
end

return BalanceModule
