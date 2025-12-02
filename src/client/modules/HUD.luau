--[[
	SINGLETON (Handler)
	
	PURPOSE:
		Handle the player's HUD display, including currency amounts and updates.
		All UI-related HUD functions are managed here.
]]

local HUD = {}

local engine
function HUD.init(engineModule)
	engine = engineModule

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local InstanceCache = require(ReplicatedStorage.Packages.InstanceCache)

	local CurrencyCache = Instance.new("Folder")
	CurrencyCache.Name = "CurrencyCache"
	CurrencyCache.Parent = workspace.Entities

	-- build instance caches for potentially high-frequency demanded objects
	HUD.coinCache = InstanceCache.new(ReplicatedStorage.Storage.CurrencyObjects.Coin, 51, CurrencyCache)
	HUD.luminiteCache = InstanceCache.new(ReplicatedStorage.Storage.CurrencyObjects.Luminite, 51, CurrencyCache)
end

function HUD:draw()
	local data = engine:get("PlayerService").data
	local UI = engine.PlayerGUi:WaitForChild("UI"):WaitForChild("HUD")

	UI.Coins.Amount.Text = tostring(data.coins)
	UI.Luminite.Amount.Text = tostring(data.luminite)
end

-- reflect currency changes to the HUD UI
-- `type` is either "coins" or "luminite"
function HUD:addCurrency(type, amount, isPhysical)
	local playerData = engine:get("PlayerService").data
	local UI = engine.PlayerGui:WaitForChild("UI"):WaitForChild("HUD")
	local QuickTween = engine:get("QuickTween")
	local Debris = game:GetService("Debris")
	local Sound = engine:get("Sound")

	-- `isPhysical` determines whether to spawn physical currency objects that fly out from the player
	if isPhysical then
		local cache = {}
		local cacheClass
		for _ = 1, math.clamp(amount, 1, 50) do
			if type == "coins" then
				cacheClass = HUD.coinCache
				table.insert(cache, HUD.coinCache:GetInstance())
			elseif type == "luminite" then
				cacheClass = HUD.luminiteCache
				table.insert(cache, HUD.luminiteCache:GetInstance())
			end
			game:GetService("RunService").Heartbeat:Wait()
		end

		for _, obj in pairs(cache) do
			obj:PivotTo(engine.player.Character:GetPivot():ToWorldSpace(CFrame.new(0, 5, -5)))
			obj.Trail.Enabled = true
			obj.Anchored = false
			obj.CollisionGroup = "Currency"
			obj:ApplyImpulse(Vector3.new(math.random(-0.05, 0.05), math.random(1, 1), math.random(-0.05, 0.05))) -- math.random(-0.1, 0.1), math.random(0.15, 0.3), math.random(-0.1, 0.1)
		end
		task.delay(3, function()
			for _, obj in pairs(cache) do
				obj.Trail.Enabled = false
				obj.Anchored = true
				cacheClass:ReturnInstance(obj)
			end
		end)
	end

	if type == "coins" then
		UI.Coins.Amount.Text = tostring(playerData.coins - amount)
		local numVal = Instance.new("NumberValue")
		numVal.Value = playerData.coins - amount

		numVal:GetPropertyChangedSignal("Value"):Connect(function()
			UI.Coins.Amount.Text = tostring(math.floor(numVal.Value))
		end)
		QuickTween(numVal, 1, { Value = playerData.coins })
		Sound:playGlobal("Coins")
		Debris:AddItem(numVal, 1.1)
	elseif type == "luminite" then
		UI.Luminite.Amount.Text = tostring(playerData.luminite - amount)
		local numVal = Instance.new("NumberValue")
		numVal.Value = playerData.luminite - amount

		numVal:GetPropertyChangedSignal("Value"):Connect(function()
			UI.Luminite.Amount.Text = tostring(math.floor(numVal.Value))
		end)
		QuickTween(numVal, 1, { Value = playerData.luminite })
		Debris:AddItem(numVal, 1.1)
	end
end

return HUD
