local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local CraftingFormulas = require(ReplicatedStorage.Shared.GameData.CraftingFormulas)
local Loot = require(ReplicatedStorage.Shared.GameData.Items.Loot)
local LootTraits = require(ReplicatedStorage.Shared.GameData.LootTraits)
local StatVisuals = require(ReplicatedStorage.Shared.GameData.StatVisuals)

local CraftingTable = {
	_tables = {},
}
CraftingTable.__index = CraftingTable

local engine

local STAT_ORDER = { "strength", "speed", "luck" }
local STAT_LABELS = {
	strength = "Strength",
	speed = "Speed",
	luck = "Luck",
}
local WALK_AWAY_DISTANCE = 20

function CraftingTable.init(engineModule)
	engine = engineModule
	engine:await("PromptService")

	local tablesFolder = workspace.Entities:WaitForChild("CraftingTables")

	for _, tableModel in pairs(tablesFolder:GetChildren()) do
		CraftingTable.new(tableModel)
	end
	tablesFolder.ChildAdded:Connect(function(child)
		CraftingTable.new(child)
	end)
end

function CraftingTable.new(tableModel)
	local self = setmetatable({}, CraftingTable)

	local PromptService = engine:get("PromptService")
	local prompt = PromptService.new()
	self.prompt = prompt
	self.tableModel = tableModel

	prompt:set("ActionText", "Craft")
	prompt:set("ObjectText", "Crafting Table")

	local promptParent = tableModel
	if promptParent then
		prompt:set("Parent", promptParent)
	else
		warn("[CraftingTable] No prompt parent found for", tableModel.Name)
	end

	prompt.prompt.Triggered:Connect(function()
		CraftingTable:openUI()
	end)

	table.insert(CraftingTable._tables, self)
	return self
end

function CraftingTable:_initUI()
	if self._uiReady then
		return
	end

	local ui = engine.PlayerGui.UI:WaitForChild("CraftingTable")
	self.ui = ui
	self.ui.Visible = false

	self.tableFrame = ui:WaitForChild("Table")
	self.formulasFrame = ui:WaitForChild("Formulas")
	self.inventoryFrame = ui:WaitForChild("Inventory")
	self.exitButton = ui:FindFirstChild("Exit")

	self.gridFrame = self.tableFrame:WaitForChild("TableFrame")
	self.statsFrame = self.tableFrame:WaitForChild("Stats")
	self.statsTemplate = self.statsFrame:WaitForChild("StatTemplate")
	self.statsTemplate.Visible = false
	self.confirmButton = self.tableFrame:WaitForChild("ConfirmCraft")
	self.confirmText = self.confirmButton:WaitForChild("ResponseText")
	self.selectionText = self.tableFrame:WaitForChild("SelectionText")
	self.craftingItemText = self.tableFrame:WaitForChild("CraftingItemText")

	self.formulaList = self.formulasFrame:WaitForChild("ScrollingFrame")
	self.formulaTemplate = self:_prepareTemplate(self.formulaList)
	self.formulaEntries = {}

	local outline = self.formulaTemplate and self.formulaTemplate:FindFirstChild("Outline")
	self.formulaOutlineDefault = outline and outline.Color or Color3.fromRGB(204, 115, 63)
	self.formulaOutlineSelected = Color3.fromRGB(255, 231, 94)

	self.inventoryList = self.inventoryFrame:WaitForChild("ScrollingFrame")
	self.inventoryTemplate = self:_prepareTemplate(self.inventoryList)

	self.gridSlots = {}
	for i = 1, 9 do
		local slot = self.gridFrame:FindFirstChild(`Spot{i}`)
		if slot then
			self.gridSlots[i] = slot
			local button = slot:FindFirstChild("Button")
			if button then
				button.Activated:Connect(function()
					self:selectSlot(i)
				end)
			end
		end
	end

	self.defaultConfirmTextColor = self.confirmText.TextColor3
	self.defaultConfirmStroke = self.confirmButton:FindFirstChild("UIStroke")
	self.defaultConfirmStrokeColor = self.defaultConfirmStroke and self.defaultConfirmStroke.Color or nil

	self.confirmButton.Activated:Connect(function()
		self:attemptCraft()
	end)
	if self.exitButton then
		self.exitButton.Activated:Connect(function()
			self:closeUI()
		end)
	end

	self._uiReady = true
