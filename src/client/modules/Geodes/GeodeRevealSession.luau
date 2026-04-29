local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewportFrameEffects = require(script.Parent.ViewportFrameEffects)

local GeodeRevealSession = {}
GeodeRevealSession.__index = GeodeRevealSession

local MAX_RACK  = 15
local ANCHOR_CF = CFrame.new(0, 1.5, 0)

local DEFAULT_LIGHT_COLOR     = Color3.fromRGB(140, 140, 140)
local DEFAULT_LIGHT_DIRECTION = Vector3.new(-1, -1, -1)
local DEFAULT_AMBIENT         = Color3.fromRGB(200, 200, 200)

local RARITY_ORB_COLORS = {
	[2] = Color3.fromRGB(80,  140, 255), -- uncommon: blue
	[3] = Color3.fromRGB(160, 60,  255), -- rare: purple
	[4] = Color3.fromRGB(255, 68, 0),  -- legendary: orange
}

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

local function toHex(c)
	return string.format("%02X%02X%02X",
		math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

-- ─── Constructor ─────────────────────────────────────────────────────────────

function GeodeRevealSession.new(engine, results)
	local self = setmetatable({}, GeodeRevealSession)
	self.results         = results
	self.QuickTween      = engine:get("QuickTween")
	self.Sound           = engine:get("Sound")
	self.GeodeAnimations = engine:get("GeodeAnimations")
	self.GeodeContents   = engine:get("GeodeContents")
	self.Loot            = engine:get("Loot")
	self.LootTraits      = engine:get("LootTraits")
	self.UI              = engine.PlayerGui.UI.GeodeReveal
	self.player          = engine.player
	self.geodeTemplate   = ReplicatedStorage.Storage.Geode.Geode
	self.particlesFolder = ReplicatedStorage.Storage.Particles
	-- mutable session state
	self.worldModel        = nil
	self.viewport          = nil
	self.humSound          = nil
	self.slotIndex         = 0
	self.rackEntries       = {}
	self.activeGeode       = nil
	self._stopRays    = nil
	self._stopLight   = nil
	self._stopStreamer = nil
	self._stopSparkle  = nil
	return self
end

-- ─── Public entry point ───────────────────────────────────────────────────────

function GeodeRevealSession:run()
	if not self.results or #self.results == 0 then
		self.GeodeAnimations:fadeFromBlack(0.3)
		self:_restoreCamera()
		return
	end
	self:_setup()
	for i, entry in ipairs(self.results) do
		self:_presentGeode(i, entry)
		self:_waitForClick()
		self:_dismissGeode(i)
	end
	self:_teardown()
end

-- ─── Setup / teardown ────────────────────────────────────────────────────────

function GeodeRevealSession:_setup()
	local vp        = self.UI.MainViewport
	self.viewport   = vp
	self.worldModel = self.GeodeAnimations:setupViewport(vp)

	self.UI.BackgroundColor3      = Color3.new(0, 0, 0)
	self.UI.BackgroundTransparency = 0
	self.UI.UIScale.Scale         = 1
	self.UI.Position              = UDim2.fromScale(0.5, 0.5)
	self.UI.Visible               = true

	self.humSound = self.Sound:playGlobal("GeodeRevealHum", 0)
	if self.humSound then
		self.QuickTween(self.humSound, 0.6, { Volume = 1 })
	end
end

function GeodeRevealSession:_teardown()
	local GA = self.GeodeAnimations
	self:_destroyOverlayButtons()
	GA:clearRack(self.rackEntries, self.QuickTween)
	if self.worldModel then
		for _, child in pairs(self.worldModel:GetChildren()) do child:Destroy() end
	end

	self.UI.ContinueButton.Visible = false
	self.UI.LootLabel.Visible      = false

	if self.humSound and self.humSound.Parent then
		self.QuickTween(self.humSound, 0.4, { Volume = 0 }).Completed:Wait()
		self.humSound:Stop()
	end

	GA:fadeToBlack(0.3)
	self.UI.Visible               = false
	self.UI.BackgroundTransparency = 1

	self:_restoreCamera()
	GA:fadeFromBlack(0.4)
end

function GeodeRevealSession:_restoreCamera()
	local camera    = workspace.CurrentCamera
	local character = self.player.Character
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then camera.CameraSubject = humanoid end
	camera.CameraType = Enum.CameraType.Custom
end

-- ─── Per-geode orchestration ─────────────────────────────────────────────────

function GeodeRevealSession:_presentGeode(i, entry)
	local trait          = entry.trait or "none"
	local traitDisplay   = TRAIT_DISPLAY[trait] or TRAIT_DISPLAY["none"]
	local geodeColor     = entry.color or Color3.fromRGB(228, 228, 228)
	local colorSecondary = entry.colorSecondary or geodeColor

	local pageStart   = math.floor((i - 1) / MAX_RACK) * MAX_RACK
	local countInPage = math.min(#self.results - pageStart, MAX_RACK)

	self.UI.LootLabel.Visible      = false
	self.UI.ContinueButton.Visible = false

	local geodeModel, halfA, halfB = self:_loadGeode(geodeColor, colorSecondary)
	local effect                   = self:_loadEffect(entry)

	self:_crack(halfA, halfB, i == 1, TRAIT_SOUNDS[trait] or TRAIT_SOUNDS.none, geodeColor)
	self:_startEffects(halfA, halfB, geodeModel, geodeColor, entry)
	self:_showLabel(entry, i, trait, traitDisplay)

	self.activeGeode = { geodeModel = geodeModel, halfA = halfA, halfB = halfB, effect = effect, countInPage = countInPage, entry = entry }
end

function GeodeRevealSession:_dismissGeode(i)
	local ag = self.activeGeode
	self.activeGeode = nil
	self:_stopEffects()
	self:_sendToSlot(ag.geodeModel, ag.effect, ag.countInPage, ag.entry)
	self:_clearPageIfFull(i)

	if i < #self.results then
		self.QuickTween(self.UI.LootLabel, 0.2, { TextTransparency = 1 }).Completed:Wait()
	end
end

-- ─── Step helpers ────────────────────────────────────────────────────────────

function GeodeRevealSession:_loadGeode(geodeColor, colorSecondary)
	local geodeModel, halfA, halfB = self.GeodeAnimations:loadGeodeHalvesInto(
		self.worldModel, ANCHOR_CF, self.geodeTemplate, geodeColor)
	for _, half in pairs({ halfA, halfB }) do
		local innerShell = half:FindFirstChild("InnerShell", true)
		if innerShell and innerShell:IsA("BasePart") then
			innerShell.Color = colorSecondary
		end
	end
	return geodeModel, halfA, halfB
end

function GeodeRevealSession:_loadEffect(entry)
	local contentData = self.GeodeContents[entry.contentKey]
	if contentData and contentData.effect then
		local template = self.particlesFolder:FindFirstChild(contentData.effect)
		if template then
			local effect = template:Clone()
			effect:PivotTo(ANCHOR_CF)
			effect.Parent = self.worldModel
			return effect
		end
	end
	return nil
end

function GeodeRevealSession:_crack(halfA, halfB, isFirst, soundName, geodeColor)
	local GA = self.GeodeAnimations
	if isFirst then
		GA:shakeGeodeHalves(halfA, halfB, self.QuickTween)
		GA:animateCrack(halfA, halfB, ANCHOR_CF, self.QuickTween)
		pcall(self.Sound.playGlobal, self.Sound, soundName)
		GA:fadeFromBlack(0.4)
	else
		self.Sound:playGlobal("FullCrack")
		GA:shakeGeodeHalves(halfA, halfB, self.QuickTween)
		GA:animateCrack(halfA, halfB, ANCHOR_CF, self.QuickTween)
		pcall(self.Sound.playGlobal, self.Sound, soundName)
	end
	ViewportFrameEffects.burst(self.worldModel, {
		position     = ANCHOR_CF.Position,
		color        = geodeColor,
		count        = 30,
		speed        = 7,
		size         = 0.12,
		sizeVariance = 0.6,
		duration     = 0.9,
		upwardBias   = 0.5,
	})
end

function GeodeRevealSession:_showLabel(entry, i, trait, traitDisplay)
	local label       = self.UI.LootLabel
	local contentName = (self.Loot[entry.contentKey] and self.Loot[entry.contentKey].name)
		or entry.contentKey or "Unknown"
	if trait ~= "none" then
		label.Text = string.format(
			'<font color="#%s">%s</font><font color="#FFFFFF"> %s Geode</font>',
			toHex(traitDisplay.color), traitDisplay.name, contentName)
	else
		label.Text = string.format('<font color="#FFFFFF">%s Geode</font>', contentName)
	end
	label.TextTransparency         = 1
	label.Visible                  = true
	self.UI.ContinueButton.Text    = (i < #self.results) and "Next" or "Done"
	self.UI.ContinueButton.Visible = true
	self.QuickTween(label, 0.3, { TextTransparency = 0 })
end

function GeodeRevealSession:_waitForClick()
	local done = false
	local clickConn = self.UI.ContinueButton.Activated:Connect(function() done = true end)
	local charConn  = self.player.CharacterRemoving:Connect(function() done = true end)
	repeat task.wait() until done
	clickConn:Disconnect()
	charConn:Disconnect()
end

function GeodeRevealSession:_sendToSlot(geodeModel, effect, countInPage, entry)
	self.GeodeAnimations:moveToViewportSlot(
		geodeModel, effect, self.slotIndex, countInPage, self.QuickTween)
	local button = self:_createOverlayButton(geodeModel, entry)
	table.insert(self.rackEntries, { geode = geodeModel, button = button })
	self.slotIndex += 1
end

function GeodeRevealSession:_clearPageIfFull(i)
	if self.slotIndex >= MAX_RACK and i < #self.results then
		self:_destroyOverlayButtons()
		self.GeodeAnimations:clearRack(self.rackEntries, self.QuickTween)
		self.rackEntries = {}
		self.slotIndex   = 0
	end
end

function GeodeRevealSession:_destroyOverlayButtons()
	for _, e in pairs(self.rackEntries) do
		if e.button and e.button.Parent then e.button:Destroy() end
	end
end

-- ─── Rack overlay ────────────────────────────────────────────────────────────

function GeodeRevealSession:_projectToScale(worldPos)
	local cam     = self.viewport.CurrentCamera
	local vpSize  = self.viewport.AbsoluteSize
	local aspect  = vpSize.X / vpSize.Y
	local localPos = cam.CFrame:PointToObjectSpace(worldPos)
	local depth    = -localPos.Z
	if depth <= 0 then return 0.5, 0.5 end
	local halfTan = math.tan(math.rad(cam.FieldOfView / 2))
	local u = ( localPos.X / (depth * halfTan * aspect) + 1) / 2
	local v = (-localPos.Y / (depth * halfTan)           + 1) / 2
	return u, v
end

function GeodeRevealSession:_buildLabelText(entry)
	local trait        = entry.trait or "none"
	local traitDisplay = TRAIT_DISPLAY[trait] or TRAIT_DISPLAY["none"]
	local contentName  = (self.Loot[entry.contentKey] and self.Loot[entry.contentKey].name)
		or entry.contentKey or "Unknown"
	if trait ~= "none" then
		return string.format(
			'<font color="#%s">%s</font><font color="#FFFFFF"> %s Geode</font>',
			toHex(traitDisplay.color), traitDisplay.name, contentName)
	else
		return string.format('<font color="#FFFFFF">%s Geode</font>', contentName)
	end
end

function GeodeRevealSession:_createOverlayButton(geodeModel, entry)
	local centerPos = geodeModel:GetPivot().Position
	local u, v      = self:_projectToScale(centerPos)
	return ViewportFrameEffects.hoverLabel(
		self.UI,
		UDim2.fromScale(u, v),
		UDim2.fromOffset(90, 70),
		self:_buildLabelText(entry)
	)
end

-- ─── Effect managers ─────────────────────────────────────────────────────────

function GeodeRevealSession:_startEffects(halfA, halfB, geodeModel, color, entry)
	self._stopRays    = self:_startRays()
	self._stopLight   = self:_startViewportLight(color)
	self._stopStreamer = ViewportFrameEffects.startStreamer(self.worldModel, {
		position         = ANCHOR_CF.Position,
		color            = color:Lerp(Color3.new(1, 1, 1), 0.3),
		rate             = 0.3,
		countPerEmission = 3,
		spawnRadius      = 1.5,
		speed            = 9,
		size             = 0.18,
		trailWidth       = 0.06,
		duration         = 1.2,
	})
	self._stopSparkle = ViewportFrameEffects.startSparkle(halfA, halfB)

	local lootData = entry and self.Loot[entry.contentKey]
	local orbColor = lootData and RARITY_ORB_COLORS[lootData.rarity]
	if orbColor then
		ViewportFrameEffects.outlineByClone(geodeModel, orbColor, self.viewport.CurrentCamera)
	end

	local traitData = self.LootTraits and self.LootTraits[entry.trait or ""]
	if traitData and traitData.orbitVisual then
		local ov = traitData.orbitVisual
		local n  = ov.numberOfOrbits or 1
		for i = 1, n do
			local cfg = {}
			for k, v in pairs(ov.orbitConfig) do cfg[k] = v end
			cfg.initialAngle = (2 * math.pi * (i - 1)) / n
			cfg.camera       = self.viewport.CurrentCamera
			ViewportFrameEffects.customOrbit(geodeModel, cfg)
		end
	end
end

function GeodeRevealSession:_stopEffects()
	if self._stopRays    then self._stopRays()    self._stopRays    = nil end
	if self._stopLight   then self._stopLight()   self._stopLight   = nil end
	if self._stopStreamer then self._stopStreamer() self._stopStreamer = nil end
	if self._stopSparkle then self._stopSparkle() self._stopSparkle = nil end
end

function GeodeRevealSession:_startRays()
	local spinning = true
	local rays     = self.UI.Rays
	local spinRays = self.UI.SpinRays
	rays.ImageTransparency     = 1
	spinRays.ImageTransparency = 1
	self.QuickTween(rays,     0.5, { ImageTransparency = 0.77 })
	self.QuickTween(spinRays, 0.5, { ImageTransparency = 0 })
	task.spawn(function()
		while spinning do
			spinRays.Rotation += 0.3
			task.wait()
		end
	end)
	return function()
		spinning = false
		self.QuickTween(rays,     0.3, { ImageTransparency = 1 })
		self.QuickTween(spinRays, 0.3, { ImageTransparency = 1 })
	end
end

function GeodeRevealSession:_startViewportLight(color)
	local active        = true
	local vp            = self.viewport
	local brightLight   = color:Lerp(Color3.new(1, 1, 1), 0.92)
	local brightAmbient = color:Lerp(Color3.new(1, 1, 1), 0.88)
	self.QuickTween(vp, 0.5, { LightColor = brightLight })
	self.QuickTween(vp, 0.5, { Ambient = brightAmbient })
	local angle = 0
	task.spawn(function()
		while active do
			angle = (angle + 0.4) % 360
			local rad = math.rad(angle)
			vp.LightDirection = Vector3.new(math.sin(rad) - 0.5, -1, math.cos(rad) - 0.5)
			task.wait()
		end
	end)
	return function()
		active = false
		self.QuickTween(vp, 0.4, { LightColor = DEFAULT_LIGHT_COLOR })
		self.QuickTween(vp, 0.4, { Ambient    = DEFAULT_AMBIENT })
		self.QuickTween(vp, 0.4, { LightDirection = DEFAULT_LIGHT_DIRECTION })
	end
end

return GeodeRevealSession
