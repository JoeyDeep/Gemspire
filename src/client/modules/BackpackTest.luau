--[[
    SINGLETON (Handler)

    PURPOSE:
        Handle tool equipping and unequipping events for tools in the player's backpack.
        !!! This module is in testing. The idea behind this backpack method is utilizing native Roblox backpack
            features, and simply listening to tool equip/unequip and add/destroy events to trigger any additional
            functionality as needed.

        As it stands, this module is the only one listening for tool equip/unequip events, and handles all such actions.
    USAGE:
        ```lua
        local BackpackTest = require(engine:get("BackpackTest"))
        ```
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local TopBarPlus = require(ReplicatedStorage.Packages.topbarplus)

local BackpackTest = {
	setupTools = {},
}
BackpackTest.__index = BackpackTest

local engine

function BackpackTest.init(engineModule)
	engine = engineModule

	local players = game:GetService("Players")
	local StarterGui = game:GetService("StarterGui")
	local InputData = engine:get("InputData")
	-- local backpack = players.LocalPlayer.Backpack

	players.LocalPlayer.CharacterAdded:Connect(function()
		local backpack = players.LocalPlayer.Backpack
		backpack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				BackpackTest.new(child)
			end
		end)
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				BackpackTest.new(tool)
			end
		end
	end)

	local keyCodeTranslation = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7,
		[Enum.KeyCode.Eight] = 8,
		[Enum.KeyCode.Nine] = 9,
		[Enum.KeyCode.Zero] = 10,
	}
	local keyboard = Input.Keyboard.new()
	keyboard.KeyDown:Connect(function(key)
		if keyCodeTranslation[key] then
			local intendedIndex = keyCodeTranslation[key]
			for _, toolInstance in pairs(BackpackTest.setupTools) do
				if toolInstance.index == intendedIndex then
					toolInstance:equip()
					break
				end
			end
			-- elseif key == InputData.Inputs.Backpack.MouseKeyboard.Input then
			-- 	BackpackTest:toggleBackpackUI()
		end
	end)

	local backpackTopBar = TopBarPlus.new()
	backpackTopBar:setImage("rbxassetid://135273755533681")
	backpackTopBar:setImageScale(1.1)
	backpackTopBar:align("Left")
	backpackTopBar:bindToggleKey(InputData.Inputs.Backpack.MouseKeyboard.Input)
	backpackTopBar:setCaption("Backpack")
	backpackTopBar.toggled:Connect(
		function(a0: boolean, a1: "AutoDeselect" | "HideParentFeature" | "OneClick" | "Overflow" | "User")
			BackpackTest:toggleBackpackUI()
		end
	)

	-- sorting
	local activeSort = "none"
	task.spawn(function()
		local backpackContents = engine.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory"):WaitForChild("Backpack")
		local sortOptions = engine.PlayerGui.UI.Inventory.BackpackBackground.Sorting

		-- interjection to disable the "T to open backpack" tip for non-mousekeyboard users (put here simply for UI yielding above)
		Input.PreferredInput.Observe(function(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
			engine.PlayerGui.UI.Inventory.OpenTip.Visible = inputType == "MouseKeyboard"
		end)

		local sortFunctions = {
			["none"] = function()
				for _, toolButton in pairs(backpackContents:GetChildren()) do
					if toolButton:IsA("Frame") then
						local toolInstance =
							BackpackTest.setupTools[players.LocalPlayer.Backpack:FindFirstChild(toolButton.Name)]
						if toolInstance then
							toolButton.LayoutOrder = toolInstance.index
							toolButton.Visible = true
						end
					end
				end
			end,
			["value"] = function()
				local toolInstances = {}
				for _, toolButton in pairs(backpackContents:GetChildren()) do
					if toolButton:IsA("Frame") then
						local toolInstance =
							BackpackTest.setupTools[players.LocalPlayer.Backpack:FindFirstChild(toolButton.Name)]
						if toolInstance and toolInstance.lootKey then
							local lootDef = engine:get("Loot")[toolInstance.lootKey]
							local sellPrice = math.round(lootDef.value_per_kg * toolInstance.kg)
							table.insert(toolInstances, { class = toolInstance, value = sellPrice })
						else
							toolButton.Visible = false
						end
					end
				end
				table.sort(toolInstances, function(a, b)
					return a.value > b.value
				end)
				for index, toolData in pairs(toolInstances) do
					local toolButton = backpackContents:FindFirstChild(toolData.class.toolObject.Name)
					if toolButton then
						toolButton.LayoutOrder = index
						toolButton.Visible = true
					end
				end
			end,
			["weight"] = function()
				local toolInstances = {}
				for _, toolButton in pairs(backpackContents:GetChildren()) do
					if toolButton:IsA("Frame") then
						local toolInstance =
							BackpackTest.setupTools[players.LocalPlayer.Backpack:FindFirstChild(toolButton.Name)]
						if toolInstance and toolInstance.lootKey then
							table.insert(toolInstances, { class = toolInstance, weight = toolInstance.kg })
						else
							toolButton.Visible = false
						end
					end
				end
				table.sort(toolInstances, function(a, b)
					return a.weight > b.weight
				end)
				for index, toolData in pairs(toolInstances) do
					local toolButton = backpackContents:FindFirstChild(toolData.class.toolObject.Name)
					if toolButton then
						toolButton.LayoutOrder = index
						toolButton.Visible = true
					end
				end
			end,
			["type"] = function()
				-- @TODO: implement type sorting
			end,
			["locked"] = function()
				-- @TODO: implement locked sorting
			end,
		}

		for _, sortOption in pairs(sortOptions:GetChildren()) do
			if sortOption:IsA("ImageButton") then
				sortOption.Activated:Connect(function()
					if activeSort ~= sortOption.Name then
						activeSort = sortOption.Name
						engine.PlayerGui.UI.Inventory.BackpackBackground.ActiveSort.Text = `Sort: {activeSort}`
						sortFunctions[sortOption:GetAttribute("SortMethod")]()
					end
				end)
			end
		end
	end)

	local function disableNativeBackpackUI()
		return pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end

	local success, err = disableNativeBackpackUI()
	if not success then
		warn("[BackpackTest] Failed to disable backpack UI:", err)
		task.spawn(function()
			while not success do
				task.wait(1)
				success, err = disableNativeBackpackUI()
			end
		end)
	end
end

function BackpackTest.new(toolObject)
	local self = setmetatable({}, BackpackTest)

	if BackpackTest.setupTools[toolObject] then
		return
	end

	local Icons = engine:get("Icons")
	local itemType = toolObject:GetAttribute("Type")

	local intendedIndex = toolObject:GetAttribute("BackpackIndex")
	if typeof(intendedIndex) ~= "number" or intendedIndex <= 0 then
		intendedIndex = 1
		for _, _ in pairs(BackpackTest.setupTools) do
			intendedIndex += 1
		end
	end

	local toolbar = engine.PlayerGui.UI.Inventory.Toolbar
	local backpack = engine.PlayerGui.UI.Inventory.Backpack
	local newTool, parentContainer
	if intendedIndex > 10 then
		parentContainer = backpack
	else
		parentContainer = toolbar
	end
	newTool = parentContainer.Template:Clone()
	newTool.Name = toolObject.Name

	self.toolbarButton = newTool
	self.index = intendedIndex
	self.toolObject = toolObject

	local typeSetups = {
		["Pickaxe"] = function()
			local pickaxeData = engine:get("Pickaxes")[toolObject.Name]
			local mainTitle = newTool.Titles.Template:Clone()
			mainTitle.Text = pickaxeData.name
			mainTitle.Name = "MainTitle"
			mainTitle.Visible = true
			mainTitle.Parent = newTool.Titles
			newTool.Icon.Image = Icons.Pickaxe
		end,
		["Drill"] = function()
			local drillData = engine:get("Drills")[toolObject.Name]
			local mainTitle = newTool.Titles.Template:Clone()
			mainTitle.Text = drillData.name
			mainTitle.Name = "MainTitle"
			mainTitle.Visible = true
			mainTitle.Parent = newTool.Titles
			newTool.Icon.Image = Icons.Drill
		end,
		["HoldLoot"] = function()
			local itemData = engine:get("Loot")[toolObject:GetAttribute("LootKey")]
			local mainTitle = newTool.Titles.Template:Clone()
			mainTitle.Text = itemData.name
			mainTitle.Name = "MainTitle"
			mainTitle.Visible = true
			mainTitle.Parent = newTool.Titles

			newTool.Weight.Text = `{toolObject:GetAttribute("Weight")} kg`
			newTool.Weight.Visible = true

			local trait = toolObject:GetAttribute("Trait")
			if trait and trait ~= "none" then
				local traitTitle = newTool.Titles.Template:Clone()
				traitTitle.Text = `{trait}`
				traitTitle.Name = "TraitTitle"
				traitTitle.Visible = true
				traitTitle.Parent = newTool.Titles
			end
			newTool.Icon.Image = Icons.HoldLoot
		end,

		["Default"] = function()
			-- Default setup for tools without specific type handling
		end,
	}

	if typeSetups[itemType] then
		typeSetups[itemType]()
	else
		typeSetups.Default()
	end
	if parentContainer == toolbar then
		newTool.Index.Text = (intendedIndex == 10 and "0") or tostring(intendedIndex)
	else
		newTool.Index.Text = ""
	end
	newTool.Visible = true
	newTool.Parent = parentContainer

	BackpackTest.setupTools[toolObject] = true
	self.ancestryChangedConnection = toolObject.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy()
		end
	end)
	self.clickEquip = newTool.Button.Activated:Connect(function()
		self:equip()
	end)

	BackpackTest.setupTools[toolObject] = self
	return self
