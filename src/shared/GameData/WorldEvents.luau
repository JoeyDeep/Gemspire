return {
	events = {
		aurora = {
			name = "Aurora Borealis",
			description = "Shimmering skies boost luck.",
			duration = 1800, -- seconds
			modifiers = {
				luck = 0.15, -- +15% luck
			},
			environment = {
				priority = 10,
				lighting = {
					ClockTime = 0,
					Brightness = 3,
					Ambient = Color3.fromRGB(90, 120, 160),
					OutdoorAmbient = Color3.fromRGB(60, 80, 120),
					FogColor = Color3.fromRGB(70, 120, 140),
					FogStart = 0,
					FogEnd = 300,
				},
			},
			loot = {
				-- multipliers use 1.15 for +15%
				zoneWeightMultipliers = {
					["*"] = {
						auroraShard = 1.25,
					},
				},
				zoneAdditions = {
					["*"] = {
						auroraShard = 0.2,
					},
				},
				traitWeightMultipliers = {
					["*"] = {
						aurora = 1.5,
					},
				},
				traitAdditions = {
					["*"] = {
						aurora = 0.15,
					},
				},
			},
		},
		myTestEvent = {
			name = "Test Event V1",
			description = "Description",
			duration = 120, -- seconds
			modifiers = {
				luck = 0.15, -- +15% luck
			},
			loot = {
				-- multipliers use 1.15 for +15%
				zoneWeightMultipliers = {
					["TestA"] = {
						iron = 1.5,
					},
				},
				zoneAdditions = {
					["TestA"] = {
						gold = 0.1,
						geode = 0.1,
					},
				},
				traitWeightMultipliers = {
					["TestA"] = {
						ancient = 1.5,
					},
				},
				traitAdditions = {
					["*"] = {
						glowing = 0.75,
					},
				},
			},
		},
	},
	schedule = {
		{ eventId = "myTestEvent", startAt = 1769192093 },
		-- { eventId = "aurora", startAt = 1730000000, duration = 1800 },
	},
}
