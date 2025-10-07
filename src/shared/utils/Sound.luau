local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local InstanceCache = require(ReplicatedStorage.Packages.InstanceCache)

local Sound = {
	registry = {},
	folderRegistry = {},

	cache = {},
}

function Sound.init()
	local soundCacheFolder = ReplicatedStorage.Storage:FindFirstChild("SoundCache") or Instance.new("Folder")
	soundCacheFolder.Parent = ReplicatedStorage.Storage
	soundCacheFolder.Name = "SoundCache"

	for _, sound in pairs(ReplicatedStorage.Storage.Sounds:GetDescendants()) do
		Sound:addToRegistry(sound)
	end

	local SoundEvent
	if RunService:IsServer() then
		SoundEvent = Instance.new("RemoteEvent")
		SoundEvent.Name = "Sound"
		SoundEvent.Parent = ReplicatedStorage.Events
	else
		SoundEvent = ReplicatedStorage.Events:WaitForChild("Sound")
		SoundEvent.OnClientEvent:Connect(function(fncName, params)
			Sound[fncName](Sound, unpack(params))
		end)
	end
end

function Sound:addToRegistry(object)
	local addedToRegistry = false

	if object:IsA("Sound") and not Sound.registry[object.Name] then
		Sound.registry[object.Name] = object
		addedToRegistry = true
	elseif object:IsA("Sound") and Sound.registry[object.Name] then
		warn(`Sound {object.Name} already exists in the registry. Skipping duplicate.`)
	elseif object:IsA("Folder") and not Sound.folderRegistry[object.Name] then
		Sound.folderRegistry[object.Name] = object
		addedToRegistry = true
	end

	if object:IsA("Sound") and addedToRegistry then
		local cacheSize = tonumber(object:GetAttribute("CacheSize"))
		if cacheSize then
			task.spawn(function()
				Sound.cache[object.Name] = InstanceCache.new(object, cacheSize, ReplicatedStorage.Storage.SoundCache)
			end)
		end
	end
end

function Sound:playGlobal(name, volume)
	local sound = Sound.registry[name]
	if not sound then
		warn(`Sound {name} not found in registry.`)
		return
	end

	local fromCache = false
	local clonedSound
	if Sound.cache[name] then
		clonedSound = Sound.cache[name]:GetInstance()
		fromCache = true
	else
		clonedSound = sound:Clone()
	end
	clonedSound.Volume = volume or clonedSound.Volume
	clonedSound.Parent = workspace
	clonedSound:Play()

	clonedSound.Ended:Once(function()
		if fromCache and Sound.cache[name] then
			Sound.cache[name]:ReturnInstance(clonedSound)
		else
			clonedSound:Destroy()
		end
	end)

	return clonedSound
end

function Sound:playGlobalFromRandom(folderName, volume)
	local folder = Sound.folderRegistry[folderName]
	if not folder then
		warn(`Folder {folderName} not found in registry.`)
		return
	end

	local sounds = {}
	for _, sound in pairs(folder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(sounds, sound)
		end
	end

	if #sounds == 0 then
		warn(`No sounds found in folder {folderName}.`)
		return
	end

	local randomSound = sounds[math.random(1, #sounds)]
	return self:playGlobal(randomSound.Name, volume)
end

function Sound:playLocalFromRandom(folderName, parent, volume)
	local folder = Sound.folderRegistry[folderName]
	if not folder then
		warn(`Folder {folderName} not found in registry.`)
		return
	end

	local sounds = {}
	for _, sound in pairs(folder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(sounds, sound)
		end
	end

	if #sounds == 0 then
		warn(`No sounds found in folder {folderName}.`)
		return
	end

	local randomSound = sounds[math.random(1, #sounds)]
	return self:playLocal(randomSound.Name, parent, volume)
end

function Sound:playLocal(name, parent, volume)
	local sound = Sound.registry[name]
	if not sound then
		warn(`Sound {name} not found in registry.`)
		return
	end
	if not parent then
		return
	end

	local fromCache = false
	local clonedSound
	if Sound.cache[name] then
		clonedSound = Sound.cache[name]:GetInstance()
		fromCache = true
	else
		clonedSound = sound:Clone()
	end
	clonedSound.Volume = volume or clonedSound.Volume
	clonedSound.Parent = parent
	clonedSound:Play()

	clonedSound.Ended:Once(function()
		if fromCache and Sound.cache[name] then
			Sound.cache[name]:ReturnInstance(clonedSound)
		else
			clonedSound:Destroy()
		end
	end)

	return clonedSound
end

return Sound
