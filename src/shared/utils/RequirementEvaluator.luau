--[[
    ACCEPTED REQUIREMENT TYPES:
    [X] "completed_quests": array of quest IDs that have been completed
        i.e. { "quest_1", "quest_2" }

    [ ] "level": minimum player level required (number)
        i.e. 5
]]

local Evaluator = {}

local engine
function Evaluator.init(engineModule)
    engine = engineModule
end

Evaluator.standardRequirements = {
    completed_quests = function(playerData, value)
        local completedQuests = playerData.quests.completed or {}
        for _, questId in ipairs(value) do
            if not completedQuests[questId] then
                return false
            end
        end
        return true
    end,

    hasQuestAtNode = function(playerData, value) -- value: "questId/nodeId"
        for questId, questData in pairs(playerData.quests.active or {}) do
            print(questId, questData.currentNode, value)
            if questId .. "/" .. questData.currentNode == value then
                return true
            end
        end
        return false
    end
}

Evaluator.taskRequirements = {
    collectLoot = function(playerData, data, taskData)
        if taskData.lootKey and data.lootKey ~= taskData.lootKey then
            return false
        end
        if taskData.kg and data.kg < taskData.kg then
            return false
        end
        if taskData.trait and data.trait ~= taskData.trait then
            return false
        end
        return true
    end,

    speakToNPC = function(playerData, data, taskData)
        if taskData.npcId and data.npc ~= taskData.npcId then
            return false
        end
        return true
    end
}

function Evaluator:evaluate(requirement, value, playerData)
    local evaluatorFunc = Evaluator.standardRequirements[requirement]
    if evaluatorFunc then
        return evaluatorFunc(playerData, value)
    end

    return false -- requirement type not recognized
end

function Evaluator:evaluateTask(task, data, playerData)
    local evaluatorFunc = Evaluator.taskRequirements[task.type]
    if evaluatorFunc then
        return evaluatorFunc(playerData, data, task)
    end

    return false -- task requirement type not recognized
end

return Evaluator