--[[
	CLASS: InventoryService.register(playerClass: PlayerClass) -> registers player to be managed by InventoryService
		PlayerClass is the class instance representing the player, from PlayerService.luau
	PURPOSE:
		Manage player inventories, including equipping tools, managing loot, and refining kits.
		Also in charge of placing physical objects in the world representing the player's inventory.
	
		Most usage from server-sent events to Inventory RemoteEvent.
		USAGE:
		```lua
		local InventoryService = require(engine:get("InventoryService"))
		InventoryService:register(playerClass)
		InventoryService:equipPickaxe(player, pickaxeName)
		```

]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryService = {}

local engine

function InventoryService:addLootEntry(player, lootKey, kg, trait, id)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	if not playerData then
		return nil
	end
	playerData.inventory = playerData.inventory or {}
	playerData.inventory.loot = playerData.inventory.loot or {}
	local entry = { lootKey = lootKey, kg = kg, trait = trait, id = id }
	table.insert(playerData.inventory.loot, entry)

	local foundLoot = playerData.statistics and playerData.statistics.found_loot
	if foundLoot and lootKey then
		if not foundLoot[lootKey] then
			foundLoot[lootKey] = { count = 1, largest = kg }
		else
			foundLoot[lootKey].count += 1
			if kg > foundLoot[lootKey].largest then
				foundLoot[lootKey].largest = kg
			end
		end
	end

	engine:get("QuestService").events.collectLoot:Fire(player, { lootKey = lootKey, kg = kg, trait = trait })
	return entry
end

function InventoryService:removeLootEntry(player, lootId, expectedLootKey)
	if typeof(lootId) == "table" then
		expectedLootKey = expectedLootKey or lootId.lootKey
		lootId = lootId.id
	end
	if typeof(lootId) ~= "string" then
		return nil
	end

	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	if not playerData or not playerData.inventory or not playerData.inventory.loot then
		return nil
	end

	local removed
	for index, loot in pairs(playerData.inventory.loot) do
		if loot.id == lootId then
			if expectedLootKey and loot.lootKey ~= expectedLootKey then
				return nil
			end
			removed = loot
			table.remove(playerData.inventory.loot, index)
			break
		end
	end

	if not removed then
		return nil
	end

	if player.Character and player.Character:FindFirstChild(lootId) then
		player.Character[lootId]:Destroy()
	elseif player.Backpack:FindFirstChild(lootId) then
		player.Backpack[lootId]:Destroy()
	end

	return removed
end

function InventoryService.init(engineModule)
	engine = engineModule

	-- register all players with their inventory, specifically to 'draw' their character from loadout
	local PlayerService = engine:get("PlayerService")
	PlayerService.PlayerAdded:Connect(function(playerClass)
		InventoryService.register(playerClass)
	end)
	for _, playerClass in ipairs(PlayerService.players) do
		InventoryService.register(playerClass)
	end

	-- weld all tools together
	for _, category in pairs(ReplicatedStorage.Storage.Tools:GetChildren()) do
		for _, tool in pairs(category:GetChildren()) do
			if tool:IsA("Model") then
				for _, part in pairs(tool:GetChildren()) do
					if
						part:IsA("BasePart")
						and not part:FindFirstChild("Weld")
						and part.Name ~= "Handle"
						and not part:GetAttribute("NoWeld")
					then
						local motor = Instance.new("WeldConstraint")
						motor.Name = "Weld"
						motor.Part0 = tool.Handle
						motor.Part1 = part
						motor.Parent = part
					end
				end
			end
		end
	end

	engine.events.Inventory.OnServerEvent:Connect(function(player, topic, data)
		if topic == "equipPickaxe" then
			InventoryService:equipPickaxe(player, data)
		elseif topic == "unequipPickaxe" then
			InventoryService:unequipPickaxe(player, data)
		elseif topic == "strikePickaxe" then
			InventoryService:strikePickaxe(player, data)
		elseif topic == "equipLoot" then
			InventoryService:equipLoot(player, data)
		elseif topic == "unequipLoot" then
			InventoryService:unequipLoot(player, data)
		elseif topic == "equipKit" then
			InventoryService:equipRefiningKit(player)
		elseif topic == "equipEquipment" then
			InventoryService:equipEquipment(player, data)
		elseif topic == "unequipEquipment" then
			InventoryService:unequipEquipment(player, data)
		elseif topic == "smashReplicate" then
			InventoryService:smashReplicate(player, data)
		elseif topic == "finishRefining" then
			InventoryService:finishRefining(player)
		elseif topic == "sellLoot" then
			InventoryService:sellLoot(player, data)
		elseif topic == "crackGeode" then
			InventoryService:crackGeode(player, data)
		elseif topic == "buyItem" then
			InventoryService:buyItem(player, data)
		elseif topic == "craftItem" then
			InventoryService:craftItem(player, data)
		end
	end)
end

function InventoryService.register(playerClass)
	local player = playerClass.player

	local function CharacterAdded(character)
		-- InventoryService.draw(playerClass)
		local Kits = engine:get("Kits")

		-- do not allow characters to collide with one another
		for _, basePart in pairs(character:GetDescendants()) do
			if basePart:IsA("BasePart") then
				basePart.CollisionGroup = "Character"
			end
		end
		character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "Character"
			end
		end)

		local equippedContainer = Kits[playerClass.profile.Data.equipped.kit].container
		local kitData = Kits[playerClass.profile.Data.equipped.kit]
		local containerModel = ReplicatedStorage.Storage.Tools.Containers[equippedContainer]:Clone()
		containerModel:PivotTo(character:GetPivot())
		containerModel.Handle.Motor6D.Part0 = character.Torso
		containerModel.Handle.Motor6D.C0 = kitData.containerPivotOffset
		containerModel.Parent = character

		local rubbleMotor = containerModel.Handle.RubbleMotor
		local fillMotor = containerModel.Handle.FillMotor
		local containerStatus = InventoryService:getContainerStatus(playerClass.player)
		local fillOffsets = kitData.containerFillOffsets
		local progressCF = fillOffsets.Min:Lerp(fillOffsets.Max, containerStatus.now / containerStatus.max)
		if containerStatus.now > 0 then
			rubbleMotor.C0 = progressCF
			fillMotor.C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset)
			containerModel.Rubble.Transparency = 0
			containerModel.FillPlane.Transparency = 0
		else
			containerModel.Rubble.Transparency = 1
			containerModel.FillPlane.Transparency = 1
		end

		character.Parent = workspace.Entities.Characters
	end

	local storage = ReplicatedStorage.Storage
	
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local drillTool = storage.Tools.Drills.Drill:Clone()
	drillTool.Name = playerData.drill.type
	drillTool.Parent = player.Backpack

	local equippedPickaxe = playerClass.profile.Data.equipped.pickaxe
	local pickaxeIndex = 1
	local pickaxeList = playerClass.profile.Data.inventory.pickaxes
	if typeof(pickaxeList) == "table" then
		local foundIndex = table.find(pickaxeList, equippedPickaxe)
		if foundIndex then
			pickaxeIndex = foundIndex
		end
	end
	local pickaxeTool = storage.Tools.Pickaxes[equippedPickaxe]:Clone()
	pickaxeTool:SetAttribute("Type", "Pickaxe")
	pickaxeTool:SetAttribute("BackpackIndex", pickaxeIndex)
	pickaxeTool.Parent = player.Backpack

	local persistentFolder = storage.Tools:FindFirstChild("Persistents")
	local vaultTool = persistentFolder and persistentFolder:FindFirstChild("vault")
	if vaultTool and vaultTool:IsA("Tool") then
		local vaultClone = vaultTool:Clone()
		vaultClone:SetAttribute("Type", "Vault")
		local index = vaultClone:GetAttribute("BackpackIndex")
		if typeof(index) ~= "number" or index <= 0 then
			vaultClone:SetAttribute("BackpackIndex", 2)
		end
		vaultClone.CanBeDropped = false
		vaultClone.Parent = player.Backpack
	else
		warn("[InventoryService] Vault tool missing or not a Tool.")
	end

	-- LOOT!
	-- InventoryService:addLootEntry(player, loot.lootKey, loot.kg, loot.trait, id)
	for _, loot in pairs(playerClass.profile.Data.inventory.loot) do
		InventoryService:drawHoldLoot(playerClass, loot, loot.id)
	end

	if player.Character and player.Character:IsDescendantOf(workspace) then
		CharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(CharacterAdded)
