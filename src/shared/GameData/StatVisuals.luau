local StatVisuals = {
	strength = {
		name = "Strength",
		color = Color3.fromRGB(255, 85, 85),
		secondaryColor = Color3.fromRGB(175, 36, 36),
		maxStat = 20,
	},
	speed = {
		name = "Speed",
		color = Color3.fromRGB(85, 170, 255),
		secondaryColor = Color3.fromRGB(30, 99, 168),
		maxStat = 5,
	},
	luck = {
		name = "Luck",
		color = Color3.fromRGB(85, 255, 127),
		secondaryColor = Color3.fromRGB(25, 160, 59),
		maxStat = 10,
	},
	density = {
		name = "Density",
		color = Color3.fromRGB(170, 85, 255),
		secondaryColor = Color3.fromRGB(107, 36, 179),
		maxStat = 10,
	},
	capacity = {
		name = "Capacity",
		color = Color3.fromRGB(197, 97, 15),
		secondaryColor = Color3.fromRGB(143, 65, 1),
		maxStat = 50,
	},
	loot_yield = {
		name = "Loot Yield",
		color = Color3.fromRGB(0, 223, 223),
		secondaryColor = Color3.fromRGB(0, 107, 102),
		maxStat = { min = 1, max = 20 },
	},
	malletStrength = {
		name = "Mallet Strength",
		color = Color3.fromRGB(216, 43, 0),
		secondaryColor = Color3.fromRGB(182, 36, 0),
		maxStat = 30,
	},
}

return StatVisuals
