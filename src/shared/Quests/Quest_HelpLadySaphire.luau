local PAYMENT = 5000

return {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "HelpLadySaphire",
		title       = "The Interest Payment",
		description = "Lady Saphire needs the town to raise funds before the company takes the statue as collateral.",

		startNode = "raiseFunds",
		nodes = {
			raiseFunds = {
				title       = "Raise Funds",
				description = `Raise {PAYMENT} coins for Lady Saphire's payment.`,
				tasks = {
					{
						type        = "haveCoins",
						amount      = PAYMENT,
						goal        = 1,
						description = `Raise <font color="rgb(255, 215, 0)">{PAYMENT} coins</font>`,
					},
				},
				rewards  = {},
				nextNode = "returnToLadySaphire",
			},
			returnToLadySaphire = {
				title       = "Return to Lady Saphire",
				description = "Bring the funds to Lady Saphire.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Lady_Saphire",
						optionId    = "saphire_have_raised_enough",
						minCoins    = PAYMENT,
						goal        = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Lady Saphire</font> with the payment`,
					},
				},
				rewards  = { removeCoins = PAYMENT, items = { { lootKey = "geode", kg = 1, trait = "ancient" } } },
				complete = true,
			},
		},
	},
}
