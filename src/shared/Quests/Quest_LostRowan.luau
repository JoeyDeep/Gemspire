return {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "LostRowan",
		title       = "Lost and Found",
		description = "Worried Dad's son Rowan has wandered off. Find him and convince him to come home.",

		startNode = "findRowan",
		nodes = {
			findRowan = {
				title       = "Find Rowan",
				description = "Find Rowan somewhere near the mine paths.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Rowan",
						goal        = 1,
						description = `Find and speak to <font color="rgb(255, 230, 0)">Rowan</font>`,
					},
				},
				rewards  = {},
				nextNode = "getGeode",
			},
			getGeode = {
				title       = "Rowan's Request",
				description = "Rowan wants a geode before he'll go home. Find one for him.",
				tasks = {
					{
						type        = "collectLoot",
						lootKey     = "geode",
						goal        = 1,
						description = `Collect a <font color="rgb(255, 230, 0)">Geode</font> for Rowan`,
					},
				},
				rewards  = {},
				nextNode = "convinceRowan",
			},
			convinceRowan = {
				title       = "Give Rowan the Geode",
				description = "Return to Rowan and give him the geode.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Rowan",
						goal        = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Rowan</font> with the geode`,
					},
				},
				rewards  = {},
				nextNode = "reportBack",
			},
			reportBack = {
				title       = "Tell the Parents",
				description = "Go back and tell Worried Dad that Rowan is on his way home.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Worried_Dad",
						goal        = 1,
						description = `Report back to <font color="rgb(255, 230, 0)">Worried Dad</font>`,
					},
				},
				rewards  = { items = { { lootKey = "gold", kg = 0.5 } } },
				complete = true,
			},
		},
	},
}
