local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)

local Pipecutter = {
	transparencyCache = {},
	inputTrove = nil,
}

local Encouragers = {
	[1.1] = { "Almost there!", "Just a little more!", "Last bit!", "0.6 More Newtons!" },
	[2] = { "Big crack!", "SNAP!", "CRUNCH!", "Wowzers!", "Mythical Squeeze!" },
	[3] = { "Such power!", "Fantastic!", "Geoderific!", "Crackmaster!" },
	[4] = { "Crackamanjaro!", "Crackasaurus Rex!", "Crackzilla!" },
	[6] = { "Keep squeezin'!", "Crack that sucker!", "OH YEAH!", "Squeezaholic!" },
}
local EncourageColors = {
	{ Main = Color3.fromRGB(0, 197, 248), Stroke = Color3.fromRGB(119, 117, 202) },
	{ Main = Color3.fromRGB(225, 78, 255), Stroke = Color3.fromRGB(206, 59, 61) },
	{ Main = Color3.fromRGB(0, 248, 82), Stroke = Color3.fromRGB(106, 154, 37) },
	{ Main = Color3.fromRGB(255, 201, 0), Stroke = Color3.fromRGB(255, 140, 0) },
	{ Main = Color3.fromRGB(255, 111, 0), Stroke = Color3.fromRGB(255, 0, 0) },
	{ Main = Color3.fromRGB(0, 255, 191), Stroke = Color3.fromRGB(0, 112, 255) },
	{ Main = Color3.fromRGB(255, 0, 234), Stroke = Color3.fromRGB(139, 0, 255) },
	{ Main = Color3.fromRGB(255, 0, 111), Stroke = Color3.fromRGB(255, 0, 0) },
	{ Main = Color3.fromRGB(0, 255, 140), Stroke = Color3.fromRGB(0, 255, 201) },
}

local engine
function Pipecutter.init(engineModule)
	engine = engineModule
end

