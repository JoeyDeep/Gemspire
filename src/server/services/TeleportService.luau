--[[
	SINGLETON (Handler)

	PURPOSE:
		Manage player dialog data on the server side, to be used for tracking what has been said and dialog flow

	USAGE:
		N/A, this is a service module initialized by the engines

]]

local TeleporterService = {}

local engine
function TeleporterService.init(engineModule)
	engine = engineModule

	engine.events.Teleporter.OnServerEvent:Connect(function(player,event,data)
		print("here")
	end)

end

return TeleporterService