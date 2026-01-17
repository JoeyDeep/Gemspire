local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local CollectionService = game:GetService("CollectionService")


local DrillUtility = {}

local engine
function DrillUtility.init(engineModule)
	engine = engineModule
end

function DrillUtility:findPlayerDrill(player)
	local result = nil

	local allDrills = game.Workspace.Entities.Drills:GetChildren()

	for index, drill in ipairs(allDrills) do
		if DrillUtility:checkDrillBelongsToPlayer(player,drill) then
			result = drill;
			break;
		end
	end

	return result
end

function DrillUtility:checkDrillBelongsToPlayer(player,drillObject)

	local owner = drillObject:getAttribute("Owner")

	return player and (player.UserId == owner)

end


function DrillUtility:paintPlayerDrill(player,drillObject)
	

	local playerData = DrillUtility:getPlayerData(player)

	


	local drillType = playerData.drill.type

	local drillDefinitions = engine:get("Drills")

	local drillInfo = drillDefinitions[drillType]

	print("painting")
	print(drillInfo)
	print(drillInfo.material)

	
	local descendants = drillObject:GetDescendants()

	for _, descendant in pairs(descendants) do

		if CollectionService:HasTag(descendant, "painted") then
			descendant.Material = drillInfo.material
			descendant.Color = drillInfo.color

		end
	end

end

function DrillUtility:drillDensityCheck(player,targetPosition)

	local Drills = engine:get("Drills")

	local playerData = DrillUtility:getPlayerData(player)

	local drillDensity = Drills[playerData.drill.type].density

	local mineZone = DrillUtility:getMineZoneFromPosition(targetPosition)

	return mineZone and drillDensity >= mineZone.minDensity 

end

function DrillUtility:getMineZoneFromPosition(position)
	local result = nil

	local MineZones = engine:get("MineZones")

	-- make a raycast including only MineZones
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Entities.MineZones }
	local cast = workspace:Raycast(position, Vector3.new(0, -20, 0), params)


	if cast and cast.Instance:IsDescendantOf(workspace.Entities.MineZones) then
		result = MineZones[cast.Instance.Parent.Name]
	end

	return result

end

function DrillUtility:getDrillTargetPivot(player)

	local character = player.Character
	local playerRoot = character:WaitForChild("HumanoidRootPart")

	-- make a raycast including terrain
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain, workspace.Entities.MineZones }

	local position = character:GetPivot().Position + playerRoot.CFrame.LookVector * 5 + Vector3.new(0,1,0)
	local cast = workspace:Raycast(position, Vector3.new(0, -20, 0), params)


	if not cast then 
		return nil
	end

	return CFrame.lookAt(cast.Position  , Vector3.new(playerRoot.Position.x,cast.Position.y,playerRoot.Position.z) )


end

function DrillUtility:getPlayerData(player)
	local playerData
	local RunService = game:GetService("RunService")

	if RunService:IsServer() then
		local PlayerService = engine:get("PlayerService")
		playerData = PlayerService:getData(player)
	else
		playerData = engine:get("PlayerService").data
	end

	return playerData
end

return DrillUtility