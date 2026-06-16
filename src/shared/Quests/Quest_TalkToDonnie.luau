return {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "TalkToDonnie",
		title       = "Meet Donnie",
		description = "Find Donnie in town — he might have something for you.",

		startNode = "talkToDonnie",
		nodes = {
			talkToDonnie = {
				title       = "Talk to Donnie",
				description = "Find Donnie and introduce yourself.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Donnie",
						goal        = 1,
						description = `Speak to <font color="rgb(255, 230, 0)">Donnie</font>`,
					},
				},
				rewards  = {},
				complete = true,
			},
		},
	},
}
