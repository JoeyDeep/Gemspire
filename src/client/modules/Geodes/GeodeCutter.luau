local StarterGui = game:GetService("StarterGui")
local GeodeCutter = {}
GeodeCutter.__index = GeodeCutter

local engine
function GeodeCutter.init(engineModule)
	engine = engineModule
	engine:await("PromptService")
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

	local function findGeodeInInventory()
		local character = engine.player.Character
		local backpack = engine.player.Backpack
		if character then
			local tool = character:FindFirstChildWhichIsA("Tool")
			if tool and tool:GetAttribute("LootKey") == "geode" then
				return tool
			end
		end
		if backpack then
			for _, tool in pairs(backpack:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("LootKey") == "geode" then
					return tool
				end
			end
		end
		return nil
	end

	self.prompt.prompt.Triggered:Connect(function()
		local geodeTool = findGeodeInInventory()
		if geodeTool then
			self:crackSequence(geodeTool)
		else
			NotificationService.new(
				`<i>You need a Geode in your inventory to use this station.</i>`,
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
		local character = engine.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid:UnequipTools() end

		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		engine.PlayerGui.UI.Inventory.Visible = false
		SpeedManager:setState("crackingGeode", "freeze")
		Controls:Disable()
		PromptService:disableAll()
		local completeCallback = crackingMethodModule:start(self.station, geodeTool)
		completeCallback.Event:Once(function(result)
			engine.events.Inventory:FireServer("crackAllGeodes")
			engine:get("GeodeService").revealCompleted.Event:Once(function()
				PromptService:reEnableAll()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				engine.PlayerGui.UI.Inventory.Visible = true
				SpeedManager:dropState("crackingGeode", "freeze")
				Controls:Enable()
				print(result)
			end)
		end)
	else
		warn("Cracking method module not found for method:", self.method)
	end
end

return GeodeCutter
