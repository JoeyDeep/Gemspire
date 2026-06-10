local Players = game:GetService("Players")

local LostRowan = {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id = "LostRowan",
		title = "Lost and Found",
		description = "Worried Dad's son Rowan has wandered off. Find him and convince him to come home.",

		startNode = "findRowan",
		nodes = {
			findRowan = {
				title = "Find Rowan",
				description = "Find Rowan somewhere near the mine paths.",
				tasks = {
					{
						type = "speakToNPC",
						npcId = "Rowan",
						goal = 1,
						description = `Find and speak to <font color="rgb(255, 230, 0)">Rowan</font>`,
					},
				},
				rewards = {},
				nextNode = "getGeode",
			},
			getGeode = {
				title = "Rowan's Request",
				description = "Rowan wants a geode before he'll go home. Find one for him.",
				tasks = {
					{
						type = "collectLoot",
						lootKey = "geode",
						goal = 1,
						description = `Collect a <font color="rgb(255, 230, 0)">Geode</font> for Rowan`,
					},
				},
				rewards = {},
				nextNode = "convinceRowan",
			},
			convinceRowan = {
				title = "Give Rowan the Geode",
				description = "Return to Rowan and give him the geode.",
				tasks = {
					{
						type = "speakToNPC",
						npcId = "Rowan",
						goal = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Rowan</font> with the geode`,
					},
				},
				rewards = {},
				nextNode = "reportBack",
			},
			reportBack = {
				title = "Tell the Parents",
				description = "Go back and tell Worried Dad that Rowan is on his way home.",
				tasks = {
					{
						type = "speakToNPC",
						npcId = "Worried_Dad",
						goal = 1,
						description = `Report back to <font color="rgb(255, 230, 0)">Worried Dad</font>`,
					},
				},
				rewards = {
					items = {
						{ lootKey = "gold", kg = 0.5 },
					},
				},
				complete = true,
			},
		},
	},
}
LostRowan.__index = LostRowan

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local engine
function LostRowan.init(engineModule)
	engine = engineModule
end

function LostRowan.new(player, existingData)
	local self = setmetatable({}, LostRowan)

	self.playerName = player.Name
	if existingData then
		for key, value in pairs(existingData) do
			self[key] = value
		end
	else
		self.currentNode = LostRowan.questData.startNode
		self.currentTasks = {}
		self.completedNodes = {}

		for index, task in ipairs(LostRowan.questData.nodes[self.currentNode].tasks or {}) do
			self.currentTasks[index] = { current = 0, goal = task.goal }
		end
	end

	self:setupTaskListeners()
	self:sendToSave(true)

	return self
end

function LostRowan:setupTaskListeners()
	local QuestService        = engine:get("QuestService")
	local PlayerService       = engine:get("PlayerService")
	local RequirementEvaluator = engine:get("RequirementEvaluator")

	local currentNodeData = LostRowan.questData.nodes[self.currentNode]

	if self.listenerTrove then
		self.listenerTrove:Destroy()
	end
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

function LostRowan:incrementTask(taskIndex)
	self.currentTasks[taskIndex].current += 1
	print(`[Quest] {self.playerName} progressed task {taskIndex} of LostRowan: {self.currentTasks[taskIndex].current}/{self.currentTasks[taskIndex].goal}`)
	if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
		self:checkNodeCompletion()
	else
		self:sendToSave(true)
	end
end

function LostRowan:checkNodeCompletion()
	local QuestService = engine:get("QuestService")

	for _, task in ipairs(self.currentTasks) do
		if task.current < task.goal then return end
	end

	local currentNodeData = LostRowan.questData.nodes[self.currentNode]
	if currentNodeData.rewards then
		QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
	end
	if currentNodeData.complete then
		QuestService:completeQuest(Players[self.playerName], LostRowan.questData.id)
	elseif currentNodeData.nextNode then
		self.completedNodes[self.currentNode] = os.time()
		self:setNode(currentNodeData.nextNode)
		print(`[Quest] {self.playerName} advanced to node {self.currentNode} of LostRowan`)
	end
end

function LostRowan:setNode(nodeId)
	self.currentNode = nodeId
	self.currentTasks = {}
	local nextNodeData = LostRowan.questData.nodes[self.currentNode]
	for index, task in ipairs(nextNodeData.tasks or {}) do
		self.currentTasks[index] = { current = 0, goal = task.goal }
	end
	self:setupTaskListeners()
	self:sendToSave(true)
end

function LostRowan:packageForSave()
	return {
		currentNode    = self.currentNode,
		currentTasks   = self.currentTasks,
		completedNodes = self.completedNodes,
	}
end

function LostRowan:sendToSave(updateClient)
	local PlayerService = engine:get("PlayerService")
	local playerClass   = PlayerService:get(Players[self.playerName])
	local questData     = self:packageForSave()
	playerClass.profile.Data.quests.active[LostRowan.questData.id] = questData
	if updateClient then
		playerClass:updateClient({ "quests" })
	end
end

function LostRowan:destroy()
	if self.listenerTrove then
		self.listenerTrove:Destroy()
		self.listenerTrove = nil
	end
	self = nil
end

return LostRowan
