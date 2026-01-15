--[[
CLASS: Vault.new(toolObj: Tool)

PURPOSE:
	Handle the Vault tool behavior. When equipped, play the hold animation and
	open the PlayerVault UI. Manages item selection, stat display, and equip/unequip.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingFormulas = require(ReplicatedStorage.Shared.GameData.CraftingFormulas)
local Loot = require(ReplicatedStorage.Shared.GameData.Items.Loot)
local LootTraits = require(ReplicatedStorage.Shared.GameData.LootTraits)
local StatVisuals = require(ReplicatedStorage.Shared.GameData.StatVisuals)

local Vault = {
	activeClass = nil,
}
Vault.__index = Vault

local engine

local STAT_ORDER = { "strength", "speed", "luck" }
local STAT_LABELS = {
	strength = "Strength",
	speed = "Speed",
	luck = "Luck",
}

function Vault.init(engineModule)
	engine = engineModule
end

function Vault.new(toolObj)
	local self = setmetatable({}, Vault)

	self.tool = toolObj
	self.equipped = false
	self.animations = {}

	self.selectedItemId = nil
	self.selectedItem = nil

	self:_initAnimations()
	self:_initUI()

	toolObj.Equipped:Connect(function()
		self:equip()
	end)
	toolObj.Unequipped:Connect(function()
		self:unequip()
	end)

	Vault.activeClass = self
	return self
end

function Vault:_initAnimations()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animFolder = ReplicatedStorage.Storage.Animations.Player:FindFirstChild("Vault")
	local holdAnim = animFolder and animFolder:FindFirstChild("Hold")
	if holdAnim then
		self.animations.Hold = animator:LoadAnimation(holdAnim)
	else
		warn("[Vault] Hold animation missing at ReplicatedStorage.Storage.Animations.Player.Vault.Hold")
	end
end

function Vault:_ensureAnimations()
	if not self.animations.Hold then
		self:_initAnimations()
	end
end

function Vault:_prepareTemplate(container)
	local template = container:FindFirstChild("Template")
	if not template then
		return nil
	end
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Template" and child ~= template then
			child:Destroy()
		end
	end
	template.Visible = false
	return template
end

function Vault:_ensureScale()
	if not self.ui then
		return nil
	end
	if not self.ui:FindFirstChild("UIScale") then
		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = self.ui
	end
	return self.ui.UIScale
end

function Vault:_initUI()
	if self.ui then
		return
	end

	local uiRoot = engine.PlayerGui:WaitForChild("UI")
	local ui = uiRoot:WaitForChild("PlayerVault")
	self.ui = ui
	self.ui.Visible = false

	self.statsFrame = ui:WaitForChild("Stats")
	self.statsTemplate = self.statsFrame:WaitForChild("StatTemplate")
	self.statsTemplate.Visible = false

	self.selectedItemLabel = ui:WaitForChild("SelectedItem")
	self.confirmButton = ui:WaitForChild("ConfirmEquip")
	self.confirmText = self.confirmButton:WaitForChild("ResponseText")

	self.inventoryFrame = ui:WaitForChild("Inventory")
	self.inventoryList = self.inventoryFrame:WaitForChild("ScrollingFrame")
	self.inventoryTemplate = self:_prepareTemplate(self.inventoryList)

	local outline = self.inventoryTemplate and self.inventoryTemplate:FindFirstChild("Outline")
	self.outlineDefaultColor = outline and outline.Color or Color3.fromRGB(204, 115, 63)
	self.outlineDefaultThickness = outline and outline.Thickness or 1.5
	self.outlineSelectedColor = Color3.fromRGB(255, 231, 94)
	self.outlineSelectedThickness = 2.5
	self.itemDefaultBackgroundColor = self.inventoryTemplate and self.inventoryTemplate.BackgroundColor3 or Color3.new(1, 1, 1)
	self.itemDefaultBackgroundTransparency = self.inventoryTemplate and self.inventoryTemplate.BackgroundTransparency or 0
	self.itemSelectedBackgroundColor = Color3.fromRGB(255, 231, 94)
	self.itemSelectedBackgroundTransparency = 0.2

	self.defaultConfirmTextColor = self.confirmText.TextColor3
	self.confirmStroke = self.confirmButton:FindFirstChild("UIStroke")
	self.defaultConfirmStrokeColor = self.confirmStroke and self.confirmStroke.Color or nil

	self.confirmButton.Activated:Connect(function()
		self:_handleConfirm()
	end)
end

function Vault:_openUI()
	if not self.ui then
		return
	end

	local QuickTween = engine:get("QuickTween")
	local Lighting = game:GetService("Lighting")
	local scale = self:_ensureScale()

	if not self._blur or not self._blur.Parent then
		self._blur = Instance.new("BlurEffect")
		self._blur.Size = 0
		self._blur.Parent = Lighting
	else
		self._blur.Size = 0
	end

	self.ui.Visible = false
	if scale then
		scale.Scale = 0.25
	end
	self.ui.Position = UDim2.fromScale(0.5, 0.8)
	self.ui.Visible = true

	if scale then
		QuickTween(scale, 0.15, { Scale = 1 })
	end
	QuickTween(self.ui, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
	QuickTween(self._blur, 0.2, { Size = 9 })
end

function Vault:_closeUI()
	if not self.ui then
		return
	end

	local QuickTween = engine:get("QuickTween")
	local scale = self.ui:FindFirstChild("UIScale")

	if scale then
		QuickTween(scale, 0.15, { Scale = 0.25 })
	end
	QuickTween(self.ui, 0.15, { Position = UDim2.fromScale(0.5, 0.8) }).Completed:Wait()
	self.ui.Visible = false

	if self._blur and self._blur.Parent then
		QuickTween(self._blur, 0.2, { Size = 0 }).Completed:Wait()
		self._blur:Destroy()
		self._blur = nil
	end
end

function Vault:_setEntrySelected(frame, selected)
	local outline = frame:FindFirstChild("Outline")
	if not outline then
		return
	end
	if selected then
		outline.Color = self.outlineSelectedColor
		outline.Thickness = self.outlineSelectedThickness
		frame.BackgroundColor3 = self.itemSelectedBackgroundColor
		frame.BackgroundTransparency = self.itemSelectedBackgroundTransparency
	else
		outline.Color = self.outlineDefaultColor
		outline.Thickness = self.outlineDefaultThickness
		frame.BackgroundColor3 = self.itemDefaultBackgroundColor
		frame.BackgroundTransparency = self.itemDefaultBackgroundTransparency
	end
end

function Vault:_findEquipmentById(itemId)
	local playerData = engine:get("PlayerService").data
	local equipment = playerData.inventory and playerData.inventory.equipment or {}
	for _, item in ipairs(equipment) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

function Vault:_isEquipped(item)
	local playerData = engine:get("PlayerService").data
	local equipped = playerData.equipped and playerData.equipped.equipment or {}
	for _, id in ipairs(equipped) do
		if id == item.id then
			return true
		end
	end
	return false
end

function Vault:_countEquippedByType(itemType)
	local playerData = engine:get("PlayerService").data
	local equipped = playerData.equipped and playerData.equipped.equipment or {}
	local count = 0
	for _, id in ipairs(equipped) do
		local entry = self:_findEquipmentById(id)
		if entry and entry.name == itemType then
			count += 1
		end
	end
	return count
end

function Vault:_getMaxEquipped(item)
	local formula = CraftingFormulas[item.name]
	return (formula and formula.max_equipped) or math.huge
end

function Vault:_getValueMultiplier(item)
	local formula = CraftingFormulas[item.name]
	return item.value_multiplier or (formula and formula.value_multiplier) or 1
end

function Vault:_getItemValue(item)
	if item.value then
		return item.value
	end

	local components = item.components
	if not components then
		return 0
	end

	local baseValue = 0
	for _, component in ipairs(components) do
		local value = component.value
		if value == nil then
			local lootDef = Loot[component.lootKey]
			local weight = component.weight or 0
			value = (lootDef and lootDef.value_per_kg or 0) * weight
			local trait = component.trait and LootTraits[component.trait]
			if trait and trait.sell_multiplier then
				value *= trait.sell_multiplier
			end
		end
		baseValue += value
	end

	return baseValue * self:_getValueMultiplier(item)
end

function Vault:_getItemColor(item)
	if item.gem and Loot[item.gem] and Loot[item.gem].color then
		return Loot[item.gem].color
	end
	if item.metal and Loot[item.metal] and Loot[item.metal].color then
		return Loot[item.metal].color
	end
	return nil
end

function Vault:_populateInventoryList()
	if not self.inventoryTemplate then
		return
	end

	for _, child in pairs(self.inventoryList:GetChildren()) do
		if child:IsA("Frame") and child ~= self.inventoryTemplate and child.Name ~= "NoItemsYet" then
			child:Destroy()
		end
	end

	local playerData = engine:get("PlayerService").data
	local equipment = playerData.inventory and playerData.inventory.equipment or {}
	local emptyState = self.inventoryList:FindFirstChild("NoItemsYet")
	if emptyState then
		emptyState.Visible = #equipment == 0
	end

	local items = {}
	for _, item in ipairs(equipment) do
		local value = self:_getItemValue(item)
		local equipped = self:_isEquipped(item)
		table.insert(items, { item = item, value = value, equipped = equipped })
	end

	table.sort(items, function(a, b)
		if a.equipped ~= b.equipped then
			return a.equipped
		end
		if a.value ~= b.value then
			return a.value > b.value
		end
		return (a.item.createdAt or 0) > (b.item.createdAt or 0)
	end)

	local selectedId = self.selectedItemId
	local selectionFound = false

	for index, entry in ipairs(items) do
		local item = entry.item
		local frame = self.inventoryTemplate:Clone()
		frame.Visible = true
		frame.Name = item.id or item.name or `Item{index}`
		frame.LayoutOrder = index

		local itemName = frame:FindFirstChild("ItemName")
		if itemName then
			itemName.Text = item.displayName or item.name or "Item"
		end

		local valueLabel = frame:FindFirstChild("Value")
		if valueLabel then
			valueLabel.Text = `Value: {math.floor(entry.value)}`
		end

		local icon = frame:FindFirstChild("TypeIcon")
		if icon then
			local formula = CraftingFormulas[item.name or ""]
			if formula and formula.icon then
				icon.Image = formula.icon
			end
			local color = self:_getItemColor(item)
			if color then
				icon.ImageColor3 = color
				icon.ImageTransparency = 0.2
			else
				icon.ImageColor3 = Color3.new(1, 1, 1)
				icon.ImageTransparency = 0
			end
		end

		local button = frame:FindFirstChild("Button")
		if button then
			button.Activated:Connect(function()
				self:_selectItem(item)
			end)
		end

		local isSelected = selectedId and item.id == selectedId
		if isSelected then
			selectionFound = true
			self.selectedItem = item
		end
		self:_setEntrySelected(frame, isSelected)

		frame.Parent = self.inventoryList
	end

	if selectedId and not selectionFound then
		self.selectedItemId = nil
		self.selectedItem = nil
	end
end

function Vault:_clearStats()
	for _, child in pairs(self.statsFrame:GetChildren()) do
		if child:IsA("TextLabel") and child.Name ~= self.statsTemplate.Name then
			child:Destroy()
		end
	end
end

function Vault:_renderStats(stats)
	self:_clearStats()
	for _, statKey in ipairs(STAT_ORDER) do
		local statValue = stats[statKey] or 0
		local statFrame = self.statsTemplate:Clone()
		statFrame.Visible = true
		statFrame.Name = statKey
		statFrame.Text = `{STAT_LABELS[statKey]}: {string.format("%+.2f", statValue * 100)}%`
		local statVisual = StatVisuals[statKey]
		if statVisual and statVisual.color then
			statFrame.TextColor3 = statVisual.color
		end
		statFrame.Parent = self.statsFrame
	end
end

function Vault:_setConfirmState(enabled, text)
	self.confirmButton.Active = enabled
	self.confirmButton.AutoButtonColor = enabled
	self.confirmText.Text = text

	if enabled then
		self.confirmText.TextColor3 = self.defaultConfirmTextColor
		if self.confirmStroke and self.defaultConfirmStrokeColor then
			self.confirmStroke.Color = self.defaultConfirmStrokeColor
		end
	else
		self.confirmText.TextColor3 = Color3.fromRGB(140, 140, 140)
		if self.confirmStroke then
			self.confirmStroke.Color = Color3.fromRGB(90, 90, 90)
		end
	end
end

function Vault:_updateConfirmState()
	if not self.selectedItem then
		self:_setConfirmState(false, "Equip")
		return
	end

	local equipped = self:_isEquipped(self.selectedItem)
	if equipped then
		self:_setConfirmState(true, "Unequip")
		return
	end

	local maxEquipped = self:_getMaxEquipped(self.selectedItem)
	local count = self:_countEquippedByType(self.selectedItem.name)
	if count >= maxEquipped then
		self:_setConfirmState(false, "Too many equipped")
		return
	end

	self:_setConfirmState(true, "Equip")
end

function Vault:_updateSelectionUI()
	if not self.selectedItem then
		self.selectedItemLabel.Text = "Select an item"
		self:_renderStats({})
		self:_updateConfirmState()
		return
	end

	self.selectedItemLabel.Text = self.selectedItem.displayName or self.selectedItem.name or "Item"
	self:_renderStats(self.selectedItem.stats or {})
	self:_updateConfirmState()
end

function Vault:_selectItem(item)
	self.selectedItemId = item.id
	self.selectedItem = item
	self:_populateInventoryList()
	self:_updateSelectionUI()
end

function Vault:_equipItem(item)
	local playerData = engine:get("PlayerService").data
	playerData.equipped = playerData.equipped or {}
	playerData.equipped.equipment = playerData.equipped.equipment or {}

	for _, id in ipairs(playerData.equipped.equipment) do
		if id == item.id then
			return
		end
	end

	table.insert(playerData.equipped.equipment, item.id)
	engine.events.Inventory:FireServer("equipEquipment", item.id)
end

function Vault:_unequipItem(item)
	local playerData = engine:get("PlayerService").data
	local equipped = playerData.equipped and playerData.equipped.equipment or {}
	for index, id in ipairs(equipped) do
		if id == item.id then
			table.remove(equipped, index)
			break
		end
	end
	playerData.equipped.equipment = equipped
	engine.events.Inventory:FireServer("unequipEquipment", item.id)
end

function Vault:_handleConfirm()
	if not self.selectedItem then
		return
	end

	local equipped = self:_isEquipped(self.selectedItem)
	if equipped then
		self:_unequipItem(self.selectedItem)
	else
		local maxEquipped = self:_getMaxEquipped(self.selectedItem)
		local count = self:_countEquippedByType(self.selectedItem.name)
		if count >= maxEquipped then
			self:_updateConfirmState()
			return
		end
		self:_equipItem(self.selectedItem)
	end

	self:_populateInventoryList()
	self:_updateSelectionUI()
end

function Vault:refresh()
	self:_initUI()
	self:_populateInventoryList()
	self:_updateSelectionUI()
end

function Vault:equip()
	self.equipped = true
	self:_ensureAnimations()
	self:_initUI()

	if self.animations.Hold then
		self.animations.Hold:Play(0.1)
	end

	self:refresh()
	self:_openUI()
end

function Vault:unequip()
	self.equipped = false
	if self.animations.Hold then
		self.animations.Hold:Stop(0.1)
	end
	self:_closeUI()
end

function Vault:destroy()
	for _, animation in pairs(self.animations) do
		animation:Stop()
		animation:Destroy()
	end
end

return Vault
