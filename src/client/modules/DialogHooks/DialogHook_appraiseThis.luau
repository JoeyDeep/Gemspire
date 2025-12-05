return function(engine, fncResponse, playerData)
	local lootData
	for _, tool in pairs(playerData.inventory.loot) do
		if engine.player.Character and engine.player.Character:FindFirstChild(tool.id) then
			lootData = tool
			break
		end
	end
	if not lootData then
		return fncResponse.null
	end
	if not lootData.lootKey then
		return fncResponse.invalid
	end
	local lootDef = engine:get("Loot")[lootData.lootKey]
	local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)

	local success = fncResponse.success

	if typeof(success) == "table" then
		for _,value in ipairs(success) do
			value:gsub("($lootName)",lootDef.name)
			value:gsub("($lootWeight)",lootDef.kg)
			value:gsub("($sellPrice)",sellPrice)
		end
	else
		success:gsub("($lootName)",lootDef.name)
		success:gsub("($lootWeight)",lootDef.kg)
		success:gsub("($sellPrice)",sellPrice)
	end

	

	return success
end
