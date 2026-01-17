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
		result.key = self:weightedPick(self.rarityTable)
		self:evalAttachments(result)
		table.insert(results, result)
	end

	return results
end



function RngEvaluator:applyModifier(modifier)

	if modifier.type == "mult" then 
		self:applyMultModifier(modifier)
	end

end

function RngEvaluator:addAttachment(attachment)

	table.insert(self.attachments,attachment)

end

-- PRIVATE ------------------------------------------------

function RngEvaluator:evalAttachments(rngResult)
	for index, attachment in ipairs(self.attachments) do
		rngResult[attachment.resultKey] = self:evaluateAttachment(rngResult,attachment.eval)
	end
end

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

function RngEvaluator:applyMultModifier(modifier)
	self.multiplyer = self.multiplyer * modifier.value
end

-- ATTACHMENTS

-- eval includes
-- {
-- 	key: what key from the definition table contains the rarityTable
-- }
function RngEvaluator:selectFromRarityTable(definition,eval)

	local rarityTable = definition[eval.key]

	return self:weightedPick(rarityTable)

end

-- eval includes
-- {
-- 	key: what key from the definition table contains the range
-- 	precision: how many decimal places to include
-- }
function RngEvaluator:rangeSelectWithLowBias(definition,eval)

	local range = definition[eval.key]

	local precision = eval.precision

	if not precision or not range or not range.min or not range.max then
		-- we are missing something. just return 1
		return 1
	end

	return self:lowValueBiasRangePick(range.min,range.max,precision)

end

-- PICK FUNCTIONS

function RngEvaluator:weightedPick(rarityTable)
	local total = self:sumWeights(rarityTable)
	if total <= 0 then
		return nil
	end
	local roll = self.rng:NextNumber(0, total)

	-- apply our multiplyer 
	roll = roll*self.multiplyer

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