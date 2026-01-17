local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local StarterGui = game:GetService("StarterGui")

function bind(method, self)
    return function(...)
        return method(self, ...)
    end
end


local PlacedDrill = {
	activeClass = nil,
	spawnTime = nil,
	drillInfo = nil,
	timeUntilNextYield = nil,
	progressBarTween = nil,
	drill = nil,
	animations = nil,
	inputTrove = Trove.new(),
	displayedLoot = {}
}
PlacedDrill.__index = PlacedDrill

local engine
function PlacedDrill.init(engineModule)
	engine = engineModule

	

end

function PlacedDrill.new(drillObj)

	print("We are calling new on placedDrill")
	local self = setmetatable({}, PlacedDrill)

	PlacedDrill:initAnimations()

	local playerData = engine:get("PlayerService").data

	

	local Drills = engine:get("Drills")

	PlacedDrill.drillInfo = Drills[playerData.drill.type]

	self.drill = drillObj

	PlacedDrill.activeClass = self
	PlacedDrill.spawnTime = playerData.drill.spawnTime

	local DrillUtility = engine:get("DrillUtility")

	DrillUtility:paintPlayerDrill(Players.LocalPlayer,self.drill)

	self:placementAnimation()
	
	-- right now 2 seconds timer is to display the prompt as the placement animation finishes
	-- this would be more solid if it was promise based
	task.delay(2, bind(self.enableUI,self) )
		

	return self
end

function PlacedDrill:initAnimations()
	if PlacedDrill.animations then
		return
	end

	local player = Players.LocalPlayer
	local animations = ReplicatedStorage.Storage.Animations.Player.Drilling

	PlacedDrill.animations = {}

	for _, animation in pairs(animations:GetChildren()) do
		PlacedDrill.animations[animation.Name] = player.Character.Humanoid.Animator:LoadAnimation(animation)
	end
end

function PlacedDrill:handleInteraction()
	if self:calculateTotalYield()<=0 then
		self:pickupDrill()
	else
		self:collectLoot()
	end
end

function PlacedDrill:collectLoot()
	engine.events.Drill:FireServer("collectLoot")
end

function PlacedDrill:pickupDrill()
	engine.events.Drill:FireServer("pickupDrill")

	self:Destroy()
end


function PlacedDrill:confirmCollectLoot(lootData)

	local character = Players.LocalPlayer.Character
	character.Humanoid:UnequipTools()

	self:startDrillingPlayerAnimation()
	self:placePlayer()
	self:focusCamera()
	self:animateRefinerStart()
	self:pauseDrillingEffects()
	

	task.delay(0.75, function()
		self:spawnLoot(lootData)
		self:enableInput() -- do after focus camera
		self:activateRefineUI() -- do after focus camera
	end)
	
end

function PlacedDrill:pauseDrillingEffects()
	self.progressBarTween:Cancel()
	self.progressBar:Destroy()
	self.prompt.prompt:Destroy()
end

function PlacedDrill:resumeDrillingEffects()
	self:enableUI()
end

function PlacedDrill:spawnLoot(lootData)

	local targetPart = self.drill.AnimatedRefiner.Animated_Drawer

	for _, loot in ipairs(lootData) do
		local clonedLoot = ReplicatedStorage.Storage.Loot[loot.key]:Clone()

		clonedLoot.Parent = self.drill

		local randomPosition = self:randomPositionInPart(targetPart)

		clonedLoot.Position = randomPosition

		CollectionService:AddTag(clonedLoot,"loot")

	end

end



function PlacedDrill:enableInput()

	local InputData = engine:get("InputData")

	PlacedDrill.keyboardInput = PlacedDrill.inputTrove:Add(Input.Keyboard.new(), "Destroy")
	PlacedDrill.keyboardInput.KeyDown:Connect(function(key)
		if key == InputData.Inputs.Drill.MouseKeyboard.Input then
			self:onInput()
		end
	end)

	PlacedDrill.touchInput = PlacedDrill.inputTrove:Add(Input.Touch.new(), "Destroy")
	PlacedDrill.touchInput.TouchEnded:Connect(function()
		self:onInput()
	end)

	PlacedDrill.gamepadInput = PlacedDrill.inputTrove:Add(Input.Gamepad.new(), "Destroy")
	PlacedDrill.gamepadInput.ButtonUp:Connect(function(button, processed)
		if processed then
			return
		end
		if InputData.Inputs.Drill.Gamepad.Input == button then
			self:onInput()
		end
	end)

	
end

function PlacedDrill:onInput()

	self:refine()
	task.delay(5.25, function()
		self:closeRefiner()
		self:resumeDrillingEffects()
	end)

end

function PlacedDrill:refine()
	local grinder1 = self.drill.AnimatedRefiner.Animated_DrillGrinderOne
	local grinder2 = self.drill.AnimatedRefiner.Animated_DrillGrinderTwo

	self:rotateGrinder(grinder1,CFrame.new(0,0,-0.3))
	self:rotateGrinder(grinder2,CFrame.new(0,-0.3,0))

	self:animateGravel()

