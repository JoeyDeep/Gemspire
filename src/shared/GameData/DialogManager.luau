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
	[ ] <luminiteAmount> -> player's current luminite```
--]]

local DialogManager = {}

local engine
function DialogManager.init(engineModule)
	engine = engineModule
end

function DialogManager:get(dialogId)
	return engine:get(`Dialog_{dialogId}`)
end

function DialogManager:compile()
	local compiledDialogs = {}
	for _, dialogModule in pairs(script.Parent.DialogTrees:GetChildren()) do
		compiledDialogs[string.gsub(dialogModule.Name, "Dialog_", "")] = require(dialogModule)
	end
	return compiledDialogs
end

return DialogManager