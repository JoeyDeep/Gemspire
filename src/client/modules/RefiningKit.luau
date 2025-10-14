local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RefiningKit = {
	_inputEnabled = false,
	refining = false,
	inputTrove = Trove.new(),
	smashInputTrove = Trove.new(),
	cameraCFCache = nil,
	animations = nil,
}

local engine
function RefiningKit.init(engineModule)
	engine = engineModule
end

function RefiningKit:start(data)
	RefiningKit.Data = data

	if RefiningKit._inputEnabled then
		RefiningKit:disableInput()
	end
	RefiningKit:enableInput()
	RefiningKit:initAnimations()

	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local kitUI = ui:WaitForChild("Kit")

	kitUI.Container.Bar.Slider.Size = UDim2.fromScale(data.now / data.max, 1)
	kitUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	kitUI.Container.QualityText.Text = `Quality: {data.quality}%`

	kitUI.Visible = true
end

function RefiningKit:enableInput()
	if RefiningKit._inputEnabled then
		return
	end

	local InputData = engine:get("InputData")

	RefiningKit.keyboardInput = RefiningKit.inputTrove:Add(Input.Keyboard.new(), "Destroy")
	RefiningKit.keyboardInput.KeyDown:Connect(function(key)
		if key == InputData.Inputs.Refine.MouseKeyboard.Input then
			RefiningKit:requestRefine()
		end
	end)

	local mobileButton = Players.LocalPlayer
		:WaitForChild("PlayerGui")
		:WaitForChild("UI")
		:WaitForChild("Kit")
		:WaitForChild("Tip")
		:WaitForChild("Refine").Mobile
	RefiningKit.mobileInput = RefiningKit.inputTrove:Connect(mobileButton.Activated, function()
		engine:get("Sound"):playGlobal("Click")
		RefiningKit:requestRefine()
	end)

	RefiningKit.gamepadInput = RefiningKit.inputTrove:Add(Input.Gamepad.new(), "Destroy")
	RefiningKit.gamepadInput.ButtonDown:Connect(function(button, processed)
		if processed then
			return
		end
		if button == InputData.Inputs.Refine.Gamepad.Input then
			RefiningKit:requestRefine()
		end
	end)

	RefiningKit.preferredInput = RefiningKit.inputTrove:Add(
		Input.PreferredInput.Observe(function(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
			RefiningKit:updateTip(inputType)
		end)
	)

	RefiningKit._inputEnabled = true
end

function RefiningKit:disableInput()
	if not RefiningKit._inputEnabled then
		return
	end

	RefiningKit.inputTrove:Clean()
	RefiningKit.smashInputTrove:Clean()
	RefiningKit._inputEnabled = false
end

function RefiningKit:requestRefine()
	local sifterStatus = engine:get("PlayerService").Data.container
	local pickaxeToolClass = engine:get("Pickaxe").activeClass
	local character = Players.LocalPlayer.Character

	if not pickaxeToolClass then
		engine
			:get("NotificationService")
			.new("Equip your pickaxe to refine!", { italic = true, textColor = Color3.fromRGB(255, 0, 0) })
		return
	end

	local charCF = character.HumanoidRootPart.CFrame
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace.Entities.Characters }
	local shapeCast =
		workspace:Blockcast(charCF:ToWorldSpace(CFrame.new(0, 3, -3)), Vector3.new(4.5, 1, 3), Vector3.new(0, -5, 0))

	if shapeCast and shapeCast.Instance then
		engine
			:get("NotificationService")
			.new("Find a more flat place to refine!", { italic = true, textColor = Color3.fromRGB(255, 0, 0) })
		return
	end

	if sifterStatus.now > 0 and pickaxeToolClass.equipped then
		RefiningKit:startRefining()
	end
end

function RefiningKit:startRefining()
	RefiningKit.cameraCFCache = workspace.CurrentCamera.CFrame

	-- local PlayerService = engine:get("PlayerService")
	local QuickTween = engine:get("QuickTween")
	-- local containerStatus = PlayerService.Data.container
	-- local kitData = engine:get("Kits")[PlayerService.Data.sifter]
	local pickaxeClass = engine:get("Pickaxe").activeClass
	local character = Players.LocalPlayer.Character
	local camera = workspace.CurrentCamera

	pickaxeClass.animations.Idle:Stop()
	RefiningKit.refining = true
	pickaxeClass.refining = true
	RefiningKit:updateTip(Input.PreferredInput.Current)
	RefiningKit.cameraCFCache = camera.CFrame
	engine:get("SpeedManager"):setState("RefiningKit", "freeze")

	engine:get("BackpackService"):disable()

	RefiningKit.animations.Kneel:Play(0.1)
	engine.events.Inventory:FireServer("equipKit")

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	Promise.delay(0.1):andThen(function()
		camera.CameraType = Enum.CameraType.Scriptable
		QuickTween(camera, 0.25, {
			CFrame = character.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(0, 2, -2.5))
				* CFrame.Angles(math.rad(-90), 0, 0),
		})
	end)
