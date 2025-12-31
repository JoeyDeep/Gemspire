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
		PlayerDialogService:handleEvent(player,event, data)
	end)

end


function PlayerDialogService:handleEvent(player,event,data)
	print(event)
	print(data)
	if event=="playerResponse" then
		PlayerDialogService:handlePlayerResponse(player,event,data)
	end
end

-- Handlers ---------------------

function PlayerDialogService:handlePlayerResponse(player,event,data)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	print(playerData)
	print("------------")

	local character = player.Character
	local playerPos = character and character:GetPivot().Position
	if data.npc and workspace.Entities.NPCs:FindFirstChild(data.npc) then
		local npcPos = workspace.Entities.NPCs[data.npc]:GetPivot().Position

		if playerPos and (playerPos - npcPos).Magnitude > 50 then
			print("Player too far from NPC to record dialog")
			return
		end
		engine:get("QuestService").events.speakToNPC:Fire(player, {npc = data.npc, option = data.option})
	end

	local dialogEntry = {}

	if playerData.dialog_history[data.npc] then
		dialogEntry = playerData.dialog_history[data.npc]
	end

	dialogEntry[data.option.id]= workspace:GetServerTimeNow()

	playerData.dialog_history[data.npc] = dialogEntry

	local toSend = {
		dialog_history = playerData.dialog_history
	}

	engine.events.PlayerData:FireClient(player, "updateClientData", toSend);
	
end


return PlayerDialogService

