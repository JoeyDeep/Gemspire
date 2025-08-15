local Players = game:GetService("Players")
local InventoryService = {}
InventoryService.__index = InventoryService

local engine
function InventoryService.init(engineModule)
	engine = engineModule

	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "sieveUpdate" then
			InventoryService:updateSieveStatus(data)
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

function InventoryService:updateSieveStatus(data)
	engine:get("PlayerService").Data.sieve_contains = data
	engine:get("Sieve"):update(data)
end

return InventoryService
