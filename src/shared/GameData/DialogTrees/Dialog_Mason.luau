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
			text = "Morning. I work stone for a living — walls, paths, whatever needs building. Hearthrock's always growing, always needs more hands.",
			post = { { type = "close" } },
		},
	},
	option_sets = {},
}
