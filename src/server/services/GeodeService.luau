local GeodeService = {}
local engine

function GeodeService.init(engineModule)
	engine = engineModule
	engine.events.Inventory.OnServerEvent:Connect(function(player, topic)
		if topic == "crackAllGeodes" then
			GeodeService:crackAllGeodes(player)
		end
	end)
end

function GeodeService:crackAllGeodes(player)
	local PlayerService    = engine:get("PlayerService")
	local InventoryService = engine:get("InventoryService")
	local RngEvaluator     = engine:get("RngEvaluator")
	local GeodeContents    = engine:get("GeodeContents")
	local LootTraits       = engine:get("LootTraits")
	local Loot             = engine:get("Loot")

	local playerClass = PlayerService:get(player)
	if not playerClass then return end

	-- Snapshot before mutating
	local geodes = {}
	for _, loot in ipairs(playerClass.profile.Data.inventory.loot) do
		if loot.lootKey == "geode" then
			table.insert(geodes, { id = loot.id, kg = loot.kg, trait = loot.trait or "none" })
		end
	end
	if #geodes == 0 then return end

	-- Build flat weights table for RngEvaluator
	local weights = {}
	for key, data in pairs(GeodeContents) do
		weights[key] = data.weight
	end
	local evaluator = RngEvaluator.new(weights, {})

	local results = {}
	for _, g in ipairs(geodes) do
		local contentKey = evaluator:weightedPick(weights)

		InventoryService:removeLootEntry(player, g.id, "geode")
		local crackedEntry = InventoryService:addLootEntry(player, "crackedGeode", g.kg, g.trait, g.id)
		if crackedEntry then
			crackedEntry.contentKey = contentKey
		end

		InventoryService:drawHoldLoot(playerClass, crackedEntry, g.id)

		local traitPrefix = (g.trait ~= "none" and LootTraits[g.trait])
			and (LootTraits[g.trait].name .. " ")
			or ""
		local contentName = (Loot[contentKey] and Loot[contentKey].name) or contentKey

		table.insert(results, {
			id          = g.id,
			kg          = g.kg,
			trait       = g.trait,
			contentKey  = contentKey,
			displayName = traitPrefix .. contentName .. " Geode",
			color       = (Loot[contentKey] and Loot[contentKey].color) or Color3.fromRGB(228, 228, 228),
			image       = GeodeContents[contentKey] and GeodeContents[contentKey].image or "",
		})
	end

	PlayerService:get(player):updateClient({ "inventory" })
	engine.events.Inventory:FireClient(player, "geodesOpened", results)
end

return GeodeService
