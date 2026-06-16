local REDIRECT  = 'Welcome to Hearthrock! You should speak with <font color="rgb(255, 230, 0)">Grandpa Gemal</font> first — he\'ll show you the ropes around here.'
local PAYMENT   = 5000

return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "SaveLilPups" } },                    result = "lil_pups_done"      },
				{ conditions = { hasQuestAtNode   = "SaveLilPups/returnToSaphire" },         result = "lil_pups_return"    },
				{ conditions = { hasQuestAtNode   = "SaveLilPups/collectAmethyst" },         result = "lil_pups_collecting"},
				{ conditions = { completed_quests = { "HelpLadySaphire" } },                result = "lil_pups_intro"     },
				{ conditions = { hasQuestAtNode   = "HelpLadySaphire/returnToLadySaphire" }, result = "return_visit"       },
				{ conditions = { hasQuestAtNode   = "HelpLadySaphire/raiseFunds" },          result = "raising_funds"      },
				{ conditions = { completed_quests = { "TalkToGemal" } },                    result = "intro_speech"       },
				{ result = "redirect" },
			},
		},

		redirect     = { text = REDIRECT, post = { { type = "close" } } },

		intro_speech = {
			text = `The company has pulled a fast one on us. We have to raise {PAYMENT} coins otherwise they will take our town statue as collateral. Will you help us?`,
			options = "intro_options",
		},

		explain_reward = {
			text = "I will give you a geode I received from the deep mines. It should hold some considerably rare gems.",
			options = "intro_options",
		},

		explain_situation = {
			text = "This is actually our last interest payment we owe the company. However they rigged this payment to be particularly expensive with hidden fees. They want us to pay them interest forever to get our statue back… we aren't going to let it happen.",
			options = "intro_options",
		},

		explain_tips = {
			text = "Good news. This is Gemspire. There are fortunes to be found around every corner. I know a particularly good spot to mine around here though if you'd like to know where it is.",
			options = "tips_options",
		},

		tips_location = {
			text = "Head up the east path past the old watermill. There's a rich vein up in the cliff face — miners have been keeping it quiet for years.",
			options = "intro_options",
		},

		tips_already_know = {
			text = "Well then I think you've got it from here then.",
			options = "intro_options",
		},

		accept_quest = {
			text = `Excellent. If you earn enough funds bring them to me. Thank you for helping, <playerName>.`,
			post = {
				{ type = "giveQuest", id = "HelpLadySaphire" },
				{ type = "delay",     duration = 1.5        },
				{ type = "close"                            },
			},
		},

		decline = {
			text = "That's alright. If you want to help come talk to me, but otherwise we'll figure something out as a town.",
			post = {
				{ type = "delay", duration = 1 },
				{ type = "close"               },
			},
		},

		raising_funds = {
			text = `Still working on raising those funds? We need {PAYMENT} coins — come back when you have it.`,
			post = { { type = "close" } },
		},

		return_visit = {
			text = "Ah, <playerName>. Have you managed to raise the funds?",
			options = "return_options",
		},

		check_payment = {
			nextLogic = {
				{ conditions = { hasCoins = PAYMENT }, result = "return_positive" },
				{ result = "return_negative" },
			},
		},

		return_positive = {
			text = "It is!! Wonderful! Thank you! This will show the company… they can bury their hidden fees where the sun doesn't shine. But anyway, here is a geode from the deep mines — enjoy cracking it open!",
			post = {
				{ type = "delay", duration = 2 },
				{ type = "close"               },
			},
		},

		return_negative = {
			text = `Sorry, that isn't enough yet — but keep up the good work. We need {PAYMENT} coins total.`,
			post = { { type = "close" } },
		},

		quest_done = {
			text = "It's done — the payment is settled. Hearthrock owes you more than you know, <playerName>.",
			post = { { type = "close" } },
		},

		lil_pups_intro = {
			text = "<playerName>, we need your help again. The company wants to take revenge after their last scheme failed. They are going to close Lil Pups.",
			options = "lil_pups_reaction_options",
		},

		lil_pups_plan = {
			text = "Don't worry, we have a plan. We aren't playing nice anymore. I called Robo Lawyer. They're going to help us but in return they need gems. Will you help?",
			options = "lil_pups_ask_options",
		},

		lil_pups_who = {
			text = "Our ace in the hole. Unfortunately they have to eat gems in order to work out hard problems.",
			options = "lil_pups_ask_options",
		},

		lil_pups_accept = {
			text = "I knew I could count on you. Come back when you have the gems.",
			post = {
				{ type = "giveQuest", id = "SaveLilPups" },
				{ type = "delay",     duration = 1.5      },
				{ type = "close"                          },
			},
		},

		lil_pups_decline = {
			text = "That's alright. If you decide you want to help, let me know.",
			post = {
				{ type = "delay", duration = 1 },
				{ type = "close"               },
			},
		},

		lil_pups_collecting = {
			text = "Still gathering the amethyst for Robo Lawyer? We need 10 — come back when you have them.",
			post = { { type = "close" } },
		},

		lil_pups_return = {
			text = "You're back! Do you have the amethyst for Robo Lawyer?",
			options = "lil_pups_return_options",
		},

		lil_pups_complete = {
			text = "Wonderful! Robo Lawyer got straight to work. We received a settlement from the Birvine Company — Lil Pups is safe! Here's your share, <playerName>.",
			post = {
				{ type = "delay", duration = 2.5 },
				{ type = "close"                 },
			},
		},

		lil_pups_done = {
			text = "Lil Pups is safe and the Birvine Company got what they deserved. Thanks to you, <playerName>.",
			post = { { type = "close" } },
		},
	},
	option_sets = {
		intro_options = {
			{ id = "saphire_whats_in_it",    optionText = "What's in it for me?",                   next = "explain_reward"    },
			{ id = "saphire_how_could_they", optionText = "How could they do this?",                 next = "explain_situation" },
			{ id = "saphire_dont_have_it",   optionText = "I don't have that much, what should I do?", next = "explain_tips"    },
			{ id = "saphire_accept",         optionText = "Yes.",                                    next = "accept_quest"      },
			{ id = "saphire_decline",        optionText = "I can't right now.",                      next = "decline"           },
		},
		tips_options = {
			{ id = "saphire_tips_sure",         optionText = "Sure!",                           next = "tips_location"    },
			{ id = "saphire_tips_already_know", optionText = "I think I already know where it is.", next = "tips_already_know" },
		},
		return_options = {
			{ id = "saphire_have_raised_enough", optionText = "Here's the payment.", next = "check_payment" },
		},
		lil_pups_reaction_options = {
			{ id = "saphire_lil_pups_evil",  optionText = "Lil Pups the dog shelter? That's pure evil!", next = "lil_pups_plan" },
			{ id = "saphire_lil_pups_noway", optionText = "No way!",                                     next = "lil_pups_plan" },
		},
		lil_pups_ask_options = {
			{ id = "saphire_lil_pups_who",    optionText = "Who's Robo Lawyer?",  next = "lil_pups_who"    },
			{ id = "saphire_lil_pups_yes",    optionText = "Yes.",                next = "lil_pups_accept" },
			{ id = "saphire_lil_pups_no",     optionText = "I can't right now.",  next = "lil_pups_decline"},
		},
		lil_pups_return_options = {
			{ id = "saphire_lil_pups_turn_in", optionText = "Here's the amethyst.", next = "lil_pups_complete" },
		},
	},
}