end

function CraftingTable:_prepareTemplate(container)
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

function CraftingTable:_stopWalkAwayMonitor()
	if self._walkAwayHeartbeat then
		self._walkAwayHeartbeat:Disconnect()
		self._walkAwayHeartbeat = nil
	end
	self._openPosition = nil
end

function CraftingTable:_startWalkAwayMonitor()
	self:_stopWalkAwayMonitor()

	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end

	self._openPosition = character:GetPivot().Position
	self._walkAwayHeartbeat = RunService.Heartbeat:Connect(function()
		local activeCharacter = player.Character
		if not activeCharacter then
			self:closeUI()
			return
		end

		local distance = (activeCharacter:GetPivot().Position - self._openPosition).Magnitude
		if distance > WALK_AWAY_DISTANCE then
			self:closeUI()
		end
	end)
end

function CraftingTable:openUI()
	self:_initUI()

	local QuickTween = engine:get("QuickTween")
	local PromptService = engine:get("PromptService")

	self.currentFormulaId = nil
	self.currentFormula = nil
	self.slotAssignments = {}
	self.selectedSlot = nil
	self.metalLock = nil

	self:_populateFormulas()
	self:_setFormula("ring")
	self:_refreshInventoryList()
	self:_updateStats()
	self:_updateCraftState()

	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = game:GetService("Lighting")
	self._blur = blur

	local scale = self.ui:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = self.ui
	end

	self.ui.Visible = false
	scale.Scale = 0.25
	self.ui.Position = UDim2.fromScale(0.5, 0.8)
	self.ui.Visible = true
	QuickTween(scale, 0.15, { Scale = 1 })
	QuickTween(self.ui, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
	QuickTween(blur, 0.2, { Size = 9 })

	self:_startWalkAwayMonitor()

	PromptService:disableAll()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	engine.PlayerGui.UI.Inventory.Visible = false
	if engine.PlayerGui.UI:FindFirstChild("Quests") then
		self._questsVisible = engine.PlayerGui.UI.Quests.Visible
		engine.PlayerGui.UI.Quests.Visible = false
	end
end

function CraftingTable:closeUI()
	if not self.ui then
		return
	end

	self:_stopWalkAwayMonitor()

	local QuickTween = engine:get("QuickTween")
	local PromptService = engine:get("PromptService")

	local scale = self.ui:FindFirstChildOfClass("UIScale")
	if scale then
		QuickTween(scale, 0.15, { Scale = 0.25 })
	end
	QuickTween(self.ui, 0.15, { Position = UDim2.fromScale(0.5, 0.8) }).Completed:Wait()
	self.ui.Visible = false

	if self._blur then
		QuickTween(self._blur, 0.2, { Size = 0 }).Completed:Wait()
		self._blur:Destroy()
		self._blur = nil
	end

	PromptService:reEnableAll()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	engine.PlayerGui.UI.Inventory.Visible = true
	if engine.PlayerGui.UI:FindFirstChild("Quests") and self._questsVisible ~= nil then
		engine.PlayerGui.UI.Quests.Visible = self._questsVisible
		self._questsVisible = nil
	end
end

function CraftingTable:_populateFormulas()
	if not self.formulaTemplate then
		return
	end

	for _, child in pairs(self.formulaList:GetChildren()) do
		if child:IsA("Frame") and child ~= self.formulaTemplate then
			child:Destroy()
		end
	end
	self.formulaEntries = {}

	for formulaId, formula in pairs(CraftingFormulas) do
		local entry = self.formulaTemplate:Clone()
		entry.Visible = true
		entry.Name = formulaId
		entry:SetAttribute("FormulaId", formulaId)

		local itemName = entry:FindFirstChild("ItemName")
		if itemName then
			itemName.Text = formula.name
		end

		local icon = entry:FindFirstChild("TypeIcon")
		if icon and formula.icon then
			icon.Image = formula.icon
			icon.ImageColor3 = Color3.new(1, 1, 1)
			icon.ImageTransparency = 0
		end

		local weight = entry:FindFirstChild("Weight")
		if weight then
			weight.Text = ""
		end

		local button = entry:FindFirstChild("Button")
		if button then
			button.Activated:Connect(function()
				self:_setFormula(formulaId)
			end)
		end

		self.formulaEntries[formulaId] = entry
		entry.Parent = self.formulaList
	end
end

function CraftingTable:_setFormula(formulaId)
	local formula = CraftingFormulas[formulaId]
	if not formula then
		return
	end

	self.currentFormulaId = formulaId
	self.currentFormula = formula
	self.slotAssignments = {}
	self.selectedSlot = nil
	self.metalLock = nil

	self:_updateCraftingItemText()

	self:_updateGridLock()
	for index, _ in pairs(self.gridSlots) do
		self:_updateSlotVisual(index)
	end
	self:_updateSlotHighlights()
	self:_updateSelectionText()
	self:_refreshInventoryList()
	self:_updateStats()
	self:_updateCraftState()
	self:_updateFormulaSelection()
end

function CraftingTable:_updateFormulaSelection()
	for formulaId, entry in pairs(self.formulaEntries) do
		local outline = entry:FindFirstChild("Outline")
		if outline then
			if formulaId == self.currentFormulaId then
				outline.Color = self.formulaOutlineSelected
				outline.Thickness = 2.5
			else
				outline.Color = self.formulaOutlineDefault
				outline.Thickness = 1.5
			end
		end
	end
end

function CraftingTable:_updateGridLock()
	if not self.currentFormula then
		return
	end

	local activeSlots = {}
	for _, slotIndex in ipairs(self.currentFormula.gridSlots) do
		activeSlots[slotIndex] = true
	end

	for index, slot in pairs(self.gridSlots) do
		local isActive = activeSlots[index] == true
		local stroke = slot:FindFirstChild("UIStroke")
		local icon = slot:FindFirstChild("TypeIcon")
		local button = slot:FindFirstChild("Button")

		if button then
			button.Active = isActive
			button.AutoButtonColor = isActive
		end
		slot.BackgroundTransparency = isActive and 0.15 or 0.75
		if icon then
			icon.ImageTransparency = isActive and 0.85 or 0.95
		end
		if stroke then
			stroke.Transparency = isActive and 0 or 0.7
		end
	end
end

function CraftingTable:selectSlot(slotIndex)
	if not self.currentFormula then
		return
	end

	if not self.currentFormula.requirements[slotIndex] then
		return
	end

	if self.selectedSlot == slotIndex then
		if self.slotAssignments[slotIndex] then
			self:clearSlot(slotIndex)
			return
		end
	end

	self.selectedSlot = slotIndex
	self:_updateSlotHighlights()
	self:_updateSelectionText()
	self:_refreshInventoryList()
end

function CraftingTable:clearSlot(slotIndex)
	self.slotAssignments[slotIndex] = nil
	self:_refreshMetalLock()
	self:_updateSlotVisual(slotIndex)
	self:_updateSlotHighlights()
	self:_updateSelectionText()
	self:_refreshInventoryList()
	self:_updateStats()
	self:_updateCraftState()
end

function CraftingTable:_updateSlotHighlights()
	for index, slot in pairs(self.gridSlots) do
		local stroke = slot:FindFirstChild("UIStroke")
		if stroke then
			if not (self.currentFormula and self.currentFormula.requirements[index]) then
				stroke.Color = Color3.fromRGB(90, 90, 90)
			elseif index == self.selectedSlot then
				stroke.Color = Color3.fromRGB(255, 231, 94)
			else
				stroke.Color = Color3.fromRGB(204, 115, 63)
			end
		end
	end
end

function CraftingTable:_updateSelectionText()
	if not self.currentFormula then
		self.selectionText.Text = ""
		return
	end

	if not self.selectedSlot then
		self.selectionText.Text = "Select a grid spot"
		return
	end

	local req = self.currentFormula.requirements[self.selectedSlot]
	if not req then
		self.selectionText.Text = "Select a grid spot"
		return
	end

	local types = table.concat(req.types, " or ")
	self.selectionText.Text = `Selecting a {string.upper(types)} spot`
end

function CraftingTable:_refreshMetalLock()
	self.metalLock = nil
	if not self.currentFormula then
		return
	end
	for _, slotIndex in ipairs(self.currentFormula.gridSlots) do
		local slotData = self.slotAssignments[slotIndex]
		if slotData and slotData.material_type == "Metal" then
			self.metalLock = slotData.lootKey
			break
		end
	end
	self:_updateCraftingItemText()
end

function CraftingTable:_refreshInventoryList()
	if not self.inventoryTemplate then
		return
	end

	for _, child in pairs(self.inventoryList:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Template" and child ~= self.inventoryTemplate then
			child:Destroy()
		end
	end

	local playerData = engine:get("PlayerService").data
	local inventory = playerData.inventory and playerData.inventory.loot or {}

	for _, lootEntry in pairs(inventory) do
		local used = self:_isLootUsed(lootEntry)
		if used then
			continue
		end

		local entry = self.inventoryTemplate:Clone()
		entry.Visible = true

		local lootKey = lootEntry.name or lootEntry.lootKey
		local lootDef = Loot[lootKey]
		if lootDef then
			local itemName = entry:FindFirstChild("ItemName")
			if itemName then
				itemName.Text = lootDef.name
			end
			local weight = entry:FindFirstChild("Weight")
			if weight then
				local kg = lootEntry.weight or lootEntry.kg or 0
				weight.Text = `{string.format("%.2f", kg)}kg`
			end
			local icon = entry:FindFirstChild("TypeIcon")
			if icon and lootDef.color then
				icon.ImageColor3 = lootDef.color
				icon.ImageTransparency = 0.2
			end
		end

		local eligible = self:_isEligibleForSelection(lootEntry)
		local button = entry:FindFirstChild("Button")
		if button then
			button.Active = eligible
			button.AutoButtonColor = eligible
			button.Activated:Connect(function()
				self:_handleInventoryPick(lootEntry)
			end)
		end

		local outline = entry:FindFirstChild("Outline")
		if outline then
			if used then
				outline.Color = Color3.fromRGB(120, 120, 120)
			elseif eligible then
				outline.Color = Color3.fromRGB(204, 115, 63)
			else
				outline.Color = Color3.fromRGB(80, 80, 80)
			end
		end

		local value = self:_getLootValue(lootEntry, lootDef)
		local priority = eligible and 0 or 1
		entry.LayoutOrder = priority * 1000000 - math.floor(value * 100)

		entry.Parent = self.inventoryList
	end
end

function CraftingTable:_getLootValue(lootEntry, lootDef)
	if not lootDef then
		return 0
	end
	local weight = lootEntry.weight or lootEntry.kg or 0
	local value = (lootDef.value_per_kg or 0) * weight
	local trait = lootEntry.trait and LootTraits[lootEntry.trait]
	if trait and trait.sell_multiplier then
		value *= trait.sell_multiplier
	end
	return value
end

function CraftingTable:_isLootUsed(lootEntry)
	for _, slotData in pairs(self.slotAssignments) do
		if slotData and slotData.id == lootEntry.id then
			return true
		end
	end
	return false
end

function CraftingTable:_isEligibleForSelection(lootEntry)
	if not self.currentFormula then
		return false
	end
	if not self.selectedSlot then
		return true
	end

	local req = self.currentFormula.requirements[self.selectedSlot]
	if not req then
		return false
	end

	local lootKey = lootEntry.name or lootEntry.lootKey
	local lootDef = Loot[lootKey]
	if not lootDef or not lootDef.material_type then
		return false
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
		return false
	end

	if material == "Metal" and self.currentFormula.lockMetal and self.metalLock and self.metalLock ~= lootKey then
		return false
	end

	return true
end

function CraftingTable:_handleInventoryPick(lootEntry)
	if not self.selectedSlot then
		return
	end
	if not self:_isEligibleForSelection(lootEntry) then
		return
	end

	for index, slotData in pairs(self.slotAssignments) do
		if slotData and slotData.id == lootEntry.id then
			self.slotAssignments[index] = nil
			self:_updateSlotVisual(index)
		end
	end

	local lootKey = lootEntry.name or lootEntry.lootKey
	local lootDef = Loot[lootKey]
	local material = lootDef and lootDef.material_type or nil

	self.slotAssignments[self.selectedSlot] = {
		id = lootEntry.id,
		lootKey = lootKey,
		trait = lootEntry.trait,
		weight = lootEntry.weight or lootEntry.kg or 0,
		material_type = material,
	}

	self:_refreshMetalLock()
	self:_updateSlotVisual(self.selectedSlot)
	self:_updateSelectionText()
	self:_refreshInventoryList()
	self:_updateStats()
	self:_updateCraftState()
end

function CraftingTable:_updateCraftingItemText()
	if not self.currentFormula then
		self.craftingItemText.Text = ""
		return
	end

	local displayName = self.currentFormula.output.displayName
	if self.metalLock and Loot[self.metalLock] then
		displayName = `{Loot[self.metalLock].name} {displayName}`
	end

	self.craftingItemText.Text = `Crafting a {string.upper(displayName)}`
end

function CraftingTable:_updateSlotVisual(slotIndex)
	local slot = self.gridSlots[slotIndex]
	if not slot then
		return
	end

	local slotData = self.slotAssignments[slotIndex]
	local icon = slot:FindFirstChild("TypeIcon")
	if not icon then
		return
	end

	if slotData then
		local lootDef = Loot[slotData.lootKey]
		if lootDef and lootDef.color then
			icon.ImageColor3 = lootDef.color
		end
		icon.ImageTransparency = 0.15
	else
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ImageTransparency = 0.85
	end
end

function CraftingTable:_updateStats()
	if not self.statsTemplate then
		return
	end

	for _, child in pairs(self.statsFrame:GetChildren()) do
		if child:IsA("TextLabel") and child.Name ~= self.statsTemplate.Name then
			child:Destroy()
		end
	end

	local stats = { strength = 0, speed = 0, luck = 0 }
	for _, slotData in pairs(self.slotAssignments) do
		local lootDef = Loot[slotData.lootKey]
		if lootDef then
			stats.luck += lootDef.craft_luck or 0
			if lootDef.craft_modifiers then
				for stat, value in pairs(lootDef.craft_modifiers) do
					stats[stat] = (stats[stat] or 0) + value
				end
			end
		end
		local trait = slotData.trait and LootTraits[slotData.trait]
		if trait then
			stats.luck += trait.craft_luck or 0
			if trait.craft_modifiers then
				for stat, value in pairs(trait.craft_modifiers) do
					stats[stat] = (stats[stat] or 0) + value
				end
			end
		end
	end

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

function CraftingTable:_isFormulaComplete()
	if not self.currentFormula then
		return false
	end
	for _, slotIndex in ipairs(self.currentFormula.gridSlots) do
		if not self.slotAssignments[slotIndex] then
			return false
		end
	end
	return true
end

function CraftingTable:_updateCraftState()
	local ready = self:_isFormulaComplete()
	self.confirmButton.Active = ready
	self.confirmButton.AutoButtonColor = ready

	if ready then
		self.confirmText.TextColor3 = self.defaultConfirmTextColor
		if self.defaultConfirmStroke and self.defaultConfirmStrokeColor then
			self.defaultConfirmStroke.Color = self.defaultConfirmStrokeColor
		end
	else
		self.confirmText.TextColor3 = Color3.fromRGB(140, 140, 140)
		if self.defaultConfirmStroke then
			self.defaultConfirmStroke.Color = Color3.fromRGB(90, 90, 90)
		end
	end
end

function CraftingTable:attemptCraft()
	if not self:_isFormulaComplete() then
		engine:get("NotificationService").new("Fill all required slots first.", { italic = true })
		return
	end

	local slots = {}
	for slotIndex, slotData in pairs(self.slotAssignments) do
		slots[tostring(slotIndex)] = slotData.id
	end

	engine.events.Inventory:FireServer("craftItem", {
		formulaId = self.currentFormulaId,
		slots = slots,
	})
end

function CraftingTable:handleCraftResult(success, data)
	if not success then
		local message = data and data.message or "Crafting failed."
		engine:get("NotificationService").new(message, { italic = true })
		return
	end

	self:closeUI()
end

return CraftingTable
