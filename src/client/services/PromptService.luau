--[[
	CLASS: PromptService.new(existingPrompt: ProximityPrompt?) -> existingPrompt is optional; if provided, wraps that prompt
	
	PURPOSE:
		Manage proximity prompts and their interactions with the player.
		This service automatically handles prompts tagged with CollectionService tag "ProximityPrompt",
		but also allows for dynamic creation of prompts via PromptService.new()

		Essentially, this service wraps ProximityPrompt instances to provide
		custom UI handling and easy management of multiple prompts and prompt types.

	USAGE:
		ProximityPrompt instances with CollectionSerivce tag "ProximityPrompt" will be
		automatically managed by this service.

		additionally,
		dynamically created prompts can be made via PromptService.new()

]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Input = require(ReplicatedStorage.Packages.Input)
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
	task.defer(function()
		for _, instance in pairs(CollectionService:GetTagged("ProximityPrompt")) do
			PromptService.new(instance)
		end
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
	for _, existingPromptClass in pairs(PromptService.prompts) do
		if existingPrompt == existingPromptClass.prompt then
			return
		end
	end
	local self = setmetatable({}, PromptService)

	local quickTween = engine:get("QuickTween")
	local InputData = engine:get("InputData")

	local prompt = existingPrompt or Instance.new("ProximityPrompt")
	prompt.Style = Enum.ProximityPromptStyle.Custom

	local ui = ReplicatedStorage:WaitForChild("Storage"):WaitForChild("ProximityPrompt"):Clone()
	ui.Enabled = false
	ui.Parent = engine.PlayerGui or Players.LocalPlayer:WaitForChild("PlayerGui")
	local defaultButtonImage = ui.PromptFrame.InputFrame.Frame.ButtonImage.Image

	if existingPrompt then
		ui.PromptFrame.ActionText.Text = existingPrompt.ActionText
		ui.PromptFrame.ObjectText.Text = existingPrompt.ObjectText
	end

	local function setInputDisplay(inputType)
		local inputFrame = ui.PromptFrame.InputFrame.Frame
		local keyToShow
		local displayText
		local usingGamepadIcon = false

		if inputType == "Gamepad" then
			keyToShow = prompt.GamepadKeyCode
			local icon = InputData.Icons and InputData.Icons[keyToShow]
			if icon then
				inputFrame.ButtonImage.Image = icon
				inputFrame.ButtonImage.Visible = true
				inputFrame.ButtonText.Visible = false
				usingGamepadIcon = true
			else
				displayText = UserInputService:GetStringForKeyCode(prompt.GamepadKeyCode)
			end
		elseif inputType == "Touch" then
			displayText = "Tap"
		else
			keyToShow = prompt.KeyboardKeyCode
			displayText = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		end

		if not usingGamepadIcon then
			if (not displayText or displayText == "") and keyToShow and typeof(keyToShow) == "EnumItem" then
				displayText = keyToShow.Name
			end
			if not displayText or displayText == "" then
				displayText = "?"
			end
			inputFrame.ButtonText.Text = displayText
			inputFrame.ButtonText.Visible = true
			inputFrame.ButtonImage.Image = defaultButtonImage
			inputFrame.ButtonImage.Visible = true
		end
	end

	local function updateAdornee()
		local parent = prompt.Parent
		if parent and (parent:IsA("BasePart") or parent:IsA("Attachment") or parent:IsA("Model")) then
			ui.Adornee = parent
		else
			ui.Adornee = nil
		end
	end

	prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		ui.PromptFrame.ActionText.Text = prompt.ActionText
	end)
	prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
		ui.PromptFrame.ObjectText.Text = prompt.ObjectText
	end)
	prompt:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(function()
		setInputDisplay(Input.PreferredInput.Current)
	end)
	prompt:GetPropertyChangedSignal("GamepadKeyCode"):Connect(function()
		setInputDisplay(Input.PreferredInput.Current)
	end)
	prompt:GetPropertyChangedSignal("Parent"):Connect(function()
		updateAdornee()
	end)

	prompt.PromptShown:Connect(function()
		print("show me!!!")
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

	local clickButton = ui:FindFirstChildWhichIsA("TextButton", true)
	if clickButton then
		clickButton.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				prompt:InputHoldBegin()
			end
		end)
		clickButton.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				prompt:InputHoldEnd()
			end
		end)
	end

	local preferredDisconnect = Input.PreferredInput.Observe(function(inputType)
		setInputDisplay(inputType)
	end)
	updateAdornee()
	prompt.Destroying:Connect(function()
		if preferredDisconnect then
			preferredDisconnect()
			preferredDisconnect = nil
		end
	end)

	table.insert(PromptService.prompts, self)
	return self
end

function PromptService:set(property, value)
	if self.prompt then
		self.prompt[property] = value
	end
end

return PromptService
