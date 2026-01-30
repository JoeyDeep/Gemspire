local RngEvaluator = {
	activeClass = nil,
	multiplyer = 1,
	rng = Random.new(),
	rarityTable = {},
	definitionTable = {},
	attachments = {},

}
RngEvaluator.__index = RngEvaluator

-- PUBLIC -----------------------------------------------

function RngEvaluator.new(rarityTable,definitionTable)
	local self = setmetatable({}, RngEvaluator)

	self.rarityTable = rarityTable
	self.definitionTable = definitionTable

	return self
end

function RngEvaluator:generateResultArray(numberOfResults)
	local results = {}

	for i = 1, numberOfResults do
		local result = {}
		result.key = self:weightedPickWithMult(self.rarityTable)
		self:evalAttachments(result)
		table.insert(results, result)
	end

	return results
end



function RngEvaluator:applyModifier(modifier)

	if modifier.type == "mult" then 
		self:applyMultModifier(modifier)
	elseif modifier.type == "multScaledDown" then 
		self:applyMultScaledDownModifier(modifier)
	elseif modifier.type == "add" then 
		self:applyAddModifier(modifier)
	end

end

function RngEvaluator:addAttachment(attachment)

	table.insert(self.attachments,attachment)

end

-- PRIVATE ------------------------------------------------
-- attachment includes
-- {
-- 	resultKey: name of key to put the computed value into
-- 	eval: table that has information needed to evaluate attachment
-- }
function RngEvaluator:evalAttachments(rngResult)
	for index, attachment in ipairs(self.attachments) do
		rngResult[attachment.resultKey] = self:evaluateAttachment(rngResult,attachment.eval)
	end
end

-- eval includes
-- {
-- 	type: what kind of attachment calculation this is,
-- 	key: key referenced against the definition table for needed values
-- }
function RngEvaluator:evaluateAttachment(rngResult,eval)

	local result = nil

	-- for a particular attachment we may have a special definition table
	local definitionTable = eval.definitionTable or self.definitionTable

	if not rngResult.key or not eval.key then
		-- we are missing something needed. return now
		return result
	end

	local definition = definitionTable[rngResult.key]
	
	if eval.type == "selectFromRarityTable" then
		result = self:selectFromRarityTable(definition,eval)
	elseif eval.type == "rangeSelectWithLowBias" then
		result = self:rangeSelectWithLowBias(definition,eval)
	end

	return result
end

-- MODIFIERS
function RngEvaluator:applyMultScaledDownModifier(modifier)
	self.multiplyer = self.multiplyer + (modifier.value * modifier.scale)
end

function RngEvaluator:applyMultModifier(modifier)
	self.multiplyer = self.multiplyer * modifier.value
end

function RngEvaluator:applyAddModifier(modifier)
	self.multiplyer = self.multiplyer + modifier.value
end


-- ATTACHMENTS

-- eval includes
-- {
-- 	key: what key from the definition table contains the rarityTable
-- }
function RngEvaluator:selectFromRarityTable(definition,eval)

	local rarityTable = definition[eval.key]

	return self:weightedPickWithMult(rarityTable)

end

-- eval includes
-- {
-- 	key: what key from the definition table contains the range
-- 	precision: how many decimal places to include
--  multiplyBy: end result is multiplied by this value (optional)
-- }
function RngEvaluator:rangeSelectWithLowBias(definition,eval)

	local range = definition[eval.key]

	local precision = eval.precision

	if not precision or not range or not range.min or not range.max then
		-- we are missing something. just return 1
		return 1
	end

	local result =  self:lowValueBiasRangePick(range.min,range.max,precision)

	if eval.multiplyBy then 
		result = result * eval.multiplyBy
	end

	return result

end

-- LUCK APPLIER

function RngEvaluator:applyMultiplier(weightedTable)

    if self.multiplyer == 1 then 
		return weightedTable 
	end

    local newWeights = {}
    local sum = 0

    -- Simple version: boost everything below average weight
    local total = 0
    for _, w in weightedTable do total += w end
    local avg = total / self:sumWeights(weightedTable)  -- or use # if array

    for item, weight in weightedTable do
        if weight < avg then
            -- rarer items get boosted more aggressively
            newWeights[item] = weight * (1 + (self.multiplyer - 1) * (1 - weight / avg))
        else
            newWeights[item] = weight / self.multiplyer ^ 0.5   -- common items slightly penalized
        end
        sum += newWeights[item]
    end

    -- normalize back to original total (optional but nice)
    if sum > 0 then
        for item in newWeights do
            newWeights[item] *= total / sum
        end
    end

    return newWeights
end

function RngEvaluator:withLuckBoost(weights)
    local boosted = {}
    local sum = 0

    for item, w in weights do
        if w <= 0 then continue end
        local rarity = 1 / w
        boosted[item] = rarity ^ self.multiplyer
        sum += boosted[item]
    end

    for item in boosted do
        boosted[item] = (boosted[item] / sum) * self:sumWeights(weights) -- keep original scale
    end

    return boosted
end

-- PICK FUNCTIONS

function RngEvaluator:weightedPickWithMult(rarityTable)
	-- print("Getting pick",self.multiplyer,rarityTable)
	-- print("after mods")
	-- print(self:applyMultiplier(rarityTable))
	-- print(self:withLuckBoost(rarityTable))
	return self:weightedPick(self:applyMultiplier(rarityTable))
end

function RngEvaluator:weightedPick(rarityTable)
	local total = self:sumWeights(rarityTable)
	if total <= 0 then
		return nil
	end
	local roll = self.rng:NextNumber(0, total)

	local acc = 0
	for k, w in pairs(rarityTable) do
		acc += w
		if roll <= acc then
			return k, w, total
		end
	end
	-- Fallback for edge precision
	for k in pairs(rarityTable) do
		return k
	end
	return nil
end

function RngEvaluator:lowValueBiasRangePick(min,max,precision)
	local result = 1

	-- default multiplyer of 1 will result in -0.5 bias which is 64% of results below midpoint
	-- raising the multiplyer results in higher yields 
	local bias = self.multiplyer - 1.5

	result = self:biasRangePick(min,max,precision, bias)

	return result
end

-- 0 is neutral bias
-- bias < 0 will result in smaller numbers
-- bias > 0 will result in larger numbers
function RngEvaluator:biasRangePick(min,max,precision,bias)
	bias = bias or 0

    local t = self.rng:NextNumber()  -- High-quality [0,1)

    local biasedT
    if bias == 0 then
        biasedT = t
    elseif bias > 0 then
        biasedT = t ^ (1 / (1 + bias))
    else
        biasedT = 1 - (1 - t) ^ (1 / (1 - bias))
    end

    local value = min + (max - min) * biasedT
    local multiplier = 10 ^ precision
    return math.floor(value * multiplier + 0.5) / multiplier
end

function RngEvaluator:sumWeights(t)
	local s = 0
	for _, w in pairs(t) do
		s += w
	end
	return s
end




return RngEvaluator