function Pipecutter:start(station, geodeTool)
	local QuickTween = engine:get("QuickTween")
	local InputData = engine:get("InputData")
	local Sound = engine:get("Sound")

	local returnEvent = Instance.new("BindableEvent")

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = station.CamPart.CFrame

	local placeholder = station.Placeholder
	for _, basePart in pairs(placeholder:GetDescendants()) do
		if basePart:IsA("BasePart") then
			Pipecutter.transparencyCache[basePart] = basePart.Transparency
			basePart.Transparency = 1
		end
	end

	local pipecutter = ReplicatedStorage.Storage.GeodeCutters.Pipecutter:Clone()
	pipecutter:PivotTo(placeholder:GetPivot())
	pipecutter.Parent = station

	pipecutter.GeodeOrigin.Material = geodeTool.Handle.Material
	pipecutter.GeodeOrigin.Color = geodeTool.Handle.Color
	pipecutter.GeodeOrigin.Transparency = 0

	task.spawn(function()
		local left = pipecutter.Left
		local right = pipecutter.Right

		local cfValue = Instance.new("CFrameValue")
		local leftCFVal = Instance.new("CFrameValue")
		local rightCFVal = Instance.new("CFrameValue")

		pipecutter.Left:PivotTo(left:GetPivot():ToWorldSpace(CFrame.Angles(0, 0, math.rad(3))))
		pipecutter.Right:PivotTo(right:GetPivot():ToWorldSpace(CFrame.Angles(0, 0, math.rad(3))))
		cfValue.Value = pipecutter:GetPivot()

		cfValue:GetPropertyChangedSignal("Value"):Connect(function()
			pipecutter:PivotTo(cfValue.Value)
		end)
		leftCFVal:GetPropertyChangedSignal("Value"):Connect(function()
			left:PivotTo(leftCFVal.Value)
		end)
		rightCFVal:GetPropertyChangedSignal("Value"):Connect(function()
			right:PivotTo(rightCFVal.Value)
		end)
		QuickTween(
			cfValue,
			0.3,
			{
				Value = pipecutter.GeodeOrigin.CFrame:ToWorldSpace(
					CFrame.new(-0.25, -2.5, -0.25) * CFrame.Angles(math.rad(-10), math.rad(20), 0)
				),
			}
		)
		QuickTween(camera, 0.15, { CFrame = station.CamPart.CFrame:ToWorldSpace(CFrame.new(0, 0, 0.25)) })
		task.wait(0.3)

		local UI = engine.PlayerGui.UI.GeodeCutGame
		local activeInput = Input.PreferredInput.Current
		local particles = ReplicatedStorage.Storage.Particles.Geode:Clone()
		local leftStartPivot = left:GetPivot()
		local rightStartPivot = right:GetPivot()
		local leftGoalPivot = leftStartPivot:ToWorldSpace(CFrame.Angles(0, 0, math.rad(-8.5)))
		local rightGoalPivot = rightStartPivot:ToWorldSpace(CFrame.Angles(0, 0, math.rad(-8.5)))
		local count, maxCount = 0, 30
		local lastInputTime = tick()
		local camShakeStarted = false

		Pipecutter.inputTrove = Trove.new()

		Pipecutter.inputTrove:Add(pipecutter)
		leftCFVal.Value = leftStartPivot
		rightCFVal.Value = rightStartPivot
		particles.Parent = pipecutter.GeodeOrigin

		local camShaker = Pipecutter.inputTrove:Add(
			CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cameraCF)
				camera.CFrame *= cameraCF
			end),
			"Stop"
		)

		local function lerp(a, b, t)
			return a + (b - a) * t
		end
		local function processInput(x, y)
			local now = tick()
			count = math.clamp(count + 1, 0, maxCount)

			if count == maxCount then
				particles.RigidDebrisClusters:Emit(2)
				particles.DustDebris:Emit(5)
				particles.SmokeClusters:Emit(2)
				Sound:playGlobal("FullCrack")

				Pipecutter:cleanup()
				returnEvent:Fire(true)
				return
			end

			if count == math.round(maxCount / 4) then
				particles.RigidDebrisClusters:Emit(1)
				Sound:playGlobal("Crack1")
			elseif count == math.round(maxCount / 2) then
				particles.RigidDebrisClusters:Emit(1)
				particles.DustDebris:Emit(3)
				Sound:playGlobal("Crack2")
			end

			for threshold, messages in pairs(Encouragers) do
				if count == math.round(maxCount / threshold) then
					local message = messages[math.random(1, #messages)]
					local color = EncourageColors[math.random(1, #EncourageColors)]
					local TextLabel = UI.EncourageTemplate:Clone()
					TextLabel.Text = message
					TextLabel.Position = UDim2.fromOffset(
						x + (((math.random() > 0.5) and math.random(30, 100)) or math.random(-100, -30)),
						y
					)
					TextLabel.TextTransparency = 1
					TextLabel.Rotation = (math.random() > 0.5 and 3) or -3
					TextLabel.TextColor3 = color.Main
					TextLabel.UIStroke.Color = color.Stroke
					TextLabel.UIStroke.Transparency = 1
					TextLabel.Name = "EncourageText"
					TextLabel.Visible = true
					TextLabel.Parent = UI
					QuickTween(
						TextLabel,
						2.5,
						{ Position = UDim2.fromOffset(x, y - 25), Rotation = TextLabel.Rotation * 1.25 }
					)
					QuickTween(TextLabel, 0.5, { TextTransparency = 0 })
					QuickTween(TextLabel.UIStroke, 0.5, { Transparency = 0 })
					task.delay(2, function()
						QuickTween(TextLabel, 0.5, { TextTransparency = 1 })
						QuickTween(TextLabel.UIStroke, 0.5, { Transparency = 1 })
						task.delay(0.5, function()
							TextLabel:Destroy()
						end)
					end)
				end
			end

			if count / maxCount > 0.5 then
				QuickTween(
					engine.PlayerGui.UI.Vignette,
					0.2,
					{ ImageTransparency = lerp(1, 0, (count - (maxCount * 0.5)) / (maxCount * 0.5)) }
				)
				if count / maxCount > 0.675 and not camShakeStarted then
					camShakeStarted = true
					camShaker:Start()
					camShaker:Shake(CameraShaker.Presets.Vibration)
				end
			end

			QuickTween(camera, 0.075, { FieldOfView = lerp(70, 45, count / maxCount) })
			local lerpedLeftPivot = leftStartPivot:Lerp(leftGoalPivot, count / maxCount)
			local lerpedRightPivot = rightStartPivot:Lerp(rightGoalPivot, count / maxCount)
			QuickTween(leftCFVal, 0.075, { Value = lerpedLeftPivot })
			QuickTween(rightCFVal, 0.075, { Value = lerpedRightPivot })

			task.delay(0.33, function()
				if now == lastInputTime then
					QuickTween(camera, 0.75, { FieldOfView = 70 })
					count = 0
					QuickTween(leftCFVal, 0.75, { Value = leftStartPivot })
					QuickTween(rightCFVal, 0.75, { Value = rightStartPivot })
					QuickTween(engine.PlayerGui.UI.Vignette, 0.5, { ImageTransparency = 1 })
					if camShakeStarted then
						camShakeStarted = false
						camShaker:Stop()
					end
				end
			end)

			lastInputTime = now
		end

		local function setInput()
			if activeInput == "Gamepad" then
				UI.GamepadInput.Visible = true
			else
				UI.GamepadInput.Visible = false
			end
		end

		local touchInput = Pipecutter.inputTrove:Add(Input.Touch.new(), "Destroy")
		touchInput.TouchTap:Connect(function(touchPositions)
			processInput(touchPositions[1].x, touchPositions[1].y)
		end)
		local mouseInput = Pipecutter.inputTrove:Add(Input.Mouse.new(), "Destroy")
		mouseInput.LeftDown:Connect(function()
			local position = mouseInput:GetPosition()
			processInput(position.x, position.y)
		end)
		local gamepadInput = Pipecutter.inputTrove:Add(Input.Gamepad.new(), "Destroy")
		gamepadInput.ButtonDown:Connect(function(button)
			if button == InputData.Inputs.Pipecutter.Gamepad.Input then
				QuickTween(UI.GamepadInput.Mover, 0.075, { Position = UDim2.fromScale(0.5, 0.5) })
				processInput(0, 0)
			end
		end)
		gamepadInput.ButtonUp:Connect(function(button)
			if button == InputData.Inputs.Pipecutter.Gamepad.Input then
				QuickTween(UI.GamepadInput.Mover, 0.075, { Position = UDim2.fromScale(0.5, 0.45) })
			end
		end)

		Input.PreferredInput.Observe(function(newInput)
			activeInput = newInput
			setInput()
		end)
		setInput()
	end)

	return returnEvent
end

function Pipecutter:cleanup()
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = engine.player.Character:WaitForChild("Humanoid")
	camera.FieldOfView = 70
	for basePart, transparency in pairs(Pipecutter.transparencyCache) do
		basePart.Transparency = transparency
	end
	engine.PlayerGui.UI.Vignette.ImageTransparency = 1
	engine.PlayerGui.UI.GeodeCutGame.GamepadInput.Visible = false
	Pipecutter.transparencyCache = {}
	Pipecutter.inputTrove:Destroy()
	camera.CameraType = Enum.CameraType.Custom
end

return Pipecutter
