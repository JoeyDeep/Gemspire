--[[
	SINGLETON (Handler)
	
	PURPOSE: 
		Manage the player's inventory, including refining kits, loot, and tool setup.

	USAGE:
		N/A, this is a service module initialized by the engine.
]]

local InventoryService = {}
InventoryService.__index = InventoryService

local engine
function InventoryService.init(engineModule)
	engine = engineModule

	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "kitUpdate" then
			InventoryService:updateRefiningKitStatus(data)
		elseif topic == "readyToRefine" then
			engine:get("RefiningKit"):setupSmash()

			for _, reward in pairs(data) do
				table.insert(engine:get("PlayerService").Data.inventory.loot, reward)
				-- [!] @TODO: add side ui to show what they got
			end
		elseif topic == "refineReplicate" then
			engine
				:get("RefineReplicate")
				:setProgress(Players[data.hostPlayerName], data.equippedKit, data.progress, data.targetRubble)
		elseif topic == "sellComplete" then
			local playerData = engine:get("PlayerService").Data
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
		end
	end)

	-- each time a new character is added, init inventory for it
	player.CharacterAdded:Connect(function(character: Model)
		InventoryService.initCharacter(character)
	end)
	if player.Character then
		InventoryService.initCharacter(player.Character)
	end
end

function InventoryService.initCharacter(character)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local backpack = player:WaitForChild("Backpack")

	local self = setmetatable({}, InventoryService)
	self.character = character
	self.backpack = backpack
	self.setupTools = {}

	self.backpack.ChildAdded:Connect(function(toolObj)
		self:setupTool(toolObj)
	end)
	for _, toolObj in pairs(backpack:GetChildren()) do
		if toolObj:IsA("Tool") then
			self:setupTool(toolObj)
		end
	end

	return self
end

function InventoryService:setupTool(toolObj)
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
		engine:get("Pickaxe").new(toolObj)
	end
end

function InventoryService:updateRefiningKitStatus(data)
	engine:get("PlayerService").Data.container = data
	engine:get("RefiningKit"):update(data)
end

return InventoryService
