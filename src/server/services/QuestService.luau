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
    QuestService:checkExistingInventory(player, id)

    return true -- quest added successfully
end

function QuestService:checkExistingInventory(player, id)
    local PlayerService        = engine:get("PlayerService")
    local RequirementEvaluator = engine:get("RequirementEvaluator")
    local playerClass          = PlayerService:get(player)
    local playerData           = PlayerService:getData(player)
    if not playerClass or not playerData then return end

    local questInstance = playerClass.localData.quests[id]
    if not questInstance then return end

    local currentNodeData = questInstance.questData.nodes[questInstance.currentNode]
    if not currentNodeData or not currentNodeData.tasks then return end

    local loot = playerData.inventory and playerData.inventory.loot or {}

    for taskIndex, task in ipairs(currentNodeData.tasks) do
        if task.type == "collectLoot" then
            local counted = 0
            for _, entry in ipairs(loot) do
                if counted >= task.goal then break end
                if RequirementEvaluator:evaluateTask(task, { lootKey = entry.lootKey, kg = entry.kg, trait = entry.trait }, playerData) then
                    questInstance:incrementTask(taskIndex)
                    counted += 1
                end
            end
        end
    end
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

function QuestService:removeItems(player, removeItems)
    local InventoryService = engine:get("InventoryService")
    local PlayerService    = engine:get("PlayerService")
    local playerData       = PlayerService:getData(player)
    for _, item in ipairs(removeItems) do
        local removed = 0
        for _, entry in ipairs(playerData.inventory.loot) do
            if removed >= item.count then break end
            if entry.lootKey == item.lootKey then
                InventoryService:removeLootEntry(player, entry.id, item.lootKey)
                removed += 1
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
    if rewards.items then
        local InventoryService = engine:get("InventoryService")
        local HttpService = game:GetService("HttpService")
        for _, item in ipairs(rewards.items) do
            local id = HttpService:GenerateGUID(false)
            local entry = InventoryService:addLootEntry(player, item.lootKey, item.kg, item.trait, id)
            if entry then
                InventoryService:drawHoldLoot(playerClass, entry, id)
            end
        end
        table.insert(updateTable, "inventory")
    end
    if rewards.removeItems then
        QuestService:removeItems(player, rewards.removeItems)
        table.insert(updateTable, "inventory")
    end
    if rewards.drill then
        playerClass.profile.Data.drill = playerClass.profile.Data.drill or {}
        playerClass.profile.Data.drill.type = rewards.drill
        engine:get("InventoryService"):giveDrillTool(player, rewards.drill)
        table.insert(updateTable, "drill")
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
