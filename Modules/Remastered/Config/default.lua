return {
	version = "0.1.52-test",
	environment = "local",
	debug = false,
	build = {
		commit = "release-0.1.52-test",
		label = "0.1.52-triple-exercise-training",
	},

	balance = {
		-- Rates efetivos em Server/data/stages.lua; camada neutra evita duplicacao.
		experienceRate = 1.0,
		skillRate = 1.0,
		lootRate = 2.0,
		magicRate = 1.0,
		spawnRate = 1.0,
		spellDamageMultiplier = 1.65,
		offensiveRuneDamageMultiplier = 1.45,
		playerSpellCooldownMultiplier = 0.50,
		bountyRewardMultiplier = 5.00,
		bestiaryRequiredKillsMultiplier = 0.50,
		bestiaryCompletionRewardMultiplier = 4.0,
		charmCostMultiplier = 0.50,
		huntingTaskShopPriceMultiplier = 0.40,
		bossCooldownDisabled = true,
		weaponProficiencyRequirementMultiplier = 1.0 / 3.0,
		weaponProficiencyExperienceMultiplier = 3.0,
		exerciseWeaponSkillMultiplier = 3.0,
		bossTiers = {
			weak = { difficultyMultiplier = 0.65 },
			medium = { difficultyMultiplier = 0.50 },
			strong = { difficultyMultiplier = 0.25 },
			endgame = { difficultyMultiplier = 0.25 },
		},
	},

	gameplay = {
		unlockQuestAccess = true,
		unlockBossAccess = true,
		unlockDoorAccess = true,
		freeExploration = {
			enabled = true,
			ignoreQuestAccess = true,
			ignoreQuestKeys = true,
			ignoreQuestItems = true,
			ignoreNpcAccess = true,
			ignoreTeleportAccess = true,
			ignoreUseItemAccess = true,
			accessRequirementMultiplier = 0.50,
			levelRequirementMultiplier = 0.50,
			minimumItemRequirement = 1,
		},
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
