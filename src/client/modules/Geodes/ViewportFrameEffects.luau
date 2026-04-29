local ViewportFrameEffects = {}

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local function tween(instance, duration, props, style, direction)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
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

return ViewportFrameEffects
