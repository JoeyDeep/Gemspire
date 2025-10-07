local DialogHooks = {}

local engine
function DialogHooks.init(engineModule)
	engine = engineModule
end

function DialogHooks:runHooks(dialogClass, hookData)
	for _, hook in ipairs(hookData) do
		if hook.type == "close" then
			task.wait(1)
			dialogClass:endDialog()
		end
	end
end

function DialogHooks:runFnc(fncName)
	print(fncName)
	if fncName == "sellAllLoot" then
		local data = engine:get("PlayerService").Data
		local lootToSell = data.inventory.loot
		local totalEarned = 0
		local itemsSold = 0
		print(lootToSell)
		for _, loot in pairs(lootToSell) do
			local lootDef = engine:get("Loot")[loot.lootKey]
			if loot.locked then
				continue
			end
			-- @todo: traits
			itemsSold += 1
			if lootDef then
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
	elseif fncName == "sellThis" then
		local heldLoot
		for _, tool in pairs(engine:get("Tool").liveTools) do
			if tool.equipped and tool.type == "HoldLoot" then
				heldLoot = tool.data
				break
			end
		end
		if not heldLoot then
			return {
				`Looks like you forgot to hold something up for me to see.`,
				`I need to <i>actually see it</i> to be able to give you coin for it.`,
			}
		end

		local lootData
		for _, loot in pairs(engine:get("PlayerService").Data.inventory.loot) do
			if loot.id == heldLoot then
				lootData = loot
				break
			end
		end
		if lootData.locked then
			return {
				`Hmm, that one's locked. I can't buy locked items.`,
				`You need to unlock it first before I can buy it.`,
			}
		end
		local lootDef = engine:get("Loot")[lootData.lootKey]
		local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)
		engine.events.Inventory:FireServer("sellLoot", { heldLoot })

		return {
			`Pleasure doing business with you! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for your <font color="rgb(255, 255, 0)">{lootDef.name}</font>.`,
			`Beautiful <font color="rgb(255, 255, 0)">{lootDef.name}</font> you got there! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
		}
	end

	return "Error: Unknown function " .. fncName
end

return DialogHooks
