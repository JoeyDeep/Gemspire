--[[
	DOCUMENTATION:
	```lua
	speaker = {
		entry = "conversation_id", -- conversation to start with
		entry_decide = { -- optional, decide entry conversation based on conditions

		conversations = {
			nodeName = {
				text = "Hello, <playerName>!", -- string or {string, string, ...} for random choice
				choice = "What do you want to ask?", -- optional, makes this a choice node
				options = { -- required if choice is present
					{
						id = "option_id", -- optional, for tracking which options were chosen
						text = "Option text",
						require = { level_min = 5, elseText = "You aren't ready to talk to me yet." }, -- optional conditions to show this option
						next = "next_node_name", -- conversation node to go to next
						pre = { ... }, -- optional hooks to run when this option is chosen (before next node)
						post = { ... }, -- optional hooks to run when this option is chosen (after next node)
					},
					...
				},

				require = { level_min = 5, flag = "SomeFlag" }, -- optional conditions to show this conversation node

				pre = { ... }, -- optional hooks to run when this node is entered (before text)
				post = { ... }, -- optional hooks to run when this node is exited (after text)

				next = "next_node_name", -- optional, conversation node to go to next automatically after text
			}
		}
	}```

	HOOKS (pre/post): -> all hooks have a {..., delay = number} option to delay by seconds
	[ ] {type = "flagOn", name = "FlagName"}
	[ ] {type = "flagOff", name = "FlagName"}
	[ ] {type = "cutscene", name = "CutsceneName"}
	[ ] {type = "playSFX", name = "SFXName"}
	[ ] {type = "addCoins", amount = number}
	[ ] {type = "addLuminite", amount = number}
	[ ] {type = "addXP", amount = number}
	[ ] {type = "giveItem", id = "ItemID", amount = number}
	[ ] {type = "removeItem", id = "ItemID", amount = number}
	[ ] {type = "teleport", location = "LocationName"}
	[ ] {type = "transition", fadeInTime = number, fadeOutTime = number}
	[X] {type = "close"}

	ENTRY DECIDE & REQUIRE CONDITIONS:
	[ ] level_min = number
	[ ] level_max = number
	[ ] has_item = "ItemID"
	[ ] had_conversation = "conversation_id"
	[ ] spoken_to = "speaker_id"
	[ ] has_quest = "quest_id"
	[ ] completed_quest = "quest_id"

	PARSE TAGS:
	[X] <playerName> -> player's DisplayName
	[ ] <playerLevel> -> player's current level
	[ ] <coinAmount> -> player's current coins
	[ ] <luminiteAmount> -> player's current luminite
]]

local example = {
	TestSpeaker = {
		entry = "hello",

		conversations = {
			hello = {
				text = {
					`Hello there <font color="rgb(255, 231, 94)"><playerName></font>! Welcome to the world of Gemspire.`,
					`Ah, a fresh face! Gemspire's luck be with you, <font color="rgb(255, 231, 94)"><playerName></font>.`,
				},
				next = "menu",
			},

			menu = {
				choice = "What would you like to know?",
				options = {
					{
						id = "world",
						optionText = "Tell me about Gemspire.",
						next = "about_world",
						post = { { type = "addCoins", amount = 1 } },
					},
					{
						id = "help",
						optionText = "How can I get stronger?",
						next = "about_leveling",
					},
					{
						id = "bye",
						optionText = "Nothing for now.",
						next = "exit",
					},
				},
			},

			about_world = {
				text = "Gemspire is stitched together by rifts and veins of power. Seek shrines, avoid the cracks—they stare back.",
				post = {
					{ type = "giveItem", id = "LorePage01", amount = 1 },
				},
				next = "menu",
			},

			about_leveling = {
				text = "Train with the Sifters' Guild. Strength comes from rhythm: gather, craft, repeat.",
				post = {
					{ type = "giveItem", id = "TrainingVoucher", amount = 1 },
				},
				next = "menu",
			},

			exit = {
				text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
				post = { { type = "close" } },
			},
		},
	},

	TestMerchant = {
		entry = "menu",

		conversations = {
			menu = {
				choice = {
					`Looking to sell some gems, <font color="rgb(255, 231, 94)"><playerName></font>?`,
					`Got some shiny stones to sell, <font color="rgb(255, 231, 94)"><playerName></font>?`,
				},
				options = {
					{
						id = "sell_all",
						optionText = "Sell all my loot",
						bubbleText = "I'd like to sell all my gems.",
						next = "sell_all_result",
					},
					{
						id = "sell_this",
						optionText = "Sell this item",
						bubbleText = "I'd like to sell this item.",
						next = "sell_result",
					},
					{
						id = "appraise",
						optionText = "How much is this worth?",
						bubbleText = "I'd like to appraise this item.",
						next = "appraise_result",
					},
					{
						id = "bye",
						optionText = "Nothing for now.",
						bubbleText = "Nevermind, just looking around.",
						next = "exit",
					},
				},
			},

			repeat_menu = {
				choice = {
					`What else can I do for you, <font color="rgb(255, 231, 94)"><playerName></font>?`,
					`Anything more, <font color="rgb(255, 231, 94)"><playerName></font>?`,
				},
				options = {
					{
						id = "sell_all",
						optionText = "Sell all my loot",
						bubbleText = "I'd like to sell all my gems.",
						next = "sell_all_result",
					},
					{
						id = "sell_this",
						optionText = "Sell this item",
						bubbleText = "I'd like to sell this item.",
						next = "sell_result",
					},
					{
						id = "appraise",
						optionText = "How much is this worth?",
						bubbleText = "I'd like to appraise this item.",
						next = "appraise_result",
					},
					{
						id = "bye",
						optionText = "Nothing for now.",
						bubbleText = "That's all for now.",
						next = "exit",
					},
				},
			},


			sell_all_result = {
				fncText = "sellAllLoot",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},
			sell_result = {
				fncText = "sellThis",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},
			appraise_result = {
				fncText = "appraiseThis",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},

		
			exit = {
				text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
				post = { { type = "close" } },
			},
		},
	},
}

