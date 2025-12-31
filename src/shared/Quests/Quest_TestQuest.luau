local Players = game:GetService("Players")
local TestQuest = {
    requirements = {
        -- none for now
    },
    questData = {
        id = "TestQuest",
        title = "Test Quest",
        description = "This is a test quest for development purposes.",

        startNode = "start",
        nodes = {
            start = {
                title = "Begin Your Journey",
                description = "Welcome to the test quest! Your journey begins here.",
                tasks = {
                    {
                        type = "collectLoot",
                        item = "test_item",
                        goal = 5,
                        description = `Collect <font color="rgb(255, 230, 0)">5</font> Loot Ores`
                    }
                },
                rewards = {
                    coins = 100,
                    xp = 50
                },
                nextNode = "testSpeakTo"
            },
            testSpeakTo = {
                title = "Moe's Manifest",
                description = "Speak to Moe the Miner in the village to learn more about your quest.",
                tasks = {
                    {
                        type = "speakToNPC",
                        npcId = "TestMerchant",
                        goal = 1,
                        description = `Speak to <font color="rgb(255, 230, 0)">Merchant Moe</font> in the village.`
                    }
                },
                rewards = {
                    coins = 150,
                    xp = 75
                },
                complete = true
            },
        }
    }
}
TestQuest.__index = TestQuest

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local engine
function TestQuest.init(engineModule)
    engine = engineModule
end

function TestQuest.new(player, existingData)
    local self = setmetatable({}, TestQuest)

    self.playerName = player.Name
    if existingData then -- quest previously started, loading existing data
        for key, value in pairs(existingData) do
            self[key] = value
        end
    else
        self.currentNode = TestQuest.questData.startNode
        self.currentTasks = {}
        self.completedNodes = {}

        for index, task in ipairs(TestQuest.questData.nodes[self.currentNode].tasks or {}) do
            self.currentTasks[index] = {
                current = 0,
                goal = task.goal
            }
        end
    end

    self:setupTaskListeners()
    self:sendToSave(true)

    return self
end

function TestQuest:setupTaskListeners()
    local QuestService = engine:get("QuestService")
    local PlayerService = engine:get("PlayerService")
    local RequirementEvaulator = engine:get("RequirementEvaluator")

    local currentNodeData = TestQuest.questData.nodes[self.currentNode]

    if self.listenerTrove then
        self.listenerTrove:Destroy()
    end
    self.listenerTrove = Trove.new()

    for index, task in ipairs(currentNodeData.tasks or {}) do
        self.listenerTrove:Add(QuestService.events[task.type]:Connect(function(player, data)
            if player.Name ~= self.playerName then return end

            local playerData = PlayerService:getData(Players[self.playerName])
            local pass = RequirementEvaulator:evaluateTask(task, data, playerData)
            if pass then
                self:incrementTask(index, pass)
            end
        end), "Disconnect")
    end
end

function TestQuest:incrementTask(taskIndex, data)
    self.currentTasks[taskIndex].current += 1

    print(`[Quest] Player {self.playerName} progressed task {taskIndex} of quest {TestQuest.questData.id}: {self.currentTasks[taskIndex].current}/{self.currentTasks[taskIndex].goal}`)

    if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
        self:checkNodeCompletion()
    else
        self:sendToSave(true)
    end
end

function TestQuest:checkNodeCompletion()
    local QuestService = engine:get("QuestService")

    for _, task in ipairs(self.currentTasks) do
        if task.current < task.goal then
            return -- not all tasks completed yet
        end
    end

    local currentNodeData = TestQuest.questData.nodes[self.currentNode]
    if currentNodeData.rewards then
        QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
    end
    if currentNodeData.complete then
        QuestService:completeQuest(Players[self.playerName], TestQuest.questData.id)
    elseif currentNodeData.nextNode then
        self.completedNodes[self.currentNode] = os.time()
        self:setNode(currentNodeData.nextNode)
        print(`[Quest] Player {self.playerName} advanced to node {self.currentNode} of quest {TestQuest.questData.id}`)
    end
end

function TestQuest:setNode(nodeId)
    self.currentNode = nodeId
    self.currentTasks = {}

    local nextNodeData = TestQuest.questData.nodes[self.currentNode]
    for index, task in ipairs(nextNodeData.tasks or {}) do
        self.currentTasks[index] = {
            current = 0,
            goal = task.goal
        }
    end
    self:setupTaskListeners()
    self:sendToSave(true)
end

function TestQuest:packageForSave()
    return {
        currentNode = self.currentNode,
        currentTasks = self.currentTasks,
        completedNodes = self.completedNodes
    }
end

function TestQuest:sendToSave(updateClient)
    local PlayerService = engine:get("PlayerService")
    local playerClass = PlayerService:get(Players[self.playerName])

    local questData = self:packageForSave()
    playerClass.profile.Data.quests.active[TestQuest.questData.id] = questData

    if updateClient then
        playerClass:updateClient({ "quests" })
    end
end

function TestQuest:destroy()
    if self.listenerTrove then
        self.listenerTrove:Destroy()
        self.listenerTrove = nil
    end
    self = nil
end

return TestQuest