local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryService = {}

local engine
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
		elseif topic == "smashReplicate" then
			InventoryService:smashReplicate(player, data)
		elseif topic == "finishRefining" then
			InventoryService:finishRefining(player)
		elseif topic == "sellLoot" then
			InventoryService:sellLoot(player, data)
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

	local equippedPickaxe = playerClass.profile.Data.equipped.pickaxe
	local pickaxeTool = storage.Tools.Pickaxes[equippedPickaxe]:Clone()
	pickaxeTool:SetAttribute("Type", "Pickaxe")
	pickaxeTool.Parent = player.Backpack

	-- LOOT!
	-- table.insert(playerData.inventory.loot, { name = loot.lootKey, trait = loot.trait, weight = loot.kg, id = id })
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

	local handle = storage.Loot[lootData.lootKey]:Clone()
	local tool = Instance.new("Tool")
	handle.Name = "Handle"
	handle.Size *= lootData.kg
	handle.Anchored = false
	handle.Parent = tool
	tool:SetAttribute("Type", "HoldLoot")
	tool.Grip *= CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	tool.Name = id
	tool.ToolTip = `{lootData.lootKey} ({math.floor(lootData.kg * 100) / 100} kg)`
	tool.Parent = playerClass.player.Backpack
end

function InventoryService:sellLoot(player, parameters)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)

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
		local lootDef = engine:get("Loot")[loot.name]
		-- @todo: traits
		if lootDef and not loot.locked then
			local sellPrice = lootDef.value_per_kg or 0
			totalEarned += sellPrice * loot.weight

			table.remove(playerData.inventory.loot, table.find(playerData.inventory.loot, loot))
			if player.Character and player.Character:FindFirstChild(loot.id) then
				player.Character[loot.id]:Destroy()
			elseif player.Backpack:FindFirstChild(loot.id) then
				player.Backpack[loot.id]:Destroy()
			end
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
	local playerData = PlayerService:GetData(player)
	local Kits = engine:get("Kits")
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

	return { now = inContainerNow, max = kitData and kitData.capacity or 0, quality = contentsQuality }
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

-----------------
-- kit methods --
-----------------

function InventoryService:equipRefiningKit(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)
	local Kits = engine:get("Kits")
	local LootRNG = engine:get("LootRNG")

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
	local rewards = LootRNG.RollFromEntries({
		entries = playerData.container,
		kit = kitData,
		pickaxes = engine:get("Pickaxes"),
		zones = engine:get("MineZones"),
		lootDefs = engine:get("Loot"),
		baseLuck = 1,
		opts = {
			rng = Random.new(), -- seed by player.UserId?
		},
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

	PlayerService:Get(player).localData.refineProgress = containerStatus.now

	local keyToId = {}
	for index, loot in pairs(rewards) do
		loot.kg = math.floor(loot.kg * 100) / 100 -- round to 2 decimal places
		local id = HttpService:GenerateGUID(false)
		keyToId[index] = id
		table.insert(playerData.inventory.loot, { name = loot.lootKey, trait = loot.trait, weight = loot.kg, id = id })
		if not playerData.statistics.found_loot[loot.lootKey] then
			-- player found this loot for first time
			playerData.statistics.found_loot[loot.lootKey] = { count = 1, largest = loot.kg }
		else
			playerData.statistics.found_loot[loot.lootKey].count += 1
			if loot.kg > playerData.statistics.found_loot[loot.lootKey].largest then
				-- player found their personal heaviest of this kind of loot
				playerData.statistics.found_loot[loot.lootKey].largest = loot.kg
			end
		end
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
		InventoryService:drawHoldLoot(PlayerService:Get(player), loot, loot.id)
	end
	engine.events.Inventory:FireClient(player, "readyToRefine", clientRewards)
	playerData.container = {}
end

function InventoryService:finishRefining(player)
	local PlayerService = engine:get("PlayerService")
	local Kits = engine:get("Kits")
	local playerData = PlayerService:GetData(player)

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

	local playerClass = PlayerService:Get(player)
	local playerData = playerClass.profile.Data
	local kitData = engine:get("Kits")[playerData.equipped.kit]

	playerClass.localData.refineProgress -= kitData.stats.malletStrength

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

---------------------
-- pickaxe methods --
---------------------
function InventoryService:strikePickaxe(player, score)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)
	local Pickaxes = engine:get("Pickaxes")
	local MineZones = engine:get("MineZones")

	local equippedPickaxe = playerData.equipped.pickaxe
	local pickaxeData = Pickaxes[equippedPickaxe].stats
	local refiningKitStatus = InventoryService:getContainerStatus(player)

	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }

	local zone
	local zoneCast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -10, 0), params)
	if zoneCast and zoneCast.Instance then
		zone = zoneCast.Instance.Parent.Name
	end

	if
		equippedPickaxe
		and refiningKitStatus.now < refiningKitStatus.max
		and zone
		and MineZones[zone]
		and MineZones[zone].minDensity <= pickaxeData.strength
	then
		local amount = math.min(pickaxeData.strength, refiningKitStatus.max - refiningKitStatus.now)
		table.insert(playerData.container, {
			pickaxe = equippedPickaxe,
			amount = amount,
			score = score,
			zone = zone,
		})

		engine.events.Inventory:FireClient(player, "kitUpdate", InventoryService:getContainerStatus(player))
	end
end

function InventoryService:equipPickaxe(player, pickaxeName)
	local PlayerService = engine:get("PlayerService")
	local Pickaxes = engine:get("Pickaxes")
	local playerData = PlayerService:GetData(player)

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
			InventoryService.draw(PlayerService:Get(player))
			pickaxe = findPickaxe()
		end
		holdPickaxe(pickaxe)
	end
end
function InventoryService:unequipPickaxe(player, pickaxeName)
	local PlayerService = engine:get("PlayerService")
	local Pickaxes = engine:get("Pickaxes")
	local playerData = PlayerService:GetData(player)

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
			InventoryService.draw(PlayerService:Get(player))
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
	local playerData = PlayerService:GetData(player)

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
		local lootModel = ReplicatedStorage.Storage.Loot[desiredLoot.name]:Clone()
		lootModel.Size *= desiredLoot.weight
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
	local playerData = PlayerService:GetData(player)

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

return InventoryService
