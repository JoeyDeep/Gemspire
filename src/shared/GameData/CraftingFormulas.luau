return {
	ring = {
		name = "Ring",
		icon = "rbxassetid://104222111266155",
		value_multiplier = 1.1,
		max_equipped = 2,
		gridSlots = { 2, 4, 6, 8 },
		requirements = {
			[2] = { types = { "Metal", "Gem" } },
			[4] = { types = { "Metal" } },
			[6] = { types = { "Metal" } },
			[8] = { types = { "Metal" } },
		},
		lockMetal = true,
		output = {
			name = "ring",
			displayName = "Ring",
		},
	},
	necklace = {
		name = "Necklace",
		icon = "rbxassetid://124858997900046",
		value_multiplier = 1.25,
		max_equipped = 1,
		gridSlots = { 1, 2, 3, 4, 6, 8 },
		requirements = {
			[1] = { types = { "Metal" } },
			[2] = { types = { "Metal" } },
			[3] = { types = { "Metal" } },
			[4] = { types = { "Metal" } },
			[6] = { types = { "Metal" } },
			[8] = { types = { "Metal", "Gem" } },
		},
		lockMetal = true,
		output = {
			name = "necklace",
			displayName = "Necklace",
		},
	},
}
