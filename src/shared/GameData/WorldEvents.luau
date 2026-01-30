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
		-- myTestEvent = {
		-- 	name = "Test Event",
		-- 	description = "Testing",
		-- 	duration = 120,
		-- 	modifiers = {
		-- 		luck = 0.50,
		-- 	},
		-- 	loot = {
		-- 		zoneWeightMultipliers = {
		-- 			["TestA"] = {
		-- 				iron = 1.5
		-- 			}
		-- 		}
		-- 	}
		-- }
	},
	schedule = {
		-- { eventId = "aurora", startAt = 1730000000, duration = 1800 },
	},
}
