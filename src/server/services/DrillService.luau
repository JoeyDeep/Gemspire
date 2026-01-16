local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local DrillService = {}
local HttpService = game:GetService("HttpService")
local DrillUtility = require(ReplicatedStorage.Shared.utils.DrillUtility)

local engine
function DrillService.init(engineModule)
	engine = engineModule

	local PlayerService = engine:get("PlayerService")

	engine.events.Drill.OnServerEvent:Connect(function(player, event, data)
		if event == "placeDrill" then
			DrillService:placeDrill(player, data)
		elseif event == "collectLoot" then
			DrillService:collectLoot(player)
		elseif event == "pickupDrill" then
			DrillService:pickupPlayerDrill(player)
		end
		
	end)

	PlayerService.PlayerRemoved:Connect(function(player)
		DrillService:removePlayerDrill(player)
	end)
end

function DrillService:collectLoot(player)
	local InventoryService = engine:get("InventoryService")
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	local lootYield = DrillService:calculateTotalYield(player)

	if  not DrillService:checkPlayerWithinMinimumDistanceOfDrill(player) then
		return
	end


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

	engine.events.Drill:FireClient(player,"lootCollected",lootArray)


end

function DrillService:placeDrill(player, data)
	-- client is checking about drill placement. server needs to check this
	local PlayerService = engine:get("PlayerService")
	local DrillUtility = engine:get("DrillUtility")
	local playerData = PlayerService:getData(player)
	local character = player.Character
	local tool = character:FindFirstChildOfClass("Tool")
	local storage = ReplicatedStorage.Storage
	


	local targetPivot = DrillUtility:getDrillTargetPivot(player)


	if tool and targetPivot and DrillService:canPlayerPlaceDrill(player,targetPivot.Position) then
		-- Placed drills location in storage could be more clear
		local placedDrill = storage.Tools.Drills.Placed.Drill:Clone()
		placedDrill.Parent = game.Workspace.Entities.Drills
		

		placedDrill:PivotTo(targetPivot)

		placedDrill:setAttribute("Owner",player.UserId)

		playerData.drill.spawnTime = os.time()
		playerData.drill.position = targetPivot.Position

		PlayerService:get(player):updateClient({"drill"})
	else
		print("player cannot place drill")
	end
end


function DrillService:pickupPlayerDrill(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	playerData.drill.spawnTime = nil
	playerData.drill.position = nil
	PlayerService:get(player):updateClient({"drill"})

	DrillService:removePlayerDrill(player)

	engine.events.Drill:FireClient(player,"drillPickedUp")

	
end

function DrillService:removePlayerDrill(player)
	local DrillUtility = engine:get("DrillUtility")

	local drillToRemove = DrillUtility:findPlayerDrill(player)

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
	local Drills = engine:get("Drills")
	local DrillUtility = engine:get("DrillUtility")

	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)
	local drillDensity = Drills[playerData.drill.type].density

	

	local mineZone = DrillUtility:getMineZoneFromPosition(targetPosition)

	if mineZone and drillDensity >= mineZone.minDensity and not DrillService:playerHasActiveDrill(player) then
		result = true
	end

	return result
end

function DrillService:evaluateDrillRng(totalLoot,drill)
	local DrillUtility = engine:get("DrillUtility")

	local lootDefinitions = engine:get("Loot")
	local drillDefinitions = engine:get("Drills")
	local mineZone = DrillUtility:getMineZoneFromPosition(drill.position)


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




function DrillService:checkPlayerWithinMinimumDistanceOfDrill(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	print("distance")
	print(player:DistanceFromCharacter(playerData.drill.position))


	return player:DistanceFromCharacter(playerData.drill.position) <= 20
end


function DrillService:playerHasActiveDrill(player)
	local PlayerService = engine:get("PlayerService")
	local playerData = PlayerService:getData(player)

	return playerData.drill.spawnTime or playerData.drill.position
end


return DrillService