end

function RefiningKit:stopRefining()
	local QuickTween = engine:get("QuickTween")
	RefiningKit.refining = false

	Promise.fromEvent(QuickTween(workspace.CurrentCamera, 0.25, { CFrame = RefiningKit.cameraCFCache }).Completed)
		:andThen(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end)

	task.wait(0.45)

	engine.events.Inventory:FireServer("finishRefining")

	local pickaxeTypeClass = engine:get("Pickaxe").activeClass
	pickaxeTypeClass.refining = false
	pickaxeTypeClass.animations.Idle:Play(0.1)

	RefiningKit.smashInputTrove:Clean()

	engine:get("SpeedManager"):dropState("RefiningKit", "freeze")

	for _, kitAnim in pairs(RefiningKit.animations) do
		kitAnim:Stop()
	end

	engine:get("BackpackService"):enable()
end

function RefiningKit:setupSmash()
	local InputData = engine:get("InputData")
	local PlayerService = engine:get("PlayerService")
	local Kits = engine:get("Kits")
	local Sound = engine:get("Sound")

	local character = Players.LocalPlayer.Character
	local equippedTray = Kits[PlayerService.Data.equipped.kit].tray
	local containerStatus = PlayerService.Data.container

	local lastSmash = tick()

	RefiningKit.refineProgress = containerStatus.now

	local function smash()
		if tick() - lastSmash < 0.5 then
			return
		end
		lastSmash = tick()

		local trayModel = character[`{equippedTray}_Tray`]
		local traySize = trayModel:GetExtentsSize()
		local middlePos = trayModel.Handle.Middle.WorldPosition
		local malletStrength = Kits[PlayerService.Data.equipped.kit].stats.malletStrength

		local chosenRubble = trayModel.RefineEntities.Rubble:GetChildren()[math.random(
			1,
			#trayModel.RefineEntities.Rubble:GetChildren()
		)]

		-- Project rubblePos onto the X axis relative to middlePos
		local rubblePos = chosenRubble.Position
		local offset = rubblePos.X - middlePos.X
		local third = traySize.X / 3

		local direction
		if offset < -third / 2 then
			direction = "Left"
		elseif offset > third / 2 then
			direction = "Right"
		else
			direction = "Middle"
		end

		local animation = RefiningKit.animations[`Strike{direction}`]
		animation:GetMarkerReachedSignal("Hit"):Once(function()
			Sound:playLocalFromRandom("RefineSmash", trayModel.Handle).PlaybackSpeed = Random.new():NextNumber(0.9, 1.1)
			RefiningKit.refineProgress = math.clamp(RefiningKit.refineProgress - malletStrength, 0, containerStatus.max)
			PlayerService.Data.container.now = RefiningKit.refineProgress
			engine:get("RefineReplicate"):setProgress(
				Players.LocalPlayer,
				PlayerService.Data.equipped.kit,
				RefiningKit.refineProgress / containerStatus.max,
				chosenRubble
			)

			RefiningKit:update(PlayerService.Data.container)
			if RefiningKit.refineProgress <= 0 then
				RefiningKit:stopRefining()
			end
		end)
		engine.events.Inventory:FireServer("smashReplicate", {
			targetRubble = chosenRubble.Name,
		})
		animation:Play()
	end

	local mouseInput = RefiningKit.smashInputTrove:Add(Input.Mouse.new(), "Destroy")
	mouseInput.LeftDown:Connect(smash)

	local touchInput = RefiningKit.smashInputTrove:Add(Input.Touch.new(), "Destroy")
	touchInput.TouchStarted:Connect(smash)

	local gamepadInput = RefiningKit.smashInputTrove:Add(Input.Gamepad.new(), "Destroy")
	gamepadInput.ButtonDown:Connect(function(button, processed)
		if processed then
			return
		end
		if button == InputData.Inputs.MalletSmash.Gamepad.Input then
			smash()
		end
	end)
end

