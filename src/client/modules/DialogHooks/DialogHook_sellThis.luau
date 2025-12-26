return function(engine, playerData)
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
		return {
			`Looks like you forgot to hold something up for me to see.`,
			`I need to <i>actually see it</i> to be able to give you coin for it.`,
		}
	end
	if lootData.locked then
		return {
			`Hmm, that one's locked. I can't buy locked items.`,
			`You need to unlock it first before I can buy it.`,
		}
	end
	if lootData.lootKey == "geode" then
		return {
			`You'd be better off crackin' that sucker open instead.`,
			`Don't you want to know what's inside? Go crack it open!`,
		}
	end
	local lootDef = engine:get("Loot")[lootData.lootKey]
	print(lootData, lootDef)
	local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)
	engine.events.Inventory:FireServer("sellLoot", { heldLoot })

	return {
		`Pleasure doing business with you! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for your <font color="rgb(255, 255, 0)">{lootDef.name}</font>.`,
		`Beautiful <font color="rgb(255, 255, 0)">{lootDef.name}</font> you got there! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
	}
end
