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

local BackpackTest = {
	setupTools = {},
}
BackpackTest.__index = BackpackTest

local engine

function BackpackTest.init(engineModule)
	engine = engineModule

	local players = game:GetService("Players")
	local StarterGui = game:GetService("StarterGui")
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
				wait(1)
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

	local toolbar = engine.PlayerGui.UI.Inventory.Toolbar
	local newTool = toolbar.Template:Clone()
	newTool.Name = toolObject.Name

	local intendedIndex = 1
	for _, _ in pairs(BackpackTest.setupTools) do
		intendedIndex += 1
	end

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
	newTool.Index.Text = tostring(intendedIndex)
	newTool.Visible = true
	newTool.Parent = toolbar

	BackpackTest.setupTools[toolObject] = true
	self.ancestryChangedConnection = toolObject.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy()
		end
	end)

	BackpackTest.setupTools[toolObject] = self
	return self
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

function BackpackTest:destroy()
	self.ancestryChangedConnection:Disconnect()
	self.toolbarButton:Destroy()
	BackpackTest.setupTools[self.toolObject] = nil
end

return BackpackTest
