--[[
	SINGLETON (Handler)

	PURPOSE:
		Manage player dialog data on the server side, to be used for tracking what has been said and dialog flow

	USAGE:
		N/A, this is a service module initialized by the engines

]]

local PlayerDialogService = {}

local engine
function PlayerDialogService.init(engineModule)
	engine = engineModule

	engine.events.Dialog.OnServerEvent:Connect(function(player,event,data)
		print("here")
		PlayerDialogService:HandleEvent(player,event, data)
	end)

end


function PlayerDialogService:HandleEvent(player,event,data)
	print(event)
	print(data)
	if event=="playerResponse" then
		PlayerDialogService:HandlePlayerResponse(player,event,data)
	end
end

-- Handlers ---------------------

function PlayerDialogService:HandlePlayerResponse(player,event,data)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)

	print(playerData)
	print("------------")

	local dialogEntry = {}

	if playerData.dialog_history[data.npc] then
		dialogEntry = playerData.dialog_history[data.npc]
	end

	dialogEntry[data.option.id]= workspace:GetServerTimeNow()

	playerData.dialog_history[data.npc] = dialogEntry
	engine.events.Dialog:FireClient(player, "historyUpdated", playerData.dialog_history);
	
end


return PlayerDialogService

