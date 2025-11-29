--[[
	PURPOSE: 
		Manage player speed affects and states, and set the player's humanoid WalkSpeed accordingly.
	USAGE:
		```lua
		local SpeedManager = require(engine:get("SpeedManager"))
		
		SpeedManager:affect("speedBoost", 5) -- increase speed by 5
		SpeedManager:setState("slowed", "freeze") -- set freeze state

		SpeedManager:removeAffect("speedBoost") -- remove speed boost
		SpeedManager:dropState("slowed", "freeze") -- drop freeze state
		```
]]

local Players = game:GetService("Players")
local SpeedManager = {
	affects = {},
	states = {},
}

local DEFAULT_SPEED = 16

function SpeedManager:affect(tag, value, noSet)
	SpeedManager.affects[tag] = value
	if not noSet then
		SpeedManager:setSpeed()
	end
end
function SpeedManager:removeAffect(tag, noSet)
	SpeedManager.affects[tag] = nil
	if not noSet then
		SpeedManager:setSpeed()
	end
end

function SpeedManager:setState(tag, state, noSet)
	if not SpeedManager.states[tag] then
		SpeedManager.states[tag] = {}
	end

	SpeedManager.states[tag][state] = tick()
	if not noSet then
		SpeedManager:setSpeed()
	end
end
function SpeedManager:dropState(tag, state, noSet)
	if SpeedManager.states[tag] then
		SpeedManager.states[tag][state] = nil
	else
		warn(`[SpeedManager]: {tag} has no active states to be dropped.`)
	end

	if not noSet then
		SpeedManager:setSpeed()
	end
end

function SpeedManager:getAffects()
	return SpeedManager.affects
end
function SpeedManager:getStates()
	return SpeedManager.states
end

function SpeedManager:getSpeed()
	local speed = DEFAULT_SPEED

	for _, value in ipairs(SpeedManager.affects) do
		speed += value
	end

	for _, states in pairs(SpeedManager.states) do
		for state, _ in pairs(states) do
			if state == "freeze" then
				speed = 0
			end
		end
	end

	return speed
end

function SpeedManager:setSpeed()
	local character = Players.LocalPlayer.Character

	if character and character:FindFirstChild("Humanoid") then
		local speed = SpeedManager:getSpeed()

		character.Humanoid.WalkSpeed = speed
	else
		warn("[SpeedManager]: No character/character.Humanoid found, set failed.")
	end
end

return SpeedManager
