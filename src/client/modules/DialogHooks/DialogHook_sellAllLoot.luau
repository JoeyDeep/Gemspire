return function(engine, playerData)
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
		return {
			`Looks like you don't have any loot to sell.`,
			`Would you like to go out and find some more?`,
			`Come back when you have something to sell.`,
		}
	end
	engine.events.Inventory:FireServer("sellLoot", "all")
	return {
		`You sold <font color="rgb(25, 255, 25)">{itemsSold}</font> items for a total of <font color="rgb(25, 255, 25)">{totalEarned}</font> coins.</font>`,
		`I count <font color="rgb(25, 255, 25)">{itemsSold}</font> things, for <font color="rgb(25, 255, 25)">{totalEarned}</font> coins. Pleasure doing business with you!`,
	}
end
