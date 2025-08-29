local BackpackService = {
	items = {}
}
BackpackService.__index = BackpackService

local engine
function BackpackService.init(engineModule)
	engine = engineModule
end

function BackpackService:setup() end

function BackpackService.newTool(name, data)
	local self = {}
	self.name = name
	self.type = data.type
	self.id = data.id

	self = setmetatable(self, BackpackService)
	BackpackService.items[self.id] = self

	self:addToBackpack()

	return self
end

function BackpackService:addToBackpack()
	engine.backpack[self.id] = self
end

return BackpackService
