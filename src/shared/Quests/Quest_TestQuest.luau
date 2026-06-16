return {
	requirements = {},
	questData = {
		id          = "TestQuest",
		title       = "Test Quest",
		description = "This is a test quest for development purposes.",

		startNode = "start",
		nodes = {
			start = {
				title       = "Begin Your Journey",
				description = "Welcome to the test quest! Your journey begins here.",
				tasks = {
					{
						type        = "collectLoot",
						item        = "test_item",
						goal        = 5,
						description = `Collect <font color="rgb(255, 230, 0)">5</font> Loot Ores`,
					},
				},
				rewards  = { coins = 100, xp = 50 },
				nextNode = "testSpeakTo",
			},
			testSpeakTo = {
				title       = "Moe's Manifest",
				description = "Speak to Moe the Miner in the village to learn more about your quest.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "TestMerchant",
						goal        = 1,
						description = `Speak to <font color="rgb(255, 230, 0)">Merchant Moe</font> in the village.`,
					},
				},
				rewards  = { coins = 150, xp = 75 },
				complete = true,
			},
		},
	},
}
