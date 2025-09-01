local BackpackService = {
	primaries = {},
	loot = {}
}
BackpackService.__index = BackpackService

local RESERVED_SLOTS = 1

local engine
function BackpackService.init(engineModule)
	engine = engineModule
end

function BackpackService:setup(data)
	BackpackService.primaries.pickaxe = BackpackService.addTool(data.equipped.pickaxe, "Pickaxe")
	-- 'collection' of loots book tool thing
	for _, lootName in ipairs(data.inventory.loot) do
		local lootTool = BackpackService.addTool(lootName, "HoldLoot")
		table.insert(BackpackService.loot, lootTool)
	end
end

function BackpackService.addTool(name, type)
	local self = {}
	self = setmetatable(self, BackpackService)

	self.name = name
	self.type = type
	-- self.data = data
	self.toolClass = engine:get("Tool").new(name, type)

	-- ui stuff

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
	local inv = Players.LocalPlayer.PlayerGui:WaitForChild("UI"):WaitForChild("Inventory")
	local toolbar = inv.Toolbar
	local template = toolbar:WaitForChild("Template") :: Frame

	self.ui = template:Clone()
	self.ui.Name = self.name
	self.ui.Icon.Image = Icons[self.type] or Icons.Other
	self.ui.Index.Text = tostring(self.position) -- will be overwritten by InventoryManager
	self.ui.Weight.Visible = false
	self.ui.Titles.Template.Text = self.typeClass.displayName or "Unknown Tool"
	self.ui.Titles.Template.Visible = true
	self.ui.Visible = true

end

function BackpackService:addToBackpack()
	engine.backpack[self.id] = self
end

return BackpackService