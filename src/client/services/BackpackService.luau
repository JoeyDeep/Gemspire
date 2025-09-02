local BackpackService = {
	primaries = {},
	loot = {},
	enabled = true,
}
BackpackService.__index = BackpackService

local RESERVED_SLOTS = 1

local engine
function BackpackService.init(engineModule)
	engine = engineModule
end

-- function BackpackService:setup(data)
-- 	-- BackpackService.primaries.pickaxe = BackpackService.addTool(data.equipped.pickaxe, "Pickaxe")
-- 	-- -- 'collection' of loots book tool thing
-- 	-- for _, lootName in ipairs(data.inventory.loot) do
-- 	-- 	local lootTool = BackpackService.addTool(lootName, "HoldLoot")
-- 	-- 	table.insert(BackpackService.loot, lootTool)
-- 	-- end
-- end

function BackpackService.addTool(name, type, data)
	local self = {}
	self = setmetatable(self, BackpackService)

	self.name = name
	self.type = type
	self.data = data

	self.order = RESERVED_SLOTS + #BackpackService.loot + 1

	if self.type == "Pickaxe" then
		self.order = 1
	end

	self:drawButton()

	return self
end

function BackpackService:drawButton()
	local Players = game:GetService("Players")
	local Icons = engine:get("Icons")
	local QuickTween = engine:get("QuickTween")
	local Sound = engine:get("Sound")

	local inv = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory")
	local toolbar = inv.Toolbar
	local template = toolbar:WaitForChild("Template") :: Frame

	self.ui = template:Clone()

	self.toolClass = engine:get("Tool").new(self.name, self.type, self.ui, self.data)

	self.ui.Name = self.name
	self.ui.Icon.Image = Icons[self.type] or Icons.Other
	self.ui.Index.Text = tostring(self.order)
	self.ui.Weight.Visible = false
	self.ui.Titles.Template.Text = self.toolClass.typeClass.displayName or "Unknown Tool"
	self.ui.Titles.Template.Visible = true
	self.ui.Visible = true

	self.ui.Button.MouseEnter:Connect(function()
		Sound:playGlobal("Hover")
		QuickTween(self.ui.Outline.UIGradient, 0.15, { Rotation = 220 })
	end)
	self.ui.Button.MouseLeave:Connect(function()
		QuickTween(self.ui.Outline.UIGradient, 0.3, { Rotation = 40 })
	end)
	self.ui.Button.Activated:Connect(function()
		Sound:playGlobal("Click")
		if BackpackService.enabled then
			if self.toolClass.equipped then
				self.toolClass:unequip()
			else
				self.toolClass:equip()
			end
		end
	end)

	-- determine toolbar or backpack
	self.ui.Parent = toolbar
end

function BackpackService:addToBackpack()
	engine.backpack[self.id] = self
end

function BackpackService:disable()
	BackpackService.enabled = false

	local Players = game:GetService("Players")
	local ui = Players.LocalPlayer.PlayerGui:WaitForChild("UI")
	ui.Inventory.Visible = false
end

function BackpackService:enable()
	BackpackService.enabled = true

	local Players = game:GetService("Players")
	local ui = Players.LocalPlayer.PlayerGui:WaitForChild("UI")
	ui.Inventory.Visible = true
end

return BackpackService
