local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterEquipmentService = {}

local engine

local function getOrCreateItemsFolder(character)
	local itemsFolder = character:FindFirstChild("Items")
	if not itemsFolder then
		itemsFolder = Instance.new("Folder")
		itemsFolder.Name = "Items"
		itemsFolder.Parent = character
	end
	return itemsFolder
end

local function removeModelsByLookup(parent, lookup)
	if not parent or not lookup then
		return
	end

	for _, child in ipairs(parent:GetChildren()) do
		if lookup[child.Name] then
			child:Destroy()
		end
	end
end

local function getKitContainerLookup(kits)
	local lookup = {}
	for _, kitData in pairs(kits or {}) do
		if kitData.container then
			lookup[kitData.container] = true
		end
	end
	return lookup
end

local function setCharacterCollision(character)
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
end

local function setContainerFill(containerModel, kitData, containerStatus)
	local fillOffsets = kitData.containerFillOffsets
	if not fillOffsets then
		return
	end

	local rubbleMotor = containerModel.Handle:FindFirstChild("RubbleMotor")
	local fillMotor = containerModel.Handle:FindFirstChild("FillMotor")
	if not rubbleMotor or not fillMotor then
		return
	end

	local max = containerStatus.max or 0
	local alpha = max > 0 and math.clamp((containerStatus.now or 0) / max, 0, 1) or 0
	local progressCF = fillOffsets.Min:Lerp(fillOffsets.Max, alpha)
	if (containerStatus.now or 0) > 0 then
		rubbleMotor.C0 = progressCF
		fillMotor.C0 = progressCF:ToWorldSpace(fillOffsets.RubbleOffset)
		containerModel.Rubble.Transparency = 0
		containerModel.FillPlane.Transparency = 0
	else
		containerModel.Rubble.Transparency = 1
		containerModel.FillPlane.Transparency = 1
	end
end

function CharacterEquipmentService.init(engineModule)
	engine = engineModule
end

function CharacterEquipmentService:setupCharacter(playerClass, character, containerStatus)
	if not playerClass or not character then
		return
	end

	setCharacterCollision(character)
	self:attachContainer(playerClass, containerStatus)
	self:showStowedPickaxe(playerClass)

	local characterFolder = workspace:FindFirstChild("Entities") and workspace.Entities:FindFirstChild("Characters")
	if characterFolder then
		character.Parent = characterFolder
	end
end

function CharacterEquipmentService:attachContainer(playerClass, containerStatus)
	local character = playerClass and playerClass.player.Character
	local playerData = playerClass and playerClass.profile and playerClass.profile.Data
	if not character or not playerData or not playerData.equipped then
		return
	end

	local kits = engine:get("Kits")
	local equippedKit = playerData.equipped.kit
	local kitData = kits and kits[equippedKit]
	if not kitData then
		return
	end

	removeModelsByLookup(character, getKitContainerLookup(kits))

	local containerTemplate = ReplicatedStorage.Storage.Tools.Containers:FindFirstChild(kitData.container)
	local torso = character:FindFirstChild("Torso")
	if not containerTemplate or not torso then
		return
	end

	local containerModel = containerTemplate:Clone()
	containerModel:PivotTo(character:GetPivot())
	containerModel.Handle.Motor6D.Part0 = torso
	containerModel.Handle.Motor6D.C0 = kitData.containerPivotOffset
	containerModel.Parent = character

	setContainerFill(containerModel, kitData, containerStatus or { now = 0, max = 0 })
end

function CharacterEquipmentService:showStowedPickaxe(playerClass)
	local character = playerClass and playerClass.player.Character
	local playerData = playerClass and playerClass.profile and playerClass.profile.Data
	if not character or not playerData or not playerData.equipped then
		return
	end

	local pickaxes = engine:get("Pickaxes")
	local equippedPickaxe = playerData.equipped.pickaxe
	local pickaxeData = pickaxes and pickaxes[equippedPickaxe]
	local pickaxeTemplate = ReplicatedStorage.Storage.Tools.Pickaxes:FindFirstChild(equippedPickaxe)
	if not pickaxeData or not pickaxeTemplate then
		return
	end

	local itemsFolder = getOrCreateItemsFolder(character)
	removeModelsByLookup(itemsFolder, pickaxes)

	local pickaxeModel = pickaxeTemplate:Clone()
	local handle = pickaxeModel:FindFirstChild("Handle")
	local motor = handle and handle:FindFirstChild("Motor6D")
	local torso = character:FindFirstChild("Torso")
	if not handle or not motor or not torso then
		pickaxeModel:Destroy()
		return
	end

	pickaxeModel:PivotTo(character:GetPivot())
	motor.Part0 = torso
	motor.C0 = pickaxeData.backPivotOffset
	pickaxeModel.Parent = itemsFolder
