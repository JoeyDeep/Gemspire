local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DefaultData = require(ReplicatedStorage.Shared.GameData.DefaultData)
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)

local PlayerService = {
	players = {},
	PlayerAdded = Signal.new(),
}
PlayerService.__index = PlayerService

-- use a temporary profile store for studio testing (does not save data)
local GameProfileStore = ProfileService.GetProfileStore("PlayerData", DefaultData)
if RunService:IsStudio() == true then
	GameProfileStore = GameProfileStore.Mock
end

local engine
function PlayerService.init(engineModule)
	engine = engineModule

	Players.PlayerAdded:Connect(function(player)
		PlayerService.new(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		Promise.new(function(resolve)
			resolve(PlayerService.new(player))
		end)
	end

	-- future uses
	engine.events.PlayerData.OnServerEvent:Connect(function(player, topic, data) end)
end

-- called when a new player joins and their profile is fully server-loaded
function PlayerService:newPlayerSetup()
	engine.events.PlayerData:FireClient(self.player, "provideClientData", self:getClientData())
end

-- package a player's profile data for client use purposes
function PlayerService:getClientData()
	local playerData = table.clone(self.profile.Data)
	-- remove sensitive data from profile below

	return playerData
end

function PlayerService.new(player)
	local self = setmetatable({}, PlayerService)

	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GPDR compliance
		profile:Reconcile() -- add any new data from DefaultData that is not in the profile
		profile:ListenToRelease(function() -- kick player if profile is loaded elsewhere
			player:Kick()
		end)

		if player:IsDescendantOf(Players) == true then -- successfully loaded profile
			self.player = player
			self.profile = profile
		else
			profile:Release() -- loaded their profile, but player is not in the game. release the profile.
		end
	else
		player:Kick() -- failed to load profile, kick the player
	end

	if not self.profile then
		warn("Failed to load profile for player: " .. player.Name)
		return
	end

	PlayerService.players[player.Name] = self
	PlayerService.PlayerAdded:Fire(self)
	print(`{player.Name} has joined:`, self)

	self:newPlayerSetup()
end

function PlayerService:GetData(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	return PlayerService.players[player.Name].profile.Data
end

function PlayerService:GetProfile(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	return PlayerService.players[player.Name].profile
end

function PlayerService:Get(player)
	if not player or not player:IsA("Player") then
		return nil
	end

	return PlayerService.players[player.Name]
end

return PlayerService
