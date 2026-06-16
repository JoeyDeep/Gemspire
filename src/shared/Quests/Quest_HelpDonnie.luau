return {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "HelpDonnie",
		title       = "Donnie's Deal",
		description = "Donnie the drill-maker needs titanium before he can sell again. Bring him some and he'll give you a starter drill.",

		startNode = "collectTitanium",
		nodes = {
			collectTitanium = {
				title       = "Collect Titanium for Donnie",
				description = "Find 3kg of titanium ore and bring it to Donnie.",
				tasks = {
					{
						type        = "collectLoot",
						lootKey     = "titanium",
						goal        = 3,
						description = `Collect <font color="rgb(185, 190, 205)">Titanium Ore</font>`,
					},
				},
				rewards  = {},
				nextNode = "returnToDonnie",
			},
			returnToDonnie = {
				title       = "Return to Donnie",
				description = "Bring the titanium back to Donnie to claim your drill.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Donnie",
						goal        = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Donnie</font> with the titanium`,
					},
				},
				rewards  = { drill = "rusty", removeItems = { { lootKey = "titanium", count = 3 } } },
				complete = true,
			},
		},
	},
}