end

function InventoryService.draw(playerClass)
	local Pickaxes = engine:get("Pickaxes")
	local Kits = engine:get("Kits")
	local character = playerClass.player.Character

	if character:FindFirstChild("Items") then
		character.Items:ClearAllChildren()
	else
		local itemsFolder = Instance.new("Folder")
		itemsFolder.Name = "Items"
		itemsFolder.Parent = character
	end
	local itemsFolder = character.Items

	-- put pickaxe on player's back
	local equippedPickaxe = playerClass.profile.Data.equipped.pickaxe
	local pickaxeData = Pickaxes[equippedPickaxe]
	local pickaxeModel = ReplicatedStorage.Storage.Tools.Pickaxes[equippedPickaxe]:Clone()
	pickaxeModel:PivotTo(character:GetPivot())
	pickaxeModel.Handle.Motor6D.Part0 = character.Torso
	pickaxeModel.Handle.Motor6D.C0 = pickaxeData.backPivotOffset
	pickaxeModel.Parent = itemsFolder

	-- put container on player's back
	local equippedContainer = Kits[playerClass.profile.Data.equipped.kit].container
	local kitData = Kits[playerClass.profile.Data.equipped.kit]
	local containerModel = ReplicatedStorage.Storage.Tools.Containers[equippedContainer]:Clone()
	containerModel:PivotTo(character:GetPivot())
	containerModel.Handle.Motor6D.Part0 = character.Torso
	containerModel.Handle.Motor6D.C0 = kitData.containerPivotOffset
	containerModel.Parent = itemsFolder

	-- show container's fill
	local rubbleMotor = containerModel.Handle.RubbleMotor
	local fillMotor = containerModel.Handle.FillMotor
	local containerStatus = InventoryService:getContainerStatus(playerClass.player)
	local fillOffsets = kitData.containerFillOffsets
	local progressCF = fillOffsets.Min:Lerp(fillOffsets.Max, containerStatus.now / containerStatus.max)
	if containerStatus.now > 0 then
		rubbleMotor.C0 = progressCF
		fillMotor.C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset)
		containerModel.Rubble.Transparency = 0
		containerModel.FillPlane.Transparency = 0
	else
		containerModel.Rubble.Transparency = 1
		containerModel.FillPlane.Transparency = 1
	end
