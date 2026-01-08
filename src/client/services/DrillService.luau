local DrillService = {
	placedDrill = nil
}
DrillService.__index = DrillService

local engine
function DrillService.init(engineModule)
	engine = engineModule

	engine.events.Drill.OnClientEvent:Connect(function(topic)
		if topic == "lootCollected" then
			DrillService.placedDrill:startProgressBar()
		end
	end)

	game.Workspace.Entities.Drills.ChildAdded:Connect(function(drillObject)

		-- if DrillService:checkDrillBelongsToLocalPlayer(drillObject) then
			DrillService.placedDrill = engine:get("PlacedDrill").new(drillObject)
		-- end

	end)

	local allDrills = game.Workspace.Entities.Drills:GetChildren()

	for index, drill in ipairs(allDrills) do
		if DrillService:checkDrillBelongsToLocalPlayer(drill) then
			DrillService.placedDrill = engine:get("PlacedDrill").new(drill)
		end
	end
	
end



function DrillService:checkDrillBelongsToLocalPlayer(drillObject)

	local player = game:GetService("Players").LocalPlayer

	local owner = drillObject:getAttribute("Owner")

	return player.UserId == owner

end

return DrillService