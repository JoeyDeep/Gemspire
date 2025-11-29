return {
	rock = {
		name = "Rock",
		description = "A common rock",
		rarity = 1,
		color = Color3.fromRGB(177, 177, 177),

		value_per_kg = 100,
		kg_range = { min = 1, max = 3 },
		traits = {
			none = 0.998,
			ancient = 0.001,
			cursed = 0.001,
		},
	},
	quartz = {
		name = "Quartz",
		description = "A common mineral with a crystalline structure.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228),

		value_per_kg = 150,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.95,
			ancient = 0.03,
			cursed = 0.02,
		},
	},
	feldspar = {
		name = "Feldspar",
		description = "A group of rock-forming minerals that make up a large part of the Earth's crust.",
		rarity = 1,
		color = Color3.fromRGB(184, 184, 184),

		value_per_kg = 200,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.9,
			ancient = 0.05,
			cursed = 0.05,
		},
	},
	iron = {
		name = "Iron Ore",
		description = "A common ore that contains iron.",
		rarity = 1,
		color = Color3.fromRGB(113, 113, 113),

		value_per_kg = 250,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.85,
			ancient = 0.1,
			cursed = 0.05,
		},
	},
	garnet = {
		name = "Garnet",
		description = "A group of silicate minerals used as abrasives and in jewelry.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 300,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.8,
			ancient = 0.15,
			cursed = 0.05,
		},
	},

	amethyst = {
		name = "Amethyst",
		description = "A purple variety of quartz often used in jewelry.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 400,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.75,
			ancient = 0.2,
			cursed = 0.05,
		},
	},
	citrine = {
		name = "Citrine",
		description = "A yellow variety of quartz often used in jewelry.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 450,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.7,
			ancient = 0.25,
			cursed = 0.05,
		},
	},
	topaz = {
		name = "Topaz",
		description = "A silicate mineral often used in jewelry.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 500,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.65,
			ancient = 0.3,
			cursed = 0.05,
		},
	},
	geode = {
		name = "Geode",
		description = "A rock containing a cavity lined with crystals or other mineral matter.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 600,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.6,
			ancient = 0.35,
			cursed = 0.05,
		},
	},
	fossil = {
		name = "Fossil",
		description = "The remains or impression of a prehistoric organism preserved in petrified form.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 700,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.55,
			ancient = 0.4,
			cursed = 0.05,
		},
	},

	sapphire = {
		name = "Sapphire",
		description = "A precious gemstone, typically blue, but can be found in a variety of colors.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 800,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.5,
			ancient = 0.45,
			cursed = 0.05,
		},
	},
	emerald = {
		name = "Emerald",
		description = "A precious gemstone, typically green, known for its rarity and beauty.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 900,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.45,
			ancient = 0.5,
			cursed = 0.05,
		},
	},
	ruby = {
		name = "Ruby",
		description = "A precious gemstone, typically red, known for its hardness and beauty.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 1000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.4,
			ancient = 0.55,
			cursed = 0.05,
		},
	},
	meteorite = {
		name = "Meteorite",
		description = "A solid fragment of a meteoroid that survives its passage through the atmosphere and lands on Earth.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 1200,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.35,
			ancient = 0.6,
			cursed = 0.05,
		},
	},
	crystal_clusters = {
		name = "Crystal Clusters",
		description = "A group of crystals that have formed together, often found in caves or mines.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 1500,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.3,
			ancient = 0.65,
			cursed = 0.05,
		},
	},
	gold = {
		name = "Gold",
		description = "A precious metal known for its luster and malleability.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 1800,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.25,
			ancient = 0.7,
			cursed = 0.05,
		},
	},
	diamond = {
		name = "Diamond",
		description = "A precious gemstone known for its hardness and brilliance.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 2000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.25,
			ancient = 0.7,
			cursed = 0.05,
		},
	},

	starfire_opal = {
		name = "Starfire Opal",
		description = "A rare and beautiful opal with a star-like pattern.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 2000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.25,
			ancient = 0.7,
			cursed = 0.05,
		},
	},
	bloodstone = {
		name = "Bloodstone",
		description = "A type of chalcedony that is dark green with red spots.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 2500,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.2,
			ancient = 0.75,
			cursed = 0.05,
		},
	},
	dragons_eye = {
		name = "Dragon's Eye",
		description = "A rare gemstone with a unique swirling pattern that resembles a dragon's eye.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 3000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.15,
			ancient = 0.8,
			cursed = 0.05,
		},
	},
	prism_cluster = {
		name = "Prism Cluster",
		description = "A cluster of crystals that refract light into a spectrum of colors.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 3500,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.1,
			ancient = 0.85,
			cursed = 0.05,
		},
	},

	celestial_diamond = {
		name = "Celestial Diamond",
		description = "A rare and powerful diamond said to be formed from the remnants of a fallen star.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 5000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.05,
			ancient = 0.9,
			cursed = 0.05,
		},
	},
	heart_of_mountain = {
		name = "Heart of the Mountain",
		description = "A legendary gemstone said to be the heart of a mountain, imbued with ancient power.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 10000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.01,
			ancient = 0.95,
			cursed = 0.04,
		},
	},
	skyglass_crystal = {
		name = "Skyglass Crystal",
		description = "A rare crystal that captures the essence of the sky, shimmering with a celestial glow.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 15000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.005,
			ancient = 0.98,
			cursed = 0.02,
		},
	},
	ember_relic = {
		name = "Ember Relic",
		description = "A relic from a long-lost civilization, said to hold the power of fire and rebirth.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 20000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.001,
			ancient = 0.99,
			cursed = 0.01,
		},
	},
	crown_jewel = {
		name = "Crown Jewel",
		description = "A legendary gemstone that once adorned the crown of a great king, symbolizing power and wealth.",
		rarity = 1,
		color = Color3.fromRGB(228, 228, 228), -- change my values

		value_per_kg = 50000,
		kg_range = { min = 0.1, max = 1 },
		traits = {
			none = 0.0005,
			ancient = 0.995,
			cursed = 0.0045,
		},
	},
}