end

function InventoryService:drawHoldLoot(playerClass, lootData, id)
	local storage = ReplicatedStorage.Storage

	local truncatedWeight = math.floor(lootData.kg * 100) / 100

	local handle = storage.Loot[lootData.lootKey]:Clone()
	local tool = Instance.new("Tool")
	if handle:IsA("Model") then
		handle:ScaleTo(handle:GetScale() * lootData.kg)
		handle.PrimaryPart.Name = "Handle"
		for _, basePart in pairs(handle:GetDescendants()) do
			if basePart ~= handle.PrimaryPart and basePart:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle.PrimaryPart
				weld.Part1 = basePart
				weld.Parent = basePart
			end
			if basePart:IsA("BasePart") then
				basePart.Anchored = false
			end
		end
		handle.PrimaryPart.Parent = tool
	else
		handle.Name = "Handle"
		handle.Size *= lootData.kg
		handle.Anchored = false
	end

	handle.Parent = tool
	tool:SetAttribute("Type", "HoldLoot")
	tool:SetAttribute("LootKey", lootData.lootKey)
	tool:SetAttribute("Weight", truncatedWeight)
	tool:SetAttribute("Trait", lootData.trait or "none")
	tool.Grip *= CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	tool.Name = id
	tool.ToolTip = `{lootData.lootKey} ({truncatedWeight} kg)`
	tool.Parent = playerClass.player.Backpack
end

function InventoryService:sellLoot(player, parameters)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local totalEarned = 0
	local lootToSell = {}

	if parameters == "all" then
		lootToSell = table.clone(playerData.inventory.loot)
	else
		for _, loot in pairs(playerData.inventory.loot) do
			if table.find(parameters, loot.id) then
				table.insert(lootToSell, loot)
				break
			end
		end
	end

	for index, loot in pairs(lootToSell) do
		print(loot)
		local lootDef = engine:get("Loot")[loot.lootKey]
		-- @todo: traits
		if lootDef and not loot.locked and loot.lootKey ~= "geode" then
			local sellPrice = lootDef.value_per_kg or 0
			totalEarned += sellPrice * loot.kg

			InventoryService:removeLootEntry(player, loot.id)
		else
			table.remove(lootToSell, index) -- cannot sell locked or undefined loot
		end
	end

	playerData.coins += math.round(totalEarned) -- round to 2 decimal places
	engine.events.Inventory:FireClient(
		player,
		"sellComplete",
		{ earned = totalEarned, newBalance = playerData.coins, toRemove = lootToSell }
	)
end

