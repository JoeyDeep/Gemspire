local REDIRECT = 'Welcome to Hearthrock! You should speak with <font color="rgb(255, 230, 0)">Grandpa Gemal</font> first — he\'ll show you the ropes around here.'

return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "TalkToGemal" } }, result = "intro" },
				{ result = "redirect" },
			},
		},
		redirect = { text = REDIRECT, post = { { type = "close" } } },
		intro = {
			text = "Hearthrock has a certain... charm. The gems here are unlike anything I've seen elsewhere. I came for a season and never left.",
			post = { { type = "close" } },
		},
	},
	option_sets = {},
}