end

function BackpackTest:getToolClass(toolObject)
	return BackpackTest.setupTools[toolObject]
end

function BackpackTest:equip()
	local players = game:GetService("Players")
	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local wasEquipped = self.toolObject.Parent == character

	for toolInstance, _ in pairs(BackpackTest.setupTools) do
		if toolInstance.Parent == players.LocalPlayer.Backpack or toolInstance.Parent == character then
			if toolInstance ~= self.toolObject then
				humanoid:UnequipTools()
			end
		end
	end

	-- Prevent equipping if the tool is already equipped
	if wasEquipped then
		humanoid:UnequipTools()
		return
	end

	humanoid:EquipTool(self.toolObject)
end

function BackpackTest:toggleBackpackUI()
	local QuickTween = engine:get("QuickTween")

	local inventoryUI = engine.PlayerGui.UI.Inventory
	local nowVisible = (inventoryUI.Backpack.Position.Y.Scale == 1.5)

	if nowVisible then
		QuickTween(inventoryUI.Backpack, 0.2, { Position = UDim2.fromScale(0.513, 0.655) })
		QuickTween(inventoryUI.BackpackBackground, 0.2, { Position = UDim2.fromScale(0.5, 0.649) })
	else
		QuickTween(inventoryUI.Backpack, 0.2, { Position = UDim2.fromScale(0.513, 1.5) })
		QuickTween(inventoryUI.BackpackBackground, 0.2, { Position = UDim2.fromScale(0.5, 1.5) })
	end
end

function BackpackTest:destroy()
	self.ancestryChangedConnection:Disconnect()
	self.toolbarButton:Destroy()
	BackpackTest.setupTools[self.toolObject] = nil
end

return BackpackTest
