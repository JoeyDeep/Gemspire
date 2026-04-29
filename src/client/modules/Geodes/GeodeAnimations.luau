local GeodeAnimations = {}

local engine
local blackOverlay

local function getBlackOverlay()
	if blackOverlay and blackOverlay.Parent then return blackOverlay end
	local frame = Instance.new("Frame")
	frame.Name = "GeodeBlackFade"
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0, 0)
	frame.ZIndex = 100
	frame.Parent = engine.PlayerGui.UI
	blackOverlay = frame
	return frame
end

function GeodeAnimations.init(engineModule)
	engine = engineModule
end

-- ─── Fade ────────────────────────────────────────────────────────────────────

function GeodeAnimations:fadeToBlack(duration)
	local QuickTween = engine:get("QuickTween")
	QuickTween(getBlackOverlay(), duration or 0.3, { BackgroundTransparency = 0 }).Completed:Wait()
end

function GeodeAnimations:fadeFromBlack(duration)
	local QuickTween = engine:get("QuickTween")
	QuickTween(getBlackOverlay(), duration or 0.3, { BackgroundTransparency = 1 }).Completed:Wait()
end

-- ─── Geode model helpers ─────────────────────────────────────────────────────

function GeodeAnimations:colorGeodeModel(model, color)
	local colored = model:FindFirstChild("Colored")
	if not colored then return end
	for _, part in pairs(colored:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
end


function GeodeAnimations:loadGeodeHalvesInto(parent, anchorCFrame, geodeTemplate, color)
	local geodeModel = Instance.new("Model")
	geodeModel.Name  = "Geode"

	-- Invisible anchor at the crack center so GetPivot() is always consistent
	local anchor          = Instance.new("Part")
	anchor.Name           = "Anchor"
	anchor.Size           = Vector3.new(0.01, 0.01, 0.01)
	anchor.Transparency   = 1
	anchor.Anchored       = true
	anchor.CanCollide     = false
	anchor.CastShadow     = false
	anchor.CFrame         = anchorCFrame
	anchor.Parent         = geodeModel
	geodeModel.PrimaryPart = anchor

	local halfA = geodeTemplate:Clone()
	local halfB = geodeTemplate:Clone()
	self:colorGeodeModel(halfA, color)
	self:colorGeodeModel(halfB, color)
	halfA:PivotTo(anchorCFrame * CFrame.Angles(0, 0, math.rad(-90)))
	halfB:PivotTo(anchorCFrame * CFrame.Angles(0, 0, math.rad(90)))
	halfA.Parent      = geodeModel
	halfB.Parent      = geodeModel
	geodeModel.Parent = parent
	return geodeModel, halfA, halfB
end

-- ─── Crack animation ─────────────────────────────────────────────────────────

function GeodeAnimations:shakeGeodeHalves(halfA, halfB, QuickTween)
	local aCFVal = Instance.new("CFrameValue")
	local bCFVal = Instance.new("CFrameValue")
	aCFVal.Value = halfA:GetPivot()
	bCFVal.Value = halfB:GetPivot()

	local connA = aCFVal:GetPropertyChangedSignal("Value"):Connect(function()
		halfA:PivotTo(aCFVal.Value)
	end)
	local connB = bCFVal:GetPropertyChangedSignal("Value"):Connect(function()
		halfB:PivotTo(bCFVal.Value)
	end)

	local baseA = aCFVal.Value
	local baseB = bCFVal.Value
	local step  = 0.065
	local shakes = {
		{ a =  0.12, b = -0.12 },
		{ a = -0.10, b =  0.10 },
		{ a =  0.07, b = -0.07 },
		{ a =  0,    b =  0    },
	}
	for _, s in ipairs(shakes) do
		QuickTween(aCFVal, step, { Value = baseA + Vector3.new(0, s.a, 0) })
		QuickTween(bCFVal, step, { Value = baseB + Vector3.new(0, s.b, 0) }).Completed:Wait()
	end

	connA:Disconnect()
	connB:Disconnect()
	aCFVal:Destroy()
	bCFVal:Destroy()
end

function GeodeAnimations:animateCrack(halfA, halfB, anchorCFrame, QuickTween)
	local aCFVal = Instance.new("CFrameValue")
	local bCFVal = Instance.new("CFrameValue")
	aCFVal.Value = halfA:GetPivot()
	bCFVal.Value = halfB:GetPivot()

	local connA = aCFVal:GetPropertyChangedSignal("Value"):Connect(function()
		halfA:PivotTo(aCFVal.Value)
	end)
	local connB = bCFVal:GetPropertyChangedSignal("Value"):Connect(function()
		halfB:PivotTo(bCFVal.Value)
	end)

	local goalA = anchorCFrame * CFrame.new(-0.9, 0, 0) * CFrame.Angles(0, math.rad(-30), 0) * CFrame.Angles(0, 0, math.rad(-90))
	local goalB = anchorCFrame * CFrame.new(0.9, 0, 0)  * CFrame.Angles(0, math.rad(30), 0)  * CFrame.Angles(0, 0, math.rad(90))

	QuickTween(aCFVal, 0.4, { Value = goalA })
	QuickTween(bCFVal, 0.4, { Value = goalB }).Completed:Wait()

	connA:Disconnect()
	connB:Disconnect()
	aCFVal:Destroy()
	bCFVal:Destroy()
end

-- ─── Viewport setup ──────────────────────────────────────────────────────────

function GeodeAnimations:setupViewport(viewport)
	local worldModel = viewport:FindFirstChildOfClass("WorldModel")
	if not worldModel then
		worldModel = Instance.new("WorldModel")
		worldModel.Parent = viewport
	end
	for _, child in pairs(worldModel:GetChildren()) do
		child:Destroy()
	end
	local cam = viewport:FindFirstChildOfClass("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Parent = viewport
	end
	cam.CFrame     = CFrame.new(0, 1.5, 14)
	cam.FieldOfView = 60
	viewport.CurrentCamera        = cam
	viewport.BackgroundTransparency = 1
	viewport.ZIndex               = 2
	return worldModel
end

-- ─── Slot / rack ─────────────────────────────────────────────────────────────

local SLOT_SPACING = 5.5
local SLOT_Y       = -12
local SLOT_Z       = -36

function GeodeAnimations:moveToViewportSlot(geodeModel, effect, slotIndex, totalCount, QuickTween)
	if effect and effect.Parent then effect:Destroy() end

	local slotX    = (slotIndex - (totalCount - 1) / 2) * SLOT_SPACING
	local targetCF = CFrame.new(slotX, SLOT_Y, SLOT_Z)

	local cfVal = Instance.new("CFrameValue")
	cfVal.Value = geodeModel:GetPivot()

	local conn = cfVal:GetPropertyChangedSignal("Value"):Connect(function()
		geodeModel:PivotTo(cfVal.Value)
	end)

	QuickTween(cfVal, 0.4, { Value = targetCF }).Completed:Wait()

	conn:Disconnect()
	cfVal:Destroy()
end


function GeodeAnimations:clearRack(rackEntries, QuickTween)
	if #rackEntries == 0 then return end
	for _, e in pairs(rackEntries) do
		if e.geode and e.geode.Parent then
			for _, part in pairs(e.geode:GetDescendants()) do
				if part:IsA("BasePart") then
					QuickTween(part, 0.2, { Transparency = 1 })
				end
			end
		end
	end
	task.wait(0.3)
	for _, e in pairs(rackEntries) do
		if e.geode and e.geode.Parent then e.geode:Destroy() end
	end
end

return GeodeAnimations
