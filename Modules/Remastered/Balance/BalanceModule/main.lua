local BalanceModule = {
	id = "RemasteredBalanceModule",
	version = "0.1.0",
}

function BalanceModule.initialize(self, remastered)
	local createMonsterHook = remastered.Balance.installGameCreateMonsterHook and remastered.Balance.installGameCreateMonsterHook()
	remastered.Utilities.log(string.format(
		"%s initialized: exp x%s skill x%s loot x%s spell x%s rune x%s bossCreateHook=%s",
		self.id,
		tostring(remastered.Balance.getExperienceRate()),
		tostring(remastered.Balance.getSkillRate()),
		tostring(remastered.Balance.getLootRate()),
		tostring(remastered.Balance.getSpellDamageMultiplier()),
		tostring(remastered.Balance.getOffensiveRuneDamageMultiplier()),
		tostring(createMonsterHook == true)
	))
	return true
end

function BalanceModule.shutdown(self, remastered)
	remastered.Utilities.log(self.id .. " shutdown")
	return true
end

return BalanceModule
