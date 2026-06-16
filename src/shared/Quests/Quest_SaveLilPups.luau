return {
	requirements = {
		completed_quests = { "HelpLadySaphire" },
	},
	questData = {
		id          = "SaveLilPups",
		title       = "Save Lil Pups",
		description = "The Birvine Company wants revenge. Help Lady Saphire save Lil Pups dog shelter by collecting amethyst for Robo Lawyer.",

		startNode = "collectAmethyst",
		nodes = {
			collectAmethyst = {
				title       = "Collect Amethyst",
				description = "Collect 10 amethyst for Robo Lawyer.",
				tasks = {
					{
						type        = "collectLoot",
						lootKey     = "amethyst",
						goal        = 10,
						description = `Collect <font color="rgb(150, 75, 210)">Amethyst</font>`,
					},
				},
				rewards  = {},
				nextNode = "returnToSaphire",
			},
			returnToSaphire = {
				title       = "Return to Lady Saphire",
				description = "Bring the amethyst to Lady Saphire.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Lady_Saphire",
						optionId    = "saphire_lil_pups_turn_in",
						goal        = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Lady Saphire</font> with the amethyst`,
					},
				},
				rewards  = { coins = 5000, removeItems = { { lootKey = "amethyst", count = 10 } } },
				complete = true,
			},
		},
	},
}
