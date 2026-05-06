--[[
	CLASS: PlayerService.new(player: Player)

	PURPOSE:
		Manage player data on the server side, including loading and saving player profiles.
	USAGE:
		N/A, this is a service module initialized by the engines

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local DefaultData = require(ReplicatedStorage.Shared.GameData.DefaultData)
local Kits = require(ReplicatedStorage.Shared.GameData.Items.Kits)
local InventoryUtils = require(ReplicatedStorage.Shared.utils.InventoryUtils)
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)

local PlayerService = {
	players = {},
	PlayerAdded = Signal.new(),
	PlayerRemoved = Signal.new(),
}
PlayerService.__index = PlayerService

-- use a temporary profile store for studio testing (does not save data)
local GameProfileStore = ProfileService.GetProfileStore("PlayerData", DefaultData)
if RunService:IsStudio() == true then
	GameProfileStore = GameProfileStore.Mock
end

local engine

local function unregisterPlayer(playerClass)
	if not playerClass or playerClass._removed then
		return
	end

	playerClass._removed = true

	local player = playerClass.player
	if player then
		PlayerService.players[player.Name] = nil
	end

	PlayerService.PlayerRemoved:Fire(playerClass)
end

local function getContainerStatus(player)
	local playerClass = PlayerService:get(player)
	if not playerClass or not playerClass.profile then
		return { now = 0, max = 0, quality = 0 }
	end

	local playerData = InventoryUtils.ensurePlayerDataShape(playerClass.profile.Data)
	local capacityOverride
	local ModifierManager = engine and engine:get("ModifierManager")
	if ModifierManager then
		local modifiedCapacity = ModifierManager:getKitStat(player, "capacity", playerData.equipped.kit)
		if typeof(modifiedCapacity) == "number" then
			capacityOverride = modifiedCapacity
		end
	end

	return InventoryUtils.getContainerStatus(playerData, Kits, capacityOverride)
end

function PlayerService.init(engineModule)
	engine = engineModule

	Players.PlayerAdded:Connect(function(player)
		PlayerService.new(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerService:playerRemoved(player)
	end)

	task.defer(function()
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerService.new(player)
		end
	end)

	-- future uses
	-- engine.events.PlayerData.OnServerEvent:Connect(function(player, topic, data) end)
end

-- called when a new player joins and their profile is fully server-loaded
function PlayerService:newPlayerSetup()
	self.localData = self.localData or {}
	if typeof(self.localData.lastPickaxeStrike) ~= "number" then
		self.localData.lastPickaxeStrike = 0
	end
	self.localData.quests = self.localData.quests or {}

	engine.events.PlayerData:FireClient(self.player, "provideClientData", self:getClientData())
end

-- profile data is locked by the time this runs. used for cleanups.
-- trying to access/change profile data here? whatever you are doing is wrong, rethink it.
-- ^ the profile should be up-to-date ALWAYS, in case of abrupt server disconnects. you shouldn't be waiting till here.
function PlayerService:processRelease()
	print(`Releasing profile for player: {self.player.Name}`)
	self.profile = nil
	self.localData = nil
end

-- package a player's profile data for client use purposes
function PlayerService:getClientData()
	local playerData = table.clone(InventoryUtils.ensurePlayerDataShape(self.profile.Data))
	-- remove sensitive data from profile below
	playerData.container = getContainerStatus(self.player)

	return playerData
end

function PlayerService.new(player)
	local self = setmetatable({}, PlayerService)

	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- add any new data from DefaultData that is not in the profile
		InventoryUtils.ensurePlayerDataShape(profile.Data)
		profile:ListenToRelease(function() -- kick player if profile is loaded elsewhere
			unregisterPlayer(self)
			if player:IsDescendantOf(Players) then
				player:Kick()
			end
			if self and self.processRelease then
				self:processRelease()
			end
		end)

		if player:IsDescendantOf(Players) == true then -- successfully loaded profile
			self.player = player
			self.profile = profile
			self.localData = {}
		else
			profile:Release() -- loaded their profile, but player is not in the game. release the profile.
		end
	else
		player:Kick() -- failed to load profile, kick the player
	end

	if not self.profile then
		warn("Failed to load profile for player: " .. player.Name)
		return nil
	end

	PlayerService.players[player.Name] = self
	PlayerService.PlayerAdded:Fire(self)
	print(`{player.Name} has joined:`, self)

	self:newPlayerSetup()
	return self
end

function PlayerService:playerRemoved(player)
	local playerClass = PlayerService:get(player)
	if not playerClass then
		return
	end

	unregisterPlayer(playerClass)

	if playerClass.profile then
		playerClass.profile:Release()
	end
end

function PlayerService:updateClient(dataTable)
	local toSend = self:getClientData()
	if dataTable and typeof(dataTable) == "table" then
		local conciseSend = {}
		for _, key in pairs(dataTable) do
			conciseSend[key] = toSend[key]
		end
		toSend = conciseSend
		engine.events.PlayerData:FireClient(self.player, "updateClientData", toSend)
		return
	end
	engine.events.PlayerData:FireClient(self.player, "setClientData", toSend)
end

function PlayerService:getData(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	local playerClass = PlayerService.players[player.Name]
	return playerClass and playerClass.profile and playerClass.profile.Data or nil
end

function PlayerService:getProfile(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	local playerClass = PlayerService.players[player.Name]
	return playerClass and playerClass.profile or nil
end

function PlayerService:get(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	return PlayerService.players[player.Name]
end

return PlayerService
