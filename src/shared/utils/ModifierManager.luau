local ModifierManager = {}

local engine
local globalModifiers = {}

function ModifierManager.init(engineModule)
	engine = engineModule
end

local function getPlayerData(player)
	local PlayerService = engine and engine:get("PlayerService")
	if not PlayerService then
		return nil
	end
	if PlayerService.getData and player then
		return PlayerService:getData(player)
	end
	return PlayerService.data
end

local function getEquippedEquipment(playerData)
	if not playerData then
		return {}
	end

	local equipment = playerData.inventory and playerData.inventory.equipment or {}
	local equippedIds = playerData.equipped and playerData.equipped.equipment or {}
	if #equippedIds == 0 or #equipment == 0 then
		return {}
	end

	local byId = {}
	for _, item in ipairs(equipment) do
		if item.id then
			byId[item.id] = item
		end
	end

	local equippedItems = {}
	for _, id in ipairs(equippedIds) do
		local item = byId[id]
		if item then
			table.insert(equippedItems, item)
		end
	end

	return equippedItems
end

function ModifierManager:accumulateStatModifiers(playerData)
	local totals = {}
	for _, item in ipairs(getEquippedEquipment(playerData)) do
		if typeof(item.stats) == "table" then
			for stat, value in pairs(item.stats) do
				if typeof(value) == "number" then
					totals[stat] = (totals[stat] or 0) + value
				end
			end
		end
	end
	for _, modifiers in pairs(globalModifiers) do
		if typeof(modifiers) == "table" then
			for stat, value in pairs(modifiers) do
				if typeof(value) == "number" then
					totals[stat] = (totals[stat] or 0) + value
				end
			end
		end
	end
	return totals
end

local function applyPercentModifier(value, percent)
	if percent == 0 or percent == nil then
		return value
	end
	if typeof(value) == "number" then
		return value * (1 + percent)
	end
	if typeof(value) == "table" then
		local out = table.clone(value)
		if typeof(out.min) == "number" then
			out.min = out.min * (1 + percent)
		end
		if typeof(out.max) == "number" then
			out.max = out.max * (1 + percent)
		end
		return out
	end
	return value
end

function ModifierManager:getPickaxeStat(player, stat, pickaxeName)
	local playerData = getPlayerData(player)
	if not playerData then
		return nil
	end

	local pickaxe = pickaxeName or (playerData.equipped and playerData.equipped.pickaxe)
	if not pickaxe then
		return nil
	end

	local pickaxes = engine and engine:get("Pickaxes")
	local pickaxeData = pickaxes and pickaxes[pickaxe]
	local baseStats = pickaxeData and pickaxeData.stats
	local baseValue = baseStats and baseStats[stat]
	if baseValue == nil then
		return nil
	end

	local modifiers = ModifierManager:accumulateStatModifiers(playerData)
	return applyPercentModifier(baseValue, modifiers[stat] or 0)
end

function ModifierManager:getPickaxeStats(player, pickaxeName)
	local playerData = getPlayerData(player)
	if not playerData then
		return nil
	end

	local pickaxe = pickaxeName or (playerData.equipped and playerData.equipped.pickaxe)
	if not pickaxe then
		return nil
	end

	local pickaxes = engine and engine:get("Pickaxes")
	local pickaxeData = pickaxes and pickaxes[pickaxe]
	if not pickaxeData or not pickaxeData.stats then
		return nil
	end

	local modifiers = ModifierManager:accumulateStatModifiers(playerData)
	local combined = {}
	for stat, value in pairs(pickaxeData.stats) do
		combined[stat] = applyPercentModifier(value, modifiers[stat] or 0)
	end

	return combined
end

function ModifierManager:getKitStat(player, stat, kitName)
	local playerData = getPlayerData(player)
	if not playerData then
		return nil
	end

	local kit = kitName or (playerData.equipped and playerData.equipped.kit)
	if not kit then
		return nil
	end

	local kits = engine and engine:get("Kits")
	local kitData = kits and kits[kit]
	local baseStats = kitData and kitData.stats
	local baseValue = baseStats and baseStats[stat]
	if baseValue == nil then
		return nil
	end

	local modifiers = ModifierManager:accumulateStatModifiers(playerData)
	return applyPercentModifier(baseValue, modifiers[stat] or 0)
end

function ModifierManager:getKitStats(player, kitName)
	local playerData = getPlayerData(player)
	if not playerData then
		return nil
	end

	local kit = kitName or (playerData.equipped and playerData.equipped.kit)
	if not kit then
		return nil
	end

	local kits = engine and engine:get("Kits")
	local kitData = kits and kits[kit]
	if not kitData or not kitData.stats then
		return nil
	end

	local modifiers = ModifierManager:accumulateStatModifiers(playerData)
	local combined = {}
	for stat, value in pairs(kitData.stats) do
		combined[stat] = applyPercentModifier(value, modifiers[stat] or 0)
	end

	return combined
end

function ModifierManager:getBaseLuck(player)
	local playerData = getPlayerData(player)
	if not playerData then
		return 1
	end

	local modifiers = ModifierManager:accumulateStatModifiers(playerData)
	local luck = modifiers.luck
	if typeof(luck) ~= "number" then
		luck = 0
	end
	return math.max(0, 1 + luck)
end

function ModifierManager:setGlobalStatModifiers(sourceId, modifiers)
	if not sourceId then
		return
	end
	if modifiers == nil then
		globalModifiers[sourceId] = nil
		return
	end
	globalModifiers[sourceId] = modifiers
end

function ModifierManager:clearGlobalStatModifiers(sourceId)
	if not sourceId then
		return
	end
	globalModifiers[sourceId] = nil
end

return ModifierManager
