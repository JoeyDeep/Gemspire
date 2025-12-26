local StarterGui = game:GetService("StarterGui")
local GeodeCutter = {}
GeodeCutter.__index = GeodeCutter

local engine
function GeodeCutter.init(engineModule)
	engine = engineModule
	for _, cuttingStation in pairs(workspace.Entities.CrackingTables:GetChildren()) do
		task.spawn(function()
			GeodeCutter.new(cuttingStation)
		end)
	end
end

function GeodeCutter.new(cuttingStation)
	local self = setmetatable({}, GeodeCutter)

	local PromptService = engine:get("PromptService")
	local NotificationService = engine:get("NotificationService")
	self.prompt = PromptService.new()
	self.station = cuttingStation
	self.method = cuttingStation:GetAttribute("CuttingMethod")

	self.prompt:set("ActionText", "Crack Geode")
	self.prompt:set("ObjectText", `{self.method} Table`)
	self.prompt:set("Parent", cuttingStation:WaitForChild("CamPart"))

	self.prompt.prompt.Triggered:Connect(function()
		local tool = engine.player.Character and engine.player.Character:FindFirstChildWhichIsA("Tool")
		if tool and tool:GetAttribute("LootKey") == "geode" then
			self:crackSequence(tool)
		else
			NotificationService.new(
				`<i>You need to be holding a Geode to use this station.</i>`,
				{ textColor = Color3.fromRGB(255, 188, 100) }
			)
		end
	end)

	return self
end

function GeodeCutter:crackSequence(geodeTool)
	local crackingMethodModule = engine:get(`CrackSequence_{self.method}`)
	local PromptService = engine:get("PromptService")
	local SpeedManager = engine:get("SpeedManager")
	local PlayerModule = require(engine.player.PlayerScripts:WaitForChild("PlayerModule"))
	local Controls = PlayerModule:GetControls()

	if crackingMethodModule then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		engine.PlayerGui.UI.Inventory.Visible = false
		SpeedManager:setState("crackingGeode", "freeze")
		Controls:Disable()
		PromptService:disableAll()
		engine.events.Inventory:FireServer("crackGeode", geodeTool.Name)
		local completeCallback = crackingMethodModule:start(self.station, geodeTool)
		completeCallback.Event:Once(function(result)
			PromptService:reEnableAll()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			engine.PlayerGui.UI.Inventory.Visible = true
			SpeedManager:dropState("crackingGeode", "freeze")
			Controls:Enable()
			print(result)
		end)
	else
		warn("Cracking method module not found for method:", self.method)
	end
end

return GeodeCutter
