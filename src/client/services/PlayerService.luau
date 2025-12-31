--[[
	SINGLETON (Handler)
	
	PURPOSE:
		Manage player data on the client side, including receiving data from the server.
	USAGE:
		N/A, this is a service module initialized by the engine

]]

local PlayerService = {
	data = {},
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
	if data.quests then
		engine:get("QuestService"):drawQuestList(data.quests)
	end
end

function PlayerService:loaded()
	PlayerService._loaded = true

	-- handle anything that needs to yield for player data here
	local data = PlayerService.data
	
	if data.quests then
		engine:get("QuestService"):drawQuestList(data.quests)
	end
end

return PlayerService
