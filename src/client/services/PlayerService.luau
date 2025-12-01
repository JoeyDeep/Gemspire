--[[
	SINGLETON (Handler)
	
	PURPOSE:
		Manage player data on the client side, including receiving data from the server.
	USAGE:
		N/A, this is a service module initialized by the engine

]]

local PlayerService = {
	Data = {},
}

local engine
function PlayerService.init(engineModule)
	engine = engineModule

	-- await player data from server
	engine.events.PlayerData.OnClientEvent:Connect(function(topic, data)
		if topic == "provideClientData" then
			PlayerService.Data = data
			print(`Client Data:`, PlayerService.Data)
			PlayerService:loaded()
		end
	end)
end

function PlayerService:loaded()
	PlayerService._loaded = true
	-- engine:get("InventoryService").register(PlayerService.Data)
end

return PlayerService
