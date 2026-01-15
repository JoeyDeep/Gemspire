return {
	TestA = {
		minDensity = 0,
		loot = {
			--geode = 1,
			rock = 0.5,
			quartz = 0.2,
			feldspar = 0.2,
			iron = 0.1,
		},
	},
	TestB = {
		minDensity = 5,
		loot = {
			rock = 0.5,
			quartz = 0.2,
			feldspar = 0.2,
			iron = 0.1,
		},
	},
	GeodeOnly = {
		minDensity = 0,
		loot = {
			geode = 1,
		},
	},

	MetalOnly = {
		minDensity = 1,
		loot = {
			gold = 1,
		},
	},

	GemOnly = {
		minDensity = 1,
		loot = {
			amethyst = 1,
		},
	},
}
