local GemspireRngService = {
	activeClass = nil,
	lootDefinitions = nil,
	drillDefinitions = nil,
	pickaxeDefinitions = nil,
	kitDefinitions = nil,
	mineZones = nil,
	worldEvents = nil,
	statMods = nil,
	baseLuck = 1,
}

local engine
function GemspireRngService.init(engineModule)
	engine = engineModule

	
end

function GemspireRngService.new(playerData)
	local self = setmetatable(GemspireRngService,{})

	GemspireRngService.activeClass = self

	self.lootDefinitions = engine:get("Loot")
	self.drillDefinitions = engine:get("Drills")
	self.pickaxeDefinitions = engine:get("Pickaxes")
	self.kitDefinitions = engine:get("Kits")
	self.mineZones = engine:get("MineZones")

	local WorldEventService = engine:get("WorldEventService")
	self.worldEvents = WorldEventService:getRngOptions()
	self.mineZones = WorldEventService:applyLootZones(self.mineZones)

	local ModifierManager = engine:get("ModifierManager")
	self.statMods = ModifierManager:accumulateStatModifiers(playerData)

	-- print("world events",self.worldEvents)
	-- print("world zones",self.mineZones)
	-- print("stat mods",self.statMods)


	return self
end




function GemspireRngService:evaluateDrillRng(totalLoot,drill)

	local DrillUtility = engine:get("DrillUtility")

	

	local mineZoneName = DrillUtility:getMineZoneNameFromPosition(drill.position)

	local mineZoneTable = GemspireRngService.mineZones[mineZoneName]
	

	local WorldEventService = engine:get("WorldEventService")
	local zoneLootDefinitions = WorldEventService:applyTraitModifiersForZone(GemspireRngService.lootDefinitions, mineZoneName)

	local rngEvaluator = engine:get("RngEvaluator").new(mineZoneTable.loot, zoneLootDefinitions)

	local baseLuck = self.drillDefinitions[drill.type].luck 

	baseLuck = self:applyStatModifiers(baseLuck)

	rngEvaluator:applyModifier({
		type="multScaledDown", 
		value=baseLuck,
		scale=0.05
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

function GemspireRngService:evaluateKitEntriesRng(entries)
	-- print("entries")
	-- print(entries)

	local results = {}

	for index, entry in ipairs(entries) do 
		local entryResults = GemspireRngService:evaluateEntryRng(entry)
		for index, result in ipairs(entryResults) do 
			table.insert(results,result)
		end
		
	end

	return results

end

function GemspireRngService:evaluateEntryRng(entry)

	if not self:validateEntry(entry) then
		return nil --invalid entry do something here. return pity result
	end

	local mineZoneTable = GemspireRngService.mineZones[entry.zone]
	local pickaxeTable = GemspireRngService.pickaxeDefinitions[entry.pickaxe]
	local kitTable = GemspireRngService.kitDefinitions[entry.kit]
	
	local WorldEventService = engine:get("WorldEventService")
	local zoneLootDefinitions = WorldEventService:applyTraitModifiersForZone(GemspireRngService.lootDefinitions, entry.zone)

	local rngEvaluator = engine:get("RngEvaluator").new(mineZoneTable.loot, zoneLootDefinitions)

	local baseLuck = pickaxeTable.stats.luck + kitTable.stats.luck

	baseLuck = self:applyStatModifiers(baseLuck)


	-- base luck works like (1 + baseLuck * 0.01)
	-- once base luck is applied as a modifier it will affect all calcs
	rngEvaluator:applyModifier({
		type="multScaledDown", 
		value=baseLuck,
		scale=0.05
	})

	-- select a value from the loot definition table. value select influenced by base luck
	rngEvaluator:addAttachment({
		resultKey="trait",
		eval = {
			type="selectFromRarityTable", 
			key = "traits", 
		}
	})

	-- select a value in range from the loot definition table. 
	-- value select influenced by base luck multiplied by entry score
	rngEvaluator:addAttachment({
		resultKey="kg",
		eval = {
			type="rangeSelectWithLowBias", 
			key = "kg_range", 
			precision = 1,
			multiplyBy = entry.score
		}
	})

	local kitRange = kitTable.stats.loot_yield

	local entryTotalYield = rngEvaluator:lowValueBiasRangePick(kitRange.min,kitRange.max,0)

	return rngEvaluator:generateResultArray(entryTotalYield)

end

function GemspireRngService:applyStatModifiers(baseLuck)

	local result = baseLuck

	if self.statMods and self.statMods.luck then 
		result = result + result * self.statMods.luck
	end

	return result
end


function GemspireRngService:validateEntry(entry)

	local mineZoneTable = GemspireRngService.mineZones[entry.zone]
	local pickaxeTable = GemspireRngService.pickaxeDefinitions[entry.pickaxe]
	local kitTable = GemspireRngService.kitDefinitions[entry.kit]

	return entry.zone and 
		entry.pickaxe and 
		entry.kit and 
		mineZoneTable and
		pickaxeTable and
		kitTable and
		mineZoneTable.loot and
		pickaxeTable.stats and
		kitTable.stats and
		pickaxeTable.stats.luck and
		kitTable.stats.luck and
		kitTable.stats.loot_yield and
		kitTable.stats.loot_yield.min and 
		kitTable.stats.loot_yield.max
end

return GemspireRngService