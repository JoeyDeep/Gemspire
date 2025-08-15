local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sieve = {}

local engine
function Sieve.init(engineModule)
	engine = engineModule
end

function Sieve:start(data)
	Sieve.Data = data

	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	sieveUI.Container.Bar.Slider.Size = UDim2.fromScale(data.now / data.max, 1)
	sieveUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	sieveUI.Container.QualityText.Text = `Quality: {data.quality}%`

	sieveUI.Visible = true
end

function Sieve:startSifting()
	print("Sifting started")
end

function Sieve:update(data)
	Sieve.Data = data

	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	QuickTween(sieveUI.Container.Bar.Slider, 0.2, { Size = UDim2.fromScale(data.now / data.max, 1) })
	sieveUI.Container.Bar.CapacityText.Text = `{data.now}/{data.max}`
	sieveUI.Container.QualityText.Text = `Quality: {data.quality}%`

	Promise.fromEvent(QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 }).Completed)
		:andThen(function()
			QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	if data.now == data.max then
		sieveUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 75, 77)
	else
		sieveUI.Container.Bar.CapacityText.TextColor3 = Color3.fromRGB(230, 230, 230)
	end
end

function Sieve:warnFull()
	local QuickTween = engine:get("QuickTween")
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	local negative = math.random() > 0.5

	QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1.1 })
	Promise.fromEvent(
		QuickTween(sieveUI.Container.Bar.CapacityText, 0.2, { Rotation = (negative and -5) or 5 }).Completed
	)
		:andThen(function()
			QuickTween(sieveUI.Container.Bar.CapacityText, 0.2, { Rotation = 0 })
			QuickTween(sieveUI.Container.Bar.CapacityText.UIScale, 0.2, { Scale = 1 })
		end)

	engine:get("NotificationService").new("Your sieve is full!", { italic = true })
end

function Sieve:stop()
	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local sieveUI = ui:WaitForChild("Sieve")

	sieveUI.Visible = false
end

return Sieve
