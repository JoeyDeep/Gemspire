return function(engine, playerData)
	local lootData
	for _, tool in pairs(playerData.inventory.loot) do
		if engine.player.Character and engine.player.Character:FindFirstChild(tool.id) then
			lootData = tool
			break
		end
	end
	if not lootData then
		return {
			`You need to hold up the item you want me to appraise.`,
			`I can't appraise something I can't see! Hold it up for me.`,
		}
	end
	if not lootData.lootKey then
		return {
			`This isn't something I'm willing to buy.`,
			`Quite a nice item, but I don't deal with these kinds of things.`,
		}
	end
	local lootDef = engine:get("Loot")[lootData.lootKey]
	local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)

	return {
		`That's a <font color="rgb(255, 255, 0)">{lootDef.name}</font>, looks to be about <font color="rgb(25, 255, 25)">{lootData.kg}kg</font>. I could give you <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
		`A fine specimen of <font color="rgb(255, 255, 0)">{lootDef.name}</font> you have there. It's about <font color="rgb(25, 255, 25)">{lootData.kg}kg</font>, I could give you <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
	}
end
