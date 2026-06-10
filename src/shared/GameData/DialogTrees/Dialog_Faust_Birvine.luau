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
			text = "I study the geological properties of the gems found here. Fascinating stuff, really. Most people just want to sell them. Can't blame them.",
			post = { { type = "close" } },
		},
	},
	option_sets = {},
}
