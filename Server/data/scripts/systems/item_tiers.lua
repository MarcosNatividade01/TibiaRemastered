local itemTierClassifications = {
	-- Upgrade classification 1
	[1] = {
		-- Update tier 0
		[1] = {
			regular = 2500,
			core = 1,
		},
	},
	-- Upgrade classification 2
	[2] = {
		-- Update tier 0
		[1] = {
			regular = 75000,
			core = 1,
		},
		-- Update tier 1
		[2] = {
			regular = 500000,
			core = 1,
		},
	},
	-- Upgrade classification 3
	[3] = {
		[1] = {
			regular = 400000,
			core = 1,
		},
		[2] = {
			regular = 1000000,
			core = 2,
		},
		[3] = {
			regular = 2000000,
			core = 3,
		},
	},
	-- Upgrade classification 4
	[4] = {
		[1] = {
			regular = 800000,
			core = 1,
			convergence = { fusion = { price = 5500000 }, transfer = { price = 6500000 } },
		},
		[2] = {
			regular = 2000000,
			core = 2,
			convergence = { fusion = { price = 11000000 }, transfer = { price = 16500000 } },
		},
		[3] = {
			regular = 4000000,
			core = 5,
			convergence = { fusion = { price = 17000000 }, transfer = { price = 37500000 } },
		},
		[4] = {
			regular = 6500000,
			core = 10,
			convergence = { fusion = { price = 30000000 }, transfer = { price = 80000000 } },
		},
		[5] = {
			regular = 10000000,
			core = 15,
			convergence = { fusion = { price = 87500000 }, transfer = { price = 200000000 } },
		},
		[6] = {
			regular = 25000000,
			core = 25,
			convergence = { fusion = { price = 235000000 }, transfer = { price = 525000000 } },
		},
		[7] = {
			regular = 75000000,
			core = 35,
			convergence = { fusion = { price = 695000000 }, transfer = { price = 1450000000 } },
		},
		[8] = {
			regular = 250000000,
			core = 50,
			convergence = { fusion = { price = 2125000000 }, transfer = { price = 4250000000 } },
		},
		[9] = {
			regular = 800000000,
			core = 60,
			convergence = { fusion = { price = 5000000000 }, transfer = { price = 10000000000 } },
		},
		[10] = {
			regular = 1500000000,
			core = 85,
			convergence = { fusion = { price = 12500000000 }, transfer = { price = 30000000000 } },
		},
	},
}

-- Item tier with gold price for upgrading it
for classificationId, classificationTable in ipairs(itemTierClassifications) do
	local itemClassification = Game.createItemClassification(classificationId)
	local classification = {}

	-- Registers table for register_item_tier.lua interface
	classification.Upgrades = {}
	for tierId, tierTable in ipairs(classificationTable) do
		table.insert(classification.Upgrades, {
			TierId = tierId,
			Core = tierTable.core,
			RegularPrice = tierTable.regular,
			ConvergenceFustionPrice = tierTable.convergence and tierTable.convergence.fusion.price or 0,
			ConvergenceTransferPrice = tierTable.convergence and tierTable.convergence.transfer.price or 0,
		})
	end
	-- Create item classification and register classification table
	itemClassification:register(classification)
end

