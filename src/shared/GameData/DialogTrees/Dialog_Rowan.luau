return {
	entry = "check",
	nodes = {
		check = {
			nextLogic = {
				{ conditions = { completed_quests = { "LostRowan" } },           result = "quest_done"    },
				{ conditions = { hasQuestAtNode   = "LostRowan/reportBack" },    result = "already_leaving" },
				{ conditions = { hasQuestAtNode   = "LostRowan/convinceRowan" }, result = "convince_home"  },
				{ conditions = { hasQuestAtNode   = "LostRowan/getGeode" },      result = "wait_geode"     },
				{ conditions = { hasQuestAtNode   = "LostRowan/findRowan" },     result = "first_meeting"  },
				{ result = "no_quest" },
			},
		},

		no_quest = {
			text = "Oh! Hi there. I'm just exploring. There's supposed to be an amazing geode around here somewhere — I can practically feel it calling to me.",
			post = { { type = "close" } },
		},

		first_meeting = {
			text = "Whoa, someone actually came looking for me? I'm totally fine! I just... I spotted the most incredible shiny geode out here and I can't leave without it.",
			options = "first_meeting_options",
		},

		first_meeting_convince = {
			text = "Hmm. You'd really get me a proper shiny geode? ...Okay fine. Get me one and I'll go home. Deal!",
			post = {
				{ type = "delay", duration = 1.5 },
				{ type = "close" },
			},
		},

		wait_geode = {
			text = "You're back! Did you find a geode yet? ...No? A deal's a deal. I'm not going home without one.",
			post = { { type = "close" } },
		},

		convince_home = {
			text = "A geode! Let me see that... *eyes light up* Oh WOW. It's even shinier than the one I saw! Okay okay, you win. I'll go home. Mum is going to be so relieved...",
			options = "convince_options",
		},

		convince_agree = {
			text = "Thanks for getting this for me. Tell my dad I'm on my way, okay? I'll take good care of it.",
			post = {
				{ type = "delay", duration = 1.5 },
				{ type = "close" },
			},
		},

		already_leaving = {
			text = "I said I'm going, I'm going! Sheesh. Tell them I'll be there soon — just taking one last look around.",
			post = { { type = "close" } },
		},

		quest_done = {
			text = "I made it home okay! Mum made dinner and everything. Thanks for the geode by the way — I've got it on my shelf.",
			post = { { type = "close" } },
		},
	},
	option_sets = {
		first_meeting_options = {
			{ id = "offer_geode_to_rowan",  optionText = "I'll find you one if you come home.",          next = "first_meeting_convince" },
			{ id = "demand_rowan_home",     optionText = "Your parents are worried sick. Come home.",    next = "first_meeting_convince" },
		},
		convince_options = {
			{ id = "give_rowan_geode", optionText = "Head home — your parents need you.", next = "convince_agree" },
		},
	},
}
