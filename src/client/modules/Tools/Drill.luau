local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)

local function bind(method, self)
	return function(...)
		return method(self, ...)
	end
end

local Drill = {
	activeClass = nil,
	heldDrill = nil,
	beam = nil,
	playerBeamAttachment = nil,
	animations = nil,
}
Drill.__index = Drill

local engine
function Drill.init(engineModule)
	engine = engineModule
end

function Drill.new(toolObj)
	local self = setmetatable({}, Drill)

	self.tool = toolObj
	self.connections = {}
	self.inputTrove = Trove.new()

	self.connections.toolEquipped = toolObj.Equipped:Connect(function()
		self:equip()
	end)
	self.connections.toolUnequipped = toolObj.Unequipped:Connect(function()
		self:unequip()
	end)

	Drill.activeClass = self

	self:initAnimations()

	return self
end

function Drill:initAnimations()
	if Drill.animations then
		return
	end

	local player = Players.LocalPlayer
	local animations = ReplicatedStorage.Storage.Animations.Player.Drilling

	Drill.animations = {}

	for _, animation in pairs(animations:GetChildren()) do
		Drill.animations[animation.Name] = player.Character.Humanoid.Animator:LoadAnimation(animation)
	end
end

function Drill:equip()
	local InputData = engine:get("InputData")

	self.inputTrove:Clean()

	self.mouseInput = self.inputTrove:Add(Input.Mouse.new(), "Destroy")
	self.mouseInput.LeftUp:Connect(bind(self.processInput, self))

	self.touchInput = self.inputTrove:Add(Input.Touch.new(), "Destroy")
	self.touchInput.TouchEnded:Connect(bind(self.processInput, self))

	self.gamepadInput = self.inputTrove:Add(Input.Gamepad.new(), "Destroy")
	self.gamepadInput.ButtonUp:Connect(function(button, processed)
		if processed then
			return
		end
		if InputData.Inputs.Drill.Gamepad.Input == button then
			self:processInput()
		end
	end)

	local playerData = engine:get("PlayerService").data

	if playerData.drill.spawnTime then
		self:turnOnDrillBeam()
	else
		self:showEquipedDrill()
		self:carryDrillPlayerAnimation()
	end
end

function Drill:unequip()
	self.inputTrove:Clean()
	if self.heldDrill then
		self.heldDrill:Destroy()
		self.heldDrill = nil
	end
	if self.beam then
		self.beam:Destroy()
		self.beam = nil
	end
	if self.playerBeamAttachment then
		self.playerBeamAttachment:Destroy()
		self.playerBeamAttachment = nil
	end
	self:carryDrillAnimationStop()
end

function Drill:processInput()
	if self:canPlayerPlaceDrill() then
		self:placeDrill()
	end
end

function Drill:turnOnDrillBeam()
	local DrillUtility = engine:get("DrillUtility")

	local character = Players.LocalPlayer.Character
	local playerDrill = DrillUtility:findPlayerDrill(Players.LocalPlayer)
	if not (character and playerDrill) then
		return
	end

	self.playerBeamAttachment = Instance.new("Attachment")
	self.playerBeamAttachment.Name = "BeamStart"
	self.playerBeamAttachment.Parent = character:FindFirstChild("Torso")

	local targetAttach = playerDrill.BeamTarget

	self.beam = Instance.new("Beam")
	self.beam.Attachment0 = self.playerBeamAttachment
	self.beam.Attachment1 = targetAttach
	self.beam.FaceCamera = true
	self.beam.Width0 = 0.2
	self.beam.Width1 = 0.2
	self.beam.Transparency = NumberSequence.new(0)
	self.beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))

	self.beam.Parent = workspace
end

function Drill:showEquipedDrill()
	local DrillUtility = engine:get("DrillUtility")
	local storage = ReplicatedStorage.Storage

	local character = Players.LocalPlayer.Character
	local torso = character and character:FindFirstChild("Torso")
	if not torso then
		return
	end

	self.heldDrill = storage.Tools.Drills.Held.Drill:Clone()

	DrillUtility:paintPlayerDrill(Players.LocalPlayer, self.heldDrill)

	local primaryPart = self.heldDrill.PrimaryPart

	self.heldDrill:PivotTo(
		torso.CFrame + torso.CFrame.LookVector * 1.75 - torso.CFrame.RightVector * 1 + Vector3.new(0, -0.75, 0)
	)

	self.heldDrill.Parent = character

	local gripWeld = Instance.new("WeldConstraint")
	gripWeld.Part0 = torso
	gripWeld.Part1 = primaryPart
	gripWeld.Parent = torso
end

function Drill:placeDrill()
	engine.events.Drill:FireServer("placeDrill")

	task.delay(0.1, function()
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end)

	self:carryDrillAnimationStop()
end

function Drill:canPlayerPlaceDrill()
	local result = false
	local Notifications = engine:get("NotificationService")
	local DrillUtility = engine:get("DrillUtility")

	local targetPivot = DrillUtility:getDrillTargetPivot(Players.LocalPlayer)

	if targetPivot then
		if DrillUtility:drillDensityCheck(Players.LocalPlayer, targetPivot.Position) then
			result = true
		else
			Notifications.new("This material is too hard for your drill to mine!", {
				italic = true,
				textColor = Color3.fromRGB(230, 75, 77),
			})
		end
	else
		Notifications.new("Nothing to mine here!", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
	end

	return result
end

function Drill:carryDrillAnimationStop()
	local carryAnimation = Drill.animations and Drill.animations.CarryDrill
	if carryAnimation then
		carryAnimation:Stop()
	end
end

function Drill:carryDrillPlayerAnimation()
	local startAnimation = Drill.animations and Drill.animations.CarryDrill
	if startAnimation then
		startAnimation:Play()
	end
end

function Drill:destroy()
	self:unequip()
	self.inputTrove:Destroy()
	for _, connection in pairs(self.connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	if Drill.activeClass == self then
		Drill.activeClass = nil
	end
end

return Drill
