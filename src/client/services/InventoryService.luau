--[[
	SINGLETON (Handler)

	PURPOSE: 
		Manage the player's inventory, including refining kits, loot, and tool setup.

	USAGE:
		N/A, this is a service module initialized by the engine.
]]

local InventoryService = {}
InventoryService.__index = InventoryService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryUtils = require(ReplicatedStorage.Shared.utils.InventoryUtils)

local engine
function InventoryService.init(engineModule)
	engine = engineModule

	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	InventoryService.setupTools = {}
	InventoryService.toolControllers = {}

	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "kitUpdate" then
			InventoryService:updateRefiningKitStatus(data)
		elseif topic == "readyToRefine" then
			engine:get("RefiningKit"):setupSmash()

			for _, reward in pairs(data) do
				local normalizedReward = InventoryUtils.normalizeLootEntry(reward)
				if normalizedReward then
					table.insert(engine:get("PlayerService").data.inventory.loot, normalizedReward)
				end
				-- [!] @TODO: add side ui to show what they got
			end
		elseif topic == "refineReplicate" then
			engine
				:get("RefineReplicate")
				:setProgress(Players[data.hostPlayerName], data.equippedKit, data.progress, data.targetRubble)
		elseif topic == "sellComplete" then
			local playerData = engine:get("PlayerService").data
			for _, lootSold in pairs(data.toRemove) do
				for i, tool in pairs(playerData.inventory.loot) do
					if tool.id == lootSold.id then
						table.remove(playerData.inventory.loot, i)
						break
					end
				end
			end
			playerData.coins += data.earned
			engine:get("HUD"):addCurrency("coins", data.earned, true)
		elseif topic == "craftComplete" then
			local playerData = engine:get("PlayerService").data
			if data.removedIds then
				for _, lootId in pairs(data.removedIds) do
					for i, loot in pairs(playerData.inventory.loot) do
						if loot.id == lootId then
							table.remove(playerData.inventory.loot, i)
							break
						end
					end
				end
			end
			if data.result then
				playerData.inventory.equipment = playerData.inventory.equipment or {}
				local exists = false
				for _, item in ipairs(playerData.inventory.equipment) do
					if item.id == data.result.id then
						exists = true
						break
					end
				end
				if not exists then
					table.insert(playerData.inventory.equipment, data.result)
				end
			end
			engine:get("CraftingTable"):handleCraftResult(true, data)
		elseif topic == "craftFailed" then
			engine:get("CraftingTable"):handleCraftResult(false, data)
		elseif topic == "buyComplete" then
			local playerData = engine:get("PlayerService").data
			if data.newBalance then
				playerData.coins = data.newBalance
			elseif data.price then
				playerData.coins -= data.price
			end
			if data.price then
				engine:get("HUD"):addCurrency("coins", -data.price, false)
			end
			engine:get("BuyItemsHandler"):handlePurchaseResult(true, data)
		elseif topic == "buyFailed" then
			engine:get("BuyItemsHandler"):handlePurchaseResult(false, data)
		end
	end)

	-- each time a new character is added, init inventory for it
	player.CharacterAdded:Connect(function(character: Model)
		InventoryService:bindCharacter(character)
	end)
	if player.Character then
		InventoryService:bindCharacter(player.Character)
	end
end

function InventoryService:cleanupTool(toolObj)
	local controller = self.toolControllers and self.toolControllers[toolObj]
	if controller and controller.destroy then
		controller:destroy()
	end
	if self.toolControllers then
		self.toolControllers[toolObj] = nil
	end
	if self.setupTools then
		self.setupTools[toolObj] = nil
	end
end

function InventoryService:cleanupToolBindings()
	if self._backpackChildAdded then
		self._backpackChildAdded:Disconnect()
		self._backpackChildAdded = nil
	end
	if self._backpackChildRemoved then
		self._backpackChildRemoved:Disconnect()
		self._backpackChildRemoved = nil
	end
	local toolsToCleanup = {}
	for toolObj in pairs(self.setupTools or {}) do
		table.insert(toolsToCleanup, toolObj)
	end
	for _, toolObj in ipairs(toolsToCleanup) do
		self:cleanupTool(toolObj)
	end
end

function InventoryService:bindCharacter(character)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local backpack = player:WaitForChild("Backpack")

	self.character = character
	self.backpack = backpack

	self:cleanupToolBindings()

	self._backpackChildAdded = backpack.ChildAdded:Connect(function(toolObj)
		self:setupTool(toolObj)
	end)
	self._backpackChildRemoved = backpack.ChildRemoved:Connect(function(toolObj)
		if not toolObj:IsA("Tool") then
			return
		end
		task.defer(function()
			if toolObj.Parent ~= self.backpack and toolObj.Parent ~= self.character then
				self:cleanupTool(toolObj)
			end
		end)
	end)

	for _, toolObj in pairs(backpack:GetChildren()) do
		if toolObj:IsA("Tool") then
			self:setupTool(toolObj)
		end
	end
end

function InventoryService:setupTool(toolObj)
	if not toolObj:IsA("Tool") then
		return
	end
	if self.setupTools[toolObj] then
		return
	end

	local type = toolObj:GetAttribute("Type")
	if type then
		self.setupTools[toolObj] = true
	else
		warn("Tool has no 'Type' attribute:", toolObj.Name)
		return
	end

	if type == "Pickaxe" then
		self.toolControllers[toolObj] = engine:get("Pickaxe").new(toolObj)
	elseif type == "Vault" then
		self.toolControllers[toolObj] = engine:get("Vault").new(toolObj)
	elseif type == "Drill" then
		self.toolControllers[toolObj] = engine:get("Drill").new(toolObj)
	end

	toolObj.Destroying:Once(function()
		self:cleanupTool(toolObj)
	end)

	if toolObj.Parent ~= self.backpack and toolObj.Parent ~= self.character then
		self:cleanupTool(toolObj)
	end
end

function InventoryService:updateRefiningKitStatus(data)
	engine:get("PlayerService").data.container = data
	engine:get("RefiningKit"):update(data)
end

return InventoryService
