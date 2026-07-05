return {
	version = "0.1.0",
	environment = "local",
	debug = false,

	balance = {
		experienceRate = 10.0,
		skillRate = 3.0,
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
