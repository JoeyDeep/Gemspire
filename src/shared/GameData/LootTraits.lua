return {
	shiny = {
		name = "Shiny",
		sell_multiplier = 1.25,
		craft_luck = 0.15,
		craft_modifiers = {
			luck = 0.02,
		},
		orbitVisual = {
			numberOfOrbits = 1,
			orbitConfig = {
				radius  = 3.5,
				color   = Color3.fromRGB(220, 220, 220),
				speed   = 0.6,
				pattern = "smooth",
			},
		},
	},
	glowing = {
		name = "Glowing",
		sell_multiplier = 1.5,
		craft_luck = 0.15,
		craft_modifiers = {
			luck = 0.03,
		},
		orbitVisual = {
			numberOfOrbits = 1,
			orbitConfig = {
				radius  = 3.5,
				color   = Color3.fromRGB(255, 240, 150),
				speed   = 0.7,
				pattern = "smooth",
			},
		},
	},
	polished = {
		name = "Polished",
		sell_multiplier = 1.75,
		craft_luck = 0.15,
		craft_modifiers = {
			speed = 0.02,
		},
		orbitVisual = {
			numberOfOrbits = 1,
			orbitConfig = {
				radius  = 3.5,
				color   = Color3.fromRGB(200, 230, 255),
				speed   = 0.8,
				pattern = "smooth",
			},
		},
	},

	ancient = {
		name = "Ancient",
		sell_multiplier = 2.0,
		craft_luck = 0.15,
		craft_modifiers = {
			luck = 0.05,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius    = 3.8,
				color     = Color3.fromRGB(80, 160, 255),
				speed     = 0.9,
				pattern   = "oscillate",
				amplitude = 1.0,
			},
		},
	},
	fossilized = {
		name = "Fossilized",
		sell_multiplier = 2.5,
		craft_luck = 0.15,
		craft_modifiers = {
			strength = 0.03,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius  = 3.8,
				color   = Color3.fromRGB(180, 140, 80),
				speed   = 0.7,
				pattern = "shaky",
				jitter  = 0.2,
			},
		},
	},
	pristine = {
		name = "Pristine",
		sell_multiplier = 3.0,
		craft_luck = 0.15,
		craft_modifiers = {
			speed = 0.03,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius  = 3.8,
				color   = Color3.fromRGB(255, 255, 255),
				speed   = 1.0,
				pattern = "smooth",
			},
		},
	},
	legendary = {
		name = "Legendary",
		sell_multiplier = 5.0,
		craft_luck = 0.15,
		craft_modifiers = {
			luck = 0.08,
		},
		orbitVisual = {
			numberOfOrbits = 3,
			orbitConfig = {
				radius    = 4.2,
				color     = Color3.fromRGB(255, 200, 30),
				speed     = 1.4,
				pattern   = "oscillate",
				amplitude = 1.4,
			},
		},
	},

	pure = {
		name = "Pure",
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = {
			strength = 0.05,
		},
		orbitVisual = {
			numberOfOrbits = 1,
			orbitConfig = {
				radius  = 3.5,
				color   = Color3.fromRGB(240, 240, 255),
				speed   = 0.6,
				pattern = "smooth",
			},
		},
	},
	magmatic = {
		name = "Magmatic",
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = {
			strength = 0.08,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius  = 3.8,
				color   = Color3.fromRGB(255, 80, 20),
				speed   = 1.5,
				pattern = "shaky",
				jitter  = 0.35,
			},
		},
	},
	starforged = {
		name = "Starforged",
		sell_multiplier = 3.0,
		craft_luck = 0.3,
		craft_modifiers = {
			speed = 0.06,
		},
		orbitVisual = {
			numberOfOrbits = 3,
			orbitConfig = {
				radius  = 4.0,
				color   = Color3.fromRGB(150, 200, 255),
				speed   = 1.1,
				pattern = "spiral",
				range   = 0.8,
				freq    = 1.5,
			},
		},
	},
	luminous = {
		name = "Luminous",
		sell_multiplier = 4.0,
		craft_luck = 0.35,
		craft_modifiers = {
			luck = 0.1,
		},
		orbitVisual = {
			numberOfOrbits = 3,
			orbitConfig = {
				radius    = 4.2,
				color     = Color3.fromRGB(255, 245, 100),
				speed     = 1.6,
				pattern   = "oscillate",
				amplitude = 1.6,
			},
		},
	},

	runed = {
		name = "Runed",
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = {
			speed = 0.05,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius    = 3.8,
				color     = Color3.fromRGB(160, 80, 255),
				speed     = 0.9,
				pattern   = "oscillate",
				amplitude = 0.8,
			},
		},
	},
	cursed = {
		name = "Cursed",
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = {
			luck  = -0.1,
			speed = -0.03,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius  = 3.8,
				color   = Color3.fromRGB(160, 20, 200),
				speed   = 1.8,
				pattern = "shaky",
				jitter  = 0.4,
			},
		},
	},
	blessed = {
		name = "Blessed",
		sell_multiplier = 3.0,
		craft_luck = 0.3,
		craft_modifiers = {
			luck = 0.08,
		},
		orbitVisual = {
			numberOfOrbits = 2,
			orbitConfig = {
				radius  = 4.0,
				color   = Color3.fromRGB(255, 215, 80),
				speed   = 1.0,
				pattern = "smooth",
			},
		},
	},
	arcane = {
		name = "Arcane",
		sell_multiplier = 4.0,
		craft_luck = 0.35,
		craft_modifiers = {
			speed = 0.07,
		},
		orbitVisual = {
			numberOfOrbits = 3,
			orbitConfig = {
				radius  = 4.2,
				color   = Color3.fromRGB(120, 60, 255),
				speed   = 1.3,
				pattern = "spiral",
				range   = 1.0,
				freq    = 2.5,
			},
		},
	},

	perfect = {
		name = "Perfect",
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = {
			strength = 0.04,
		},
		orbitVisual = {
			numberOfOrbits = 1,
			orbitConfig = {
				radius  = 3.5,
				color   = Color3.fromRGB(255, 255, 255),
				speed   = 0.5,
				pattern = "smooth",
			},
		},
	},
	otherworldly = {
		name = "Otherworldly",
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = {
			speed = 0.05,
			luck  = 0.04,
		},
		orbitVisual = {
			numberOfOrbits = 3,
			orbitConfig = {
				radius    = 4.4,
				color     = Color3.fromRGB(60, 220, 200),
				speed     = 1.2,
				pattern   = "oscillate",
				amplitude = 1.8,
			},
		},
	},
}
