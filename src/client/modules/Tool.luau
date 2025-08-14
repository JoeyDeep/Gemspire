local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icons = require(ReplicatedStorage.Shared.GameData.Icons)
local QuickTween = require(ReplicatedStorage.Shared.utils.QuickTween)
local Sound = require(ReplicatedStorage.Shared.utils.Sound)
local Tool = {
	liveTools = {},
}
Tool.__index = Tool

local engine
function Tool.init(engineModule)
	engine = engineModule
end

-- new Tool class, used for Backpack & Inventory control
function Tool.new(name, type)
	local self = setmetatable({}, Tool)

	self.name = name
	self.type = type -- e.g., "pickaxe", "sifter"
	self.position = Tool.countTools() + 1 -- used for inventory keybind (e.g. 1, 2, 3, etc.)
	self.equipCooldown = tick()
	self.equipped = false

	if Tool.liveTools[name] then
		Tool.liveTools[name]:destroy() -- Clean up the old tool if it exists
		warn("Tool with name '" .. name .. "' already exists. Cleaned up the old...")
	end

	self:setup()

	Tool.liveTools[name] = self
	return self
end

function Tool:setup()
	self.typeClass = engine:get(self.type).new(self.name, self)

	-- create toolbar button for the tool
	self.ui = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory").Container.Template:Clone()
	self.ui.Name = self.name
	self.ui.Icon.Image = Icons[self.type] or Icons.Other
	self.ui.Index.Text = tostring(self.position)
	self.ui.Weight.Visible = false
	self.ui.Titles.Template.Text = self.typeClass.displayName or "Unknown Tool"
	self.ui.Titles.Template.Visible = true
	self.ui.Visible = true

	self.ui.Button.MouseEnter:Connect(function()
		Sound:playGlobal("Hover")
		QuickTween(self.ui.Outline.UIGradient, 0.15, {
			Rotation = 220,
		})
	end)
	self.ui.Button.MouseLeave:Connect(function()
		QuickTween(self.ui.Outline.UIGradient, 0.3, {
			Rotation = 40,
		})
	end)
	self.ui.Button.Activated:Connect(function()
		Sound:playGlobal("Click")
		if self.equipped then
			self:unequip()
		else
			self:equip()
		end
	end)

	self.ui.Parent = Players.LocalPlayer.PlayerGui.UI.Inventory.Container
end

function Tool:equip()
	if self.equipped then
		warn("Tool '" .. self.name .. "' is already equipped.")
		return
	end
	if tick() <= self.equipCooldown then
		return
	end

	self.equipCooldown = tick() + 1
	self.equipped = true
	self.typeClass:equip()

	-- Update UI to show equipped state
	QuickTween(self.ui.Outline, 0.15, {
		Color = Color3.new(1, 1, 1),
	})
end

function Tool:unequip()
	if not self.equipped then
		warn("Tool '" .. self.name .. "' is not equipped.")
		return
	end
	if tick() <= self.equipCooldown then
		return
	end

	self.equipCooldown = tick() + 1
	self.equipped = false
	self.typeClass:unequip()

	-- Update UI to show unequipped state
	QuickTween(self.ui.Outline, 0.15, {
		Color = Color3.new(0, 0, 0),
	})
end

function Tool:destroy()
	self.typeClass:destroy()

	self.ui:Destroy()

	if Tool.liveTools[self.name] then
		Tool.liveTools[self.name] = nil
	end
	self = nil
end

function Tool.countTools()
	local count = 0
	for _, _ in pairs(Tool.liveTools) do
		count += 1
	end

	return count
end

return Tool
