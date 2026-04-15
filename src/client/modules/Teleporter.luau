local Players = game:GetService("Players")

local Teleporter = {
	_teleporters = {},
}

Teleporter.__index = Teleporter

local engine
function Teleporter.init(engineModule)
    engine = engineModule
	engine:await("PromptService")

    local teleportersFolder = workspace.Entities:WaitForChild("Teleporters")

    for _, teleportModel in pairs(teleportersFolder:GetChildren()) do
        Teleporter.new(teleportModel)
    end
    teleportersFolder.ChildAdded:Connect(function(child)
		Teleporter.new(child)
	end)
end

function Teleporter.new(teleporterModel)
    local self = setmetatable({}, Teleporter)

	local PromptService = engine:get("PromptService")
	local prompt = PromptService.new()
	self.prompt = prompt
	self.teleporterModel = teleporterModel

	prompt:set("ActionText", "Teleport")
	prompt:set("ObjectText", "Teleporter")

	local promptParent = teleporterModel
	if promptParent then
		prompt:set("Parent", promptParent)
	else
		warn("[CraftingTable] No prompt parent found for", teleporterModel.Name)
	end

	prompt.prompt.Triggered:Connect(function()
		print("teleport menu")
        -- self:openUI()
        self:teleport()
	end)

	table.insert(Teleporter._teleporters, self)
	return self
end

function Teleporter:openUI()
    local ui = engine.PlayerGui.UI:WaitForChild("Teleporter")
	self.ui = ui
	self.ui.Visible = true
end

function Teleporter:teleport()
	engine.events.Teleporter:FireServer("teleport", {
		fromTeleporter = "TeleporterA",
		toTeleporter = "TeleporterB",
	})
end
return Teleporter