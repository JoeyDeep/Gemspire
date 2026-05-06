local Players = game:GetService("Players")


local DrillService = {
	placedDrill = nil
}
DrillService.__index = DrillService

local engine
function DrillService.init(engineModule)
	engine = engineModule

	engine.events.Drill.OnClientEvent:Connect(function(topic,data)
		if topic == "lootCollected" then
			DrillService.placedDrill:confirmCollectLoot(data)
		elseif topic == "drillPickedUp" then
			DrillService:equipPlayerDrill()
		end
	end)

	game.Workspace.Entities.Drills.ChildAdded:Connect(function(drillObject)

		if DrillService:checkDrillBelongsToLocalPlayer(drillObject) then
			DrillService.placedDrill = engine:get("PlacedDrill").new(drillObject)
		end

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

	local owner = drillObject:GetAttribute("Owner")

	return player.UserId == owner

end


function DrillService:equipPlayerDrill()

	local character = Players.LocalPlayer.Character
	character.Humanoid:UnequipTools()

	task.delay(0.1,function()
		local backpack = Players.LocalPlayer.Backpack
		local drill = backpack:FindFirstChild(engine:get("PlayerService").data.drill.type)
		if not drill then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("Type") == "Drill" then
					drill = tool
					break
				end
			end
		end
		if drill then
			character.Humanoid:EquipTool(drill)
		end
	end)
	
	
end

return DrillService
