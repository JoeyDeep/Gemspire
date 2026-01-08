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
	return self
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
end

function Drill:unequip()
	print("We have unequiped the drill")
	self.inputTrove:Destroy()
end


function Drill:processInput()
	if self:canPlayerPlaceDrill() then
		self:placeDrill()
	end
end

function Drill:placeDrill()
	print("placing drill")
	print(self.tool)
	engine.events.Drill:FireServer("placeDrill")
	-- self.tool.Parent = game.Workspace.Entities
	-- self.tool.CanCollide = true
	-- self.tool.Anchored = true
	-- self.tool.Position = Players.LocalPlayer.Character:GetPivot().Position


end

function Drill:canPlayerPlaceDrill()
	local result = false
	local MineZones = engine:get("MineZones")
	local Notifications = engine:get("NotificationService")
	local character = Players.LocalPlayer.Character

	-- make a raycast including only MineZones
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }
	local cast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -20, 0), params)

	if cast and cast.Instance:IsDescendantOf(workspace.Entities.MineZones) then
		local mineZone = cast.Instance.Parent.Name
		Notifications.new("You can mine here!", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
		result = true
	else
		Notifications.new("Nothing to mine here!", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
	end

	return result
end

return Drill