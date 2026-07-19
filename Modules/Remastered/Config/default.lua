return {
	version = "0.1.0",
	environment = "local",
	debug = false,

	balance = {
		-- Rates efetivos em Server/data/stages.lua; camada neutra evita duplicacao.
		experienceRate = 1.0,
		skillRate = 1.0,
		lootRate = 2.0,
		magicRate = 1.0,
		spawnRate = 1.0,
		spellDamageMultiplier = 1.15,
		offensiveRuneDamageMultiplier = 1.30,
		bountyRewardMultiplier = 1.40,
		bestiaryRequiredKillsMultiplier = 0.50,
		bestiaryCompletionRewardMultiplier = 4.0,
		charmCostMultiplier = 0.50,
		weaponProficiencyRequirementMultiplier = 1.0 / 3.0,
		weaponProficiencyExperienceMultiplier = 3.0,
		bossTiers = {
			weak = { difficultyMultiplier = 0.85 },
			medium = { difficultyMultiplier = 0.80 },
			strong = { difficultyMultiplier = 0.70 },
			endgame = { difficultyMultiplier = 0.50 },
		},
	},

	gameplay = {
		globalEvents = {
			timezone = "UTC",
			events = {
				{
					id = "winterlight_solstice",
					name = "Winterlight Solstice",
					status = "READY_AFTER_IMPORT",
					startMonth = 12,
					startDay = 20,
					durationDays = 15,
				},
				{
					id = "anniversary_week",
					name = "Anniversary Week",
					status = "READY",
					startMonth = 7,
					startDay = 1,
					durationDays = 7,
				},
			},
		},
	},
	interface = {},
	network = {},
	systems = {},

	modules = {
		available = {
			"Features/ExampleModule",
			"Features/DisabledExampleModule",
			"Features/InvalidExampleModule",
			"Features/MissingDependencyExampleModule",
			"Balance/BalanceModule",
			"Utilities/AdminBalanceTests",
			"Upstream/UpdatePack01",
		},
	},

	development = {
		strictModules = true,
	},
}
