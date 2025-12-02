--[[
	SINGLETON (Utility)

	PURPOSE:
		Handle dialog hooks and functions for dialogs in the game.
		All DialogData.luau's "fncText" topics are processed by context here,
		and returned for in-dialog response.

	USAGE:
		```lua
		local DialogHooks = require(engine:get("DialogHooks"))
		local text = DialogHooks:runFnc(selectedNode.fncText)

		if selectedNode.pre then -- pre-NPC text dialog hook to decide what NPC will say
			engine:get("DialogHooks"):runHooks(self, selectedNode.pre) -- self being a DialogService.luau class
		end
	end
		```
]]

local DialogHooks = {}

local engine
function DialogHooks.init(engineModule)
	engine = engineModule
end

function DialogHooks:runHooks(dialogClass, hookData)
	for _, hook in ipairs(hookData) do
		if hook.type == "close" then
			task.wait(1)
			dialogClass:endDialog()
		elseif hook.type == "delay" then
			task.wait(hook.duration or 1)
		end
	end
end

function DialogHooks:runFnc(fncName)
	local data = engine:get("PlayerService").data

	-- dialog for selling all loot of a a player's inventory
	local hookModule = engine:get(`DialogHook_{fncName}`)
	if hookModule then
		return hookModule(engine, data)
	else
		return "Error: Unknown function " .. fncName
	end
end

return DialogHooks
