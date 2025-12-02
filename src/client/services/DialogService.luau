--[[
	CLASS: DialogService.new(npcName: string) -> npcName corresponds to a model in workspace.Entities.NPCs

	PURPOSE:
		Manage dialog interactions between the player and NPCs. New instance for each approach.

		General sequence:
			1. Player approaches NPC and triggers dialog (handled by NPCHandler, triggered by PromptService)
			2. DialogService instance is created for that NPC
			3. DialogService processes DialogData for that NPC to determine entry point
			4. DialogService manages dialog flow, including NPC speech, player choices, and dialog hooks
			5. DialogService ends dialog when complete or player walks away
	USAGE:
		```lua
		local DialogService = require(engine:get("DialogService"))
		DialogService.new("NPC_Name") -- starts dialog with specified NPC
		```

]]

local DialogService = {
	playerDialogKey = nil,
}
DialogService.__index = DialogService

local engine
function DialogService.init(engineModule)
	engine = engineModule

	engine.events.Dialog.OnClientEvent:Connect(function(event,data)
		print("client event")
		print(event)
		if event=="historyUpdated" then 
			DialogService:onHistoryUpdated(data)
		end
	end)

end

function DialogService.new(npc)
	local self = setmetatable({}, DialogService)

	self.npc = npc
	self.npcModel = workspace.Entities:WaitForChild("NPCs"):WaitForChild(npc)

	local player = game:GetService("Players").LocalPlayer
	self.walkAwayHeartbeat = game:GetService("RunService").Heartbeat:Connect(function()
		local character = player.Character
		if not character or (character:GetPivot().Position - self.npcModel:GetPivot().Position).Magnitude > 20 then
			self.walkAwayHeartbeat:Disconnect()
			self.walkAwayHeartbeat = nil
			self:walkAway()
		end
	end)

	self:start()

	return self
end

function DialogService:start()
	local DialogData = engine:get("DialogData")
	local npcDialog = DialogData[self.npc]

	-- find entry dialog
	if npcDialog.entry then
		self:npcSpeak(npcDialog.entry)
	elseif npcDialog.entry_decide then
		for _, entry in ipairs(npcDialog.entry_decide) do
			if entry.type == "flag" then
				local GameData = engine:get("GameData")
				if GameData.flags[entry.name] then
					-- found matching entry
					if entry.next then
						self:beginConversation(entry.next)
						return
					end
				end
			end
		end
	end
end

function DialogService:onHistoryUpdated(data)
	print("updating history")
	local playerData = engine:get("PlayerService").Data
	playerData.dialog_history = data;
end

