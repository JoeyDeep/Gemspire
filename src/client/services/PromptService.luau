--[[
	PURPOSE:
		Manage proximity prompts and their interactions with the player.

	USAGE:
	N/A, this is a service module initialized by the engine
	Read more:
		ProximityPrompt instances with CollectionSerivce tag "ProximityPrompt" will be
		automatically managed by this service.

		additionally,
		dynamically created prompts can be made via PromptService.new()

]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PromptService = {
	prompts = {},
}
PromptService.__index = PromptService

local engine
function PromptService.init(engineModule)
	engine = engineModule

	CollectionService:GetInstanceAddedSignal("ProximityPrompt"):Connect(function(instance)
		PromptService.new(instance)
	end)
	for _, instance in pairs(CollectionService:GetTagged("ProximityPrompt")) do
		PromptService.new(instance)
	end

	task.spawn(function()
		task.wait(5)
		local newPrompt = PromptService.new()
		newPrompt:set("Parent", workspace.Test)
		task.wait(5)
		newPrompt:set("ActionText", "Hey! This is a dynamically created prompt!")
	end)
end

function PromptService:disableAll()
	for _, prompt in pairs(PromptService.prompts) do
		if prompt.prompt.Enabled then
			prompt:set("Enabled", false)
			prompt.wasEnabled = true
		end
	end
end

function PromptService:reEnableAll()
	for _, prompt in pairs(PromptService.prompts) do
		if prompt.wasEnabled then
			prompt:set("Enabled", true)
			prompt.wasEnabled = nil
		end
	end
end

function PromptService.new(existingPrompt)
	local self = setmetatable({}, PromptService)

	local quickTween = engine:get("QuickTween")

	local prompt = existingPrompt or Instance.new("ProximityPrompt")
	prompt.Style = Enum.ProximityPromptStyle.Custom

	local ui = ReplicatedStorage:WaitForChild("Storage"):WaitForChild("ProximityPrompt"):Clone()
	ui.Enabled = false

	if existingPrompt and existingPrompt.Parent then
		ui.Parent = existingPrompt.Parent
	end
	if existingPrompt then
		ui.PromptFrame.ActionText.Text = existingPrompt.ActionText
		ui.PromptFrame.ObjectText.Text = existingPrompt.ObjectText
	end

	prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		ui.PromptFrame.ActionText.Text = prompt.ActionText
	end)
	prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
		ui.PromptFrame.ObjectText.Text = prompt.ObjectText
	end)
	prompt:GetPropertyChangedSignal("Parent"):Connect(function()
		if prompt.Parent then
			ui.Parent = prompt.Parent
		end
	end)

	prompt.PromptShown:Connect(function()
		ui.Enabled = true
	end)
	prompt.PromptHidden:Connect(function()
		ui.Enabled = false
	end)
	prompt.PromptButtonHoldBegan:Connect(function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.5, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
	end)
	prompt.Triggered:Connect(function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.5, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
	end)
	prompt.PromptButtonHoldEnded:Connect(function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.15, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
	end)
	prompt.TriggerEnded:Connect(function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.15, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
	end)

	self.prompt = prompt
	self.ui = ui

	table.insert(PromptService.prompts, self)
	return self
end

function PromptService:set(property, value)
	if self.prompt then
		self.prompt[property] = value
	end
end

return PromptService
