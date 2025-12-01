return {
	basic = {
		name = "Basic Refining Kit",
		description = "A simple refining kit that can separate basic materials from dirt and gravel. It is not very efficient but gets the job done.",

		mallet = "basic_mallet",
		container = "basic_container",
		tray = "basic_tray",

		rarity = 1,
		stats = {
			luck = 1,
			capacity = 10, -- amount of 'rubble' that can be held before refining
			loot_yield = { min = 1, max = 3 }, -- amount of loot items gained per refine
			malletStrength = 5, -- how much rubble is broken per mallet hit
		},

		containerPivotOffset = CFrame.new(0, 0, 0),
		containerFillOffsets = {
			Min = CFrame.new(0, 0, 0),
			Max = CFrame.new(-0.225, 0.7, 0),
			RubbleOffset = CFrame.new(0, 0, 0),
		},

		rubbleMotorData = {
			Min = CFrame.new(1.3, -0.54, 0),
			Max = CFrame.new(1.3, 0.175, 0),
		},

		trayHoldOffset = CFrame.new(0, -1.5, -1) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
		malletHoldOffset = CFrame.new(0, -1, -0.6) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	},
}
