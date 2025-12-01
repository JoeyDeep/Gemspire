return {
	coins = 0,
	luminite = 0,
	xp = 0,

	inventory = {
		pickaxes = { "rusty" },
		kit = { "basic" },
		loot = {},
		equipment = {},
	},
	equipped = {
		pickaxe = "rusty",
		kit = "basic",
		equipment = {},
	},

	quests = {},
	dialog_history = {},
	container = {}, -- { now = 0, max = 0, quality = 0-100 }

	statistics = {
		found_loot = {}, -- ["loot_name"] = {count = x, largest = y}
	},

	settings = {
		music_volume = 0.5,
		sfx_volume = 0.5,
	},
}
