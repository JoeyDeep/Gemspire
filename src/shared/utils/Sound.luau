local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Sound = {
	registry = {},
	folderRegistry = {},
}

function Sound.init()
	for _, sound in pairs(ReplicatedStorage.Storage.Sounds:GetDescendants()) do
		if sound:IsA("Sound") and not Sound.registry[sound.Name] then
			Sound.registry[sound.Name] = sound
		elseif sound:IsA("Sound") and Sound.registry[sound.Name] then
			warn(`Sound {sound.Name} already exists in the registry. Skipping duplicate.`)
		elseif sound:IsA("Folder") and not Sound.folderRegistry[sound.Name] then
			Sound.folderRegistry[sound.Name] = sound
		end
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

function Sound:playGlobal(name, volume)
	local sound = Sound.registry[name]
	if not sound then
		warn(`Sound {name} not found in registry.`)
		return
	end

	local clonedSound = sound:Clone()
	clonedSound.Volume = volume or clonedSound.Volume
	clonedSound.Parent = workspace
	clonedSound:Play()

	clonedSound.Ended:Connect(function()
		clonedSound:Destroy()
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

	local clonedSound = sound:Clone()
	clonedSound.Volume = volume or sound.Volume
	clonedSound.Parent = parent
	clonedSound:Play()

	clonedSound.Ended:Connect(function()
		clonedSound:Destroy()
	end)

	return clonedSound
end

return Sound
