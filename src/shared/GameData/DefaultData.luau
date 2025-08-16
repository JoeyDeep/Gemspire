return {
	coins = 0,
	luminite = 0,
	xp = 0,

	inventory = {
		pickaxes = { "rusty" },
		sieves = { "basic" },
		loot = {},
		equipment = {},
	},
	equipped = {
		pickaxe = "rusty",
		sieve = "basic",
		equipment = {},
	},
	quests = {},
	sieve_contains = {}, -- { now = 0, max = 0, quality = 0-100 }

	statistics = {
		found_loot = {}, -- ["loot_name"] = {count = x, largest = y}
	},

	settings = {
		music_volume = 0.5,
		sfx_volume = 0.5,
	},
}
