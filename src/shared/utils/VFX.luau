local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = {
	registry = {},
	folder = nil,
}

local function resolveVFXFolder()
	if VFX.folder then
		return VFX.folder
	end

	local storage = ReplicatedStorage:FindFirstChild("Storage")
	if not storage then
		warn("VFX: ReplicatedStorage.Storage not found.")
		return nil
	end

	local folder = storage:FindFirstChild("VFX")
	if not folder then
		warn("VFX: ReplicatedStorage.Storage.VFX not found.")
		return nil
	end

	VFX.folder = folder
	return folder
end

local function findTemplate(name)
	if VFX.registry[name] then
		return VFX.registry[name]
	end

	local folder = resolveVFXFolder()
	if not folder then
		return nil
	end

	local found = folder:FindFirstChild(name, true)
	if found and found:IsA("Attachment") then
		VFX.registry[name] = found
		return found
	end

	return nil
end

local function resolveParent(parent)
	if not parent then
		return nil, nil
	end

	if parent:IsA("Attachment") then
		local basePart = parent.Parent
		if basePart and basePart:IsA("BasePart") then
			return basePart, parent.CFrame
		end
		return nil, nil
	end

	if parent:IsA("Model") then
		local basePart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
		return basePart, nil
	end

	if parent:IsA("BasePart") then
		return parent, nil
	end

	return nil, nil
end

local function normalizeSpawnArgs(parent, options)
	if options == nil and type(parent) == "table" and typeof(parent) ~= "Instance" then
		options = parent
		parent = nil
	end
	return parent, options
end

