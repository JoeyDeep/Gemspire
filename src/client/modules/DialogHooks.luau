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
		elseif hook.type == "delay" then
			task.wait(hook.duration or 1)
		end
	end
end

function DialogHooks:runFnc(fncName)
	local data = engine:get("PlayerService").Data
	if fncName == "sellAllLoot" then
		local lootToSell = data.inventory.loot
		local totalEarned = 0
		local itemsSold = 0
		for _, loot in pairs(lootToSell) do
			local lootDef = engine:get("Loot")[loot.lootKey]
			if loot.locked then
				continue
			end
			-- @todo: traits value multiplier
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
		local lootData
		for _, tool in pairs(data.inventory.loot) do
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
		local lootDef = engine:get("Loot")[lootData.lootKey]
		local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)
		engine.events.Inventory:FireServer("sellLoot", { heldLoot })

		return {
			`Pleasure doing business with you! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for your <font color="rgb(255, 255, 0)">{lootDef.name}</font>.`,
			`Beautiful <font color="rgb(255, 255, 0)">{lootDef.name}</font> you got there! Here's <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
		}
	elseif fncName == "appraiseThis" then
		local lootData
		for _, tool in pairs(data.inventory.loot) do
			if engine.player.Character and engine.player.Character:FindFirstChild(tool.id) then
				lootData = tool
				break
			end
		end
		local lootDef = engine:get("Loot")[lootData.lootKey]
		local sellPrice = math.round(lootDef.value_per_kg * lootData.kg)

		return {
			`That's a <font color="rgb(255, 255, 0)">{lootDef.name}</font>, looks to be about <font color="rgb(25, 255, 25)">{lootData.kg}kg</font>. I could give you <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
			`A fine specimen of <font color="rgb(255, 255, 0)">{lootDef.name}</font> you have there. It's about <font color="rgb(25, 255, 25)">{lootData.kg}kg</font>, I could give you <font color="rgb(25, 255, 25)">{sellPrice}</font> coins for it.`,
		}
	end

	return "Error: Unknown function " .. fncName
end

return DialogHooks
