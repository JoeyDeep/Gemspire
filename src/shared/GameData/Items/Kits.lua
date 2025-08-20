return {
	basic = {
		name = "Basic Refining Kit",
		description = "A simple refining kit that can separate basic materials from dirt and gravel. It is not very efficient but gets the job done.",

		mallet = "basic",
		container = "basic",
		tray = "basic",

		rarity = 1,
		stats = {
			luck = 1,
			capacity = 10,
			loot_yield = { min = 1, max = 3 },
			malletStrength = 1,
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
