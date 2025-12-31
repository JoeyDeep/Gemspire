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

    engine.events.Quests.OnServerEvent:Connect(function(player, topic, data)
        if topic == "giveQuest" then
            QuestService:addQuest(player, data)
        end
    end)
end

function QuestService:addQuest(player, id)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(player)
    local questClass = engine:get(`Quest_{id}`)

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

function QuestService:giveRewards(player, rewards)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(player)

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

    playerClass.profile.Data.quests.completed[id] = os.time()
    playerClass.profile.Data.quests.active[id] = nil

    playerClass.localData.quests[id]:destroy()

    playerClass:updateClient({ "quests" })
end

return QuestService