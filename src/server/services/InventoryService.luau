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
					if part:IsA("BasePart") and not part:FindFirstChild("Motor6D") and part.Name ~= "Handle" then
						local motor = Instance.new("Motor6D")
						motor.Name = "Motor6D"
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
		end
	end)
end

function InventoryService.register(playerClass)
	local player = playerClass.player

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	-- draw the player's inventory on their character
	InventoryService.draw(playerClass)
	player.CharacterAdded:Connect(function(character)
		InventoryService.draw(playerClass)

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
	end)
end

function InventoryService.draw(playerClass)
	local Pickaxes = engine:get("Pickaxes")
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
end

function InventoryService:getSieveStatus(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)
	local Sieves = engine:get("Sieves")
	local equippedSieve = playerData.equipped.sieve
	local sieveData = Sieves[equippedSieve].stats

	local scoopData = playerData.sieve_contains
	local inSieveNow = 0
	local contentsQuality = 0

	for _, scoop in pairs(scoopData) do
		inSieveNow += scoop.amount
		contentsQuality += scoop.score
	end
	-- quality determined by average scoop's mini game score
	contentsQuality = (contentsQuality == 0 and 0) or (math.floor((contentsQuality / #scoopData) * 100) / 100) * 100

	return { now = inSieveNow, max = sieveData and sieveData.capacity or 0, quality = contentsQuality }
end

---------------------
-- pickaxe methods --
---------------------
function InventoryService:strikePickaxe(player, score)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:GetData(player)
	local Pickaxes = engine:get("Pickaxes")

	local equippedPickaxe = playerData.equipped.pickaxe
	local pickaxeData = Pickaxes[equippedPickaxe].stats
	local sieveStatus = InventoryService:getSieveStatus(player)

	if equippedPickaxe and sieveStatus.now < sieveStatus.max then
		local amount = math.min(pickaxeData.strength, sieveStatus.max - sieveStatus.now)
		table.insert(playerData.sieve_contains, {
			name = equippedPickaxe,
			amount = amount,
			score = score,
		})

		engine.events.Inventory:FireClient(player, "sieveUpdate", InventoryService:getSieveStatus(player))
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

return InventoryService
