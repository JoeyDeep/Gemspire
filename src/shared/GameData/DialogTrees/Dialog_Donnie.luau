return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "HelpDonnie" } },             result = "quest_done"           },
				{ conditions = { hasQuestAtNode   = "HelpDonnie/returnToDonnie" },  result = "return_with_titanium" },
				{ conditions = { hasQuestAtNode   = "HelpDonnie/collectTitanium" }, result = "collecting_titanium"  },
				{ result = "intro_speech" },
			},
		},

		intro_speech = {
			text = "Hello there newcomer! You looking for a drill? I can't sell anymore until I get my hands on some more titanium though. If you help me get some I'll give you a starter drill in exchange.",
			options = "intro_options",
		},

		explain_drill = {
			text = "Well, with a drill you just gotta place that sucker on some mining rock and let it be for a while. It'll even keep running if you leave the game. After some time when you come back you can refine & collect the minerals in the drill.",
			options = "intro_options",
		},

		accept_quest = {
			text = "Rad rubies! Alright then — come back once you've got 3kg of titanium for me.",
			post = {
				{ type = "giveQuest", id = "HelpDonnie" },
				{ type = "delay",     duration = 1.5    },
				{ type = "close"                        },
			},
		},

		collecting_titanium = {
			text = "Still working on that titanium? Come back once you've got 3kg for me!",
			post = { { type = "close" } },
		},

		return_with_titanium = {
			text = "You got the titanium — a deal's a deal! Here's your starter drill. Stick it on some mining rock and let it do the work.",
			options = "titanium_return_options",
		},

		handoff_done = {
			text = "Good luck out there! Check back with me once you're ready to upgrade.",
			post = {
				{ type = "delay", duration = 1.5 },
				{ type = "close"                 },
			},
		},

		quest_done = {
			text = "Drills are something else, right? Let me know when you need an upgrade!",
			post = { { type = "close" } },
		},
	},
	option_sets = {
		intro_options = {
			{ id = "donnie_ask_drill",   optionText = "What do I do with a drill?", next = "explain_drill" },
			{ id = "donnie_accept_help", optionText = "I'll help you out.",          next = "accept_quest"  },
		},
		titanium_return_options = {
			{ id = "donnie_thanks", optionText = "Thanks, Donnie!", next = "handoff_done" },
		},
	},
}
