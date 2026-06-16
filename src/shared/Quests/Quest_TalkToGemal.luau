return {
	requirements = {},
	questData = {
		id          = "TalkToGemal",
		title       = "Meet Grandpa Gemal",
		description = "Find Grandpa Gemal in town — he'll show you the ropes of Hearthrock.",

		startNode = "talkToGemal",
		nodes = {
			talkToGemal = {
				title       = "Talk to Grandpa Gemal",
				description = "Find Grandpa Gemal and introduce yourself.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Grandpa_Gemal",
						goal        = 1,
						description = `Speak to <font color="rgb(255, 230, 0)">Grandpa Gemal</font>`,
					},
				},
				rewards  = { coins = 50 },
				complete = true,
			},
		},
	},
}