function InventoryService:getContainerStatus(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local Kits = engine:get("Kits")
	local ModifierManager = engine:get("ModifierManager")
	local equippedKit = playerData.equipped.kit
	local kitData = Kits[equippedKit].stats

	local scoopData = playerData.container
	local inContainerNow = 0
	local contentsQuality = 0

	for _, scoop in pairs(scoopData) do
		inContainerNow += scoop.amount
		contentsQuality += scoop.score
	end
	-- quality determined by average scoop's mini game score
	contentsQuality = (contentsQuality == 0 and 0) or (math.floor((contentsQuality / #scoopData) * 100) / 100) * 100

	local capacity = kitData and kitData.capacity or 0
	if ModifierManager then
		local modifiedCapacity = ModifierManager:getKitStat(player, "capacity", equippedKit)
		if typeof(modifiedCapacity) == "number" then
			capacity = modifiedCapacity
		end
	end

	return { now = inContainerNow, max = capacity, quality = contentsQuality }
end

function InventoryService:spawnLootInTray(trayModel, rewards)
	local lootStorage = ReplicatedStorage.Storage.Loot

	local rng = Random.new()
	local traySize = trayModel:GetExtentsSize()
	local middlePos = trayModel.Handle.Middle.WorldPosition
	local lootFolder = Instance.new("Folder")
	lootFolder.Name = "Loot"
	lootFolder.Parent = trayModel

	for _, reward in pairs(rewards) do
		local lootObj = lootStorage[reward.lootKey]:Clone()
		local weld = Instance.new("WeldConstraint")
		lootObj.Size *= Vector3.new(reward.kg, reward.kg, reward.kg)
		local halfSize = lootObj.Size / 2
		lootObj.CollisionGroup = "TrayLoot"
		lootObj.Position = middlePos
			+ Vector3.new(
				rng:NextNumber(-traySize.X / 2 + halfSize.X, traySize.X / 2 - halfSize.X),
				rng:NextNumber(halfSize.Y, halfSize.Y * 2),
				rng:NextNumber(-traySize.Z / 2 + halfSize.Z, traySize.Z / 2 - halfSize.Z)
			)
		lootObj.Orientation = Vector3.new(rng:NextNumber(0, 360), rng:NextNumber(0, 360), rng:NextNumber(0, 360))
		lootObj.Parent = lootFolder
		lootObj.Anchored = false
		weld.Part1 = trayModel.Handle
		weld.Part0 = lootObj
		weld.Parent = lootObj
	end
end

--------------------
-- crafting method --
--------------------

function InventoryService:craftItem(player, data)
	if typeof(data) ~= "table" then
		return
	end

	local formulaId = data.formulaId
	local slots = data.slots
	if typeof(formulaId) ~= "string" or typeof(slots) ~= "table" then
		return
	end

	local CraftingFormulas = engine:get("CraftingFormulas")
	local Loot = engine:get("Loot")
	local LootTraits = engine:get("LootTraits")
	local PlayerService = engine:get("PlayerService")

	local formula = CraftingFormulas and CraftingFormulas[formulaId]
	if not formula then
		engine.events.Inventory:FireClient(player, "craftFailed", { message = "Invalid formula." })
		return
	end

	local playerData = PlayerService:getData(player)
	if not playerData then
		return
	end

	local inventoryLoot = playerData.inventory.loot
	local usedIds = {}
	local selected = {}
	local metalKey

	for _, slotIndex in ipairs(formula.gridSlots) do
		local lootId = slots[slotIndex] or slots[tostring(slotIndex)]
		if not lootId then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Missing ingredients." })
			return
		end

		if usedIds[lootId] then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Duplicate ingredients." })
			return
		end
		usedIds[lootId] = true

		local lootEntry
		for _, entry in pairs(inventoryLoot) do
			if entry.id == lootId then
				lootEntry = entry
				break
			end
		end
		if not lootEntry then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Ingredient missing." })
			return
		end

		local lootKey = lootEntry.lootKey
		local lootDef = lootKey and Loot and Loot[lootKey]
		if not lootDef or not lootDef.material_type then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Invalid ingredient." })
			return
		end

		local req = formula.requirements[slotIndex]
		if not req then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Invalid slot." })
			return
		end

		local material = lootDef.material_type
		local typeAllowed = false
		for _, t in pairs(req.types) do
			if t == material then
				typeAllowed = true
				break
			end
		end
		if not typeAllowed then
			engine.events.Inventory:FireClient(player, "craftFailed", { message = "Wrong ingredient type." })
			return
		end

		if material == "Metal" and formula.lockMetal then
			if not metalKey then
				metalKey = lootKey
			elseif metalKey ~= lootKey then
				engine.events.Inventory:FireClient(player, "craftFailed", { message = "All metals must match." })
				return
			end
		end

		selected[slotIndex] = {
			entry = lootEntry,
			lootKey = lootKey,
			material_type = material,
		}
	end

	local stats = { strength = 0, speed = 0, luck = 0 }
	for _, slotData in pairs(selected) do
		local lootDef = Loot[slotData.lootKey]
		if lootDef then
			stats.luck += lootDef.craft_luck or 0
			if lootDef.craft_modifiers then
				for stat, value in pairs(lootDef.craft_modifiers) do
					stats[stat] = (stats[stat] or 0) + value
				end
			end
		end
		local trait = slotData.entry.trait and LootTraits[slotData.entry.trait]
		if trait then
			stats.luck += trait.craft_luck or 0
			if trait.craft_modifiers then
				for stat, value in pairs(trait.craft_modifiers) do
					stats[stat] = (stats[stat] or 0) + value
				end
			end
		end
	end

	local components = {}
	local baseValue = 0
	local valueMultiplier = formula.value_multiplier or 1
	for _, slotData in pairs(selected) do
		local lootDef = Loot[slotData.lootKey]
		local weight = slotData.entry.kg or 0
		local value = 0
		if lootDef then
			value = (lootDef.value_per_kg or 0) * weight
		end
		local traitName = slotData.entry.trait
		local trait = traitName and LootTraits[traitName]
		if trait and trait.sell_multiplier then
			value *= trait.sell_multiplier
		end
		baseValue += value
		table.insert(components, {
			lootKey = slotData.lootKey,
			weight = weight,
			trait = traitName,
			material_type = slotData.material_type,
			value = value,
		})
	end
	local craftedValue = baseValue * valueMultiplier

	local removedIds = {}
	for lootId in pairs(usedIds) do
		if InventoryService:removeLootEntry(player, lootId) then
			table.insert(removedIds, lootId)
		end
	end

	local ringId = HttpService:GenerateGUID(false)
	local displayName = formula.output.displayName
	if metalKey and Loot[metalKey] then
		displayName = `{Loot[metalKey].name} {displayName}`
	end

	local ring = {
		id = ringId,
		name = formula.output.name,
		displayName = displayName,
		metal = metalKey,
		stats = stats,
		createdAt = os.time(),
		components = components,
		base_value = baseValue,
		value_multiplier = valueMultiplier,
		value = craftedValue,
	}

	for slotIndex, slotData in pairs(selected) do
		if slotData.material_type == "Gem" then
			ring.gem = slotData.lootKey
			ring.gemTrait = slotData.entry.trait
			ring.gemWeight = slotData.entry.kg or 0
			ring.gemSlot = slotIndex
			break
		end
	end

	playerData.inventory.equipment = playerData.inventory.equipment or {}
	table.insert(playerData.inventory.equipment, ring)

	PlayerService:get(player):updateClient({ "inventory" })

	engine.events.Inventory:FireClient(player, "craftComplete", {
		result = ring,
		removedIds = removedIds,
	})
	print("[Crafting] Player data snapshot:", playerData)
end

--------------------
-- shop buy method --
--------------------

function InventoryService:buyItem(player, data)
	if typeof(data) ~= "table" then
		return
	end

	local itemType = data.itemType
	local itemName = data.itemName
	if not itemType or not itemName then
		return
	end

	local typeKey = string.lower(itemType)
	if typeKey ~= "pickaxe" and typeKey ~= "kit" then
		engine.events.Inventory:FireClient(player, "buyFailed", { reason = "invalidItem" })
		return
	end

	local items = typeKey == "pickaxe" and engine:get("Pickaxes") or engine:get("Kits")
	local itemData = items[itemName]
	if not itemData then
		engine.events.Inventory:FireClient(player, "buyFailed", { reason = "invalidItem" })
		return
	end

	local PlayerService = engine:get("PlayerService")
	local playerClass = PlayerService:get(player)
	local playerData = playerClass.profile.Data

	if playerData.equipped[typeKey] == itemName then
		engine.events.Inventory:FireClient(player, "buyFailed", { reason = "alreadyEquipped" })
		return
	end

	local price = itemData.price or 0
	if playerData.coins < price then
		engine.events.Inventory:FireClient(player, "buyFailed", {
			reason = "insufficientFunds",
			price = price,
			balance = playerData.coins,
		})
		return
	end

	local oldItemName = playerData.equipped[typeKey]
	playerData.coins -= price

	playerData.inventory.oldEquipment = playerData.inventory.oldEquipment or { pickaxe = {}, kit = {}, equipment = {} }
	playerData.inventory.oldEquipment[typeKey] = playerData.inventory.oldEquipment[typeKey] or {}
	if oldItemName then
		table.insert(playerData.inventory.oldEquipment[typeKey], { name = oldItemName, replacedAt = os.time() })
	end

	local listKey = typeKey == "pickaxe" and "pickaxes" or typeKey == "kit" and "kit" or nil
	if listKey then
		playerData.inventory[listKey] = playerData.inventory[listKey] or {}
		local list = playerData.inventory[listKey]
		local replaced = false
		for i, name in ipairs(list) do
			if name == oldItemName then
				list[i] = itemName
				replaced = true
				break
			end
		end
		if not replaced then
			table.insert(list, itemName)
		end
	end

	playerData.equipped[typeKey] = itemName

	if typeKey == "pickaxe" then
		local oldTool
		local wasEquipped = false
		if oldItemName then
			oldTool = player.Backpack:FindFirstChild(oldItemName)
				or (player.Character and player.Character:FindFirstChild(oldItemName))
		end
		local oldIndex = oldTool and oldTool:GetAttribute("BackpackIndex")
		if oldTool then
			wasEquipped = oldTool.Parent == player.Character
			if wasEquipped then
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:UnequipTools()
				end
			end
			oldTool:Destroy()
		end

		if not oldIndex then
			oldIndex = listKey and table.find(playerData.inventory[listKey], itemName) or 1
		end

		local pickaxeTool = ReplicatedStorage.Storage.Tools.Pickaxes[itemName]:Clone()
		pickaxeTool:SetAttribute("Type", "Pickaxe")
		pickaxeTool:SetAttribute("BackpackIndex", oldIndex)
		pickaxeTool.Parent = player.Backpack

		if wasEquipped then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:EquipTool(pickaxeTool)
			end
		end
	elseif typeKey == "kit" then
		local character = player.Character
		local Kits = engine:get("Kits")
		if character and Kits[oldItemName] then
			local oldContainerName = Kits[oldItemName].container
			local oldContainer = character:FindFirstChild(oldContainerName)
			if oldContainer then
				oldContainer:Destroy()
			end
		end

		if character then
			local kitData = Kits[itemName]
			local containerModel = ReplicatedStorage.Storage.Tools.Containers[kitData.container]:Clone()
			containerModel:PivotTo(character:GetPivot())
			containerModel.Handle.Motor6D.Part0 = character.Torso
			containerModel.Handle.Motor6D.C0 = kitData.containerPivotOffset
			containerModel.Parent = character

			local rubbleMotor = containerModel.Handle.RubbleMotor
			local fillMotor = containerModel.Handle.FillMotor
			local containerStatus = InventoryService:getContainerStatus(player)
			local fillOffsets = kitData.containerFillOffsets
			local progressCF = fillOffsets.Min:Lerp(fillOffsets.Max, containerStatus.now / containerStatus.max)
			if containerStatus.now > 0 then
				rubbleMotor.C0 = progressCF
				fillMotor.C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset)
				containerModel.Rubble.Transparency = 0
				containerModel.FillPlane.Transparency = 0
			else
				containerModel.Rubble.Transparency = 1
				containerModel.FillPlane.Transparency = 1
			end
		end

		engine.events.Inventory:FireClient(player, "kitUpdate", InventoryService:getContainerStatus(player))
	end

	playerClass:updateClient({ "equipped", "inventory", "coins", "container" })

	engine.events.Inventory:FireClient(player, "buyComplete", {
		itemType = itemType,
		itemName = itemName,
		oldItemName = oldItemName,
		price = price,
		newBalance = playerData.coins,
	})
end

-----------------
-- kit methods --
-----------------

function InventoryService:equipRefiningKit(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local Kits = engine:get("Kits")
	local LootRNG = engine:get("LootRNG")
	local ModifierManager = engine:get("ModifierManager")
	local WorldEventService = engine:get("WorldEventService")

	local character = player.Character
	local equippedKit = playerData.equipped.kit
	local kitData = Kits[equippedKit]

	local equippedMallet = kitData.mallet
	local equippedTray = kitData.tray
	local equippedPickaxe = playerData.equipped.pickaxe

	for _, pickaxePart in pairs(character[equippedPickaxe]:GetChildren()) do
		if pickaxePart:IsA("BasePart") then
			pickaxePart:SetAttribute("Transparency", pickaxePart.Transparency)
			pickaxePart.Transparency = 1
		end
	end

	local malletModel = ReplicatedStorage.Storage.Tools.Mallets[equippedMallet]:Clone()
	malletModel.Handle.Motor6D.Part0 = character["Right Arm"]
	malletModel.Handle.Motor6D.C0 = kitData.malletHoldOffset
	malletModel.Name = `{equippedMallet}_Mallet`
	malletModel.Parent = character

	local trayModel = ReplicatedStorage.Storage.Tools.Trays[equippedTray]:Clone()
	trayModel.Handle.Motor6D.Part0 = character["Left Arm"]
	trayModel.Handle.Motor6D.C0 = kitData.trayHoldOffset
	trayModel.Name = `{equippedTray}_Tray`
	trayModel.Parent = character
	for _, basePart in pairs(trayModel:GetDescendants()) do
		if basePart:IsA("BasePart") then
			basePart.CollisionGroup = "Tray"
			basePart.CanCollide = true
		end
	end

	-- determine findings
	local kitStats = kitData.stats
	if ModifierManager then
		kitStats = ModifierManager:getKitStats(player, equippedKit) or kitData.stats
	end
	local kitForRng = kitData
	if kitStats ~= kitData.stats then
		kitForRng = table.clone(kitData)
		kitForRng.stats = kitStats
	end

	local baseLuck = ModifierManager and ModifierManager:getBaseLuck(player) or 1
	local zones = engine:get("MineZones")
	if WorldEventService then
		zones = WorldEventService:applyLootZones(zones)
	end
	local opts = {
		rng = Random.new(), -- seed by player.UserId?
		pickaxeLuck = ModifierManager
				and function(pickaxeName, pickaxeDefs)
					local def = pickaxeDefs and pickaxeDefs[pickaxeName]
					return def and def.stats and def.stats.luck or 1
				end
			or nil,
	}
	if WorldEventService then
		local eventOpts = WorldEventService:getLootRngOptions()
		if eventOpts then
			for key, value in pairs(eventOpts) do
				opts[key] = value
			end
		end
	end
	local rewards = LootRNG.RollFromEntries({
		entries = playerData.container,
		kit = kitForRng,
		pickaxes = engine:get("Pickaxes"),
		zones = zones,
		lootDefs = engine:get("Loot"),
		baseLuck = baseLuck,
		opts = opts,
	})

	local containerStatus = InventoryService:getContainerStatus(player)
	local lerpAlpha = 1 - math.clamp((containerStatus.now / containerStatus.max), 0, 1)
	trayModel.RefineEntities.FillPlane.Motor6D.C0 =
		kitData.rubbleMotorData.Max:Lerp(kitData.rubbleMotorData.Min, lerpAlpha)

	for _, rubblePart in pairs(trayModel.RefineEntities.Rubble:GetChildren()) do
		if rubblePart:IsA("BasePart") then
			rubblePart:SetAttribute("OriginalSize", rubblePart.Size)
		end
	end

	PlayerService:get(player).localData.refineProgress = containerStatus.now

	local keyToId = {}
	for index, loot in pairs(rewards) do
		loot.kg = math.floor(loot.kg * 100) / 100 -- round to 2 decimal places
		local id = HttpService:GenerateGUID(false)
		keyToId[index] = id
		InventoryService:addLootEntry(player, loot.lootKey, loot.kg, loot.trait, id)
	end

	InventoryService:spawnLootInTray(trayModel, rewards)

	local clientRewards = table.clone(rewards)
	for index, loot in pairs(clientRewards) do
		if loot.trait == "none" then
			loot.trait = nil
		end
		loot._meta = nil
		loot.id = keyToId[index]
	end

	for _, loot in pairs(clientRewards) do
		InventoryService:drawHoldLoot(PlayerService:get(player), loot, loot.id)
	end
	engine.events.Inventory:FireClient(player, "readyToRefine", clientRewards)
	playerData.container = {}
end

function InventoryService:finishRefining(player)
	local PlayerService = engine:get("PlayerService")
	local Kits = engine:get("Kits")
	local playerData = PlayerService:getData(player)

	local equippedPickaxe = playerData.equipped.pickaxe
	local equippedTray = Kits[playerData.equipped.kit].tray
	local equippedMallet = Kits[playerData.equipped.kit].mallet

	-- remove refining kit from character
	local character = player.Character
	if character then
		local refiningKit = character:FindFirstChild(`{equippedTray}_Tray`)
		if refiningKit then
			refiningKit:Destroy()
		end
		local mallet = character:FindFirstChild(`{equippedMallet}_Mallet`)
		if mallet then
			mallet:Destroy()
		end
	end

	for _, pickaxePart in pairs(character[equippedPickaxe]:GetChildren()) do
		local transparency = pickaxePart:GetAttribute("Transparency")
		if pickaxePart:IsA("BasePart") and transparency then
			pickaxePart.Transparency = transparency
		end
	end

	engine.events.Inventory:FireClient(player, "kitUpdate", InventoryService:getContainerStatus(player))
end

function InventoryService:smashReplicate(player, data)
	local PlayerService = engine:get("PlayerService")

	local playerClass = PlayerService:get(player)
	local playerData = playerClass.profile.Data
	local kitData = engine:get("Kits")[playerData.equipped.kit]
	local ModifierManager = engine:get("ModifierManager")

	local malletStrength = kitData.stats.malletStrength
	if ModifierManager then
		local modifiedStrength = ModifierManager:getKitStat(player, "malletStrength", playerData.equipped.kit)
		if typeof(modifiedStrength) == "number" then
			malletStrength = modifiedStrength
		end
	end
	playerClass.localData.refineProgress -= malletStrength

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player then
			engine.events.Inventory:FireClient(plr, "smashReplicate", {
				hostPlayerName = player.Name,
				equippedKit = playerData.equipped.kit,
				progress = playerClass.localData.refineProgress,
				targetRubble = data.targetRubble,
			})
		end
	end
end

-------------------------
-- equipment methods ----
-------------------------

local function findEquipmentEntry(playerData, itemId)
	local equipment = playerData.inventory and playerData.inventory.equipment or {}
	for _, item in ipairs(equipment) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

local function normalizeEquippedList(playerData)
	local equipped = playerData.equipped and playerData.equipped.equipment or {}
	local cleaned = {}
	for _, id in ipairs(equipped) do
		if findEquipmentEntry(playerData, id) then
			table.insert(cleaned, id)
		end
	end
	playerData.equipped = playerData.equipped or {}
	playerData.equipped.equipment = cleaned
	return cleaned
end

function InventoryService:equipEquipment(player, itemId)
	if typeof(itemId) == "table" then
		itemId = itemId.id or itemId.itemId
	end
	if typeof(itemId) ~= "string" then
		return
	end

	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	if not playerData then
		return
	end

	local item = findEquipmentEntry(playerData, itemId)
	if not item then
		return
	end

	local equipped = normalizeEquippedList(playerData)
	for _, id in ipairs(equipped) do
		if id == itemId then
			return
		end
	end

	local countsByType = {}
	for _, id in ipairs(equipped) do
		local entry = findEquipmentEntry(playerData, id)
		if entry and entry.name then
			countsByType[entry.name] = (countsByType[entry.name] or 0) + 1
		end
	end

	local CraftingFormulas = engine:get("CraftingFormulas")
	local formula = CraftingFormulas and CraftingFormulas[item.name]
	local maxEquipped = (formula and formula.max_equipped) or math.huge
	if countsByType[item.name] and countsByType[item.name] >= maxEquipped then
		return
	end

	table.insert(equipped, itemId)
	playerData.equipped.equipment = equipped

	PlayerService:get(player):updateClient({ "equipped" })

	-- TODO: attach equipment visuals to the character here.
end

function InventoryService:unequipEquipment(player, itemId)
	if typeof(itemId) == "table" then
		itemId = itemId.id or itemId.itemId
	end
	if typeof(itemId) ~= "string" then
		return
	end

	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	if not playerData then
		return
	end

	local equipped = normalizeEquippedList(playerData)
	for index, id in ipairs(equipped) do
		if id == itemId then
			table.remove(equipped, index)
			break
		end
	end
	playerData.equipped.equipment = equipped

	PlayerService:get(player):updateClient({ "equipped" })

	-- TODO: remove equipment visuals from the character here.
end

---------------------
-- pickaxe methods --
---------------------
function InventoryService:strikePickaxe(player, score)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local Pickaxes = engine:get("Pickaxes")
	local MineZones = engine:get("MineZones")
	local ModifierManager = engine:get("ModifierManager")

	local equippedPickaxe = playerData.equipped.pickaxe
	local pickaxeData = Pickaxes[equippedPickaxe].stats
	local refiningKitStatus = InventoryService:getContainerStatus(player)
	local pickaxeStrength = pickaxeData.strength
	if ModifierManager then
		local modifiedStrength = ModifierManager:getPickaxeStat(player, "strength", equippedPickaxe)
		if typeof(modifiedStrength) == "number" then
			pickaxeStrength = modifiedStrength
		end
	end

	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }

	local zone
	local zoneCast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -10, 0), params)
	if zoneCast and zoneCast.Instance then
		zone = zoneCast.Instance.Parent.Name
	end

	local lastStrike = PlayerService:get(player).localData.lastPickaxeStrike

	if
		equippedPickaxe
		and refiningKitStatus.now < refiningKitStatus.max
		and zone
		and MineZones[zone]
		and MineZones[zone].minDensity <= pickaxeStrength
		and tick() - lastStrike > 0.25
	then
		local amount = math.min(pickaxeStrength, refiningKitStatus.max - refiningKitStatus.now)
		table.insert(playerData.container, {
			pickaxe = equippedPickaxe,
			amount = amount,
			score = score,
			zone = zone,
		})

		PlayerService:get(player).localData.lastPickaxeStrike = tick()
		engine.events.Inventory:FireClient(player, "kitUpdate", InventoryService:getContainerStatus(player))
	end
end

function InventoryService:equipPickaxe(player, pickaxeName)
	local PlayerService = engine:get("PlayerService")
	local Pickaxes = engine:get("Pickaxes")
	local playerData = PlayerService:getData(player)

	local function findPickaxe()
		return player.Character and player.Character.Items:FindFirstChild(pickaxeName)
	end
	local function holdPickaxe(pickaxe)
		pickaxe.Handle.Motor6D.C0 = Pickaxes[pickaxeName].heldPivotOffset
		pickaxe.Handle.Motor6D.Part0 = player.Character["Right Arm"]
	end

	if playerData.equipped.pickaxe == pickaxeName then
		local pickaxe = findPickaxe()
		if not pickaxe then
			InventoryService.draw(PlayerService:get(player))
			pickaxe = findPickaxe()
		end
		holdPickaxe(pickaxe)
	end
end
function InventoryService:unequipPickaxe(player, pickaxeName)
	local PlayerService = engine:get("PlayerService")
	local Pickaxes = engine:get("Pickaxes")
	local playerData = PlayerService:getData(player)

	local function findPickaxe()
		return player.Character and player.Character.Items:FindFirstChild(pickaxeName)
	end
	local function stowPickaxe(pickaxe)
		pickaxe.Handle.Motor6D.C0 = Pickaxes[pickaxeName].backPivotOffset
		pickaxe.Handle.Motor6D.Part0 = player.Character.Torso
	end

	if playerData.equipped.pickaxe == pickaxeName then
		local pickaxe = findPickaxe()
		if not pickaxe then
			InventoryService.draw(PlayerService:get(player))
			pickaxe = findPickaxe()
		end
		stowPickaxe(pickaxe)
	end
end

-----------------------
-- loot hold methods --
-----------------------

function InventoryService:equipLoot(player, lootID)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local inventory = playerData.inventory
	local desiredLoot

	for _, loot in pairs(inventory.loot) do
		if loot.id == lootID then
			desiredLoot = loot
			break
		end
	end

	-- @todo: traits

	if desiredLoot then
		local lootModel = ReplicatedStorage.Storage.Loot[desiredLoot.lootKey]:Clone()
		lootModel.Size *= desiredLoot.kg
		local weld = Instance.new("Weld")
		weld.Parent = lootModel
		weld.Part0 = lootModel
		weld.Part1 = player.Character["Right Arm"]
		weld.C0 = CFrame.new(0, 1 + lootModel.Size.Y / 2, 0)
		lootModel.Anchored = false
		lootModel.Parent = player.Character
	end
end

function InventoryService:unequipLoot(player, lootID)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local inventory = playerData.inventory
	local desiredLoot

	for _, loot in pairs(inventory.loot) do
		if loot.id == lootID then
			desiredLoot = loot
			break
		end
	end

	if desiredLoot then
		if player.Character:FindFirstChild(desiredLoot.name) then
			player.Character[desiredLoot.name]:Destroy()
		end
	end
end

function InventoryService:crackGeode(player, geodeID)
	local PlayerService = engine:get("PlayerService")

	local oldData = InventoryService:removeLootEntry(player, geodeID, "geode")
	if not oldData then
		return
	end

	local crackedEntry = InventoryService:addLootEntry(player, "crackedGeode", oldData.kg, oldData.trait, geodeID)
	PlayerService:get(player):updateClient({ "inventory" })
	if crackedEntry then
		InventoryService:drawHoldLoot(PlayerService:get(player), crackedEntry, geodeID)
	end
end

return InventoryService
