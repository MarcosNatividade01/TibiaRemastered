local BalanceModule = {
	id = "RemasteredBalanceModule",
	version = "0.1.0",
}

function BalanceModule.initialize(self, remastered)
	local createMonsterHook = remastered.Balance.installGameCreateMonsterHook and remastered.Balance.installGameCreateMonsterHook()
	remastered.Utilities.log(string.format(
		"%s initialized: version=%s build=%s commit=%s core=%s datapack=%s exp x%s skill x%s loot x%s spell x%s rune x%s spellCooldown x%s bossCooldownDisabled=%s bossCreateHook=%s",
		self.id,
		tostring(remastered.Core.getVersion()),
		tostring(remastered.Config.get("build.label", "unknown")),
		tostring(remastered.Config.get("build.commit", "unknown")),
		tostring(CORE_DIRECTORY or "unknown"),
		tostring(DATA_DIRECTORY or "unknown"),
		tostring(remastered.Balance.getExperienceRate()),
		tostring(remastered.Balance.getSkillRate()),
		tostring(remastered.Balance.getLootRate()),
		tostring(remastered.Balance.getSpellDamageMultiplier()),
		tostring(remastered.Balance.getOffensiveRuneDamageMultiplier()),
		tostring(remastered.Balance.getPlayerSpellCooldownMultiplier()),
		tostring(remastered.Balance.isBossCooldownDisabled()),
		tostring(createMonsterHook == true)
	))
	return true
end

function BalanceModule.shutdown(self, remastered)
	remastered.Utilities.log(self.id .. " shutdown")
	return true
end

return BalanceModule
