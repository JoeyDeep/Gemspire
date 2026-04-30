local ViewportFrameEffects = {}

local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function tween(instance, duration, props, style, direction)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

-- Clones a model, scales all parts outward from the model's pivot, colors them
-- Neon, and parents the clone inside the original so it follows and is destroyed
-- with it. Transparent parts (e.g. the Anchor) are left as-is.
--
-- The push direction is recomputed every Heartbeat based on the actual camera→model
-- vector so the outline stays behind the original regardless of viewing angle.
-- Only the delta between old and new push is applied each frame, since PivotTo
-- already moves all descendant parts (including the clone) as a unit.
function ViewportFrameEffects.outlineByClone(model, color, camera)
	local Z_BACK = 3.0
	local SCALE  = 1.04 * (14 + Z_BACK) / 14  -- compensates perspective reduction

	local outline = model:Clone()
	local pivotCF = model:GetPivot()

	local cloneParts = {}
	for _, part in pairs(outline:GetDescendants()) do
		if part:IsA("BasePart") then
			local localCF = pivotCF:ToObjectSpace(part.CFrame)
			part.CFrame   = pivotCF:ToWorldSpace(
				CFrame.new(localCF.Position * SCALE) * localCF.Rotation
			)
			part.Size       = part.Size * SCALE
			part.CastShadow = false
			if part.Transparency < 1 then
				part.Color        = color
				part.Material     = Enum.Material.Neon
				part.Transparency = 1
			end
			table.insert(cloneParts, part)
		end
	end

	outline.Name   = "Outline"
	outline.Parent = model

	for _, part in pairs(cloneParts) do
		if part.Material == Enum.Material.Neon then
			tween(part, 0.4, { Transparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end

	local lastPush = Vector3.zero

	local heartbeatConn
	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			heartbeatConn:Disconnect()
			return
		end
		local dir = model:GetPivot().Position - camera.CFrame.Position
		if dir.Magnitude < 0.001 then return end
		local newPush = dir.Unit * Z_BACK
		local delta   = newPush - lastPush
		if delta.Magnitude < 0.001 then return end
		lastPush = newPush
		for _, part in pairs(cloneParts) do
			if part.Parent then
				part.CFrame = part.CFrame + delta
			end
		end
	end)

	model.Destroying:Connect(function()
		heartbeatConn:Disconnect()
	end)
end

-- Creates an invisible hover/tap button that shows a TextLabel popup directly
-- above it. The popup is dismissed on MouseLeave, any tap outside the button,
-- or when the button itself is destroyed.
-- Returns the TextButton so the caller can position or destroy it.
function ViewportFrameEffects.hoverLabel(parent, position, size, text)
	local btn = Instance.new("TextButton")
	btn.Text               = ""
	btn.BackgroundTransparency = 1
	btn.Size               = size
	btn.Position           = position
	btn.AnchorPoint        = Vector2.new(0.5, 0.5)
	btn.ZIndex             = 3
	btn.Parent             = parent

	local popup    = nil
	local inputConn = nil

	local function hidePopup()
		if inputConn then inputConn:Disconnect() inputConn = nil end
		if popup and popup.Parent then popup:Destroy() end
		popup = nil
	end

	local function showPopup()
		if popup then return end

		local label = Instance.new("TextLabel")
		label.Name               = "HoverLabelPopup"
		label.RichText           = true
		label.Text               = text
		label.TextColor3         = Color3.new(1, 1, 1)
		label.BackgroundTransparency = 1
		label.Size               = UDim2.new(size.X.Scale, math.max(size.X.Offset, 300), 0, 40)
		label.AnchorPoint        = Vector2.new(0.5, 1)
		label.Position           = UDim2.new(
			position.X.Scale, position.X.Offset,
			position.Y.Scale, position.Y.Offset - size.Y.Offset / 2 - 6)
		label.ZIndex             = 4
		label.Parent             = parent
		popup = label

		inputConn = UserInputService.InputBegan:Connect(function(input)
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
				local p   = input.Position
				local abs = btn.AbsolutePosition
				local sz  = btn.AbsoluteSize
				if p.X < abs.X or p.X > abs.X + sz.X or p.Y < abs.Y or p.Y > abs.Y + sz.Y then
					hidePopup()
				end
			end
		end)
	end

	btn.MouseEnter:Connect(showPopup)
	btn.MouseLeave:Connect(hidePopup)
	btn.Activated:Connect(function()
		if popup then hidePopup() else showPopup() end
	end)
	btn.Destroying:Connect(hidePopup)

	return btn
end

-- Spawns a burst of neon sparks from a position inside a WorldModel.
--
-- config fields:
--   position     Vector3   origin of the burst
--   color        Color3    spark color (default white)
--   count        number    number of sparks (default 25)
--   speed        number    max travel distance in studs (default 4)
--   size         number    base sphere diameter in studs (default 0.15)
--   sizeVariance number    0-1 random size multiplier added on top (default 0.5)
--   duration     number    base lifetime in seconds (default 0.7)
--   upwardBias   number    0-1, how much to skew direction upward (default 0.4)
function ViewportFrameEffects.burst(worldModel, config)
	local origin      = config.position or Vector3.new(0, 0, 0)
	local color       = config.color or Color3.new(1, 1, 1)
	local count       = config.count or 25
	local speed       = config.speed or 4
	local baseSize    = config.size or 0.15
	local sizeVar     = config.sizeVariance or 0.5
	local duration    = config.duration or 0.7
	local upwardBias  = config.upwardBias or 0.4

	for _ = 1, count do
		local s = baseSize * (1 + math.random() * sizeVar)

		local spark = Instance.new("Part")
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.new(s, s, s)
		spark.Material = Enum.Material.Neon
		spark.Color = color
		spark.Transparency = 0
		spark.Anchored = true
		spark.CanCollide = false
		spark.CastShadow = false
		spark.CFrame = CFrame.new(origin)
		spark.Parent = worldModel

		local dx = math.random() * 2 - 1
		local dy = math.random() * upwardBias + (1 - upwardBias) * (math.random() * 2 - 1)
		local dz = math.random() * 2 - 1
		local dist = speed * (0.5 + math.random() * 0.5)
		local targetPos = origin + Vector3.new(dx, dy, dz).Unit * dist
		local life = duration * (0.6 + math.random() * 0.7)

		local cfVal = Instance.new("CFrameValue")
		cfVal.Value = spark.CFrame
		cfVal.Parent = spark
		cfVal:GetPropertyChangedSignal("Value"):Connect(function()
			if spark.Parent then
				spark.CFrame = cfVal.Value
			end
		end)

		tween(cfVal, life, { Value = CFrame.new(targetPos) })
		tween(spark, life, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			.Completed:Connect(function()
				spark:Destroy()
			end)
	end
end

-- Continuously emits neon balls with a trailing cylinder line behind them.
-- Returns a stop function to halt emission.
--
-- config fields:
--   position         Vector3   center of the emitter
--   color            Color3    particle color (default white)
--   rate             number    seconds between each batch (default 0.3)
--   countPerEmission number    streamers fired per batch (default 3)
--   spawnRadius      number    radius around origin to start each streamer (default 1.5)
--   speed            number    max travel distance in studs (default 9)
--   size             number    ball diameter in studs (default 0.18)
--   trailWidth       number    cylinder diameter in studs (default 0.06)
--   duration         number    base particle lifetime in seconds (default 1.2)
function ViewportFrameEffects.startStreamer(worldModel, config)
	local active          = true
	local origin          = config.position or Vector3.new(0, 0, 0)
	local color           = config.color or Color3.new(1, 1, 1)
	local rate            = config.rate or 0.3
	local countPerEmit    = config.countPerEmission or 3
	local spawnRadius     = config.spawnRadius or 1.5
	local speed           = config.speed or 9
	local ballSize        = config.size or 0.18
	local trailWidth      = config.trailWidth or 0.06
	local duration        = config.duration or 1.2

	local function cylinderCFrame(pos, dir)
		local up = math.abs(dir:Dot(Vector3.new(0, 1, 0))) < 0.99
			and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0)
		return CFrame.fromMatrix(pos, dir, dir:Cross(up).Unit)
	end

	local function emit()
		-- Pick a random point on the surface of a sphere, then launch perpendicular to it
		local sx = math.random() * 2 - 1
		local sy = math.random() * 2 - 1
		local sz = math.random() * 2 - 1
		local normal   = Vector3.new(sx, sy, sz).Unit
		local startPos = origin + normal * spawnRadius
		local dir      = normal  -- perpendicular to sphere surface

		local dist = speed * (0.5 + math.random() * 0.5)
		local life = duration * (0.7 + math.random() * 0.5)
		local targetPos = startPos + dir * dist

		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(ballSize, ballSize, ballSize)
		ball.Material = Enum.Material.Neon
		ball.Color = color
		ball.Transparency = 0
		ball.Anchored = true
		ball.CanCollide = false
		ball.CastShadow = false
		ball.CFrame = CFrame.new(startPos)
		ball.Parent = worldModel

		local trail = Instance.new("Part")
		trail.Shape = Enum.PartType.Cylinder
		trail.Size = Vector3.new(0.001, trailWidth, trailWidth)
		trail.Material = Enum.Material.Neon
		trail.Color = color
		trail.Transparency = 0.35
		trail.Anchored = true
		trail.CanCollide = false
		trail.CastShadow = false
		trail.CFrame = CFrame.new(startPos)
		trail.Parent = worldModel

		local cfVal = Instance.new("CFrameValue")
		cfVal.Value = ball.CFrame
		cfVal.Parent = ball
		cfVal:GetPropertyChangedSignal("Value"):Connect(function()
			if ball.Parent then ball.CFrame = cfVal.Value end
		end)

		local conn = RunService.Heartbeat:Connect(function()
			if not ball.Parent or not trail.Parent then return end
			local trailVec = ball.CFrame.Position - startPos
			local len = trailVec.Magnitude
			if len < 0.01 then return end
			trail.Size = Vector3.new(len, trailWidth, trailWidth)
			trail.CFrame = cylinderCFrame(startPos + trailVec * 0.5, trailVec.Unit)
		end)

		tween(cfVal, life, { Value = CFrame.new(targetPos) })
		tween(ball, life, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(trail, life, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			.Completed:Connect(function()
				conn:Disconnect()
				ball:Destroy()
				trail:Destroy()
			end)
	end

	task.spawn(function()
		while active do
			for _ = 1, countPerEmit do
				emit()
			end
			task.wait(rate)
		end
	end)

	return function()
		active = false
	end
end

-- Randomly flickers "Part" children inside geode halves to Neon, creating a sparkle.
-- Returns a stop function.
function ViewportFrameEffects.startSparkle(halfA, halfB)
	local active = true
	local parts  = {}
	for _, model in pairs({ halfA, halfB }) do
		local colored = model:FindFirstChild("Colored")
		if colored then
			for _, part in pairs(colored:GetDescendants()) do
				if part:IsA("BasePart") and part.Name == "Part" then
					table.insert(parts, { part = part, origMat = part.Material, origColor = part.Color })
				end
			end
		end
	end
	if #parts > 0 then
		task.spawn(function()
			while active do
				for _ = 1, math.random(1, 4) do
					local entry = parts[math.random(1, #parts)]
					local part  = entry.part
					if part and part.Parent then
						part.Material = Enum.Material.Neon
						part.Color    = entry.origColor:Lerp(Color3.new(1, 1, 1), 0.85)
						local dur = math.random(10, 35) / 100
						task.delay(dur, function()
							if part and part.Parent then
								part.Material = entry.origMat
								part.Color    = entry.origColor
							end
						end)
					end
				end
				task.wait(math.random(6, 18) / 100)
			end
		end)
	end
	return function() active = false end
end

-- Orbits a neon ball with a trailing cylinder around the model's pivot.
-- The orbit plane is parallel to the camera's view plane (uses camera right/up
-- vectors), so it always faces the viewer regardless of where the model is.
-- The ball and trail are parented to the model so they move with PivotTo
-- and are destroyed when the model is destroyed.
-- Returns a stop function.
--
-- config fields:
--   camera     Camera   viewport camera (required for camera-plane orbit)
--   radius     number   orbit radius in studs (default 4)
--   color      Color3   ball and trail color (default white)
--   speed      number   radians per second (default 1)
--   pattern    string   "smooth" (default) | "shaky" | "oscillate" | "spiral"
--   jitter     number   shaky: max offset per axis in studs (default 0.3)
--   amplitude  number   oscillate: peak along camera up axis in studs (default 1.5)
--   range      number   spiral: radius variance in studs (default 1.0)
--   freq       number   spiral: oscillation frequency in Hz (default 2)
--   initialAngle number  starting angle in radians (default 0)
function ViewportFrameEffects.customOrbit(model, config)
	local camera  = config.camera
	local radius  = config.radius or 4
	local color   = config.color  or Color3.new(1, 1, 1)
	local speed   = config.speed  or 1
	local pattern = config.pattern or "smooth"

	-- Pattern helpers — each returns a (angle, elapsed, right, up) -> Vector3 function.
	-- Shaky uses multi-frequency sine waves per axis so the path is continuous (no
	-- teleporting) but erratic; harmonic overtones give it a sharp zigzag feel.
	local function makeSmooth()
		return function() return Vector3.zero end
	end

	local function makeShaky(jitter)
		return function(_, elapsed)
			local x = math.sin(elapsed * 8.0)       + 0.4 * math.sin(elapsed * 13.0)
			local y = math.sin(elapsed * 7.0 + 1.5) + 0.4 * math.sin(elapsed * 11.0 + 0.7)
			local z = math.sin(elapsed * 6.0 + 3.0) + 0.4 * math.sin(elapsed *  9.0 + 1.2)
			return Vector3.new(x, y, z) * (jitter / 1.4)
		end
	end

	local function makeOscillate(amplitude)
		return function(angle, _, _, up)
			return up * math.sin(angle * 2) * amplitude
		end
	end

	local function makeSpiral(range, freq)
		return function(angle, elapsed, right, up)
			local extra = math.sin(elapsed * freq) * range
			return right * math.cos(angle) * extra + up * math.sin(angle) * extra
		end
	end

	local patternFn
	if pattern == "shaky" then
		patternFn = makeShaky(config.jitter or 0.3)
	elseif pattern == "oscillate" then
		patternFn = makeOscillate(config.amplitude or 1.5)
	elseif pattern == "spiral" then
		patternFn = makeSpiral(config.range or 1.0, config.freq or 2)
	else
		patternFn = makeSmooth()
	end

	local BALL_SIZE    = 0.3
	local GHOST_LIFE   = 0.8  -- seconds for ghost to shrink and fade
	local GHOST_RATE   = 0.04 -- seconds between ghost spawns

	local ball = Instance.new("Part")
	ball.Shape        = Enum.PartType.Ball
	ball.Size         = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
	ball.Material     = Enum.Material.Neon
	ball.Color        = color
	ball.Transparency = 0
	ball.Anchored     = true
	ball.CanCollide   = false
	ball.CastShadow   = false
	ball.CFrame       = model:GetPivot()
	ball.Parent       = model

	local active      = true
	local angle       = config.initialAngle or 0
	local elapsed     = 0
	local ghostTimer  = 0

	model.Destroying:Connect(function() active = false end)

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not active or not model.Parent then
			conn:Disconnect()
			if ball.Parent then ball:Destroy() end
			return
		end

		angle      = angle     + speed * dt
		elapsed    = elapsed   + dt
		ghostTimer = ghostTimer + dt

		local camCF = camera and camera.CFrame or CFrame.new()
		local right = camCF.RightVector
		local up    = camCF.UpVector
		local pivot = model:GetPivot().Position

		local basePos = pivot + right * math.cos(angle) * radius + up * math.sin(angle) * radius
		local pos     = basePos + patternFn(angle, elapsed, right, up)

		ball.CFrame = CFrame.new(pos)

		if ghostTimer >= GHOST_RATE then
			ghostTimer = 0
			local ghost = Instance.new("Part")
			ghost.Shape        = Enum.PartType.Ball
			ghost.Size         = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
			ghost.Material     = Enum.Material.Neon
			ghost.Color        = color
			ghost.Transparency = 0
			ghost.Anchored     = true
			ghost.CanCollide   = false
			ghost.CastShadow   = false
			ghost.CFrame       = CFrame.new(pos)
			ghost.Parent       = model

			local tiny = Vector3.new(0.001, 0.001, 0.001)
			tween(ghost, GHOST_LIFE, { Size = tiny, Transparency = 1 },
				Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				.Completed:Connect(function()
					if ghost.Parent then ghost:Destroy() end
				end)
		end
	end)

	return function()
		active = false
		conn:Disconnect()
		if ball.Parent then ball:Destroy() end
	end
end

return ViewportFrameEffects
