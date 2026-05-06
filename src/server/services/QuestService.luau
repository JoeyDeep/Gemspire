local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local QuestService = {

    events = {
        collectLoot = Signal.new(),
        speakToNPC = Signal.new(),
    }
}

local engine
function QuestService.init(engineModule)
    engine = engineModule
    local PlayerService = engine:get("PlayerService")

    engine.events.Quests.OnServerEvent:Connect(function(player, topic, data)
        if topic == "giveQuest" and typeof(data) == "string" then
            local DialogService = engine:get("DialogService")
            if not (DialogService and DialogService:consumePendingQuestGrant(player, data)) then
                return
            end
            QuestService:addQuest(player, data)
        end
    end)

    PlayerService.PlayerAdded:Connect(function(playerClass)
        task.defer(function()
            QuestService:loadActiveQuests(playerClass)
        end)
    end)
end

function QuestService:addQuest(player, id)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(player)
    local questClass = engine:get(`Quest_{id}`)
    if not playerClass or not questClass then
        return false
    end

    playerClass.profile.Data.quests = playerClass.profile.Data.quests or { active = {}, completed = {} }
    playerClass.localData.quests = playerClass.localData.quests or {}

    if playerClass.localData.quests[id] or playerClass.profile.Data.quests.active[id] or playerClass.profile.Data.quests.completed[id] then
        return false
    end

    if questClass and questClass.requirements then
        local RequirementEvaluator, pass = engine:get("RequirementEvaluator"), true
        for requirement, value in pairs(questClass.requirements) do
            if not RequirementEvaluator:evaluate(requirement, value, playerClass.profile.Data) then
                pass = false
                break
            end
        end
        if not pass then
            return false -- requirements not met to start quest
        end
    end

    playerClass.localData.quests[id] = questClass.new(player)

    return true -- quest added successfully
end

function QuestService:loadActiveQuests(playerClass)
    if not playerClass or not playerClass.player or not playerClass.profile then
        return
    end

    local activeQuests = (((playerClass or {}).profile or {}).Data or {}).quests
    activeQuests = activeQuests and activeQuests.active or {}

    playerClass.localData.quests = playerClass.localData.quests or {}
    for questId, questData in pairs(activeQuests) do
        if not playerClass.localData.quests[questId] then
            local questClass = engine:get(`Quest_{questId}`)
            if questClass then
                playerClass.localData.quests[questId] = questClass.new(playerClass.player, questData)
            end
        end
    end
end

function QuestService:giveRewards(player, rewards)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(player)
    if not playerClass then
        return
    end

    local updateTable = {}

    if rewards.coins then
        playerClass.profile.Data.coins += rewards.coins
        table.insert(updateTable, "coins")
    end
    if rewards.xp then
        playerClass.profile.Data.xp += rewards.xp
        table.insert(updateTable, "xp")
    end

    -- @TODO: special fire to client for reward animations?

    if #updateTable > 0 then
        playerClass:updateClient(updateTable)
    end
end

function QuestService:completeQuest(player, id)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(player)
    if not playerClass then
        return
    end

    playerClass.profile.Data.quests.completed[id] = os.time()
    playerClass.profile.Data.quests.active[id] = nil

    if playerClass.localData.quests[id] then
        playerClass.localData.quests[id]:destroy()
        playerClass.localData.quests[id] = nil
    end

    playerClass:updateClient({ "quests" })
end

return QuestService
