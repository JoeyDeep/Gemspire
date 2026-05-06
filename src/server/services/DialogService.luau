--[[
	SINGLETON (Handler)

	PURPOSE:
		Manage player dialog data on the server side, to be used for tracking what has been said and dialog flow

	USAGE:
		N/A, this is a service module initialized by the engines

]]

local PlayerDialogService = {}
PlayerDialogService.pendingQuestGrants = {}

local engine
function PlayerDialogService.init(engineModule)
	engine = engineModule
	local PlayerService = engine:get("PlayerService")

	engine.events.Dialog.OnServerEvent:Connect(function(player,event,data)
		PlayerDialogService:handleEvent(player,event, data)
	end)
	PlayerService.PlayerRemoved:Connect(function(playerClass)
		if playerClass and playerClass.player then
			PlayerDialogService.pendingQuestGrants[playerClass.player.UserId] = nil
		end
	end)

end


function PlayerDialogService:handleEvent(player,event,data)
	if event=="playerResponse" then
		PlayerDialogService:handlePlayerResponse(player,event,data)
	end
end

-- Handlers ---------------------

function PlayerDialogService:handlePlayerResponse(player,event,data)
	if
		typeof(data) ~= "table"
		or typeof(data.npc) ~= "string"
		or typeof(data.option) ~= "table"
		or typeof(data.option.id) ~= "string"
	then
		return
	end

	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	if not playerData then
		return
	end

	local character = player.Character
	local playerPos = character and character:GetPivot().Position
	if data.npc and workspace.Entities.NPCs:FindFirstChild(data.npc) then
		local npcPos = workspace.Entities.NPCs[data.npc]:GetPivot().Position

		if playerPos and (playerPos - npcPos).Magnitude > 50 then
			print("Player too far from NPC to record dialog")
			return
		end
		engine:get("QuestService").events.speakToNPC:Fire(player, {npc = data.npc, option = data.option})
	else
		return
	end

	local dialogEntry = {}

	if playerData.dialog_history[data.npc] then
		dialogEntry = playerData.dialog_history[data.npc]
	end

	dialogEntry[data.option.id]= workspace:GetServerTimeNow()

	playerData.dialog_history[data.npc] = dialogEntry
	PlayerDialogService:queuePendingQuestGrants(player, data.npc, data.option)

	local toSend = {
		dialog_history = playerData.dialog_history
	}

	engine.events.PlayerData:FireClient(player, "updateClientData", toSend);
	
end

function PlayerDialogService:queuePendingQuestGrants(player, npcId, option)
	local dialogData = engine:get("DialogManager"):get(npcId)
	if not dialogData or typeof(option.id) ~= "string" then
		return
	end

	local matchedOption
	for _, optionSet in pairs(dialogData.option_sets or {}) do
		for _, definedOption in ipairs(optionSet) do
			if definedOption.id == option.id and definedOption.next == option.next then
				matchedOption = definedOption
				break
			end
		end
		if matchedOption then
			break
		end
	end

	if not matchedOption or typeof(matchedOption.next) ~= "string" then
		return
	end

	local nextNode = dialogData.nodes and dialogData.nodes[matchedOption.next]
	if not nextNode or typeof(nextNode.post) ~= "table" then
		return
	end

	local playerPending = {}
	local expiresAt = os.clock() + 10
	for _, hook in ipairs(nextNode.post) do
		if hook.type == "giveQuest" and typeof(hook.id) == "string" then
			playerPending[hook.id] = expiresAt
		end
	end

	if next(playerPending) ~= nil then
		PlayerDialogService.pendingQuestGrants[player.UserId] = playerPending
	end
end

function PlayerDialogService:consumePendingQuestGrant(player, questId)
	local playerPending = PlayerDialogService.pendingQuestGrants[player.UserId]
	if not playerPending then
		return false
	end

	local expiresAt = playerPending[questId]
	if typeof(expiresAt) ~= "number" or expiresAt < os.clock() then
		playerPending[questId] = nil
		if next(playerPending) == nil then
			PlayerDialogService.pendingQuestGrants[player.UserId] = nil
		end
		return false
	end

	playerPending[questId] = nil
	if next(playerPending) == nil then
		PlayerDialogService.pendingQuestGrants[player.UserId] = nil
	end
	return true
end


return PlayerDialogService

