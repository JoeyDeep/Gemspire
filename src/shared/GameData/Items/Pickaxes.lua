return {
	rusty = {
		name = "Rusty Pickaxe",
		description = "A rusty pickaxe that has seen better days. It is not very effective but can be used to mine basic ores.",
		rarity = 1,
		stats = {
			strength = 5, -- how much 'rubble' is accumulated to container per hit
			speed = 1, -- how fast the minigame bar moves
			density = 1, -- minimum hardness of rubble that can be mined
			luck = 1,
		},

		backPivotOffset = CFrame.new(1.15, -1, -0.5) * CFrame.Angles(math.rad(110), math.rad(-0), math.rad(-0)), --CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(45)),
		heldPivotOffset = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), math.rad(-0), math.rad(0)),
	},
}
