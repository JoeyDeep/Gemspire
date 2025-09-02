local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HoldLoot = {
	activeCharacter = nil,
	activeAnims = {},
}
HoldLoot.__index = HoldLoot

local engine
function HoldLoot.init(engineModule)
	engine = engineModule
end

function HoldLoot.new(name, toolClass)
	local self = setmetatable({}, HoldLoot)
	self.name = name
	self.toolClass = toolClass

	self:_initAnimations()
	return self
end

function HoldLoot:_initAnimations()
	local character = Players.LocalPlayer.Character
	local animStorage = ReplicatedStorage.Storage.Animations.Player.HoldLoot

	if not HoldLoot.activeCharacter or not HoldLoot.activeCharacter:IsDescendantOf(workspace) then
		HoldLoot.activeCharacter = character

		for _, anim in pairs(animStorage:GetChildren()) do
			HoldLoot.activeAnims[anim.Name] = character.Humanoid.Animator:LoadAnimation(anim)
		end
	end
end

function HoldLoot:equip()
	HoldLoot.activeAnims.Equip:GetMarkerReachedSignal("Equip"):Once(function()
		if self.toolClass.equipped then
			engine.events.Inventory:FireServer("equipLoot", self.toolClass.data)
		end
	end)
	HoldLoot.activeAnims.Equip.Stopped:Once(function()
		if self.toolClass.equipped then
			HoldLoot.activeAnims.Idle:Play(0)
		end
	end)
	HoldLoot.activeAnims.Equip:AdjustSpeed(1)
	HoldLoot.activeAnims.Equip.TimePosition = 0
	HoldLoot.activeAnims.Equip:Play()
	HoldLoot.activeAnims.Equip:AdjustSpeed(1)
end

function HoldLoot:unequip()
	engine.events.Inventory:FireServer("unequipLoot", self.toolClass.data)

	HoldLoot.activeAnims.Idle:Stop()

	HoldLoot.activeAnims.Equip:AdjustSpeed(-1)
	HoldLoot.activeAnims.Equip:Play()
	HoldLoot.activeAnims.Equip:AdjustSpeed(-1)
end

function HoldLoot:destroy() -- cleanup fnc
end

return HoldLoot
