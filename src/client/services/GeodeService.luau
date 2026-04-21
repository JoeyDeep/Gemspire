local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GeodeService = {}
local engine

GeodeService.revealCompleted = Instance.new("BindableEvent")

local RACK_SCALE = 0.3
local SLOT_WIDTH = 2

local TRAIT_DISPLAY = {
	none    = { name = "No Trait", color = Color3.fromRGB(180, 180, 180) },
	ancient = { name = "Ancient",  color = Color3.fromRGB(80,  160, 255) },
	cursed  = { name = "Cursed",   color = Color3.fromRGB(180, 60,  255) },
}
local TRAIT_SOUNDS = {
	none    = "RevealCommon",
	ancient = "RevealAncient",
	cursed  = "RevealCursed",
}

local GeodeAnimations

function GeodeService.init(engineModule)
	engine = engineModule
	GeodeAnimations = engine:get("GeodeAnimations")
	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "geodesOpened" then
			GeodeService:startRevealSequence(data)
		end
	end)
end

function GeodeService:startRevealSequence(results)
	if not results or #results == 0 then
		GeodeService.revealCompleted:Fire()
		return
	end

	local QuickTween      = engine:get("QuickTween")
	local Sound           = engine:get("Sound")
	local GeodeContents   = engine:get("GeodeContents")
	local UI              = engine.PlayerGui.UI.GeodeReveal
	local geodeTemplate   = ReplicatedStorage.Storage.Geode.Geode
	local particlesFolder = ReplicatedStorage.Storage.Particles

	local revealStage   = workspace.RevealStage
	local anchorCFrame  = revealStage.GeodeAnchor.CFrame
	local rack          = revealStage.GeodeRack
	local rackSlotCount = math.max(1, math.floor(rack.Size.X / SLOT_WIDTH))

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = revealStage.CamPart.CFrame

	UI.UIScale.Scale = 0.25
	UI.Position      = UDim2.fromScale(0.5, 0.8)
	UI.Visible       = true
	QuickTween(UI.UIScale, 0.15, { Scale = 1 })
	QuickTween(UI, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
	task.wait(0.2)

	local rackEntries = {}
	local currentSlot = 0

	for i, entry in ipairs(results) do
		local trait        = entry.trait or "none"
		local traitDisplay = TRAIT_DISPLAY[trait] or TRAIT_DISPLAY["none"]
		local soundName    = TRAIT_SOUNDS[trait]   or TRAIT_SOUNDS["none"]
		local geodeColor   = entry.color or Color3.fromRGB(228, 228, 228)

		UI.LootLabel.Visible      = false
		UI.TraitLabel.Visible     = false
		UI.ContinueButton.Visible = false

		local halfA, halfB = GeodeAnimations:loadGeodeHalves(anchorCFrame, geodeTemplate, geodeColor)

		local effect
		local contentData = GeodeContents[entry.contentKey]
		if contentData and contentData.effect then
			local effectTemplate = particlesFolder:FindFirstChild(contentData.effect)
			if effectTemplate then
				effect = effectTemplate:Clone()
				effect:PivotTo(anchorCFrame)
				effect.Parent = workspace
			end
		end

		task.wait(0.1)

		Sound:playGlobal("FullCrack")

		task.wait(0.2)
		GeodeAnimations:animateCrack(halfA, halfB, anchorCFrame, QuickTween)
		pcall(Sound.playGlobal, Sound, soundName)

		UI.LootLabel.Text              = entry.displayName or ""
		UI.LootLabel.TextTransparency  = 1
		UI.LootLabel.Visible           = true

		UI.TraitLabel.Text             = traitDisplay.name
		UI.TraitLabel.TextColor3       = traitDisplay.color
		UI.TraitLabel.TextTransparency = 1
		UI.TraitLabel.Visible          = true

		QuickTween(UI.LootLabel,  0.3, { TextTransparency = 0 })
		QuickTween(UI.TraitLabel, 0.3, { TextTransparency = 0 })

		UI.ContinueButton.Text    = (i < #results) and "Next" or "Done"
		UI.ContinueButton.Visible = true

		local clicked = false
		local conn = UI.ContinueButton.Activated:Connect(function()
			clicked = true
		end)
		repeat task.wait() until clicked
		conn:Disconnect()

		local slotCF = GeodeAnimations:getSlotCFrame(rack, currentSlot, rackSlotCount, SLOT_WIDTH)
		GeodeAnimations:moveToRack(halfA, halfB, effect, slotCF, RACK_SCALE, QuickTween)
		table.insert(rackEntries, { halfA = halfA, halfB = halfB })
		currentSlot += 1

		if currentSlot >= rackSlotCount and i < #results then
			GeodeAnimations:clearRack(rackEntries, QuickTween)
			rackEntries = {}
			currentSlot = 0
		end

		if i < #results then
			QuickTween(UI.LootLabel,  0.2, { TextTransparency = 1 })
			QuickTween(UI.TraitLabel, 0.2, { TextTransparency = 1 }).Completed:Wait()
		end
	end

	GeodeAnimations:clearRack(rackEntries, QuickTween)

	UI.ContinueButton.Visible = false
	UI.LootLabel.Visible      = false
	UI.TraitLabel.Visible     = false
	QuickTween(UI.UIScale, 0.15, { Scale = 0.25 })
	QuickTween(UI, 0.15, { Position = UDim2.fromScale(0.5, 0.8) }).Completed:Wait()
	UI.Visible = false

	local character = engine.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.CameraType = Enum.CameraType.Custom

	GeodeService.revealCompleted:Fire()
end

return GeodeService
