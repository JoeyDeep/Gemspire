--[[
	CLASS: NPCHandler.new(npcName: string) -> npcName corresponds to a model in workspace.Entities.NPCs

	PURPOSE: Handles all NPC behavior, particularly dialog interaction, but future
	concerns include animation playing, action decisions, etc... will be expanded later.

]]

local NPCHandler = {
	NPCs = {},
}
NPCHandler.__index = NPCHandler

local engine
function NPCHandler.init(engineModule)
	engine = engineModule
	engine:await("PromptService")

	for _, NPC in pairs(workspace.Entities.NPCs:GetChildren()) do
		NPCHandler.new(NPC.Name)
	end
end

function NPCHandler.new(npcName)
	local self = setmetatable({}, NPCHandler)

	self.npcModel = workspace.Entities.NPCs:WaitForChild(npcName)

	local PromptService = engine:get("PromptService")
	local Prompt = PromptService.new(workspace.Entities.NPCs[npcName].ProximityPrompt)
	Prompt.prompt.ActionText = "Speak"
	Prompt.prompt.ObjectText = npcName

	Prompt.prompt.Triggered:Connect(function()
		local DialogService = engine:get("DialogService")
		PromptService:disableAll() -- disable other prompts while in dialog
		DialogService.new(npcName)
	end)

	NPCHandler.NPCs[npcName] = self

	return self
end

function NPCHandler:get(npcName)
	return NPCHandler.NPCs[npcName]
end

function NPCHandler:displayDialog(text)
	-- display chosen text from DialogService.luau above our particular NPC's head

	local QuickTween = engine:get("QuickTween")
	local Typewriter = engine:get("Typewriter")
	local dialogUI = self.npcModel:WaitForChild("Dialog")

	-- if dialog box is not already prepared & visible on screen, set it up
	if not dialogUI.Dialog.Visible then
		dialogUI.Dialog.Position = UDim2.fromScale(0.5, 0.5)
		dialogUI.Dialog.Shadow.ImageTransparency = 1
		dialogUI.Dialog.Message.Text = ""
		dialogUI.Dialog.Visible = true

		QuickTween(dialogUI.Dialog, 0.15, { Position = UDim2.fromScale(0.5, 0.33) })
		QuickTween(dialogUI.Dialog.Shadow, 0.15, { ImageTransparency = 0.77 })
		QuickTween(dialogUI.Dialog.Message, 0.15, { TextTransparency = 0 })
		QuickTween(dialogUI.Dialog.Message.UIStroke, 0.15, { Transparency = 0 })
		task.wait(0.2)
	end

	-- typewrite effect play on the dialog TextLabel
	-- @TODO: "Typewrite1" sound effect should be manipulated or changed per NPC type for personality
	Typewriter.Play(dialogUI.Dialog.Message, text, {
		sound = "Typewrite1",
		soundParent = self.npcModel.Head,
	})
end

function NPCHandler:closeDialog()
	local QuickTween = engine:get("QuickTween")
	local dialogUI = self.npcModel:WaitForChild("Dialog")

	if dialogUI.Dialog.Visible then
		QuickTween(dialogUI.Dialog, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
		QuickTween(dialogUI.Dialog.Shadow, 0.15, { ImageTransparency = 1 })
		QuickTween(dialogUI.Dialog.Message, 0.15, { TextTransparency = 1 })
		QuickTween(dialogUI.Dialog.Message.UIStroke, 0.15, { Transparency = 1 })
		task.wait(0.2)
		dialogUI.Dialog.Visible = false
	end
end

return NPCHandler
