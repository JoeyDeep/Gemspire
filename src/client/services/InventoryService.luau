local Players = game:GetService("Players")
local InventoryService = {}
InventoryService.__index = InventoryService

local engine
function InventoryService.init(engineModule)
	engine = engineModule

	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "kitUpdate" then
			InventoryService:updateRefiningKitStatus(data)
		elseif topic == "readyToRefine" then
			engine:get("RefiningKit"):setupSmash()
		elseif topic == "refineReplicate" then
			engine
				:get("RefineReplicate")
				:setProgress(Players[data.hostPlayerName], data.equippedKit, data.progress, data.targetRubble)
		end
	end)
end

function InventoryService.register(playerData)
	InventoryService.tools = {}

	if not Players.LocalPlayer.Character then
		Players.LocalPlayer.CharacterAdded:Wait()
	end

	-- Initialize the player's inventory
	InventoryService.tools.pickaxe = engine:get("Tool").new(playerData.equipped.pickaxe, "Pickaxe")
end

function InventoryService:updateRefiningKitStatus(data)
	engine:get("PlayerService").Data.container = data
	engine:get("RefiningKit"):update(data)
end

return InventoryService
