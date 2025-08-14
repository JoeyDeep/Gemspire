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
	player.CharacterAdded:Connect(function()
		InventoryService.draw(playerClass)
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