function RefiningKit:updateTip(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
	if not inputType then
		inputType = Input.PreferredInput.Current
	end

	local InputData = engine:get("InputData")
	local containerStatus = engine:get("PlayerService").Data.container

	local tipUI =
		Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI"):WaitForChild("Kit"):WaitForChild("Tip")

	if RefiningKit.refining then
		tipUI.Refine.Visible = false
		tipUI.Mine.Visible = false
		tipUI.Both.Visible = false

		tipUI.Smash.InputIcon.Image = InputData.Icons[InputData.Inputs.MalletSmash[inputType].Input]

		tipUI.Smash.Visible = true
		return
	else
		tipUI.Smash.Visible = false
	end

	-- if at capacity
	if containerStatus.now >= containerStatus.max then
		tipUI.Mine.Visible = false
		tipUI.Both.Visible = false
		if inputType == "Touch" then
			tipUI.Refine.Mobile.Visible = true
			tipUI.Refine.InputIcon.Visible = false
			tipUI.Refine.Topic.Visible = false
		else
			tipUI.Refine.InputIcon.Image = InputData.Icons[InputData.Inputs.Refine[inputType].Input]
			tipUI.Refine.Mobile.Visible = false
			tipUI.Refine.InputIcon.Visible = true
			tipUI.Refine.Topic.Visible = true
		end
		tipUI.Refine.Visible = true

	-- if none in capacity
	elseif containerStatus.now == 0 then
		tipUI.Both.Visible = false
		tipUI.Refine.Visible = false
		tipUI.Mine.InputIcon.Image = InputData.Icons[InputData.Inputs.Pickaxe[inputType].Input]
		tipUI.Mine.Visible = true

	-- if some in capacity, but not maxxed out
	else
		tipUI.Refine.Visible = false
		tipUI.Mine.Visible = false
		tipUI.Both.MineInputIcon.Image = InputData.Icons[InputData.Inputs.Pickaxe[inputType].Input]
		if inputType == "Touch" then
			tipUI.Both.RefineInputIcon.Visible = false
			tipUI.Both.RefineTopic.Visible = false
			tipUI.Both.Mobile.Visible = true
		else
			tipUI.Both.RefineInputIcon.Visible = true
			tipUI.Both.RefineTopic.Visible = true
			tipUI.Both.Mobile.Visible = false
			tipUI.Both.RefineInputIcon.Image = InputData.Icons[InputData.Inputs.Refine[inputType].Input]
		end
		tipUI.Both.Visible = true
	end
end

function RefiningKit:update(data)
	RefiningKit.Data = data

	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local kitUI = ui:WaitForChild("Kit")

	QuickTween(kitUI.Container.Bar.Slider, 0.2, { Size = UDim2.fromScale(data.now / data.max, 1) })
	kitUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	kitUI.Container.QualityText.Text = `Quality: {data.quality}%`

	Promise.fromEvent(QuickTween(kitUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 }).Completed)
		:andThen(function()
			QuickTween(kitUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	local character = Players.LocalPlayer.Character
	if character then
		local kitData = engine:get("Kits")[engine:get("PlayerService").Data.equipped.kit]
		local equippedContainer = kitData.container
		local containerModel = character:FindFirstChild(equippedContainer)
		if containerModel then
			if data.now > 0 then
				local fillMotor = containerModel.Handle.FillMotor
				local rubbleMotor = containerModel.Handle.RubbleMotor
				local fillOffsets = kitData.containerFillOffsets
				local progressCF = fillOffsets.Min:Lerp(fillOffsets.Max, data.now / data.max)
				containerModel.Rubble.Transparency = 0
				containerModel.FillPlane.Transparency = 0
				QuickTween(fillMotor, 2, { C0 = progressCF })
				QuickTween(rubbleMotor, 2, { C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset) })
				-- fillMotor.C0 = progressCF
				-- rubbleMotor.C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset)
			else
				containerModel.Rubble.Transparency = 1
				containerModel.FillPlane.Transparency = 1
			end
		end
	else
		warn("Items folder not found in character.")
	end

	if data.now == data.max then
		kitUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 75, 77)
	else
		kitUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 230, 230)
	end
	RefiningKit:updateTip(Input.PreferredInput.Current)
end

function RefiningKit:warnFull()
	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local kitUI = ui:WaitForChild("Kit")

	local negative = math.random() > 0.5

	QuickTween(kitUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 })
	Promise.fromEvent(
		QuickTween(kitUI.Container.Bar.CapacityText, 0.2, { Rotation = (negative and -5) or 5 }).Completed
	)
		:andThen(function()
			QuickTween(kitUI.Container.Bar.CapacityText, 0.2, { Rotation = 0 })
			QuickTween(kitUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	engine:get("NotificationService").new("Your container is full!", { italic = true })
end

function RefiningKit:initAnimations()
	if RefiningKit.animations then
		return
	end

	local player = Players.LocalPlayer
	local animations = ReplicatedStorage.Storage.Animations.Player.Refining

	RefiningKit.animations = {}

	for _, animation in pairs(animations:GetChildren()) do
		RefiningKit.animations[animation.Name] = player.Character.Humanoid.Animator:LoadAnimation(animation)
	end
end

function RefiningKit:stop()
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local kitUI = ui:WaitForChild("Kit")

	kitUI.Visible = false
end

return RefiningKit