end


function PlacedDrill:closeRefiner()

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	engine.PlayerGui.UI.Inventory.Visible = true

	self:animateRefinerClose()

	engine:get("SpeedManager"):dropState("PlacedDrill", "freeze")

	local startAnimation = PlacedDrill.animations.StartDrilling

	startAnimation:Stop()

	local drillUI = Players.LocalPlayer.PlayerGui.UI.Drill

	drillUI.Visible = false
	
	self.inputTrove:Destroy()

	local taggedLoot = CollectionService:GetTagged("loot")

	for _, lootPart in ipairs(taggedLoot) do
		lootPart:Destroy()
	end

end


function PlacedDrill:activateRefineUI()
	local drillUI = Players.LocalPlayer.PlayerGui.UI.Drill

	PlacedDrill.preferredInput = PlacedDrill.inputTrove:Add(
		Input.PreferredInput.Observe(function(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
			PlacedDrill:updateTip(inputType)
		end)
	)

	drillUI.Visible = true
end

function PlacedDrill:placementAnimation()
	
	local QuickTeen = engine:get("QuickTween")
	local Utility = engine:get("Utility")

	local startGoalParts = self.drill.StartGoalParts:GetChildren()
	local animatedParts = self.drill.AnimatedParts
	local goalParts = self.drill.GoalParts:GetChildren()
	local promiseList = {}


	Utility:ModelTween(self.drill, 
		self.drill:GetPivot() + Vector3.new(0,0.8,0) , 
		TweenInfo.new(2, Enum.EasingStyle.Linear))

	for index, part in ipairs(startGoalParts) do 


		promiseList[index] = Promise.new(function(resolve, reject, onCancel)
			local tween = QuickTeen(
				animatedParts["Animated_"..part.Name], 2,{
					CFrame=part.CFrame,
					Size=part.Size
				}
			)
			tween.Completed:Connect(resolve)
		end)	
	end


	Promise.all(promiseList):andThen(function()
		for index, part in ipairs(goalParts) do 
			QuickTeen(animatedParts["Animated_"..part.Name],2,{
					CFrame=part.CFrame,
					Size=part.Size
				},
				TweenInfo.new(
					2,
					Enum.EasingStyle.Cubic,
					Enum.EasingDirection.InOut,
					-1,
					true,
					1
				)
			)
		end
	end)	

end


function PlacedDrill:startDrillingPlayerAnimation()
	engine:get("SpeedManager"):setState("PlacedDrill", "freeze")

	local startAnimation = PlacedDrill.animations.StartDrilling

	startAnimation.Stopped:Once(function()
		startAnimation:Play(0, 1, 0)
    	startAnimation.TimePosition = startAnimation.Length - .000001
	end)

	startAnimation:Play(0.1)
end

function PlacedDrill:animateGravel()

	local animatedParts = self.drill.AnimatedRefiner
	local goalParts = self.drill.GoalRubble:GetChildren()
	local QuickTeen = engine:get("QuickTween")

	for index, part in ipairs(goalParts) do 
		local tween = QuickTeen(animatedParts["Animated_"..part.Name],4,{
			CFrame=part.CFrame,
			Size=part.Size
		})
	end

end

function PlacedDrill:animateRefinerStart()
	local animatedParts = self.drill.AnimatedRefiner
	local goalParts = self.drill.GoalRefiner:GetChildren()
	local QuickTeen = engine:get("QuickTween")

	for index, part in ipairs(goalParts) do 
		local tween = QuickTeen(animatedParts["Animated_"..part.Name],0.75,{
			CFrame=part.CFrame,
			Size=part.Size
		})
	end
end

function PlacedDrill:animateRefinerClose()
	local animatedParts = self.drill.AnimatedRefiner
	local goalParts = self.drill.GoalRefinerClose:GetChildren()
	local QuickTeen = engine:get("QuickTween")

	for index, part in ipairs(goalParts) do 
		local tween = QuickTeen(animatedParts["Animated_"..part.Name],0.75,{
			CFrame=part.CFrame,
			Size=part.Size
		})
	end
end


function PlacedDrill:rotateGrinder(part,distanceCFrame)

	local animationTime = 2
	local tweenInfo = TweenInfo.new(animationTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,0,true)
	local goal = {
		Position = part.CFrame:ToWorldSpace(distanceCFrame).Position ,
		Orientation = part.Orientation + Vector3.new(-1080, 0, 0) 
	}
	
	local rotateTween = TweenService:Create(part, tweenInfo, goal)
	rotateTween:Play()	

end

function PlacedDrill:placePlayer()
	local placementPart = self.drill.OperatorPart
	local character = Players.LocalPlayer.Character

	local hrp = character:WaitForChild("HumanoidRootPart")

	hrp.CFrame = placementPart.CFrame

end

function PlacedDrill:focusCamera()
	local QuickTween = engine:get("QuickTween")
	local character = Players.LocalPlayer.Character
	local camera = workspace.CurrentCamera

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	engine.PlayerGui.UI.Inventory.Visible = false


	Promise.delay(0.1):andThen(function()
		
		camera.CameraType = Enum.CameraType.Scriptable
		QuickTween(camera, 0.25, {
			CFrame = character.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(0, 1.75, -1.5))
				* CFrame.Angles(math.rad(-90), 0, 0),
		})
	
	end)

