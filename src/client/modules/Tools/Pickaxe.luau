local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Pickaxe = {}
Pickaxe.__index = Pickaxe

local engine
function Pickaxe.init(engineModule)
	engine = engineModule
end

local CORE_ANIMS = { "Idle", "Windup", "ReadyLoop", "Strike" }

-- new Pickaxe class, inherits from Tool
-- safe to assume this is called when a Character is properly loaded
function Pickaxe.new(name, toolClass)
	local pickaxeData = engine:get("Pickaxes")[name]
	local self = setmetatable({}, Pickaxe)

	self.name = name
	self.displayName = pickaxeData.name
	self.model = Players.LocalPlayer.Character:WaitForChild("Items"):WaitForChild(name)
	self.toolClass = toolClass
	self.stats = pickaxeData.stats
	self.cameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cameraCF)
		workspace.CurrentCamera.CFrame *= cameraCF
	end)

	self.strikeCooldown = tick()
	self.connections = {}

	self:initAnimations()

	return self
end

function Pickaxe:_stopCoreAnims(fade)
	fade = fade or 0
	for _, name in ipairs(CORE_ANIMS) do
		local tr = self.animations and self.animations[name]
		if tr and tr.IsPlaying then
			tr:Stop(fade)
		end
	end
end

function Pickaxe:_playOnly(animName, fade, weight, speed)
	-- Hard stop every core anim, then play exactly one
	self:_stopCoreAnims(fade or 0)
	local tr = self.animations[animName]
	if not tr then
		return
	end
	if weight then
		pcall(function()
			tr:AdjustWeight(weight)
		end)
	end
	if speed then
		pcall(function()
			tr:AdjustSpeed(speed)
		end)
	end
	tr:Play(fade or 0, 1, speed)
end

function Pickaxe:_resetStrikeState()
	-- full cleanup so later clicks always work
	if self.tween and self.tween.Pause then
		pcall(function()
			self.tween:Pause()
		end)
	end
	self.tween = nil
	self.striking = false
	self.awaitingRelease = false
	self.earlyRelease = false
	self.strikePromise = nil

	local ui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if ui then
		local s = ui:FindFirstChild("UI") and ui.UI:FindFirstChild("StrikeGame")
		if s then
			s.Visible = false
		end
	end

	-- Return to idle cleanly
	if self.animations then
		self:_playOnly("Idle", 0.1, 1, 1)
	end

	-- Short lockout to avoid accidental spam
	self.strikeCooldown = tick() + 0.2
	-- print("Reset strike state:", reason)
end

function Pickaxe:_inMineZone()
	local character = Players.LocalPlayer.Character
	if not character then
		return false, nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }

	local cast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -20, 0), params)
	if not cast then
		return false, nil
	end
	if not cast.Instance:IsDescendantOf(workspace.Entities.MineZones) then
		return false, nil
	end
	return true, cast.Instance.Parent.Name
end

function Pickaxe:initAnimations()
	local player = Players.LocalPlayer
	local animations = ReplicatedStorage.Storage.Animations.Player.Pickaxe

	self.animations = {}

	for _, animation in pairs(animations:GetChildren()) do
		self.animations[animation.Name] = player.Character.Humanoid.Animator:LoadAnimation(animation)
	end
end

