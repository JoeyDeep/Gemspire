local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sieve = {
	_inputEnabled = false,
	sifting = false,
	inputTrove = Trove.new(),
}

local engine
function Sieve.init(engineModule)
	engine = engineModule
end

function Sieve:start(data)
	Sieve.Data = data

	if Sieve._inputEnabled then
		Sieve:disableInput()
	end
	Sieve:enableInput()
	Sieve:initAnimations()

	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	sieveUI.Container.Bar.Slider.Size = UDim2.fromScale(data.now / data.max, 1)
	sieveUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	sieveUI.Container.QualityText.Text = `Quality: {data.quality}%`

	sieveUI.Visible = true
end

function Sieve:enableInput()
	if Sieve._inputEnabled then
		return
	end

	local InputData = engine:get("InputData")

	Sieve.keyboardInput = Sieve.inputTrove:Add(Input.Keyboard.new(), "Destroy")
	Sieve.keyboardInput.KeyDown:Connect(function(key)
		if key == InputData.Inputs.Sieve.MouseKeyboard.Input then
			Sieve:requestSift()
		end
	end)

	local mobileButton = Players.LocalPlayer
		:WaitForChild("PlayerGui")
		:WaitForChild("UI")
		:WaitForChild("Sieve")
		:WaitForChild("Tip")
		:WaitForChild("Sift").Mobile
	Sieve.mobileInput = Sieve.inputTrove:Connect(mobileButton.Activated, function()
		engine:get("Sound"):playGlobal("Click")
		Sieve:requestSift()
	end)

	Sieve.gamepadInput = Sieve.inputTrove:Add(Input.Gamepad.new(), "Destroy")
	Sieve.gamepadInput.ButtonDown:Connect(function(button, processed)
		if processed then
			return
		end
		if button == InputData.Inputs.Sieve.Gamepad.Input then
			Sieve:requestSift()
		end
	end)

	Sieve.preferredInput =
		Sieve.inputTrove:Add(Input.PreferredInput.Observe(function(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
			Sieve:updateTip(inputType)
		end))

	Sieve._inputEnabled = true
end

function Sieve:disableInput()
	if not Sieve._inputEnabled then
		return
	end

	Sieve.inputTrove:Clean()

	Sieve._inputEnabled = false
end

function Sieve:requestSift()
	local sieveStatus = engine:get("PlayerService").Data.sieve_contains
	local pickaxeToolClass = engine:get("InventoryService").tools.pickaxe
	local pickaxeClass = pickaxeToolClass.typeClass

	if not pickaxeClass then
		engine
			:get("NotificationService")
			.new("Equip your pickaxe to sift!", { italic = true, textColor = Color3.fromRGB(255, 0, 0) })
		return
	end

	if sieveStatus.now > 0 and pickaxeToolClass.equipped then
		print("pass")
		Sieve:startSifting()
	end
end

function Sieve:startSifting()
	Sieve.cameraCFCache = workspace.CurrentCamera.CFrame

	local PlayerService = engine:get("PlayerService")
	local sieveStatus = PlayerService.Data.sieve_contains
	local sieveData = engine:get("Sieves")[PlayerService.Data.sieve]
	local pickaxeClass = engine:get("InventoryService").tools.pickaxe.typeClass

	pickaxeClass.animations.Idle:Stop()
	Sieve.sifting = true
	pickaxeClass.sifting = true
	Sieve:updateTip(Input.PreferredInput.Current)

	engine.events.Inventory:FireServer("equipSieve")
end

function Sieve:updateTip(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
	if not inputType then
		inputType = Input.PreferredInput.Current
	end

	print(inputType)

	local InputData = engine:get("InputData")
	local sieveStatus = engine:get("PlayerService").Data.sieve_contains
	local tipUI =
		Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI"):WaitForChild("Sieve"):WaitForChild("Tip")

	if Sieve.sifting then
		tipUI.Sift.Visible = false
		tipUI.Mine.Visible = false
		tipUI.Both.Visible = false

		tipUI.Shake.InputIcon.Image = InputData.Icons[InputData.Inputs.SieveShake[inputType].Input]

		tipUI.Shake.Visible = true
		return
	end

	-- if at capacity
	if sieveStatus.now >= sieveStatus.max then
		tipUI.Mine.Visible = false
		tipUI.Both.Visible = false
		if inputType == "Touch" then
			tipUI.Sift.Mobile.Visible = true
			tipUI.Sift.InputIcon.Visible = false
			tipUI.Sift.Topic.Visible = false
		else
			tipUI.Sift.InputIcon.Image = InputData.Icons[InputData.Inputs.Sieve[inputType].Input]
			tipUI.Sift.Mobile.Visible = false
			tipUI.Sift.InputIcon.Visible = true
			tipUI.Sift.Topic.Visible = true
		end
		tipUI.Sift.Visible = true

	-- if none in capacity
	elseif sieveStatus.now == 0 then
		tipUI.Both.Visible = false
		tipUI.Sift.Visible = false
		tipUI.Mine.InputIcon.Image = InputData.Icons[InputData.Inputs.Pickaxe[inputType].Input]
		tipUI.Mine.Visible = true

	-- if some in capacity, but not maxxed out
	else
		tipUI.Sift.Visible = false
		tipUI.Mine.Visible = false
		tipUI.Both.MineInputIcon.Image = InputData.Icons[InputData.Inputs.Pickaxe[inputType].Input]
		if inputType == "Touch" then
			tipUI.Both.SiftInputIcon.Visible = false
			tipUI.Both.SiftTopic.Visible = false
			tipUI.Both.Mobile.Visible = true
		else
			tipUI.Both.SiftInputIcon.Visible = true
			tipUI.Both.SiftTopic.Visible = true
			tipUI.Both.Mobile.Visible = false
			tipUI.Both.SiftInputIcon.Image = InputData.Icons[InputData.Inputs.Sieve[inputType].Input]
		end
		tipUI.Both.Visible = true
	end
end

function Sieve:update(data)
	Sieve.Data = data

	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	QuickTween(sieveUI.Container.Bar.Slider, 0.2, { Size = UDim2.fromScale(data.now / data.max, 1) })
	sieveUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	sieveUI.Container.QualityText.Text = `Quality: {data.quality}%`

	Promise.fromEvent(QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 }).Completed)
		:andThen(function()
			QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	if data.now == data.max then
		sieveUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 75, 77)
	else
		sieveUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 230, 230)
	end
	Sieve:updateTip(Input.PreferredInput.Current)
end

function Sieve:warnFull()
	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	local negative = math.random() > 0.5

	QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 })
	Promise.fromEvent(
		QuickTween(sieveUI.Container.Bar.CapacityText, 0.2, { Rotation = (negative and -5) or 5 }).Completed
	)
		:andThen(function()
			QuickTween(sieveUI.Container.Bar.CapacityText, 0.2, { Rotation = 0 })
			QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	engine:get("NotificationService").new("Your sieve is full!", { italic = true })
end

function Sieve:initAnimations()
	local player = Players.LocalPlayer
	local animations = ReplicatedStorage.Storage.Animations.Player.Sieve

	Sieve.animations = {}

	for _, animation in pairs(animations:GetChildren()) do
		Sieve.animations[animation.Name] = player.Character.Humanoid.Animator:LoadAnimation(animation)
	end
end

function Sieve:stop()
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	sieveUI.Visible = false
end

return Sieve
