local GeodeService = {}
local engine

GeodeService.revealCompleted = Instance.new("BindableEvent")

local GeodeRevealSession
local sessionActive = false

function GeodeService.init(engineModule)
	engine = engineModule
	GeodeRevealSession = require(script.Parent.Parent.modules.Geodes.GeodeRevealSession)
	engine.events.Inventory.OnClientEvent:Connect(function(topic, data)
		if topic == "geodesOpened" then
			if sessionActive then return end
			sessionActive = true
			GeodeRevealSession.new(engine, data):run()
			GeodeService.revealCompleted:Fire()
			sessionActive = false
		end
	end)
end

return GeodeService