-- called after requestStrike approves strike conditions
function Pickaxe:strike()
	local QuickTween = engine:get("QuickTween")
	local character = Players.LocalPlayer.Character

	-- terrain sanity (your original)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local cast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -20, 0), params)
	if not cast then
		self:_resetStrikeState("no-terrain")
		return
	end

	self.striking = true
	self:_playOnly("Windup", 0.1, 1, self.stats.speed)

	-- clear old conn
	if self.connections.windUp and self.connections.windUp.Disconnect then
		pcall(function()
			self.connections.windUp:Disconnect()
		end)
	end

	-- >>> CREATE a windup promise that resolves exactly once when Windup stops
	self.windupPromise = Promise.new(function(resolve)
		self.connections.windUp = self.animations.Windup.Stopped:Once(function()
			-- Enter READY state; show UI and loop anim
			self.awaitingRelease = true
			self:_playOnly("ReadyLoop", 0, 1, 2)

			local ui = Players.LocalPlayer.PlayerGui:WaitForChild("UI")
			local strikeUI = ui:WaitForChild("StrikeGame")
			strikeUI.Container.Bar.Position = UDim2.fromScale(0.5, 1)
			strikeUI.Container.Bar.UIScale.Scale = 1
			strikeUI.Container.Bar.BackgroundTransparency = 0
			strikeUI.Container.Bar.BackgroundColor3 = Color3.new(0, 0, 0)
			strikeUI.Visible = true

			self.tween = QuickTween(
				strikeUI.Container.Bar,
				0,
				{ Position = UDim2.fromScale(0.5, 0) },
				TweenInfo.new(0.75 / self.stats.speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
			)

			resolve("ready") -- <<< resolve AFTER we've entered ReadyLoop/UI
		end)
	end)

	-- generous ceiling so people can’t requeue mid mini-game
	self.strikeCooldown = tick() + 5
end

function Pickaxe:readStrikeGame()
	local QuickTween = engine:get("QuickTween")
	local strikeUI = Players.LocalPlayer.PlayerGui.UI.StrikeGame
	local bar = strikeUI.Container.Bar
	local barY = bar.Position.Y.Scale

	-- Freeze bar tween right away
	if self.tween and self.tween.Pause then
		pcall(function()
			self.tween:Pause()
		end)
	end
	self.tween = nil

	return Promise.resolve()
		:andThen(function()
			-- Feedback popup
			if barY < 0.5 then
				local billboard = ReplicatedStorage.Storage.Billboards.StrikeGame.CharacterBoard:Clone()
				if barY <= 0.04 then
					billboard.TextLabel.Text = "PERFECT!"
					billboard.TextLabel.TextColor3 = Color3.fromRGB(255, 180, 29)
				else
					billboard.TextLabel.Text = "Good!"
				end
				billboard.Parent = Players.LocalPlayer.Character.HumanoidRootPart

				Promise.all({
					Promise.resolve(QuickTween(billboard.TextLabel.UIStroke, 1.75, { Transparency = 1 })),
					Promise.fromEvent(QuickTween(billboard.TextLabel, 1.75, {
						Position = UDim2.fromScale(0.5, 0.1),
						TextTransparency = 1,
					}).Completed):andThen(function()
						billboard:Destroy()
					end),
				})
			end

			-- Bar flash
			if barY <= 0.04 then
				return Promise.all({
					Promise.resolve(QuickTween(bar, 0.15, { BackgroundColor3 = Color3.new(0, 1, 0) })),
					Promise.resolve(QuickTween(bar, 0.25, { BackgroundTransparency = 1 })),
					Promise.resolve(QuickTween(bar.UIScale, 0.3, { Scale = 2 })),
				})
			else
				return Promise.all({
					Promise.resolve(
						QuickTween(bar, 0.15, { BackgroundColor3 = Color3.new(0.466667, 0.466667, 0.466667) })
					),
					Promise.resolve(QuickTween(bar, 0.25, { BackgroundTransparency = 1 })),
					Promise.resolve(QuickTween(bar.UIScale, 0.3, { Scale = 2 })),
				})
			end
		end)
		:andThen(function()
			-- Enter STRIKE exclusively
			self:_playOnly("Strike", 0)
			self.animations.Strike:GetMarkerReachedSignal("Hit"):Once(function()
				engine:get("Sound"):playLocalFromRandom("PickaxeStrike", self.model.Handle)
				self.cameraShaker:ShakeOnce(1.5, 5, 0.1, 0.3)
			end)
			return Promise.fromEvent(self.animations.Strike.Stopped)
		end)
		:catch(function(err)
			warn("[Pickaxe] StrikeGame error:", err)
		end)
		:finallyCall(function()
			local ui = Players.LocalPlayer.PlayerGui:FindFirstChild("UI")
			if ui and ui:FindFirstChild("StrikeGame") then
				ui.StrikeGame.Visible = false
			end
			self:_resetStrikeState("end-mini-game")
			-- Give a snappier post-strike cooldown
			self.strikeCooldown = tick() + 0.5
		end)
end

-- called from enableInput when the player clicks to strike
function Pickaxe:requestStrike()
	local MineZones = engine:get("MineZones")
	local character = Players.LocalPlayer.Character
	if not (character and self.toolClass.equipped and tick() > (self.strikeCooldown or 0)) then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }
	local cast = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -20, 0), params)

	if cast and cast.Instance:IsDescendantOf(workspace.Entities.MineZones) then
		local mineZone = cast.Instance.Parent.Name
		if MineZones[mineZone] and MineZones[mineZone].minDensity <= self.stats.density then
			self:strike()
			return true
		else
			print("TOO WEAK!")
			self.striking = false
			self.awaitingRelease = false
			self.earlyRelease = false
			self.strikeCooldown = tick() + 0.2
			-- UI/anim cleanup only
			local ui = Players.LocalPlayer:FindFirstChild("PlayerGui")
			local s = ui and ui:FindFirstChild("UI") and ui.UI:FindFirstChild("StrikeGame")
			if s then
				s.Visible = false
			end
			if self.tween and self.tween.Pause then
				pcall(function()
					self.tween:Pause()
				end)
			end
			self.tween = nil
			self:_stopCoreAnims(0)
			if self.animations and self.animations.Idle then
				pcall(function()
					self.animations.Idle:Play(0.1)
				end)
			end
			return false
		end
	else
		print("NOTHING TO HIT!")
		self.striking = false
		self.awaitingRelease = false
		self.earlyRelease = false
		self.strikeCooldown = tick() + 0.2
		local ui = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local s = ui and ui:FindFirstChild("UI") and ui.UI:FindFirstChild("StrikeGame")
		if s then
			s.Visible = false
		end
		if self.tween and self.tween.Pause then
			pcall(function()
				self.tween:Pause()
			end)
		end
		self.tween = nil
		self:_stopCoreAnims(0)
		if self.animations and self.animations.Idle then
			pcall(function()
				self.animations.Idle:Play(0.1)
			end)
		end
		return false
	end
