local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Input = require(ReplicatedStorage.Packages.Input)

local PromptService = {
	prompts = {},
	promptMap = {},
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
		if prompt.prompt and prompt.prompt.Enabled then
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
	if existingPrompt and PromptService.promptMap[existingPrompt] then
		return PromptService.promptMap[existingPrompt]
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

	self.prompt = prompt
	self.ui = ui
	self._connections = {}

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

	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(self._connections, connection)
		return connection
	end

	connect(prompt:GetPropertyChangedSignal("ActionText"), function()
		ui.PromptFrame.ActionText.Text = prompt.ActionText
	end)
	connect(prompt:GetPropertyChangedSignal("ObjectText"), function()
		ui.PromptFrame.ObjectText.Text = prompt.ObjectText
	end)
	connect(prompt:GetPropertyChangedSignal("KeyboardKeyCode"), function()
		setInputDisplay(Input.PreferredInput.Current)
	end)
	connect(prompt:GetPropertyChangedSignal("GamepadKeyCode"), function()
		setInputDisplay(Input.PreferredInput.Current)
	end)
	connect(prompt:GetPropertyChangedSignal("Parent"), updateAdornee)
	connect(prompt.PromptShown, function()
		ui.Enabled = true
	end)
	connect(prompt.PromptHidden, function()
		ui.Enabled = false
	end)
	connect(prompt.PromptButtonHoldBegan, function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.5, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
	end)
	connect(prompt.Triggered, function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.5, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(0, 0, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
	end)
	connect(prompt.PromptButtonHoldEnded, function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.15, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
	end)
	connect(prompt.TriggerEnded, function()
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame.UICorner, 0.1, { CornerRadius = UDim.new(0.15, 0) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonImage, 0.1, { ImageColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonText, 0.1, { TextColor3 = Color3.new(1, 1, 1) })
		quickTween(ui.PromptFrame.InputFrame.Frame.ButtonFrame, 0.1, { ImageColor3 = Color3.new(0, 0, 0) })
	end)
	connect(prompt.Destroying, function()
		self:destroy()
	end)

	local clickButton = ui:FindFirstChildWhichIsA("TextButton", true)
	if clickButton then
		connect(clickButton.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				prompt:InputHoldBegin()
			end
		end)
		connect(clickButton.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				prompt:InputHoldEnd()
			end
		end)
	end

	self._preferredDisconnect = Input.PreferredInput.Observe(function(inputType)
		setInputDisplay(inputType)
	end)

	ui.PromptFrame.ActionText.Text = prompt.ActionText
	ui.PromptFrame.ObjectText.Text = prompt.ObjectText
	setInputDisplay(Input.PreferredInput.Current)
	updateAdornee()

	table.insert(PromptService.prompts, self)
	PromptService.promptMap[prompt] = self
	return self
end

function PromptService:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	if self._preferredDisconnect then
		self._preferredDisconnect()
		self._preferredDisconnect = nil
	end

	for _, connection in ipairs(self._connections or {}) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	self._connections = nil

	if self.ui then
		self.ui:Destroy()
		self.ui = nil
	end

	if self.prompt then
		PromptService.promptMap[self.prompt] = nil
	end

	local index = table.find(PromptService.prompts, self)
	if index then
		table.remove(PromptService.prompts, index)
	end
end

function PromptService:set(property, value)
	if self.prompt then
		self.prompt[property] = value
	end
end

return PromptService
