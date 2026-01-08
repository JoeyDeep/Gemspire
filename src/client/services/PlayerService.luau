--[[
	SINGLETON (Handler)
	
	PURPOSE:
		Manage player data on the client side, including receiving data from the server.
	USAGE:
		N/A, this is a service module initialized by the engine

]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local PlayerService = {
	data = {},
	Loaded = Signal.new()
}

local engine
function PlayerService.init(engineModule)
	engine = engineModule

	-- await player data from server
	engine.events.PlayerData.OnClientEvent:Connect(function(topic, data)
		-- first time receiving player data from server
		if topic == "provideClientData" then
			PlayerService.data = data
			print(`Client Data:`, PlayerService.data)
			PlayerService:loaded()

		-- full set from server
		elseif topic == "setClientData" then
			PlayerService.data = data
		-- partial update from server
		elseif topic == "updateClientData" then
			for key, value in pairs(data) do
				PlayerService.data[key] = value
			end
			PlayerService:processClientDataUpdate(data)
		end
	end)
end

function PlayerService:processClientDataUpdate(data)
	-- handle any special cases for data updates here
end

function PlayerService:loaded()
	PlayerService._loaded = true
	PlayerService.Loaded:Fire(self)
	-- engine:get("InventoryService").register(PlayerService.data)
end

return PlayerService
