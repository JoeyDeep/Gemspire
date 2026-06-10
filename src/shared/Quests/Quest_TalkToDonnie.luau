local Players = game:GetService("Players")

local TalkToDonnie = {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "TalkToDonnie",
		title       = "Meet Donnie",
		description = "Find Donnie in town — he might have something for you.",

		startNode = "talkToDonnie",
		nodes = {
			talkToDonnie = {
				title       = "Talk to Donnie",
				description = "Find Donnie and introduce yourself.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Donnie",
						goal        = 1,
						description = `Speak to <font color="rgb(255, 230, 0)">Donnie</font>`,
					},
				},
				rewards  = {},
				complete = true,
			},
		},
	},
}
TalkToDonnie.__index = TalkToDonnie

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local engine
function TalkToDonnie.init(engineModule)
	engine = engineModule
end

function TalkToDonnie.new(player, existingData)
	local self = setmetatable({}, TalkToDonnie)

	self.playerName = player.Name
	if existingData then
		for key, value in pairs(existingData) do
			self[key] = value
		end
	else
		self.currentNode    = TalkToDonnie.questData.startNode
		self.currentTasks   = {}
		self.completedNodes = {}

		for index, task in ipairs(TalkToDonnie.questData.nodes[self.currentNode].tasks or {}) do
			self.currentTasks[index] = { current = 0, goal = task.goal }
		end
	end

	self:setupTaskListeners()
	self:sendToSave(true)

	return self
end

function TalkToDonnie:setupTaskListeners()
	local QuestService         = engine:get("QuestService")
	local PlayerService        = engine:get("PlayerService")
	local RequirementEvaluator = engine:get("RequirementEvaluator")

	local currentNodeData = TalkToDonnie.questData.nodes[self.currentNode]

	if self.listenerTrove then self.listenerTrove:Destroy() end
	self.listenerTrove = Trove.new()

	for index, task in ipairs(currentNodeData.tasks or {}) do
		self.listenerTrove:Add(QuestService.events[task.type]:Connect(function(player, data)
			if player.Name ~= self.playerName then return end
			local playerData = PlayerService:getData(Players[self.playerName])
			if RequirementEvaluator:evaluateTask(task, data, playerData) then
				self:incrementTask(index)
			end
		end), "Disconnect")
	end
end

function TalkToDonnie:incrementTask(taskIndex)
	self.currentTasks[taskIndex].current += 1
	if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
		self:checkNodeCompletion()
	else
		self:sendToSave(true)
	end
end

function TalkToDonnie:checkNodeCompletion()
	local QuestService = engine:get("QuestService")

	for _, task in ipairs(self.currentTasks) do
		if task.current < task.goal then return end
	end

	local currentNodeData = TalkToDonnie.questData.nodes[self.currentNode]
	if currentNodeData.rewards then
		QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
	end
	if currentNodeData.complete then
		QuestService:completeQuest(Players[self.playerName], TalkToDonnie.questData.id)
	elseif currentNodeData.nextNode then
		self.completedNodes[self.currentNode] = os.time()
		self:setNode(currentNodeData.nextNode)
	end
end

function TalkToDonnie:setNode(nodeId)
	self.currentNode  = nodeId
	self.currentTasks = {}
	local nextNodeData = TalkToDonnie.questData.nodes[self.currentNode]
	for index, task in ipairs(nextNodeData.tasks or {}) do
		self.currentTasks[index] = { current = 0, goal = task.goal }
	end
	self:setupTaskListeners()
	self:sendToSave(true)
end

function TalkToDonnie:packageForSave()
	return {
		currentNode    = self.currentNode,
		currentTasks   = self.currentTasks,
		completedNodes = self.completedNodes,
	}
end

function TalkToDonnie:sendToSave(updateClient)
	local PlayerService = engine:get("PlayerService")
	local playerClass   = PlayerService:get(Players[self.playerName])
	local questData     = self:packageForSave()
	playerClass.profile.Data.quests.active[TalkToDonnie.questData.id] = questData
	if updateClient then
		playerClass:updateClient({ "quests" })
	end
end

function TalkToDonnie:destroy()
	if self.listenerTrove then
		self.listenerTrove:Destroy()
		self.listenerTrove = nil
	end
	self = nil
end

return TalkToDonnie