end

function Pickaxe:enableInput()
	self:_resetStrikeState("enable-input") -- puts us in idle & clears flags, sets short cooldown

	self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not self.toolClass.equipped then
			return
		end
		if tick() <= (self.strikeCooldown or 0) then
			return
		end
		if self.striking or self.awaitingRelease then
			return
		end
		if self.strikePromise ~= nil then
			return
		end -- only blocks while Windup is pending

		self.earlyRelease = false

		local ok = self:requestStrike()
		if not ok then
			return
		end

		-- strike() created self.windupPromise
		local p = self.windupPromise
		if not p then
			return
		end

		self.strikePromise = p
		p:andThen(function(_)
			-- We're now in ReadyLoop (Windup finished)
			self.awaitingRelease = true

			-- If user released during Windup, run the mini-game right now
			if self.earlyRelease then
				self.awaitingRelease = false
				return Promise.try(function()
					task.wait(0.02) -- tiny yield so ReadyLoop/UI is fully applied
					return self:readStrikeGame()
				end)
			end
			return
		end)
			:catch(function(err)
				warn("[Pickaxe] Windup wait error:", err)
			end)
			:finallyCall(function()
				if self.strikePromise == p then
					self.strikePromise = nil
				end
			end)
	end)

	self.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		-- If we never started a strike, ignore
		if not self.striking then
			return
		end

		-- If we released during Windup, mark early and let Windup handler finish
		if not self.awaitingRelease then
			self.earlyRelease = true
			return
		end

		-- We are in ReadyLoop → run the mini-game (do NOT require strikePromise)
		self.awaitingRelease = false
		Promise.try(function()
			return self:readStrikeGame()
		end)
			:catch(function(err)
				warn("[Pickaxe] readStrikeGame from InputEnded error:", err)
			end)
			:finallyCall(function()
				-- readStrikeGame() will reset state in its own finally; no need to touch striking here
				-- it's ok to clear any leftover windup sentinel, but not required
				self.strikePromise = nil
			end)
	end)

	self.cameraShaker:Start()
end

function Pickaxe:disableInput()
	if self.connections.inputBegan then
		self.connections.inputBegan:Disconnect()
		self.connections.inputBegan = nil
	end
	if self.connections.inputEnded then
		self.connections.inputEnded:Disconnect()
		self.connections.inputEnded = nil
	end

	self.cameraShaker:Stop()
	self:_resetStrikeState("disable-input")
	self:_stopCoreAnims(0)
end

function Pickaxe:equip()
	local key = tick()
	self.toolClass.equipKey = key

	self.connections.equipReached = self.animations.Equip:GetMarkerReachedSignal("Equip"):Once(function()
		if key == self.toolClass.equipKey then
			engine.events.Inventory:FireServer("equipPickaxe", self.name)
		end
	end)
	self.connections.equipStopped = self.animations.Equip.Stopped:Once(function()
		if key == self.toolClass.equipKey then
			self.animations.Idle:Play()
		end
	end)

	self:enableInput()

	self.animations.Equip:Play()
	self.animations.Equip:AdjustSpeed(1.5)
end

function Pickaxe:unequip()
	local key = tick()
	self.toolClass.equipKey = key

	self.connections.unequipReached = self.animations.Equip:GetMarkerReachedSignal("Equip"):Once(function()
		if key == self.toolClass.equipKey then
			engine.events.Inventory:FireServer("unequipPickaxe", self.name)
		end
	end)

	self:disableInput()

	self.animations.Idle:Stop()
	self.animations.Equip.TimePosition = self.animations.Equip.Length + 0.01
	self.animations.Equip:Play(0, 1, -1.5)
end

function Pickaxe:destroy()
	for _, animation in pairs(self.animations) do
		animation:Stop()
		animation:Destroy()
	end
	for _, connection in pairs(self.connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
end

return Pickaxe
