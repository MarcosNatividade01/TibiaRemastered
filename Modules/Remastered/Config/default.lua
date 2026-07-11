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
	},

	gameplay = {},
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
		},
	},

	development = {
		strictModules = true,
	},
}