return {
	TestSpeaker = {
		entry = "hello",

		nodes = {
			hello = {
				text = {
					`Dello there <font color="rgb(255, 231, 94)"><playerName></font>! Welcome to the world of Gemspire.`,
					`Ah, a fresh face! Gemspire's luck be with you, <font color="rgb(255, 231, 94)"><playerName></font>.`,
				},
				next = "menu",
			},

			menu = {
				text = "What would you like to know?",
				options = "menu_options"
			},

			about_world = {
				text = "Gemspire is stitched together by rifts and veins of power. Seek shrines, avoid the cracks—they stare back.",
				post = {
					{ type = "giveItem", id = "LorePage01", amount = 1 },
				},
				next = "menu",
			},

			about_leveling = {
				text = "Train with the Sifters' Guild. Strength comes from rhythm: gather, craft, repeat.",
				post = {
					{ type = "giveItem", id = "TrainingVoucher", amount = 1 },
				},
				next = "menu",
			},

			merchant_answer = {
				text = "The merchant can buy your stuff.",
				next = "menu",
			},

			exit = {
				text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
				post = { { type = "close" } },
			},
		},

		option_sets = {
			menu_options = {
				{
					id = "world",
					optionText = "Tell me about Gemspire.",
					next = "about_world",
					post = { { type = "addCoins", amount = 1 } },
				},
				{
					id = "help",
					optionText = "How can I get stronger?",
					next = "about_leveling",
				},
				{
					id = "bye",
					optionText = "Nothing for now.",
					next = "exit",
				},
				{
					id = "merchant",
					optionText = "What do you think of the merchant?",
					bubbleText = "Do you know the merchant?",
					next = "merchant_answer",
					displayLogic = {
						{
							conditions = {
								spoken_to = "TestMerchant"
							},
							result = true,
						},
						{
							result = false,
						}
					}
				},
			}
		}
	},
	TestMerchant = {

		entry = "merchantStart",

		nodes = {
			merchantStart = {
				nextLogic = {
					-- evaluate in order. if we pass a condition take the result. 
					-- if there is no condition take the result
					-- a conditon can have more than one requirement
					{
						conditions = {
							spoken_to = "TestMerchant"
						},
						result = "welcome_back"
					},
					{
						-- like default
						result = "menu"
					},
				}
			},
			welcome_back = {
				text = "Welcome back.",
				next = "menu",
			},
			menu = {
				text = {
					`Looking to sell some gems, <font color="rgb(255, 231, 94)"><playerName></font>?`,
					`Got some shiny stones to sell, <font color="rgb(255, 231, 94)"><playerName></font>?`,
				},
				options = "menu_options",
			},
			repeat_menu = {
				text = {
					`What else can I do for you, <font color="rgb(255, 231, 94)"><playerName></font>?`,
					`Anything more, <font color="rgb(255, 231, 94)"><playerName></font>?`
				},
				options = "menu_options",
			},
			sell_all_result = {
				fncText = "sellAllLoot",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},
			sell_result = {
				fncText = "sellThis",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},
			appraise_result = {
				fncText = "appraiseThis",
				next = "repeat_menu",
				post = { { type = "delay", duration = 3 } },
			},

			exit = {
				text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
				post = { { type = "close" } },
			},
		},

		option_sets = {
			menu_options = {
				{
					id = "sell_all",
					optionText = "Sell all my loot",
					bubbleText = "I'd like to sell all my gems.",
					next = "sell_all_result",
				},
				{
					id = "sell_this",
					optionText = "Sell this item",
					bubbleText = "I'd like to sell this item.",
					next = "sell_result",
				},
				{
					id = "appraise",
					optionText = "How much is this worth?",
					bubbleText = "I'd like to appraise this item.",
					next = "appraise_result",
				},
				{
					id = "imrich",
					optionText = "I'm rich.",
					bubbleText = "I'm so rich!",
					next = "repeat_menu",
					displayLogic = {
						{
							conditions = {
								completed_quest = "become_rich"
							},
							result = true,
						},
						{
							result = false,
						}
					}
				},
				{
					id = "bye",
					optionText = "Nothing for now.",
					bubbleText = "That's all for now.",
					next = "exit",
				},
			}
		}

	}
}
