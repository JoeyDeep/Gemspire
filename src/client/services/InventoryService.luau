local Players = game:GetService("Players")
local InventoryService = {}
InventoryService.__index = InventoryService

local engine
function InventoryService.init(engineModule)
	engine = engineModule
end

function InventoryService.register(playerData)
	InventoryService.tools = {}

	if not Players.LocalPlayer.Character then
		Players.LocalPlayer.CharacterAdded:Wait()
	end

	-- Initialize the player's inventory
	InventoryService.tools.pickaxe = engine:get("Tool").new(playerData.equipped.pickaxe, "Pickaxe")
end

return InventoryService
