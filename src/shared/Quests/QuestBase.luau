local Players = game:GetService("Players")
local Trove   = require(game.ReplicatedStorage.Packages.Trove)

local QuestBase = {}
QuestBase.__index = QuestBase

local engine
function QuestBase.init(engineModule)
	engine = engineModule
end

function QuestBase.new(player, descriptor, existingData)
	local self      = setmetatable({}, QuestBase)
	self.playerName = player.Name
	self.questData  = descriptor.questData

	if existingData then
		for key, value in pairs(existingData) do
			self[key] = value
		end
	else
		self.currentNode    = self.questData.startNode
		self.currentTasks   = {}
		self.completedNodes = {}
		for index, task in ipairs(self.questData.nodes[self.currentNode].tasks or {}) do
			self.currentTasks[index] = { current = 0, goal = task.goal }
		end
	end

	self:setupTaskListeners()
	self:sendToSave(true)
	return self
end

function QuestBase:setupTaskListeners()
	local QuestService         = engine:get("QuestService")
	local PlayerService        = engine:get("PlayerService")
	local RequirementEvaluator = engine:get("RequirementEvaluator")

	local currentNodeData = self.questData.nodes[self.currentNode]

	if self.listenerTrove then self.listenerTrove:Destroy() end
	self.listenerTrove = Trove.new()

	for index, task in ipairs(currentNodeData.tasks or {}) do
		local eventName = QuestService.taskEventMap[task.type] or task.type
		self.listenerTrove:Add(QuestService.events[eventName]:Connect(function(player, data)
			if player.Name ~= self.playerName then return end
			local playerData = PlayerService:getData(Players[self.playerName])
			if RequirementEvaluator:evaluateTask(task, data, playerData) then
				self:incrementTask(index)
			end
		end), "Disconnect")
	end
end

function QuestBase:incrementTask(taskIndex)
	self.currentTasks[taskIndex].current += 1
	if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
		self:checkNodeCompletion()
	else
		self:sendToSave(true)
	end
end

function QuestBase:checkNodeCompletion()
	local QuestService = engine:get("QuestService")

	for _, task in ipairs(self.currentTasks) do
		if task.current < task.goal then return end
	end

	local currentNodeData = self.questData.nodes[self.currentNode]
	if currentNodeData.rewards then
		QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
	end
	if currentNodeData.complete then
		QuestService:completeQuest(Players[self.playerName], self.questData.id)
	elseif currentNodeData.nextNode then
		self.completedNodes[self.currentNode] = os.time()
		self:setNode(currentNodeData.nextNode)
	end
end

function QuestBase:setNode(nodeId)
	self.currentNode  = nodeId
	self.currentTasks = {}
	local nextNodeData = self.questData.nodes[self.currentNode]
	for index, task in ipairs(nextNodeData.tasks or {}) do
		self.currentTasks[index] = { current = 0, goal = task.goal }
	end
	self:setupTaskListeners()
	self:sendToSave(true)
end

function QuestBase:packageForSave()
	return {
		currentNode    = self.currentNode,
		currentTasks   = self.currentTasks,
		completedNodes = self.completedNodes,
	}
end

function QuestBase:sendToSave(updateClient)
	local PlayerService = engine:get("PlayerService")
	local playerClass   = PlayerService:get(Players[self.playerName])
	local questData     = self:packageForSave()
	playerClass.profile.Data.quests.active[self.questData.id] = questData
	if updateClient then
		playerClass:updateClient({ "quests" })
	end
end

function QuestBase:destroy()
	if self.listenerTrove then
		self.listenerTrove:Destroy()
		self.listenerTrove = nil
	end
	self = nil
end

return QuestBase
