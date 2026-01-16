local drills = {
	rusty = {
		name = "Rusty Drill",
		description = "A rusty drill that has seen better days. It is not very effective but can be used to mine basic ores.",
		lootInterval = 1, -- this is how many minutes
		maxLoot = 10,
		rarity = 1,
		luck = 1,
		density = 1,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(170, 85, 0)
	},
	steel = {
		name = "Steel Drill",
		description = "A strong and effective drill.",
		lootInterval = .5, -- this is how many minutes
		maxLoot = 10,
		rarity = 1,
		luck = 1,
		density = 5,
		material = Enum.Material.DiamondPlate,
		color = Color3.fromRGB(86, 86, 86)
	},
}

return drills