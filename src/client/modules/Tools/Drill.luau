local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

function bind(method, self)
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

	toolObj.Equipped:Connect(function()
		self:equip()
	end)
	toolObj.Unequipped:Connect(function()
		self:unequip()
	end)

	self.inputTrove = Trove.new()

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
	print("We have equiped the drill")

	local InputData = engine:get("InputData")

	self.mouseInput = self.inputTrove:Add(Input.Mouse.new(), "Destroy")
	self.mouseInput.LeftUp:Connect(bind(self.processInput,self))

	self.touchInput = self.inputTrove:Add(Input.Touch.new(), "Destroy")
	self.touchInput.TouchEnded:Connect(bind(self.processInput,self))

	self.gamepadInput = self.inputTrove:Add(Input.Gamepad.new(), "Destroy")
	self.gamepadInput.ButtonUp:Connect(function(button, processed)
		if processed then
			return
		end
		if InputData.Inputs.Pickaxe.Gamepad.Input == button then
			self:processInput()
		end
	end)

	local playerData = engine:get("PlayerService").data

	if playerData.drill.spawnTime then
		print("do something else")
		self:turnOnDrillBeam()
	else
		self:showEquipedDrill()
		self:carryDrillPlayerAnimation()
	end

end

function Drill:unequip()
	print("We have unequiped the drill")
	self.inputTrove:Destroy()
	if self.heldDrill then
		self.heldDrill:Destroy()
	end
	if self.beam then
		self.beam:Destroy()
	end
	if self.playerBeamAttachment then
		self.playerBeamAttachment:Destroy()
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

	self.playerBeamAttachment = Instance.new("Attachment")
    self.playerBeamAttachment.Name = "BeamStart"
    self.playerBeamAttachment.Parent = character:FindFirstChild("Torso")

	local targetAttach = playerDrill.BeamTarget

	self.beam = Instance.new("Beam")
    self.beam.Attachment0 = self.playerBeamAttachment
    self.beam.Attachment1 = targetAttach
    self.beam.FaceCamera = true  -- Always faces camera (no twisting)
    self.beam.Width0 = 0.2
    self.beam.Width1 = 0.2
    self.beam.Transparency = NumberSequence.new(0)  -- Opaque
    self.beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) 

	self.beam.Parent = workspace
end

function Drill:showEquipedDrill()

	local DrillUtility = engine:get("DrillUtility")
	local storage = ReplicatedStorage.Storage

	local character = Players.LocalPlayer.Character

	local torso = character:FindFirstChild("Torso")

	self.heldDrill = storage.Tools.Drills.Held.Drill:Clone()

	DrillUtility:paintPlayerDrill(Players.LocalPlayer,self.heldDrill)

	local primaryPart =self.heldDrill.PrimaryPart

	print(torso.CFrame.LookVector)

	self.heldDrill:PivotTo(torso.CFrame + torso.CFrame.LookVector * 1.75 - torso.CFrame.RightVector * 1 + Vector3.new(0,-.75,0))
	--primaryPart.CFrame = rightHand.CFrame

	self.heldDrill.Parent = character

	local gripWeld = Instance.new("WeldConstraint")
    gripWeld.Part0 = torso
    gripWeld.Part1 = primaryPart
    gripWeld.Parent = torso

end

function Drill:placeDrill()
	print("placing drill")
	print(self.tool)
	
	engine.events.Drill:FireServer("placeDrill")
	
	

	task.delay(0.1, function()
		local character = Players.LocalPlayer.Character
		local humanoid = character.Humanoid
		humanoid:UnequipTools()
	end)

	self:carryDrillAnimationStop()


end

function Drill:canPlayerPlaceDrill()
	local result = false
	local Notifications = engine:get("NotificationService")
	local DrillUtility = engine:get("DrillUtility")

	local targetPivot = DrillUtility:getDrillTargetPivot(Players.LocalPlayer)

	if targetPivot then
		if DrillUtility:drillDensityCheck(Players.LocalPlayer,targetPivot.Position) then			
			result = true
		else
			Notifications.new("This material is too hard for your drill to mine!", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
		end
		
	else
		Notifications.new("Nothing to mine here!", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
	end

	return result
end

function Drill:carryDrillAnimationStop()
	local carryAnimation = Drill.animations.CarryDrill
	carryAnimation:Stop()	

end

function Drill:carryDrillPlayerAnimation()

	local startAnimation = Drill.animations.CarryDrill

	startAnimation:Play()
end

return Drill