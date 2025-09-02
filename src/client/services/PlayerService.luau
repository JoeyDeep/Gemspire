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
	engine:get("InventoryService").register(PlayerService.Data)
	-- engine:get("BackpackService"):setup(PlayerService.Data)
end

return PlayerService
