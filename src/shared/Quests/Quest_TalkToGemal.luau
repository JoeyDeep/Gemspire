local Players = game:GetService("Players")

local TalkToGemal = {
	requirements = {},
	questData = {
		id          = "TalkToGemal",
		title       = "Meet Grandpa Gemal",
		description = "Find Grandpa Gemal in town — he'll show you the ropes of Hearthrock.",

		startNode = "talkToGemal",
		nodes = {
			talkToGemal = {
				title       = "Talk to Grandpa Gemal",
				description = "Find Grandpa Gemal and introduce yourself.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Grandpa_Gemal",
						goal        = 1,
						description = `Speak to <font color="rgb(255, 230, 0)">Grandpa Gemal</font>`,
					},
				},
				rewards  = { coins = 50 },
				complete = true,
			},
		},
	},
}
TalkToGemal.__index = TalkToGemal

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local engine
function TalkToGemal.init(engineModule)
	engine = engineModule
end

function TalkToGemal.new(player, existingData)
	local self = setmetatable({}, TalkToGemal)

	self.playerName = player.Name
	if existingData then
		for key, value in pairs(existingData) do
			self[key] = value
		end
	else
		self.currentNode   = TalkToGemal.questData.startNode
		self.currentTasks  = {}
		self.completedNodes = {}

		for index, task in ipairs(TalkToGemal.questData.nodes[self.currentNode].tasks or {}) do
			self.currentTasks[index] = { current = 0, goal = task.goal }
		end
	end

	self:setupTaskListeners()
	self:sendToSave(true)

	return self
end

function TalkToGemal:setupTaskListeners()
	local QuestService         = engine:get("QuestService")
	local PlayerService        = engine:get("PlayerService")
	local RequirementEvaluator = engine:get("RequirementEvaluator")

	local currentNodeData = TalkToGemal.questData.nodes[self.currentNode]

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

function TalkToGemal:incrementTask(taskIndex)
	self.currentTasks[taskIndex].current += 1
	if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
		self:checkNodeCompletion()
	else
		self:sendToSave(true)
	end
end

function TalkToGemal:checkNodeCompletion()
	local QuestService = engine:get("QuestService")

	for _, task in ipairs(self.currentTasks) do
		if task.current < task.goal then return end
	end

	local currentNodeData = TalkToGemal.questData.nodes[self.currentNode]
	if currentNodeData.rewards then
		QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
	end
	if currentNodeData.complete then
		QuestService:completeQuest(Players[self.playerName], TalkToGemal.questData.id)
	elseif currentNodeData.nextNode then
		self.completedNodes[self.currentNode] = os.time()
		self:setNode(currentNodeData.nextNode)
	end
end

function TalkToGemal:setNode(nodeId)
	self.currentNode  = nodeId
	self.currentTasks = {}
	local nextNodeData = TalkToGemal.questData.nodes[self.currentNode]
	for index, task in ipairs(nextNodeData.tasks or {}) do
		self.currentTasks[index] = { current = 0, goal = task.goal }
	end
	self:setupTaskListeners()
	self:sendToSave(true)
end

function TalkToGemal:packageForSave()
	return {
		currentNode    = self.currentNode,
		currentTasks   = self.currentTasks,
		completedNodes = self.completedNodes,
	}
end

function TalkToGemal:sendToSave(updateClient)
	local PlayerService = engine:get("PlayerService")
	local playerClass   = PlayerService:get(Players[self.playerName])
	local questData     = self:packageForSave()
	playerClass.profile.Data.quests.active[TalkToGemal.questData.id] = questData
	if updateClient then
		playerClass:updateClient({ "quests" })
	end
end

function TalkToGemal:destroy()
	if self.listenerTrove then
		self.listenerTrove:Destroy()
		self.listenerTrove = nil
	end
	self = nil
end

return TalkToGemal
