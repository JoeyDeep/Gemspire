return function(engine, fncResponse, playerData)
	local heldLoot
	local lootData
	for _, tool in pairs(playerData.inventory.loot) do
		if engine.player.Character and engine.player.Character:FindFirstChild(tool.id) then
			heldLoot = tool.id
			lootData = tool
			break
		end
	end
	if not heldLoot then
		return fncResponse.null
	end
	if lootData.locked then
		return fncResponse.invalid
	end
	if lootData.lootKey == "geode" then
		return fncResponse.geode
	end 
	
	local lootDef = engine:get("Loot")[lootData.lootKey]
	local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)
	engine.events.Inventory:FireServer("sellLoot", { heldLoot })

	local success = fncResponse.success

	if typeof(success) == "table" then
		for index,value in ipairs(success) do
			value = value:gsub("($sellPrice)",sellPrice)
			value = value:gsub("($lootName)",lootDef.name)
			success[index] = value
		end
	else
		success = success:gsub("($sellPrice)",sellPrice)
		success = success:gsub("($lootName)",lootDef.name)
	end

	return success
end
