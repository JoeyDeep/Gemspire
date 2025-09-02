local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Icons = require(ReplicatedStorage.Shared.GameData.Icons)
local QuickTween = require(ReplicatedStorage.Shared.utils.QuickTween)
-- local Sound = require(ReplicatedStorage.Shared.utils.Sound)

local Tool = {
	liveTools = {},
}
Tool.__index = Tool

local engine
function Tool.init(engineModule)
	engine = engineModule
end

function Tool.new(name, type, ui, data)
	local self = setmetatable({}, Tool)

	self.name = name
	self.type = type
	self.ui = ui
	self.data = data
	self.position = Tool.countTools() + 1
	self.equipCooldown = tick()
	self.equipped = false
	self.typeClass = engine:get(self.type).new(self.name, self)

	-- if Tool.liveTools[name] then
	-- 	Tool.liveTools[name]:destroy()
	-- 	warn("Tool with name '" .. name .. "' already exists. Cleaned up the old...")
	-- 	self = nil
	-- 	return
	-- end

	-- self:setup()

	-- Tool.liveTools[name] = self
	return self
end

-- unused right now
function Tool:setup()

	-- -- create UI FROM Toolbar template (same template used in Backpack), but don't parent yet
	-- local inv = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory")
	-- local toolbar = inv.Toolbar
	-- local template = toolbar:WaitForChild("Template") :: Frame

	-- self.ui = template:Clone()
	-- self.ui.Name = self.name
	-- self.ui.Icon.Image = Icons[self.type] or Icons.Other
	-- self.ui.Index.Text = tostring(self.position) -- will be overwritten by InventoryManager
	-- self.ui.Weight.Visible = false
	-- self.ui.Titles.Template.Text = self.typeClass.displayName or "Unknown Tool"
	-- self.ui.Titles.Template.Visible = true
	-- self.ui.Visible = true

	-- -- FX
	-- self.ui.Button.MouseEnter:Connect(function()
	-- 	Sound:playGlobal("Hover")
	-- 	QuickTween(self.ui.Outline.UIGradient, 0.15, { Rotation = 220 })
	-- end)
	-- self.ui.Button.MouseLeave:Connect(function()
	-- 	QuickTween(self.ui.Outline.UIGradient, 0.3, { Rotation = 40 })
	-- end)
	-- self.ui.Button.Activated:Connect(function()
	-- 	-- Simple click toggles equip; drag is handled in InventoryManager
	-- 	Sound:playGlobal("Click")
	-- 	if self.equipped then
	-- 		self:unequip()
	-- 	else
	-- 		self:equip()
	-- 	end
	-- end)

	-- Parent placement is now owned by InventoryManager:
	-- engine:get("BackpackManager").addTool(self)
end

-- Called by InventoryManager to show/hide the toolbar hotkey label
function Tool:setIndexLabel(idxText: string?)
	if idxText then
		self.ui.Index.Text = idxText
		self.ui.Index.Visible = true
	else
		self.ui.Index.Visible = false
	end
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

	QuickTween(self.ui.Outline, 0.15, { Color = Color3.new(1, 1, 1) })
	local inv = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory")
	inv.Tip.Visible = false
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

	QuickTween(self.ui.Outline, 0.15, { Color = Color3.new(0, 0, 0) })
	local inv = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory")
	inv.Tip.Visible = true
end

function Tool:destroy()
	self.typeClass:destroy()
	self.ui:Destroy()
	-- if Tool.liveTools[self.name] then
	-- 	Tool.liveTools[self.name] = nil
	-- end
	self = nil
end

function Tool.countTools()
	local count = 0
	-- for _, _ in pairs(Tool.liveTools) do
	-- 	count += 1
	-- end
	return count
end

return Tool