end

function CharacterEquipmentService:hideStowedPickaxe(player, pickaxeName)
	local character = player and player.Character
	local itemsFolder = character and character:FindFirstChild("Items")
	if not itemsFolder then
		return
	end

	local pickaxes = engine:get("Pickaxes")
	removeModelsByLookup(itemsFolder, pickaxeName and { [pickaxeName] = true } or pickaxes)
end

function CharacterEquipmentService:setupRefiningKit(player, playerData)
	local character = player and player.Character
	if not character or not playerData or not playerData.equipped then
		return nil, nil
	end

	local kits = engine:get("Kits")
	local equippedKit = playerData.equipped.kit
	local kitData = kits and kits[equippedKit]
	if not kitData then
		return nil, nil
	end

	local malletTemplate = ReplicatedStorage.Storage.Tools.Mallets:FindFirstChild(kitData.mallet)
	local trayTemplate = ReplicatedStorage.Storage.Tools.Trays:FindFirstChild(kitData.tray)
	local rightArm = character:FindFirstChild("Right Arm")
	local leftArm = character:FindFirstChild("Left Arm")
	if not malletTemplate or not trayTemplate or not rightArm or not leftArm then
		return nil, kitData
	end

	local equippedPickaxe = playerData.equipped.pickaxe
	local pickaxeModel = equippedPickaxe and character:FindFirstChild(equippedPickaxe)
	if pickaxeModel then
		for _, pickaxePart in pairs(pickaxeModel:GetChildren()) do
			if pickaxePart:IsA("BasePart") then
				pickaxePart:SetAttribute("Transparency", pickaxePart.Transparency)
				pickaxePart.Transparency = 1
			end
		end
	end

	local malletModel = malletTemplate:Clone()
	malletModel.Handle.Motor6D.Part0 = rightArm
	malletModel.Handle.Motor6D.C0 = kitData.malletHoldOffset
	malletModel.Name = `{kitData.mallet}_Mallet`
	malletModel.Parent = character

	local trayModel = trayTemplate:Clone()
	trayModel.Handle.Motor6D.Part0 = leftArm
	trayModel.Handle.Motor6D.C0 = kitData.trayHoldOffset
	trayModel.Name = `{kitData.tray}_Tray`
	trayModel.Parent = character
	for _, basePart in pairs(trayModel:GetDescendants()) do
		if basePart:IsA("BasePart") then
			basePart.CollisionGroup = "Tray"
			basePart.CanCollide = true
		end
	end

	return trayModel, kitData
end

function CharacterEquipmentService:finishRefining(player, playerData)
	local character = player and player.Character
	if not character or not playerData or not playerData.equipped then
		return
	end

	local kits = engine:get("Kits")
	local kitData = kits and kits[playerData.equipped.kit]
	if kitData then
		local tray = character:FindFirstChild(`{kitData.tray}_Tray`)
		if tray then
			tray:Destroy()
		end

		local mallet = character:FindFirstChild(`{kitData.mallet}_Mallet`)
		if mallet then
			mallet:Destroy()
		end
	end

	local pickaxeModel = playerData.equipped.pickaxe and character:FindFirstChild(playerData.equipped.pickaxe)
	if not pickaxeModel then
		return
	end

	for _, pickaxePart in pairs(pickaxeModel:GetChildren()) do
		local transparency = pickaxePart:GetAttribute("Transparency")
		if pickaxePart:IsA("BasePart") and transparency ~= nil then
			pickaxePart.Transparency = transparency
		end
	end
end

return CharacterEquipmentService
