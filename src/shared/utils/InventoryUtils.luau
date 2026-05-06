local InventoryUtils = {}

local function ensureTable(parent, key, defaultValue)
	if typeof(parent[key]) ~= "table" then
		parent[key] = defaultValue
	end
	return parent[key]
end

function InventoryUtils.normalizeLootEntry(entry)
	if typeof(entry) ~= "table" then
		return nil
	end

	local lootKey = entry.lootKey or entry.key or entry.name
	local kg = entry.kg or entry.weight

	if typeof(lootKey) ~= "string" then
		return nil
	end

	if typeof(kg) ~= "number" then
		kg = tonumber(kg)
	end
	if typeof(kg) ~= "number" then
		return nil
	end

	local normalized = {
		lootKey = lootKey,
		kg = kg,
		trait = entry.trait or entry.traits,
		id = entry.id,
	}

	if entry.locked ~= nil then
		normalized.locked = entry.locked
	end

	return normalized
end

function InventoryUtils.ensurePlayerDataShape(playerData)
	if typeof(playerData) ~= "table" then
		return playerData
	end

	local inventory = ensureTable(playerData, "inventory", {})
	ensureTable(inventory, "pickaxes", { "rusty" })
	ensureTable(inventory, "kit", { "basic" })
	ensureTable(inventory, "equipment", {})

	local oldEquipment = ensureTable(inventory, "oldEquipment", {})
	ensureTable(oldEquipment, "pickaxe", {})
	ensureTable(oldEquipment, "kit", {})
	ensureTable(oldEquipment, "equipment", {})

	local loot = ensureTable(inventory, "loot", {})
	local normalizedLoot = table.create(#loot)
	for _, entry in ipairs(loot) do
		local normalized = InventoryUtils.normalizeLootEntry(entry)
		if normalized then
			table.insert(normalizedLoot, normalized)
		end
	end
	inventory.loot = normalizedLoot

	local equipped = ensureTable(playerData, "equipped", {})
	if typeof(equipped.pickaxe) ~= "string" then
		equipped.pickaxe = "rusty"
	end
	if typeof(equipped.kit) ~= "string" then
		equipped.kit = "basic"
	end
	ensureTable(equipped, "equipment", {})

	local drill = ensureTable(playerData, "drill", {})
	if typeof(drill.type) ~= "string" then
		drill.type = "steel"
	end

	ensureTable(playerData, "container", {})
	ensureTable(playerData, "dialog_history", {})

	local quests = ensureTable(playerData, "quests", {})
	ensureTable(quests, "active", {})
	ensureTable(quests, "completed", {})

	local statistics = ensureTable(playerData, "statistics", {})
	ensureTable(statistics, "found_loot", {})

	return playerData
end

function InventoryUtils.getContainerStatus(playerData, kits, capacityOverride)
	local equippedKit = playerData and playerData.equipped and playerData.equipped.kit
	local kitData = equippedKit and kits and kits[equippedKit]
	local kitStats = kitData and kitData.stats or {}

	local scoopData = playerData and playerData.container or {}
	local inContainerNow = 0
	local contentsQuality = 0
	local scoopCount = 0

	for _, scoop in pairs(scoopData) do
		if typeof(scoop) == "table" then
			if typeof(scoop.amount) == "number" then
				inContainerNow += scoop.amount
			end
			if typeof(scoop.score) == "number" then
				contentsQuality += scoop.score
			end
			scoopCount += 1
		end
	end

	if contentsQuality ~= 0 and scoopCount > 0 then
		contentsQuality = (math.floor((contentsQuality / scoopCount) * 100) / 100) * 100
	else
		contentsQuality = 0
	end

	local capacity = kitStats.capacity or 0
	if typeof(capacityOverride) == "number" then
		capacity = capacityOverride
	end

	return {
		now = inContainerNow,
		max = capacity,
		quality = contentsQuality,
	}
end

return InventoryUtils
