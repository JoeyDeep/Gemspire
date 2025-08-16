return {
	rusty = {
		name = "Rusty Pickaxe",
		description = "A rusty pickaxe that has seen better days. It is not very effective but can be used to mine basic ores.",
		rarity = 1,
		stats = {
			strength = 5,
			speed = 1,
			density = 1,
			luck = 1,
		},

		backPivotOffset = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), math.rad(120)), --CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(45)),
		heldPivotOffset = CFrame.new(0, -1, -0.7) * CFrame.Angles(0, math.rad(-90), math.rad(90)),
	},
}
