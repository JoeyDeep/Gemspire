return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "LostRowan" } },           result = "after_quest"        },
				{ conditions = { hasQuestAtNode   = "LostRowan/reportBack" },    result = "almost_home"        },
				{ conditions = { hasQuestAtNode   = "LostRowan/convinceRowan" }, result = "quest_active_geode" },
				{ conditions = { hasQuestAtNode   = "LostRowan/getGeode" },      result = "quest_active_geode" },
				{ conditions = { hasQuestAtNode   = "LostRowan/findRowan" },     result = "quest_active"       },
				{ conditions = { completed_quests = { "TalkToGemal" } },         result = "intro"              },
				{ result = "redirect" },
			},
		},

		redirect = {
			text = 'Welcome to Hearthrock! You should speak with <font color="rgb(255, 230, 0)">Grandpa Gemal</font> first — he\'ll show you the ropes around here.',
			post = { { type = "close" } },
		},

		intro = {
			text = "My boy... *sniffles* Where has he gone? I told him not to wander but he never listens. His father's out of his mind too.",
			post = { { type = "close" } },
		},

		quest_active = {
			text = "You're looking for Rowan? Oh please find him... he's my whole world. *sobs* He was heading toward those horrible mine paths.",
			post = { { type = "close" } },
		},

		quest_active_geode = {
			text = "You're looking for Rowan? Oh please find him... he's my whole world. *sobs* He was heading toward those horrible mine paths.",
			post = { { type = "close" } },
		},

		almost_home = {
			text = "My Rowan is home safe. *wipes eyes* I never want to go through that again. You're a true lifesaver.",
			post = { { type = "close" } },
		},

		after_quest = {
			text = "My Rowan is home safe. *wipes eyes* I never want to go through that again. You're a true lifesaver.",
			post = { { type = "close" } },
		},
	},
	option_sets = {},
}
