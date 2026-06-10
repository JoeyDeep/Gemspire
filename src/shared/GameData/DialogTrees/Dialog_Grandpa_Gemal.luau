return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "TalkToGemal" } },        result = "after_intro"   },
				{ conditions = { hasQuestAtNode   = "TalkToGemal/talkToGemal" }, result = "intro_speech" },
				{ result = "intro_speech" },
			},
		},

		intro_speech = {
			text = "Ah, a fresh face! Welcome to Hearthrock, young one. I'm Gemal — been here longer than most of these buildings. Pull up a moment and I'll tell you what you need to know.",
			options = "intro_options",
		},

		intro_explain = {
			text = "This town sits on some of the richest gem deposits in the land. You'll want a pickaxe and a good eye. Crack open geodes, sell what you find, and build yourself up.",
			next = "intro_ready",
		},

		intro_ready = {
			text = "One more thing: talk to the folks in town. People around here always need a helping hand. Now get out there — Hearthrock's been waiting for someone like you.",
			options = "ready_options",
		},

		intro_done = {
			text = "Good luck, young one. We're glad to have you in Hearthrock.",
			post = {
				{ type = "giveQuest", id = "TalkToDonnie" },
				{ type = "delay",     duration = 2        },
				{ type = "close"                          },
			},
		},

		after_intro = {
			text = "Good to see you again! How's the mining treating you? If you follow the mine paths you can find some interesting mineral deposits.",
			post = { { type = "close" } },
		},
	},
	option_sets = {
		intro_options = {
			{ id = "gemal_tell_me_more", optionText = "Tell me more about Hearthrock.", next = "intro_explain" },
			{ id = "gemal_ready_now",    optionText = "I think I've got it, thanks!",  next = "intro_ready"   },
		},
		ready_options = {
			{ id = "gemal_im_ready", optionText = "I'm ready. Thanks, Gemal!", next = "intro_done" },
		},
	},
}
