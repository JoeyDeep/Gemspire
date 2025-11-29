--[[
PURPOSE:
	Process holding a particular loot item from a player's backpack (specifically ore-like loot)

USAGE:
	```lua
	local HoldLoot = require(engine:get("HoldLoot"))
	local myNewlyAcquiredLootItem = HoldLoot.new("GoldOre", toolClassInstance) -- toolClassInstance inherited from Tool.luau

	-- later, primary from BackpackTest.luau (for now, later be put into a permanent handler module)
	myNewlyAcquiredLootItem:equip()
	-- later, from a BackpackTest.luau (or more likely a permanent handler module)'s handling, a forced :unequip()
	myNewlyAcquiredLootItem:unequip()
	```
]]

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

	self:_initAnimations() -- load animations if not already loaded to play when loot is equipped to be held
	return self
end

function HoldLoot:_initAnimations()
	local character = Players.LocalPlayer.Character
	local animStorage = ReplicatedStorage.Storage.Animations.Player.HoldLoot -- find animation in storage

	-- only load this animation if not already loaded for the current client character
	if not HoldLoot.activeCharacter or not HoldLoot.activeCharacter:IsDescendantOf(workspace) then
		HoldLoot.activeCharacter = character

		for _, anim in pairs(animStorage:GetChildren()) do
			HoldLoot.activeAnims[anim.Name] = character.Humanoid.Animator:LoadAnimation(anim)
		end
	end
end

function HoldLoot:equip()
	-- load animation events prior to animation play to ensure they are caught
	HoldLoot.activeAnims.Equip:GetMarkerReachedSignal("Equip"):Once(function()
		if self.toolClass.equipped then
			-- tell server to physically place loot in hand for all clients to see
			engine.events.Inventory:FireServer("equipLoot", self.toolClass.data)
		end
	end)
	HoldLoot.activeAnims.Equip.Stopped:Once(function()
		if self.toolClass.equipped then
			HoldLoot.activeAnims.Idle:Play(0)
		end
	end)

	-- prepare animation to be played, then play
	HoldLoot.activeAnims.Equip:AdjustSpeed(1)
	HoldLoot.activeAnims.Equip.TimePosition = 0
	HoldLoot.activeAnims.Equip:Play()
	HoldLoot.activeAnims.Equip:AdjustSpeed(1) -- ensure speed is normal after adjusting above (@todo: test if needed)
end

function HoldLoot:unequip()
	-- tell server to destroy loot item in-hand for all clients to see
	engine.events.Inventory:FireServer("unequipLoot", self.toolClass.data)

	HoldLoot.activeAnims.Idle:Stop()

	HoldLoot.activeAnims.Equip:AdjustSpeed(-1)
	HoldLoot.activeAnims.Equip:Play()
	HoldLoot.activeAnims.Equip:AdjustSpeed(-1)
end

function HoldLoot:destroy() -- cleanup fnc
end

return HoldLoot