end

function PlacedDrill:updateTip(inputType: "Gamepad" | "MouseKeyboard" | "Touch")

	if not inputType then
		inputType = Input.PreferredInput.Current
	end


	local drillUI = Players.LocalPlayer.PlayerGui.UI.Drill
	local InputData = engine:get("InputData")


	drillUI.Tip.InputIcon.Image = InputData.Icons[InputData.Inputs.Drill[inputType].Input]

	local tipText = "Refine Material"

	if inputType == "Touch" then
		tipText = "Tap to Refine"
	end

	drillUI.Tip.TipText.Text = tipText


end	

function PlacedDrill:enableUI()

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local storage = ReplicatedStorage.Storage

	-- Rename to "DrillProgressBar"
	local progressBar = storage.Billboards.ProgressBar:Clone()
	progressBar.Adornee = self.drill
	progressBar.Parent = playerGui

	self.progressBar = progressBar

	self:startProgressBar()
	self:enablePrompt()

end

function PlacedDrill:enablePrompt()
	local PromptService = engine:get("PromptService")

	local myPrompt = PromptService.new()


	if self:calculateTotalYield()<=0 then
		myPrompt.prompt.ActionText = "Pickup Drill"
	else
		myPrompt.prompt.ActionText = "Collect Loot"
	end
	
	myPrompt.prompt.ObjectText = "Drill"
	myPrompt.prompt.Parent = self.drill
	-- myPrompt.Enabled = true
	-- myPrompt.prompt.MaxActivationDistance = 10

	myPrompt.prompt.Triggered:Connect(bind(self.handleInteraction,self))

	self.prompt = myPrompt

end

function PlacedDrill:startProgressBar()

	print("starting progress bar")
	local totalYield = self:calculateTotalYield()

	local fill = self.progressBar.Bar:WaitForChild("Fill")

	local lootText = self.progressBar:WaitForChild("LootText")

	lootText.Text = tostring(totalYield) .. "/" .. tostring(self.drillInfo.maxLoot)

	if totalYield >= self.drillInfo.maxLoot then
		fill.Size = UDim2.new(1, 0, 1, 0)
	else
		local progress = self:calculateProgressToNextYield() / (self.drillInfo.lootInterval * 60)

		print(progress)
		fill.Size = UDim2.new(progress, 0, 1, 0)  -- Reset empty

		
		local tweenInfo = TweenInfo.new(
			self.drillInfo.lootInterval * 60,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut,
			0, false, 0
		)

		local goal = {Size = UDim2.new(1, 0, 1, 0)}

		self.progressBarTween = TweenService:Create(fill, tweenInfo, goal)

		self.progressBarTween:Play()

		self.progressBarTween.Completed:Once(function(playbackState)
			print(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				self:startProgressBar()
				self:enablePrompt()
			end
		end)

		
	end

	

end

function PlacedDrill:calculateProgressToNextYield()
	local playerData = engine:get("PlayerService").data
	local interval = self.drillInfo.lootInterval * 60
	local totalProgress = os.time() - playerData.drill.spawnTime
	local progressUntilNextLoot = totalProgress % interval

	return progressUntilNextLoot
end

function PlacedDrill:calculateTotalYield()
	local playerData = engine:get("PlayerService").data
	local interval = self.drillInfo.lootInterval * 60
	local totalProgress = os.time() - playerData.drill.spawnTime
	local totalYield = math.floor(totalProgress / interval)

	if totalYield > self.drillInfo.maxLoot then 
		totalYield = self.drillInfo.maxLoot
	end 

	return totalYield
end


function PlacedDrill:randomPositionInPart(part)
    
    local size = part.Size - Vector3.new(.2,.5,.2)
    local cf = part.CFrame
    
    -- Random local offsets: [-size/2, +size/2) uniform
    local localOffset = Vector3.new(
        math.random() * size.X - size.X / 2,
        math.random() * size.Y - size.Y / 2,
        math.random() * size.Z - size.Z / 2
    )
    
    -- Transform to world space (handles rotation/orientation)
    return cf.Position + cf:VectorToWorldSpace(localOffset)
end

function PlacedDrill:Destroy()
	print("destroying progress bar")
	if self.progressBarTween then
		self.progressBarTween:Destroy()
	end
	self.inputTrove:Destroy()
	for _, animation in pairs(self.animations) do
		animation:Stop()
		animation:Destroy()
	end
end

return PlacedDrill