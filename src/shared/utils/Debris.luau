local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local InstanceCache = require(ReplicatedStorage.Packages.InstanceCache)

local Debris = {
	cache = nil,
	cacheFolder = nil,
	cacheSize = 50,
	_warnedCollisionGroup = false,
	_spawnToken = 0,
}

local DEFAULT_SIZE = Vector3.new(0.4, 0.4, 0.4)
local DEFAULT_MATERIAL = Enum.Material.Rock
local DEFAULT_COLOR = Color3.fromRGB(120, 120, 120)

local function ensureEntitiesFolder()
	local entities = workspace:FindFirstChild("Entities")
	if not entities then
		entities = Instance.new("Folder")
		entities.Name = "Entities"
		entities.Parent = workspace
	end
	return entities
end

local function ensureCacheFolder()
	if Debris.cacheFolder and Debris.cacheFolder.Parent then
		return Debris.cacheFolder
	end

	local entities = ensureEntitiesFolder()
	local cacheFolder = entities:FindFirstChild("DebrisCache")
	if not cacheFolder then
		cacheFolder = Instance.new("Folder")
		cacheFolder.Name = "DebrisCache"
		cacheFolder.Parent = entities
	end

	Debris.cacheFolder = cacheFolder
	return cacheFolder
end

local function ensureCache()
	if Debris.cache then
		return Debris.cache
	end

	local template = Instance.new("Part")
	template.Name = "DebrisPart"
	template.Size = DEFAULT_SIZE
	template.Anchored = true
	template.CanCollide = false
	template.CanTouch = false
	template.TopSurface = Enum.SurfaceType.Smooth
	template.BottomSurface = Enum.SurfaceType.Smooth

	Debris.cache = InstanceCache.new(template, Debris.cacheSize, ensureCacheFolder())
	return Debris.cache
end

local function setCollisionGroup(part)
	local ok = pcall(function()
		part.CollisionGroup = "Debris"
	end)
	if not ok and not Debris._warnedCollisionGroup then
		Debris._warnedCollisionGroup = true
		warn("Debris: CollisionGroup 'Debris' not found.")
	end
end

local function resolveSize(sizeSpec)
	if typeof(sizeSpec) == "Vector3" then
		return sizeSpec
	end
	if type(sizeSpec) == "table" and typeof(sizeSpec.min) == "Vector3" and typeof(sizeSpec.max) == "Vector3" then
		return Vector3.new(
			math.random() * (sizeSpec.max.X - sizeSpec.min.X) + sizeSpec.min.X,
			math.random() * (sizeSpec.max.Y - sizeSpec.min.Y) + sizeSpec.min.Y,
			math.random() * (sizeSpec.max.Z - sizeSpec.min.Z) + sizeSpec.min.Z
		)
	end
	return DEFAULT_SIZE
end

local function resolveImpulse(impulse, direction)
	if typeof(impulse) == "number" then
		return direction * impulse
	end
	if typeof(impulse) == "Vector3" then
		return Vector3.new(direction.X * impulse.X, direction.Y * impulse.Y, direction.Z * impulse.Z)
	end
	return nil
end

local function buildRaycastParams(excludeList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}

	local entities = workspace:FindFirstChild("Entities")
	if entities then
		table.insert(params.FilterDescendantsInstances, entities)
	end

	if typeof(excludeList) == "Instance" then
		table.insert(params.FilterDescendantsInstances, excludeList)
	elseif type(excludeList) == "table" then
		for _, item in ipairs(excludeList) do
			if typeof(item) == "Instance" then
				table.insert(params.FilterDescendantsInstances, item)
			end
		end
	end

	return params
end

local function getSurfaceInfo(epicenter, rayHeight, rayDistance, excludeList)
	local origin = epicenter + Vector3.new(0, rayHeight, 0)
	local direction = Vector3.new(0, -rayDistance, 0)
	local result = workspace:Raycast(origin, direction, buildRaycastParams(excludeList))
	if not result then
		return {
			position = epicenter,
			material = DEFAULT_MATERIAL,
			color = DEFAULT_COLOR,
			normal = Vector3.new(0, 1, 0),
		}
	end

	local material = result.Material
	local color = DEFAULT_COLOR
	if result.Instance == workspace.Terrain then
		color = workspace.Terrain:GetMaterialColor(material)
	elseif result.Instance and result.Instance:IsA("BasePart") then
		material = result.Instance.Material
		color = result.Instance.Color
	end

	return {
		position = result.Position,
		material = material,
		color = color,
		normal = result.Normal,
	}
