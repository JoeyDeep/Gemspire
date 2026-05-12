local Magic      = "rbxassetid://564943308"
local Lightning  = "rbxassetid://7156661799"
local Spiral     = "rbxassetid://6700006778"
local WindSpiral = "rbxassetid://18787656402"
local ArmSpiral  = "rbxassetid://917189380"
local FireRing   = "rbxassetid://135909460168064"
local CloudRing  = "rbxassetid://87437014451396"
local Spooky     = "rbxassetid://126404290352207"
local Sparkle    = "rbxassetid://86630871053206"

return {
	shiny = {
		name = "Shiny",
		display_color = Color3.fromRGB(255, 215, 60),
		sell_multiplier = 1.25,
		craft_luck = 0.15,
		craft_modifiers = { luck = 0.02 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Sparkle, rotation = 0, speed = 20 } },
		},
	},
	glowing = {
		name = "Glowing",
		display_color = Color3.fromRGB(60, 220, 255),
		sell_multiplier = 1.5,
		craft_luck = 0.15,
		craft_modifiers = { luck = 0.03 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Lightning, rotation = 0, speed = 35 } },
		},
	},
	polished = {
		name = "Polished",
		display_color = Color3.fromRGB(200, 210, 230),
		sell_multiplier = 1.75,
		craft_luck = 0.15,
		craft_modifiers = { speed = 0.02 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Spiral, rotation = 0, speed = 30 } },
		},
	},

	ancient = {
		name = "Ancient",
		display_color = Color3.fromRGB(80, 160, 255),
		reveal_sound  = "RevealAncient",
		sell_multiplier = 2.0,
		craft_luck = 0.15,
		craft_modifiers = { luck = 0.05 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Magic, rotation = 0, speed = 25 } },
		},
	},
	fossilized = {
		name = "Fossilized",
		display_color = Color3.fromRGB(180, 130, 60),
		sell_multiplier = 2.5,
		craft_luck = 0.15,
		craft_modifiers = { strength = 0.03 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = CloudRing, rotation = 0, speed = 20 } },
		},
	},
	pristine = {
		name = "Pristine",
		display_color = Color3.fromRGB(200, 240, 255),
		sell_multiplier = 3.0,
		craft_luck = 0.15,
		craft_modifiers = { speed = 0.03 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = WindSpiral, rotation = 0, speed = 35 } },
		},
	},
	legendary = {
		name = "Legendary",
		display_color = Color3.fromRGB(255, 140, 0),
		sell_multiplier = 5.0,
		craft_luck = 0.15,
		craft_modifiers = { luck = 0.08 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = ArmSpiral, rotation = 0, speed = 50 } },
		},
	},

	pure = {
		name = "Pure",
		display_color = Color3.fromRGB(220, 220, 255),
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = { strength = 0.05 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Sparkle, rotation = 0, speed = 25 } },
		},
	},
	magmatic = {
		name = "Magmatic",
		display_color = Color3.fromRGB(255, 80, 20),
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = { strength = 0.08 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = FireRing, rotation = 0, speed = 60 } },
		},
	},
	starforged = {
		name = "Starforged",
		display_color = Color3.fromRGB(140, 80, 255),
		sell_multiplier = 3.0,
		craft_luck = 0.3,
		craft_modifiers = { speed = 0.06 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Lightning, rotation = 0, speed = 45 } },
		},
	},
	luminous = {
		name = "Luminous",
		display_color = Color3.fromRGB(255, 235, 80),
		sell_multiplier = 4.0,
		craft_luck = 0.35,
		craft_modifiers = { luck = 0.1 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Magic, rotation = 0, speed = 40 } },
		},
	},

	runed = {
		name = "Runed",
		display_color = Color3.fromRGB(60, 200, 180),
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = { speed = 0.05 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Spooky, rotation = 0, speed = 30 } },
		},
	},
	cursed = {
		name = "Cursed",
		display_color = Color3.fromRGB(180, 60, 255),
		reveal_sound  = "RevealCursed",
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = { luck = -0.1, speed = -0.03 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Spooky, rotation = 0, speed = 70 } },
		},
	},
	blessed = {
		name = "Blessed",
		display_color = Color3.fromRGB(255, 200, 60),
		sell_multiplier = 3.0,
		craft_luck = 0.3,
		craft_modifiers = { luck = 0.08 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = WindSpiral, rotation = 0, speed = 30 } },
		},
	},
	arcane = {
		name = "Arcane",
		display_color = Color3.fromRGB(160, 60, 255),
		sell_multiplier = 4.0,
		craft_luck = 0.35,
		craft_modifiers = { speed = 0.07 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = CloudRing, rotation = 0, speed = 50 } },
		},
	},

	perfect = {
		name = "Perfect",
		display_color = Color3.fromRGB(255, 255, 255),
		sell_multiplier = 1.5,
		craft_luck = 0.2,
		craft_modifiers = { strength = 0.04 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = Spiral, rotation = 0, speed = 25 } },
		},
	},
	otherworldly = {
		name = "Otherworldly",
		display_color = Color3.fromRGB(255, 60, 200),
		sell_multiplier = 2.0,
		craft_luck = 0.25,
		craft_modifiers = { speed = 0.05, luck = 0.04 },
		imageVisual = {
			size   = 1.7,
			layers = { { image = ArmSpiral, rotation = 0, speed = 55 } },
		},
	},
}
