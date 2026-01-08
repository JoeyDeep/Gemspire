local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local DrillService = {}
local HttpService = game:GetService("HttpService")

local engine
function DrillService.init(engineModule)
	engine = engineModule

	local PlayerService = engine:get("PlayerService")

	engine.events.Drill.OnServerEvent:Connect(function(player, event, data)
		if event == "placeDrill" then
			DrillService:placeDrill(player, data)
		elseif event == "collectLoot" then
			DrillService:collectLoot(player)
		end
		
	end)

	PlayerService.PlayerRemoved:Connect(function(player)
		DrillService:RemovePlayerDrill(player)
	end)
end

function DrillService:collectLoot(player)
	local InventoryService = engine:get("InventoryService")
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local lootYield = DrillService:calculateTotalYield(player)


	local lootArray = DrillService:evaluateDrillRng(lootYield,playerData.drill)


	for index, loot in ipairs(lootArray) do
		local lootId = HttpService:GenerateGUID(false)
		table.insert(playerData.inventory.loot, { name = loot.key, trait = loot.traits, weight = loot.kg, id =  lootId})
		InventoryService:drawHoldLoot({player=player}, {lootKey = loot.key, trait = loot.traits, kg = loot.kg},lootId)
	end

	if #lootArray ~= 0 then
		playerData.drill.spawnTime = os.time()
	end
	

	PlayerService:get(player):updateClient({"inventory","drill"})

	engine.events.Drill:FireClient(player,"lootCollected")


end

function DrillService:placeDrill(player, data)
	-- client is checking about drill placement. server needs to check this
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local character = player.Character
	local tool = character:FindFirstChildOfClass("Tool")
	local storage = ReplicatedStorage.Storage


	local targetPivot = DrillService:getDrillTargetPivot(player)


	if tool and DrillService:canPlayerPlaceDrill(player,targetPivot.Position) then
		-- Placed drills location in storage could be more clear
		local placedDrill = storage.Tools.Drills.Placed.Drill:Clone()
		placedDrill.Parent = game.Workspace.Entities.Drills
		

		placedDrill:PivotTo(targetPivot)

		placedDrill:setAttribute("Owner",player.UserId)

		playerData.drill.spawnTime = os.time()
		playerData.drill.position = targetPivot.Position

		-- add an owner attribute to drill

		PlayerService:get(player):updateClient({"drill"})

	end
end

function DrillService:RemovePlayerDrill(player)
	local drillToRemove = DrillService:findPlayerDrill(player)

	if drillToRemove then
		drillToRemove:Destroy()
	end

end

function DrillService:calculateTotalYield(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local Drills = engine:get("Drills")

	local drillInfo = Drills[playerData.drill.type]

	local interval = drillInfo.lootInterval * 60
	local totalProgress = os.time() - playerData.drill.spawnTime
	local totalYield = math.floor(totalProgress / interval)

	if totalYield > drillInfo.maxLoot then 
		totalYield = drillInfo.maxLoot
	end 

	return totalYield
end

function DrillService:canPlayerPlaceDrill(player,targetPosition)
	local result = false
	local MineZones = engine:get("MineZones")
	local character = player.Character

	if DrillService:getMineZoneFromPosition(targetPosition) then
		result = true
	end

	return result
end

function DrillService:evaluateDrillRng(totalLoot,drill)


	local lootDefinitions = engine:get("Loot")
	local drillDefinitions = engine:get("Drills")
	local mineZone = DrillService:getMineZoneFromPosition(drill.position)


	local rngEvaluator = engine:get("RngEvaluator").new(mineZone.loot, lootDefinitions)

	rngEvaluator:applyModifier({
		type="mult", 
		value=drillDefinitions[drill.type].luck 
	})

	rngEvaluator:addAttachment({
		resultKey="kg",
		eval = {
			type="rangeSelectWithLowBias", 
			key = "kg_range", 
			precision = 1 
			-- definitionTable = engine:get("Loot"), -- If needed we can do this to supply a special definition table
		}
	})

	rngEvaluator:addAttachment({
		resultKey="traits",
		eval = {
			type="selectFromRarityTable", 
			key ="traits", 
		}
	})

	return rngEvaluator:generateResultArray(totalLoot)

end


function DrillService:getDrillTargetPivot(player)

	local character = player.Character
	local playerRoot = character:WaitForChild("HumanoidRootPart")

	-- make a raycast including terrain
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local cast = workspace:Raycast(character:GetPivot().Position + playerRoot.CFrame.LookVector * 2 + Vector3.new(0,1,0), Vector3.new(0, -20, 0), params)


	return CFrame.new(cast.Position + playerRoot.CFrame.LookVector * 2 )

end

function DrillService:getMineZoneFromPosition(position)
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

function DrillService:findPlayerDrill(player)
	local result = nil

	local allDrills = game.Workspace.Entities.Drills:GetChildren()

	for index, drill in ipairs(allDrills) do
		if DrillService:checkDrillBelongsToPlayer(player,drill) then
			result = drill;
			break;
		end
	end

	return result
end

function DrillService:checkDrillBelongsToPlayer(player,drillObject)

	local owner = drillObject:getAttribute("Owner")

	return player and (player.UserId == owner)

end

return DrillService