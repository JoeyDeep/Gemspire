local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldEventService = {
	_active = {},
	_manualStops = {},
	_scheduleState = {},
}
WorldEventService.__index = WorldEventService

local engine

local LIGHTING_KEYS = {
	"Ambient",
	"Brightness",
	"ClockTime",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"FogColor",
	"FogEnd",
	"FogStart",
	"GeographicLatitude",
	"GlobalShadows",
	"OutdoorAmbient",
	"ShadowSoftness",
	"ExposureCompensation",
}

local function cloneLootTable(baseLoot)
	local copy = {}
	for key, value in pairs(baseLoot or {}) do
		copy[key] = value
	end
	return copy
end

function WorldEventService.init(engineModule)
	engine = engineModule

	local config = require(ReplicatedStorage.Shared.GameData.WorldEvents)
	WorldEventService._definitions = config.events or {}
	WorldEventService._schedule = config.schedule or {}

	WorldEventService:_snapshotLighting()
	WorldEventService:_startScheduler()
	WorldEventService:_broadcastState()
end

function WorldEventService:_snapshotLighting()
	self._baseLighting = {}
	for _, key in ipairs(LIGHTING_KEYS) do
		self._baseLighting[key] = Lighting[key]
	end
end

function WorldEventService:_restoreLighting()
	for key, value in pairs(self._baseLighting or {}) do
		Lighting[key] = value
	end
end

function WorldEventService:_applyLighting(lightingOverrides)
	if not lightingOverrides then
		self:_restoreLighting()
		return
	end
	for key, value in pairs(lightingOverrides) do
		Lighting[key] = value
	end
end

function WorldEventService:_applyEnvironment()
	local best
	for eventId, active in pairs(self._active) do
		local env = active.def and active.def.environment
		local lighting = env and env.lighting
		if lighting then
			local priority = env.priority or 0
			if
				not best
				or priority > best.priority
				or (priority == best.priority and active.startedAt > best.startedAt)
			then
				best = {
					eventId = eventId,
					priority = priority,
					startedAt = active.startedAt,
					lighting = lighting,
				}
			end
		end
	end

	if best and best.lighting then
		self:_applyLighting(best.lighting)
	else
		self:_restoreLighting()
	end
end

function WorldEventService:_broadcastState()
	local active = {}
	for eventId, info in pairs(self._active) do
		active[eventId] = {
			id = eventId,
			name = info.def and info.def.name or eventId,
			description = info.def and info.def.description or nil,
			startedAt = info.startedAt,
			endAt = info.endAt,
			modifiers = info.def and info.def.modifiers or nil,
		}
	end

	engine.events.WorldEvent:FireAllClients("update", {
		active = active,
		schedule = self._schedule,
		serverTime = os.time(),
	})
end

function WorldEventService:_startScheduler()
	task.spawn(function()
		while true do
			self:_tickSchedule()
			task.wait(1)
		end
	end)
end

function WorldEventService:_tickSchedule()
	local now = os.time()
	for index, entry in ipairs(self._schedule) do
		local def = self._definitions[entry.eventId]
		if not def then
			continue
		end

		local startAt = entry.startAt or 0
		local duration = entry.duration or def.duration or 0
		local endAt = (duration > 0) and (startAt + duration) or nil

		if endAt and now >= endAt and not self._scheduleState[index] then
			self._scheduleState[index] = { ended = true }
		end

		local suppressed = self._manualStops[entry.eventId]
		if suppressed and endAt and now < endAt then
			continue
		end

		local state = self._scheduleState[index]
		if not state and now >= startAt and (not endAt or now < endAt) then
			self._scheduleState[index] = { started = true }
			self:startEvent(entry.eventId, {
				source = "schedule",
				startedAt = startAt,
				duration = duration,
			})
		elseif state and state.started and not state.ended and endAt and now >= endAt then
			state.ended = true
			self:stopEvent(entry.eventId, "schedule")
		end
	end
end

function WorldEventService:startEvent(eventId, opts)
	local def = self._definitions[eventId]
	if not def then
		warn("[WorldEventService] Unknown event:", eventId)
		return false
	end
	if self._active[eventId] then
		return false
	end

	local now = os.time()
	local duration = (opts and opts.duration) or def.duration or 0
	local startedAt = (opts and opts.startedAt) or now
	local endAt = duration > 0 and (startedAt + duration) or nil

	self._active[eventId] = {
		def = def,
		startedAt = startedAt,
		endAt = endAt,
		source = opts and opts.source or "manual",
	}

	local ModifierManager = engine:get("ModifierManager")
	if ModifierManager and def.modifiers then
		ModifierManager:setGlobalStatModifiers(`event:{eventId}`, def.modifiers)
	end

	self:_applyEnvironment()
	self:_broadcastState()
	return true
