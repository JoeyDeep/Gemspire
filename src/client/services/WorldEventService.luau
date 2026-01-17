local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldEventService = {
	active = {},
	schedule = {},
	serverTime = 0,
	_appliedModifiers = {},
}
WorldEventService.__index = WorldEventService

local engine

function WorldEventService.init(engineModule)
	engine = engineModule

	local config = require(ReplicatedStorage.Shared.GameData.WorldEvents)
	WorldEventService.schedule = config.schedule or {}

	local remote = ReplicatedStorage.Events:WaitForChild("WorldEvent")
	remote.OnClientEvent:Connect(function(topic, payload)
		if topic ~= "update" or typeof(payload) ~= "table" then
			return
		end
		WorldEventService.active = payload.active or {}
		WorldEventService.schedule = payload.schedule or WorldEventService.schedule
		WorldEventService.serverTime = payload.serverTime or os.time()
		WorldEventService:_applyModifiers()
	end)
end

function WorldEventService:_applyModifiers()
	local ModifierManager = engine and engine:get("ModifierManager")
	if not ModifierManager then
		return
	end

	for sourceId in pairs(self._appliedModifiers) do
		ModifierManager:clearGlobalStatModifiers(sourceId)
	end
	self._appliedModifiers = {}

	for eventId, info in pairs(self.active) do
		if info.modifiers then
			local sourceId = `event:{eventId}`
			ModifierManager:setGlobalStatModifiers(sourceId, info.modifiers)
			self._appliedModifiers[sourceId] = true
		end
	end
end

function WorldEventService:getActiveEvents()
	return self.active
end

function WorldEventService:getSchedule()
	return self.schedule
end

function WorldEventService:getServerTime()
	return self.serverTime
end

return WorldEventService
