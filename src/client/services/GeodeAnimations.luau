local GeodeAnimations = {}

local engine

function GeodeAnimations.init(engineModule)
	engine = engineModule
end

function GeodeAnimations:colorGeodeModel(model, color)
	local colored = model:FindFirstChild("Colored")
	if not colored then return end
	for _, part in pairs(colored:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
end

function GeodeAnimations:loadGeodeHalves(anchorCFrame, geodeTemplate, color)
	local halfA = geodeTemplate:Clone()
	local halfB = geodeTemplate:Clone()
	self:colorGeodeModel(halfA, color)
	self:colorGeodeModel(halfB, color)
	halfA:PivotTo(anchorCFrame * CFrame.Angles(0, 0, math.rad(-90)))
	halfB:PivotTo(anchorCFrame * CFrame.Angles(0, 0, math.rad(90)))
	halfA.Parent = workspace
	halfB.Parent = workspace
	return halfA, halfB
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
	local goalB = anchorCFrame * CFrame.new(0.9, 0, 0) * CFrame.Angles(0, math.rad(30), 0) * CFrame.Angles(0, 0, math.rad(90))

	QuickTween(aCFVal, 0.4, { Value = goalA })
	QuickTween(bCFVal, 0.4, { Value = goalB }).Completed:Wait()

	connA:Disconnect()
	connB:Disconnect()
	aCFVal:Destroy()
	bCFVal:Destroy()
end

-- Returns the world CFrame for a slot on the rack
function GeodeAnimations:getSlotCFrame(rack, slotIndex, slotCount, slotWidth)
	local totalWidth = slotCount * slotWidth
	local localX = -totalWidth / 2 + slotWidth / 2 + slotIndex * slotWidth
	return rack.CFrame * CFrame.new(localX, rack.Size.Y / 2, 0)
end

-- Scales the geode down and tweens it to its rack slot position
function GeodeAnimations:moveToRack(halfA, halfB, effect, slotCFrame, rackScale, QuickTween)
	if effect and effect.Parent then
		effect:Destroy()
	end

	halfA:ScaleTo(rackScale)
	halfB:ScaleTo(rackScale)

	local offset = 0.9 * rackScale
	local targetA = slotCFrame * CFrame.new(-offset, 0, 0) * CFrame.Angles(0, math.rad(-30), 0) * CFrame.Angles(0, 0, math.rad(-90))
	local targetB = slotCFrame * CFrame.new(offset, 0, 0) * CFrame.Angles(0, math.rad(30), 0) * CFrame.Angles(0, 0, math.rad(90))

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

	QuickTween(aCFVal, 0.3, { Value = targetA })
	QuickTween(bCFVal, 0.3, { Value = targetB }).Completed:Wait()

	connA:Disconnect()
	connB:Disconnect()
	aCFVal:Destroy()
	bCFVal:Destroy()
end

-- Fades out and destroys all models currently on the rack
function GeodeAnimations:clearRack(rackEntries, QuickTween)
	if #rackEntries == 0 then return end
	for _, e in pairs(rackEntries) do
		for _, m in pairs({ e.halfA, e.halfB }) do
			if m and m.Parent then
				for _, part in pairs(m:GetDescendants()) do
					if part:IsA("BasePart") then
						QuickTween(part, 0.2, { Transparency = 1 })
					end
				end
			end
		end
	end
	task.wait(0.3)
	for _, e in pairs(rackEntries) do
		if e.halfA and e.halfA.Parent then e.halfA:Destroy() end
		if e.halfB and e.halfB.Parent then e.halfB:Destroy() end
	end
end

return GeodeAnimations