-- run through logic to begin conversation at a certain node (see DialogData.luau)
function DialogService:npcSpeak(node)
	local DialogData = engine:get("DialogData")
	local npcDialog = DialogData[self.npc]
	local conversations = npcDialog.conversations

	if self.ended then
		return
	end

	local selectedNode = conversations[node]
	local text = selectedNode.text or selectedNode.choice or selectedNode.fncText
	self.activeNode = node

	if selectedNode.fncText then
		local DialogHooks = engine:get("DialogHooks")
		text = DialogHooks:runFnc(selectedNode.fncText)
	end

	if selectedNode.pre then
		engine:get("DialogHooks"):runHooks(self, selectedNode.pre)
	end

	if typeof(text) == "table" then
		text = text[math.random(1, #text)]
	end

	text = self:parseText(text)
	local NPCHandler = engine:get("NPCHandler")
	NPCHandler:get(self.npc):displayDialog(text, selectedNode.next ~= nil or selectedNode.choice ~= nil)

	if selectedNode.post then
		engine:get("DialogHooks"):runHooks(self, selectedNode.post)
	end

	if selectedNode.choice then
		self:displayChoices(selectedNode.options)
	end

	if not self.ended and selectedNode.next and not selectedNode.choice then
		task.wait(2) -- wait a bit before continuing
		self:npcSpeak(selectedNode.next)
	end
end

function DialogService:displayChoices(options)
	local Typewriter = engine:get("Typewriter")
	local QuickTween = engine:get("QuickTween")

	if self.ended then
		return
	end

	local optionsToDisplay = {}
	for _, option in ipairs(options) do
		if option.require then
			if not self:checkRequirements(option.require) then
				continue
			end
		end
		table.insert(optionsToDisplay, option)
	end

	local player = game:GetService("Players").LocalPlayer
	local responseUI = player.PlayerGui:WaitForChild("DialogResponse")
	responseUI.Adornee = player.Character

	for _, oldOption in pairs(responseUI.Container:GetChildren()) do
		if oldOption.Name ~= "UIListLayout" and oldOption.Name ~= "Template" then
			oldOption:Destroy()
		end
	end

	local playerData = engine:get("PlayerService").Data
	
	local historyWithNpc = playerData.dialog_history[self.npc]
	print(historyWithNpc)

	for i, option in pairs(optionsToDisplay) do
		local optionUI = responseUI.Container.Template:Clone()
		optionUI.Name = "Option" .. i
		local text = self:parseText(option.optionText)
		-- @TODO We may need rich text capibilities for options in the future. If so rework this.
		local color = "rgb(255, 255, 255)"
		
		if historyWithNpc and historyWithNpc[option.id] then
				color = "rgb(180, 180, 180)"
		end

		text = `<font color="rgb(255, 231, 94)">{i}. </font><font color="{color}">{text}</font>`

		optionUI.TextLabel.Text = ""
		optionUI.UIPadding.PaddingLeft = UDim.new(0.1, 0)
		optionUI.Visible = true
		optionUI.Parent = responseUI.Container

		optionUI.TextButton.Activated:Connect(function()
			for _, oldOption in pairs(responseUI.Container:GetChildren()) do
				if oldOption.Name ~= "UIListLayout" and oldOption.Name ~= "Template" then
					oldOption.TextButton.Active = false
				end
			end
			engine.events.Dialog:FireServer("playerResponse",{npc=self.npc,option=option})
			self:playerRespond(option.bubbleText or option.optionText)
			self:npcSpeak(option.next)
		end)
		optionUI.TextButton.MouseEnter:Connect(function()
			local Sound = engine:get("Sound")
			Sound:playGlobal("Hover")
			QuickTween(optionUI.UIScale, 0.15, { Scale = 1.1 })
		end)
		optionUI.TextButton.MouseLeave:Connect(function()
			QuickTween(optionUI.UIScale, 0.3, { Scale = 1 })
		end)

		QuickTween(optionUI.UIPadding, 0.2, { PaddingLeft = UDim.new(0, 0) })
		task.spawn(function()
			Typewriter.Play(optionUI.TextLabel, text)
		end)
		task.wait(0.25)
	end
end

function DialogService:playerRespond(text)
	local Typewriter = engine:get("Typewriter")
	local QuickTween = engine:get("QuickTween")
	local player = game:GetService("Players").LocalPlayer
	local dialogUI = player.PlayerGui:WaitForChild("PlayerDialog")

	-- clean up display choices
	task.spawn(function()
		local responseUI = player.PlayerGui:WaitForChild("DialogResponse")
		for _, oldOption in pairs(responseUI.Container:GetChildren()) do
			if oldOption.Name ~= "UIListLayout" and oldOption.Name ~= "Template" then
				oldOption.TextButton.Active = false
				QuickTween(oldOption.UIPadding, 0.25, { PaddingLeft = UDim.new(0.1, 0) })
				QuickTween(oldOption.TextLabel, 0.25, { TextTransparency = 1 })
				QuickTween(oldOption.TextLabel.UIStroke, 0.25, { Transparency = 1 })
				QuickTween(oldOption.Shadow, 0.25, { ImageTransparency = 1 })
				task.wait(0.1)
			end
		end
	end)

	local respondKey = tick()
	DialogService.playerDialogKey = respondKey

	if not dialogUI.Dialog.Visible then
		dialogUI.Dialog.Position = UDim2.fromScale(0.5, 0.75)
		dialogUI.Dialog.Shadow.ImageTransparency = 1
		QuickTween(dialogUI.Dialog, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
		QuickTween(dialogUI.Dialog.Shadow, 0.15, { ImageTransparency = 0.77 })
		QuickTween(dialogUI.Dialog.Message, 0.3, { TextTransparency = 0 })
		QuickTween(dialogUI.Dialog.Message.UIStroke, 0.3, { Transparency = 0 })
	end

	dialogUI.Dialog.Message.Text = ""
	dialogUI.Dialog.Message.UIStroke.Transparency = 0
	dialogUI.Dialog.Visible = true
	dialogUI.Adornee = player.Character

	text = self:parseText(text)
	Typewriter.Play(dialogUI.Dialog.Message, text)

	task.delay(2, function()
		if DialogService.playerDialogKey == respondKey then
			QuickTween(dialogUI.Dialog, 0.3, { Position = UDim2.fromScale(0.5, 0.75) })
			QuickTween(dialogUI.Dialog.Shadow, 0.3, { ImageTransparency = 1 })
			QuickTween(dialogUI.Dialog.Message, 0.3, { TextTransparency = 1 })
			QuickTween(dialogUI.Dialog.Message.UIStroke, 0.3, { Transparency = 1 })
			task.wait(0.3)
			dialogUI.Dialog.Visible = false
		end
	end)
end

function DialogService:endDialog()
	local NPCHandler = engine:get("NPCHandler")
	local PromptService = engine:get("PromptService")
	local QuickTween = engine:get("QuickTween")
	local Debris = game:GetService("Debris")

	NPCHandler:get(self.npc):closeDialog()

	local player = game:GetService("Players").LocalPlayer

	local responseUI = player.PlayerGui:WaitForChild("DialogResponse")
	task.spawn(function()
		for _, oldOption in pairs(responseUI.Container:GetChildren()) do
			if oldOption.Name ~= "UIListLayout" and oldOption.Name ~= "Template" then
				oldOption.TextButton.Active = false
				QuickTween(oldOption.UIPadding, 0.25, { PaddingLeft = UDim.new(0.1, 0) })
				QuickTween(oldOption.TextLabel, 0.25, { TextTransparency = 1 })
				QuickTween(oldOption.TextLabel.UIStroke, 0.25, { Transparency = 1 })
				QuickTween(oldOption.Shadow, 0.25, { ImageTransparency = 1 })
				Debris:AddItem(oldOption, 0.3)
				task.wait(0.1)
			end
		end
	end)

	task.delay(1, function()
		PromptService:reEnableAll()
	end)

	self.ended = true
end

function DialogService:walkAway()
	self:endDialog()
end

function DialogService:checkRequirements(require)
	-- local PlayerService = engine:get("PlayerService")
	-- local PlayerData = PlayerService.data

	-- if require.level_min and PlayerData.level < require.level_min then
	-- 	return false
	-- end
	-- if require.level_max and PlayerData.level > require.level_max then
	-- 	return false
	-- end

	-- blah blah blah @todo

	return true
end

function DialogService:parseText(text)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local playerName = player.DisplayName

	text = text:gsub("<playerName>", playerName)

	return text
end

-- function DialogService:respond(choice) end

return DialogService
