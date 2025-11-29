--[[
	PURPOSE:
		Manage and display low-priority notifications to the player.
	USAGE:
		```lua
		local NotificationService = require(engine:get("NotificationService"))
		NotificationService.new("This is a notification message!", { timeout = 5, italic = true, textColor = Color3.new(1, 0, 0) })
		```

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local NotificationService = {}
NotificationService.__index = NotificationService

local engine
function NotificationService.init(engineModule)
	engine = engineModule
end

function NotificationService.new(message, data)
	local self = {}
	self.message = message
	self.data = data
	self.timeout = self.data.timeout or math.max(string.len(message) * 0.1, 3)

	self = setmetatable(self, NotificationService)

	self.object = self:_build()
	self:send()

	return self
end

function NotificationService:send()
	local QuickTween = engine:get("QuickTween")
	self.object.Visible = true
	self.object.Parent =
		Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI"):WaitForChild("LowNotification").Container

	Promise.delay(self.timeout - 1):andThen(function()
		if self.object and self.object.Parent then
			QuickTween(self.object, 1, { TextTransparency = 1 })
			Promise.fromEvent(QuickTween(self.object.UIStroke, 1, { Transparency = 1 }).Completed):andThen(function()
				self:destroy()
			end)
		end
	end)
end

function NotificationService:_build()
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local notificationUI = ui:WaitForChild("LowNotification")

	local newNotification = notificationUI.Container.Template:Clone()
	newNotification.Name = self.message
	newNotification.Text = self.message

	if self.data.italic then
		newNotification.Text = `<i>{self.message}</i>`
	end
	if self.data.bold then
		newNotification.Text = `<b>{self.message}</b>`
	end
	if self.data.textColor then
		newNotification.TextColor3 = self.data.textColor
	end
	if self.data.strokeColor then
		newNotification.UIStroke.Color = self.data.strokeColor
	end

	return newNotification
end

function NotificationService:destroy()
	if self.object and self.object.Parent then
		self.object:Destroy()
	end
	self.object = nil
	self = nil
end

return NotificationService