end

local function resetPart(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function nextToken()
	Debris._spawnToken += 1
	return Debris._spawnToken
end

function Debris.init(cacheSizeOverride)
	if typeof(cacheSizeOverride) == "number" then
		Debris.cacheSize = cacheSizeOverride
	end
	ensureCache()
end

function Debris:spawn(epicenterOrOptions, count, size, radius, impulse, lifetime, options)
	local config
	if type(epicenterOrOptions) == "table" then
		config = epicenterOrOptions
	else
		config = options or {}
		config.epicenter = epicenterOrOptions
		config.count = count
		config.size = size
		config.radius = radius
		config.impulse = impulse
		config.lifetime = lifetime
	end

	local epicenter = config.epicenter
	if typeof(epicenter) ~= "Vector3" then
		warn("Debris: Invalid epicenter.")
		return {}
	end

	local spawnCount = tonumber(config.count) or 0
	if spawnCount <= 0 then
		return {}
	end

	local cache = ensureCache()
	local surface = getSurfaceInfo(
		epicenter,
		config.rayHeight or 5,
		config.rayDistance or 50,
		config.raycastExclude
	)

	local radiusValue = tonumber(config.radius) or 0
	local surfaceOffset = tonumber(config.surfaceOffset) or 0.1
	local startAngle = tonumber(config.startAngle) or 0
	if config.randomizeAngle then
		startAngle = math.random() * math.pi * 2
	end

	local lifetimeValue = tonumber(config.lifetime) or 1.25
	local shrinkDuration = tonumber(config.shrinkDuration) or 0.15
	local shrinkSize = config.shrinkSize
	if typeof(shrinkSize) ~= "Vector3" then
		shrinkSize = Vector3.new(0.05, 0.05, 0.05)
	end
	local sinkDelay = tonumber(config.sinkDelay) or 0.15

	local randomRotation = config.randomRotation == true
	local parts = table.create(spawnCount)

	for i = 1, spawnCount do
		local angle = startAngle + ((i - 1) / spawnCount) * math.pi * 2
		local spawnPos = Vector3.new(
			epicenter.X + math.cos(angle) * radiusValue,
			surface.position.Y + surfaceOffset,
			epicenter.Z + math.sin(angle) * radiusValue
		)

		local part = cache:GetInstance()
		part.Size = resolveSize(config.size)
		part.Color = surface.color
		part.Material = surface.material
		part.Anchored = false
		part.CanCollide = true
		part.CanTouch = false
		part.CFrame = CFrame.new(spawnPos)

		if randomRotation then
			part.CFrame = part.CFrame
				* CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
		end

		setCollisionGroup(part)

		local direction = spawnPos - epicenter
		if direction.Magnitude > 0 then
			local impulseVector = resolveImpulse(config.impulse, direction.Unit)
			if impulseVector then
				part:ApplyImpulse(impulseVector)
			end
		end

		local token = nextToken()
		part:SetAttribute("DebrisToken", token)

		task.delay(lifetimeValue, function()
			if not part.Parent or part:GetAttribute("DebrisToken") ~= token then
				return
			end

			local tween = TweenService:Create(
				part,
				TweenInfo.new(shrinkDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = shrinkSize }
			)
			tween:Play()
			tween.Completed:Once(function()
				if not part.Parent or part:GetAttribute("DebrisToken") ~= token then
					return
				end

				part.CanCollide = false
				task.delay(sinkDelay, function()
					if not part.Parent or part:GetAttribute("DebrisToken") ~= token then
						return
					end
					resetPart(part)
					cache:ReturnInstance(part)
				end)
			end)
		end)

		table.insert(parts, part)
	end

	return parts
end

return Debris
