return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "LostRowan" } },           result = "after_quest"  },
				{ conditions = { hasQuestAtNode   = "LostRowan/reportBack" },    result = "report_back"  },
				{ conditions = { hasQuestAtNode   = "LostRowan/findRowan"  },    result = "quest_active" },
				{ conditions = { hasQuestAtNode   = "LostRowan/getGeode"   },    result = "quest_active" },
				{ conditions = { hasQuestAtNode   = "LostRowan/convinceRowan" }, result = "quest_active" },
				{ conditions = { completed_quests = { "TalkToGemal" } },         result = "intro"        },
				{ result = "redirect" },
			},
		},

		redirect = {
			text = 'Welcome to Hearthrock! You should speak with <font color="rgb(255, 230, 0)">Grandpa Gemal</font> first — he\'ll show you the ropes around here.',
			post = { { type = "close" } },
		},

		intro = {
			text = "My son Rowan... he wandered off again toward the old mine paths and we can't find him. You look capable, would you search for him?",
			options = "help_options",
		},

		offer_quest = {
			text = "Thank you! Please bring him home safely.",
			post = {
				{ type = "giveQuest", id = "LostRowan" },
				{ type = "delay", duration = 2.5 },
			},
			next = "exit",
		},

		decline = {
			text = "...I understand. We'll continue searching, you can find me here if you want to help.",
			post = { { type = "close" } },
		},

		quest_active = {
			text = "Any sign of Rowan out there? His mother hasn't stopped crying. Please find him.",
			post = { { type = "close" } },
		},

		report_back = {
			text = "You found Rowan!? Hurray! Thank you stranger!",
			options = "report_options",
		},

		report_confirm = {
			text = "He's home... oh thank goodness. Take this — it's not much but it's yours.",
			post = {
				{ type = "delay", duration = 3 },
			},
			next = "exit",
		},

		after_quest = {
			text = "Rowan's home safe and sound. Thank you for finding him.",
			post = { { type = "close" } },
		},

		exit = {
			text = "You have our deepest gratitude.",
			post = { { type = "close" } },
		},
	},
	option_sets = {
		help_options = {
			{ id = "help_rowan",  optionText = "I'll search for him.",              next = "offer_quest" },
			{ id = "deny_rowan",  optionText = "Sorry, I can't help right now.",    next = "decline"     },
		},
		report_options = {
			{ id = "rowan_coming_home", optionText = "Of course! Happy to help.", next = "report_confirm" },
		},
	},
}