end

function WorldEventService:stopEvent(eventId, reason)
	local active = self._active[eventId]
	if not active then
		return false
	end

	self._active[eventId] = nil
	if reason and reason ~= "schedule" then
		self._manualStops[eventId] = os.time()
	end

	local ModifierManager = engine:get("ModifierManager")
	if ModifierManager then
		ModifierManager:clearGlobalStatModifiers(`event:{eventId}`)
	end

	self:_applyEnvironment()
	self:_broadcastState()
	return true
end

function WorldEventService:getActiveEvents()
	return self._active
end

function WorldEventService:_collectLootModifiers()
	local merged = {
		zoneWeightMultipliers = {},
		zoneAdditions = {},
		traitWeightMultipliers = {},
		traitAdditions = {},
	}

	local function mergeScopedTable(target, source, isMultiplier)
		for scope, values in pairs(source or {}) do
			target[scope] = target[scope] or {}
			for key, value in pairs(values) do
				if isMultiplier then
					target[scope][key] = (target[scope][key] or 1) * value
				else
					target[scope][key] = (target[scope][key] or 0) + value
				end
			end
		end
	end

	for _, active in pairs(self._active) do
		local loot = active.def and active.def.loot
		if loot then
			mergeScopedTable(merged.zoneWeightMultipliers, loot.zoneWeightMultipliers, true)
			mergeScopedTable(merged.zoneAdditions, loot.zoneAdditions, false)
			mergeScopedTable(merged.traitWeightMultipliers, loot.traitWeightMultipliers, true)
			mergeScopedTable(merged.traitAdditions, loot.traitAdditions, false)
		end
	end

	return merged
end

function WorldEventService:applyLootZones(baseZones)
	local modifiers = self:_collectLootModifiers()
	local hasMods = next(modifiers.zoneWeightMultipliers) or next(modifiers.zoneAdditions)
	if not hasMods then
		return baseZones
	end

	local zonesCopy = {}
	for zoneName, zone in pairs(baseZones or {}) do
		local zoneCopy = table.clone(zone)
		local lootCopy = cloneLootTable(zone.loot)

		for _, scope in ipairs({ "*", zoneName }) do
			local multipliers = modifiers.zoneWeightMultipliers[scope]
			if multipliers then
				for lootKey, multiplier in pairs(multipliers) do
					lootCopy[lootKey] = (lootCopy[lootKey] or 0) * multiplier
				end
			end
			local additions = modifiers.zoneAdditions[scope]
			if additions then
				for lootKey, addition in pairs(additions) do
					lootCopy[lootKey] = (lootCopy[lootKey] or 0) + addition
				end
			end
		end

		zoneCopy.loot = lootCopy
		zonesCopy[zoneName] = zoneCopy
	end

	return zonesCopy
end

function WorldEventService:_applyTraitModifiers(weights, lootKey)
	local modifiers = self:_collectLootModifiers()
	local hasMods = next(modifiers.traitWeightMultipliers) or next(modifiers.traitAdditions)
	if not hasMods then
		return weights
	end

	local adjusted = table.clone(weights)
	for _, scope in ipairs({ "*", lootKey }) do
		local multipliers = modifiers.traitWeightMultipliers[scope]
		if multipliers then
			for trait, multiplier in pairs(multipliers) do
				if adjusted[trait] then
					adjusted[trait] = adjusted[trait] * multiplier
				end
			end
		end
		local additions = modifiers.traitAdditions[scope]
		if additions then
			for trait, addition in pairs(additions) do
				adjusted[trait] = (adjusted[trait] or 0) + addition
			end
		end
	end

	local total = 0
	for _, weight in pairs(adjusted) do
		total += weight
	end
	if total > 0 then
		for trait, weight in pairs(adjusted) do
			adjusted[trait] = weight / total
		end
	end

	return adjusted
end

function WorldEventService:getLootRngOptions()
	local modifiers = self:_collectLootModifiers()
	local hasTraitMods = next(modifiers.traitWeightMultipliers) or next(modifiers.traitAdditions)
	if not hasTraitMods then
		return nil
	end

	local LootRNG = engine:get("LootRNG")
	local Defaults = LootRNG and LootRNG.Defaults

	return {
		adjustTraitWeights = function(traitsTable, effLuck, entry, context, lootKey)
			local baseWeights = traitsTable
			if Defaults and Defaults.adjustTraitWeights then
				baseWeights = Defaults.adjustTraitWeights(traitsTable, effLuck, entry, context)
			end
			return WorldEventService:_applyTraitModifiers(baseWeights, lootKey)
		end,
	}
end

return WorldEventService
