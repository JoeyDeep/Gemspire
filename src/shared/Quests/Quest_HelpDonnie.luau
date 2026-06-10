local Players = game:GetService("Players")

local HelpDonnie = {
	requirements = {
		completed_quests = { "TalkToGemal" },
	},
	questData = {
		id          = "HelpDonnie",
		title       = "Donnie's Deal",
		description = "Donnie the drill-maker needs titanium before he can sell again. Bring him some and he'll give you a starter drill.",

		startNode = "collectTitanium",
		nodes = {
			collectTitanium = {
				title       = "Collect Titanium for Donnie",
				description = "Find 3kg of titanium ore and bring it to Donnie.",
				tasks = {
					{
						type        = "collectLoot",
						lootKey     = "titanium",
						goal        = 3,
						description = `Collect <font color="rgb(185, 190, 205)">Titanium Ore</font>`,
					},
				},
				rewards  = {},
				nextNode = "returnToDonnie",
			},
			returnToDonnie = {
				title       = "Return to Donnie",
				description = "Bring the titanium back to Donnie to claim your drill.",
				tasks = {
					{
						type        = "speakToNPC",
						npcId       = "Donnie",
						goal        = 1,
						description = `Return to <font color="rgb(255, 230, 0)">Donnie</font> with the titanium`,
					},
				},
				rewards  = { drill = "rusty", removeItems = { { lootKey = "titanium", count = 3 } } },
				complete = true,
			},
		},
	},
}
HelpDonnie.__index = HelpDonnie

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local engine
function HelpDonnie.init(engineModule)
	engine = engineModule
end

function HelpDonnie.new(player, existingData)
	local self = setmetatable({}, HelpDonnie)

	self.playerName = player.Name
	if existingData then
		for key, value in pairs(existingData) do
			self[key] = value
		end
	else
		self.currentNode    = HelpDonnie.questData.startNode
		self.currentTasks   = {}
		self.completedNodes = {}

		for index, task in ipairs(HelpDonnie.questData.nodes[self.currentNode].tasks or {}) do
			self.currentTasks[index] = { current = 0, goal = task.goal }
		end
	end

	self:setupTaskListeners()
	self:sendToSave(true)

	return self
end

function HelpDonnie:setupTaskListeners()
	local QuestService         = engine:get("QuestService")
	local PlayerService        = engine:get("PlayerService")
	local RequirementEvaluator = engine:get("RequirementEvaluator")

	local currentNodeData = HelpDonnie.questData.nodes[self.currentNode]

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

function HelpDonnie:incrementTask(taskIndex)
	self.currentTasks[taskIndex].current += 1
	print(`[Quest] {self.playerName} progressed task {taskIndex} of HelpDonnie: {self.currentTasks[taskIndex].current}/{self.currentTasks[taskIndex].goal}`)
	if self.currentTasks[taskIndex].current >= self.currentTasks[taskIndex].goal then
		self:checkNodeCompletion()
	else
		self:sendToSave(true)
	end
end

function HelpDonnie:checkNodeCompletion()
	local QuestService = engine:get("QuestService")

	for _, task in ipairs(self.currentTasks) do
		if task.current < task.goal then return end
	end

	local currentNodeData = HelpDonnie.questData.nodes[self.currentNode]
	if currentNodeData.rewards then
		QuestService:giveRewards(Players[self.playerName], currentNodeData.rewards)
	end
	if currentNodeData.complete then
		QuestService:completeQuest(Players[self.playerName], HelpDonnie.questData.id)
	elseif currentNodeData.nextNode then
		self.completedNodes[self.currentNode] = os.time()
		self:setNode(currentNodeData.nextNode)
		print(`[Quest] {self.playerName} advanced to node {self.currentNode} of HelpDonnie`)
	end
end

function HelpDonnie:setNode(nodeId)
	self.currentNode  = nodeId
	self.currentTasks = {}
	local nextNodeData = HelpDonnie.questData.nodes[self.currentNode]
	for index, task in ipairs(nextNodeData.tasks or {}) do
		self.currentTasks[index] = { current = 0, goal = task.goal }
	end
	self:setupTaskListeners()
	self:sendToSave(true)
end

function HelpDonnie:packageForSave()
	return {
		currentNode    = self.currentNode,
		currentTasks   = self.currentTasks,
		completedNodes = self.completedNodes,
	}
end

function HelpDonnie:sendToSave(updateClient)
	local PlayerService = engine:get("PlayerService")
	local playerClass   = PlayerService:get(Players[self.playerName])
	local questData     = self:packageForSave()
	playerClass.profile.Data.quests.active[HelpDonnie.questData.id] = questData
	if updateClient then
		playerClass:updateClient({ "quests" })
	end
end

function HelpDonnie:destroy()
	if self.listenerTrove then
		self.listenerTrove:Destroy()
		self.listenerTrove = nil
	end
	self = nil
end

return HelpDonnie