local function getEmitters(attachment)
	local emitters = {}
	for _, descendant in ipairs(attachment:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	return emitters
end

local function resolveEmitCount(emitCount, emitter)
	if type(emitCount) == "number" then
		return emitCount
	end
	if type(emitCount) == "table" then
		local count = emitCount[emitter.Name] or emitCount.default
		if type(count) == "number" then
			return count
		end
	end

	local attrCount = emitter:GetAttribute("EmitCount")
	if type(attrCount) == "number" then
		return attrCount
	end

	return 1
end

local function resolveEmitterOptions(options, emitterName, emitterNameSet)
	if type(options) ~= "table" then
		return options
	end

	local perEmitter = options[emitterName]
	if type(perEmitter) ~= "table" then
		return options
	end

	local merged = {}
	for key, value in pairs(options) do
		if not (emitterNameSet[key] and type(value) == "table") then
			merged[key] = value
		end
	end
	for key, value in pairs(perEmitter) do
		merged[key] = value
	end

	return merged
end

function VFX.init(folderOverride)
	if typeof(folderOverride) == "Instance" then
		VFX.folder = folderOverride
	else
		VFX.folder = nil
	end
	VFX.folder = VFX.folder or resolveVFXFolder()
	if not VFX.folder or not VFX.folder:IsA("Folder") then
		return
	end

	VFX.registry = {}
	for _, descendant in ipairs(VFX.folder:GetDescendants()) do
		if descendant:IsA("Attachment") then
			if VFX.registry[descendant.Name] then
				warn(`VFX: Attachment {descendant.Name} already registered. Skipping duplicate.`)
			else
				VFX.registry[descendant.Name] = descendant
			end
		end
	end
end

function VFX:get(name)
	return findTemplate(name)
end

function VFX:spawn(name, parent, options)
	parent, options = normalizeSpawnArgs(parent, options)
	options = options or {}

	local template = findTemplate(name)
	if not template then
		warn(`VFX: Attachment {name} not found.`)
		return nil
	end

	local basePart, inheritCFrame = resolveParent(parent or options.parent)
	if not basePart then
		warn(`VFX: Invalid parent for {name}. Expected BasePart, Attachment, or Model.`)
		return nil
	end

	local clone = template:Clone()
	clone.Parent = basePart

	if options.cframe then
		clone.CFrame = basePart.CFrame:ToObjectSpace(options.cframe)
	elseif options.position then
		clone.Position = basePart.CFrame:PointToObjectSpace(options.position)
	elseif inheritCFrame then
		clone.CFrame = inheritCFrame
	end

	local emitters = getEmitters(clone)
	local lockParent = parent or options.parent
	local emitterNameSet = {}
	for _, emitter in ipairs(emitters) do
		emitterNameSet[emitter.Name] = true
	end
	local maxLifetime = 0
	local maxCleanupDelay = 0
	local anyEmitRequested = false
	local anyDuration = false
	local anySoftEnabled = false
	for _, emitter in ipairs(emitters) do
		local emitterOptions = resolveEmitterOptions(options, emitter.Name, emitterNameSet)
		local emitCount = emitterOptions.emitCount
		if emitCount == nil then
			emitCount = emitterOptions.emit
		end
		local emitRequested = emitCount ~= nil and emitCount ~= false
		if emitRequested then
			anyEmitRequested = true
		end
		local softEnabled = emitterOptions.softEnabled == true
		if softEnabled then
			anySoftEnabled = true
		end
		local burstOnly = emitRequested and emitterOptions.enabled == nil and not softEnabled

		maxLifetime = math.max(maxLifetime, emitter.Lifetime.Max)
		if emitterOptions.enabled ~= nil then
			emitter.Enabled = emitterOptions.enabled
		elseif softEnabled then
			emitter.Enabled = true
		elseif burstOnly then
			emitter.Enabled = false
		end
		if emitterOptions.duration and not burstOnly and emitterOptions.enabled ~= false and not softEnabled then
			anyDuration = true
			emitter.Enabled = true
			local duration = emitterOptions.duration
			task.delay(duration, function()
				if clone.Parent then
					emitter.Enabled = false
				end
			end)
		elseif softEnabled then
			local disableDelay = emitterOptions.cleanupDelay
			if disableDelay == nil then
				disableDelay = 0
			end
			if disableDelay < 0 then
				disableDelay = 0
			end
			task.delay(disableDelay, function()
				if clone.Parent then
					emitter.Enabled = false
				end
			end)
		end

		if lockParent and (lockParent:IsA("BasePart") or lockParent:IsA("Attachment") and emitterOptions.lock) then
			emitter.LockedToPart = true
		end

		if emitRequested then
			emitter:Emit(resolveEmitCount(emitCount, emitter))
		end

		local cleanupPadding = emitterOptions.cleanupPadding
		if cleanupPadding == nil then
			cleanupPadding = options.cleanupPadding
		end
		if cleanupPadding == nil then
			cleanupPadding = 0.1
		end
		if softEnabled then
			local disableDelay = emitterOptions.cleanupDelay
			if disableDelay == nil then
				disableDelay = 0
			end
			if disableDelay < 0 then
				disableDelay = 0
			end
			local cleanupDelay = disableDelay + emitter.Lifetime.Max + cleanupPadding
			if cleanupDelay > maxCleanupDelay then
				maxCleanupDelay = cleanupDelay
			end
		elseif emitterOptions.duration then
			local cleanupDelay = emitterOptions.duration + emitter.Lifetime.Max + cleanupPadding
			if cleanupDelay > maxCleanupDelay then
				maxCleanupDelay = cleanupDelay
			end
		elseif emitRequested then
			local cleanupDelay = emitter.Lifetime.Max + cleanupPadding
			if cleanupDelay > maxCleanupDelay then
				maxCleanupDelay = cleanupDelay
			end
		end
	end

	local autoDestroy = options.autoDestroy
	if autoDestroy == nil then
		autoDestroy = anyEmitRequested or anyDuration or anySoftEnabled
	end

	if autoDestroy then
		local cleanupDelay = options.cleanupDelay
		if cleanupDelay == nil or anySoftEnabled then
			cleanupDelay = maxCleanupDelay
			if cleanupDelay <= 0 then
				cleanupDelay = (options.duration or 0) + maxLifetime + (options.cleanupPadding or 0.1)
			end
		end
		if cleanupDelay < 0 then
			cleanupDelay = 0
		end
		task.delay(cleanupDelay, function()
			if clone.Parent then
				clone:Destroy()
			end
		end)
	end

	return clone
end

function VFX:play(name, parent, options)
	parent, options = normalizeSpawnArgs(parent, options)
	options = options or {}
	if options.emit == nil then
		options.emit = true
	end
	if options.autoDestroy == nil then
		options.autoDestroy = true
	end
	return self:spawn(name, parent, options)
end

function VFX:emit(attachmentOrName, emitCount)
	local attachment = attachmentOrName
	if type(attachmentOrName) == "string" then
		attachment = findTemplate(attachmentOrName)
	end

	if not attachment or not attachment:IsA("Attachment") then
		warn("VFX: Invalid attachment for emit.")
		return
	end

	for _, emitter in ipairs(getEmitters(attachment)) do
		emitter:Emit(resolveEmitCount(emitCount, emitter))
	end
end

return VFX
