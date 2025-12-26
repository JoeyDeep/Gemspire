return function(engine, fncResponse, playerData)
	local lootToSell = playerData.inventory.loot
	local totalEarned = 0
	local itemsSold = 0
	for _, loot in pairs(lootToSell) do
		local lootDef = engine:get("Loot")[loot.lootKey]
		if loot.locked then
			continue
		end
		-- @todo: traits value multiplier
		itemsSold += 1
		if lootDef and lootDef.name ~= "Geode" then
			local sellPrice = lootDef.value_per_kg or 0
			totalEarned += sellPrice * loot.kg
		end
	end

	if totalEarned == 0 then
		return fncResponse.invalid
	end
	engine.events.Inventory:FireServer("sellLoot", "all")

	local success = fncResponse.success

	if typeof(success) == "table" then
		for index,value in ipairs(success) do
			value = value:gsub("($itemsSold)",itemsSold)
			value = value:gsub("($totalEarned)",totalEarned)
			success[index] = value
		end
	else
		success = success:gsub("($itemsSold)",itemsSold)
		success = success:gsub("($totalEarned)",totalEarned)
	end

	return success
end
