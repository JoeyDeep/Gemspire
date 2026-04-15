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
		if event == "teleport" then
			TeleporterService:TeleportHandler(player, data)
		end
	end)

end

function TeleporterService:TeleportHandler(player, data)
	local teleporterA = workspace.Entities.Teleporters:WaitForChild(data.fromTeleporter)
	local teleporterB = workspace.Entities.Teleporters:WaitForChild(data.toTeleporter)
	TeleporterService:TeleportPlayer(player,teleporterA,teleporterB)
end

function TeleporterService:TeleportPlayer(player,teleA,teleB)
	print(teleA.WorldPivot)
	print(teleB.WorldPivot)
	local humanoid = player.character.Humanoid
	print(humanoid)
	

end

return TeleporterService