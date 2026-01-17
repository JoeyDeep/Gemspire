-- LootRNG.lua
-- Modular, per-entry loot roller with luck, traits, weight curves, and score-nudged yield.
-- Now GUARANTEES: Every overall roll (RollFromEntries) returns at least ONE piece.

-- Public API:
--   LootRNG.RollFromEntries({
--       entries  = { {amount, pickaxe, score, zone}, ... },
--       zones    = { [zoneName] = { loot = { lootKey = weight, ... }, ... }, ... },
--       lootDefs = { [lootKey]  = { name, rarity, value_per_kg, kg_range={min,max}, traits={...}, weight_bias?, weight_luck_influence? }, ... },
--       kit      = { stats = { luck, capacity, ore_yield={min,max} } },
--       pickaxes = { [pickaxeName] = { stats={ luck, ... }, ... }, ... },
--       baseLuck = 1.0,                -- optional global multiplier
--       context  = any,                -- optional bag for your systems to read
--       opts     = {                   -- all optional; override hooks to customize behavior
--           rng = Random.new(),        -- seedable RNG
--           effectiveLuck = fn(kitLuck, baseLuck, pickaxeLuck, entry, context) -> number,
--           pickaxeLuck   = fn(pickaxeName, pickaxeDefs, entry, context) -> number,
--           qualityScore  = fn(lootDef, lootKey) -> number,
--           luckToQualityBoost = fn(effLuck) -> number,
--           adjustZoneWeights  = fn(zoneWeights, lootDefs, effLuck, qualityScoreFn, luckBoostFn, entry, context) -> dict,
--           adjustTraitWeights = fn(traitsTable, effLuck, entry, context) -> dict,
--           sampleWeight       = fn(lootDef, effLuck, rng, entry, context) -> number,
--           piecesFromEntry    = fn(kit, entry, rng, knobs) -> integer,
--           knobs = {
--               scoreNudge = 0.18,     -- how strongly entry.score nudges quantity (small effect)
--           }
--       }
--   }) -> { { lootKey, name, trait, kg, value_per_kg, value, rarity, _meta={...} }, ... }
--
-- Helper:
--   LootRNG.RollOne(args, entry) -> array of pieces for just that entry

local LootRNG = {}

-- ===============================
-- ============ UTILS ============
-- ===============================
local function clamp(x, a, b)
	return math.max(a, math.min(b, x))
end
local function lerp(a, b, t)
	return a + (b - a) * t
end

-- changed
local function shallowCopy(t)
	return table.clone(t)
end

local function sumWeights(t)
	local s = 0
	for _, w in pairs(t) do
		s += w
	end
	return s
end

local function weightedPick(dict, rng)
	local total = sumWeights(dict)
	if total <= 0 then
		return nil
	end
	local roll = (rng or Random.new()):NextNumber(0, total)
	local acc = 0
	for k, w in pairs(dict) do
		acc += w
		if roll <= acc then
			return k, w, total
		end
	end
	-- Fallback for edge precision
	for k in pairs(dict) do
		return k
	end
	return nil
end

-- If weightedPick fails, choose a reasonable fallback loot key.
local function safePickLootKey(zoneWeights, lootDefs, rng)
	local k = weightedPick(zoneWeights, rng)
	if k then
		return k
	end
	-- Try any zone key present in lootDefs with positive/any weight:
	local candidates = {}
	for key, w in pairs(zoneWeights or {}) do
		if lootDefs[key] and (w == nil or w > 0) then
			candidates[#candidates + 1] = key
		end
	end
	if #candidates > 0 then
		local i = (rng or Random.new()):NextInteger(1, #candidates)
		return candidates[i]
	end
	-- Final fallback: any key from lootDefs
	for key in pairs(lootDefs or {}) do
		return key
	end
	return nil
end

-- Bias > 1 => favors LOWER values (e.g., lighter weights more common)
-- Bias = 1 => uniform
-- Bias < 1 => favors HIGHER values
local function biasedLerp(minV, maxV, u, bias)
	bias = math.max(1e-6, bias)
	local t = u ^ bias
	return minV + (maxV - minV) * t
end

-- Stochastic rounding: returns floor/ceil so that E[result] ≈ x
local function stochasticRound(x, rng)
	local f = x - math.floor(x)
	if (rng or Random.new()):NextNumber() < f then
		return math.ceil(x)
	else
		return math.floor(x)
	end
end

-- ===============================
-- ===== DEFAULT HOOKS/KNOBS =====
-- ===============================
local Defaults = {}

-- Combine luck sources (extend later with events, auras, zone buffs, etc.)
function Defaults.effectiveLuck(kitLuck, baseLuck, pickaxeLuck)
	kitLuck = kitLuck or 1
	baseLuck = baseLuck or 1
	pickaxeLuck = pickaxeLuck or 1
	return kitLuck * baseLuck * pickaxeLuck
end

-- Default: pull luck directly from pickaxe definition
function Defaults.pickaxeLuck(pickaxeName, pickaxeDefs)
	local def = pickaxeDefs and pickaxeDefs[pickaxeName]
	local luck = def and def.stats and def.stats.luck or 1
	return luck
end

-- Score "quality" of a loot type to bias zone weights
function Defaults.qualityScore(lootDef)
	local v = lootDef.value_per_kg or 0
	local r = lootDef.rarity or 1
	return v * (1 + 0.15 * math.max(0, r - 1))
end

-- Map luck to tilt power; gentle curve by default
function Defaults.luckToQualityBoost(effLuck)
	return math.log(math.max(1e-6, effLuck)) / math.log(1.5)
end

-- Softly reweight zone table by quality using luck (keeps all items in play)
function Defaults.adjustZoneWeights(zoneWeights, lootDefs, effLuck, qualityScoreFn, luckBoostFn)
	local adjusted = {}
	local maxQ, minQ = -math.huge, math.huge
	for k in pairs(zoneWeights) do
		local q = qualityScoreFn(lootDefs[k] or {}, k)
		if q > maxQ then
			maxQ = q
		end
		if q < minQ then
			minQ = q
		end
	end
	local rangeQ = math.max(1e-6, maxQ - minQ)
	local boost = luckBoostFn(effLuck)
	for k, baseW in pairs(zoneWeights) do
		local q = qualityScoreFn(lootDefs[k] or {}, k)
		local q01 = (q - minQ) / rangeQ
		local tilt = math.exp(boost * (q01 - 0.5))
		adjusted[k] = baseW * tilt
	end
	return adjusted
end

-- Nudge trait weights away from "none" toward rare traits with luck
function Defaults.adjustTraitWeights(traitsTable, effLuck)
	local adjusted = {}
	local boost = math.log(math.max(1e-6, effLuck)) / math.log(1.7)
	local total = 0
	for trait, w in pairs(traitsTable) do
		local isNone = (trait == "none")
		local mult = isNone and (1 / (1 + 0.75 * math.max(0, boost))) or (1 + 0.75 * math.max(0, boost))
		local adj = w * mult
		adjusted[trait] = adj
		total += adj
	end
	if total > 0 then
		for t, w in pairs(adjusted) do
			adjusted[t] = w / total
		end
	end
	return adjusted
end

-- Sample a piece's mass; luck bends bias slightly toward heavier pieces
function Defaults.sampleWeight(lootDef, effLuck, rng)
	local r = lootDef.kg_range or { min = 0.1, max = 1 }
	local minKg, maxKg = r.min or 0.1, r.max or 1
	local baseBias = lootDef.weight_bias or 1.6 -- >1 = lighter more common
	local influence = lootDef.weight_luck_influence or 0.6 -- how strongly luck reduces light-bias
	local bias = clamp(baseBias - (effLuck - 1) * influence, 0.25, 3.0)
	local u = (rng or Random.new()):NextNumber()
	return biasedLerp(minKg, maxKg, u, bias)
end

-- Yield per entry: scale kit ore_yield by (entry.amount / kit.capacity), then nudge by entry.score
function Defaults.piecesFromEntry(kit, entry, rng, knobs)
	local oy = (kit.stats and kit.stats.ore_yield) or { min = 1, max = 1 }
	local cap = (kit.stats and kit.stats.capacity) or 10
	local amount = entry.amount or 0
	local share = cap > 0 and clamp(amount / cap, 0, 1) or 0
	if share <= 0 then
		return 0
	end

	local u = (rng or Random.new()):NextNumber() -- baseline uniform roll
	local score = clamp(entry.score or 0.5, 0, 1) -- 0..1
	local scoreCentered = (score - 0.5) -- -0.5..+0.5
	local scoreNudge = (knobs and knobs.scoreNudge) or 0.18
	local u2 = clamp(u + scoreCentered * scoreNudge, 0, 1)

	local minY = oy.min or 1
	local maxY = oy.max or minY
	local expectedFull = lerp(minY, maxY, u2) -- expected pieces if full capacity
	local expected = expectedFull * share -- scale by this entry's share

	return math.max(0, stochasticRound(expected, rng))
end

-- ===============================
-- ============ ROLL =============
-- ===============================

-- Rolls for ONE entry and returns an array of piece objects
function LootRNG.RollOne(args, entry)
	-- Validate required args
	local zones = assert(args.zones, "zones table is required (keyed by zone name)")
	local lootDefs = assert(args.lootDefs, "lootDefs table is required")
	local kit = assert(args.kit, "kit is required")
	local pickaxes = args.pickaxes or {}
	local baseLuck = args.baseLuck or 1
	local opts = args.opts or {}
	local rng = opts.rng or Random.new()
	local context = args.context

	-- Hooks
	local effLuckFn = opts.effectiveLuck or Defaults.effectiveLuck
	local pickaxeLuckFn = opts.pickaxeLuck or Defaults.pickaxeLuck
	local qualityScoreFn = opts.qualityScore or Defaults.qualityScore
	local luckBoostFn = opts.luckToQualityBoost or Defaults.luckToQualityBoost
	local adjustZoneFn = opts.adjustZoneWeights or Defaults.adjustZoneWeights
	local adjustTraitFn = opts.adjustTraitWeights or Defaults.adjustTraitWeights
	local sampleWeightFn = opts.sampleWeight or Defaults.sampleWeight
	local piecesFn = opts.piecesFromEntry or Defaults.piecesFromEntry

	-- Resolve zone
	local zoneName = entry.zone
	local zone = zones[zoneName]
	if not zone then
		-- Unknown zone: return nothing (caller can handle fallback)
		return {}
	end

	-- Quantity (per-entry)
	local pieces = piecesFn(kit, entry, rng, opts.knobs)
	if pieces <= 0 then
		return {}
	end

	-- Effective luck (kit * base * pickaxe)
	local kitLuck = (kit.stats and kit.stats.luck) or 1
	local pickaxeName = entry.pickaxe
	local pickaxeLuck = pickaxeLuckFn(pickaxeName, pickaxes, entry, context)
	local effLuck = effLuckFn(kitLuck, baseLuck, pickaxeLuck, entry, context)

	-- Adjust zone weights with luck tilt
	local zoneWeights = zone.loot or {}
	local adjustedWeights = adjustZoneFn(zoneWeights, lootDefs, effLuck, qualityScoreFn, luckBoostFn, entry, context)

	-- Roll pieces
	local out = {}
	for i = 1, pieces do
		-- 1) Loot type (safe pick to avoid nil)
		local lootKey = safePickLootKey(adjustedWeights, lootDefs, rng)
		if not lootKey then
			-- No viable loot anywhere; abort this piece (extremely rare edge)
			break
		end
		local def = lootDefs[lootKey] or {}

		-- 2) Trait (luck-adjusted; normalize even if weird input)
		local traits = def.traits or { none = 1 }
		local traitWeights = adjustTraitFn(traits, effLuck, entry, context, lootKey, def)
		local traitKey = weightedPick(traitWeights, rng) or "none"

		-- 3) Weight (kg) (luck-adjusted bias)
		local kg = sampleWeightFn(def, effLuck, rng, entry, context) or ((def.kg_range and def.kg_range.min) or 0.1)

		-- 4) Value
		-- local vpk = def.value_per_kg or 0
		-- local value = kg * vpk

		out[#out + 1] = {
			lootKey = lootKey,
			--name = def.name or lootKey,
			trait = traitKey,
			kg = kg,
			--value_per_kg = vpk,
			--value = value,
			--rarity = def.rarity or 1,
			_meta = {
				zone = zoneName or (zone.name or "UnknownZone"),
				entryAmount = entry.amount or 0,
				entryScore = entry.score or 0.5,
				pickaxe = pickaxeName,
				effLuck = effLuck,
				kitLuck = kitLuck,
				baseLuck = baseLuck,
				pieceIndex = i,
			},
		}
	end

	return out
end

-- Rolls for an array of entries and returns a flat array of all pieces.
-- GUARANTEE: If all entries yield 0, perform a one-piece "pity" roll using the best candidate entry.
function LootRNG.RollFromEntries(args)
	local entries = assert(args.entries, "entries array is required")
	local kit = assert(args.kit, "kit is required")

	local all = {}
	for _, entry in ipairs(entries) do
		local drops = LootRNG.RollOne(args, entry)
		for i = 1, #drops do
			all[#all + 1] = drops[i]
		end
	end

	if #all > 0 then
		return all
	end

	-- === PITY FALLBACK: ensure at least ONE piece ===
	-- Pick the "best" entry (highest (amount/capacity) * score) with a valid zone.
	local zones = assert(args.zones, "zones table is required (keyed by zone name)")
	local cap = (kit.stats and kit.stats.capacity) or 10

	local bestEntry, bestMetric = nil, -math.huge
	for _, e in ipairs(entries) do
		if e and zones[e.zone] then
			local share = (cap > 0) and clamp((e.amount or 0) / cap, 0, 1) or 0
			local metric = share * clamp(e.score or 0.5, 0, 1)
			if metric > bestMetric then
				bestMetric = metric
				bestEntry = e
			end
		end
	end
	-- If still nil, just take the first entry (if any)
	bestEntry = bestEntry or entries[1]
	if not bestEntry or not zones[bestEntry.zone] then
		-- As an ultimate safety, fabricate a single generic piece from any lootDef
		local lootDefs = assert(args.lootDefs, "lootDefs table is required")
		for lootKey, def in pairs(lootDefs) do
			local kg = (def.kg_range and def.kg_range.min) or 0.1
			all[1] = {
				lootKey = lootKey,
				name = def.name or lootKey,
				trait = "none",
				kg = kg,
				value_per_kg = def.value_per_kg or 0,
				value = kg * (def.value_per_kg or 0),
				rarity = def.rarity or 1,
				_meta = { pity = true },
			}
			return all
		end
		-- If no lootDefs at all, return empty (nothing else we can do)
		return all
	end

	-- Force a 1-piece roll for the chosen entry by overriding piecesFromEntry.
	local forcedArgs = shallowCopy(args)
	forcedArgs.opts = shallowCopy(args.opts or {})
	forcedArgs.opts.piecesFromEntry = function()
		return 1
	end

	local drops = LootRNG.RollOne(forcedArgs, bestEntry)
	if #drops > 0 then
		all[1] = drops[1]
		return all
	end

	-- Final ultra-rare safety: fabricate from lootDefs
	local lootDefs = assert(args.lootDefs, "lootDefs table is required")
	for lootKey, def in pairs(lootDefs) do
		local kg = (def.kg_range and def.kg_range.min) or 0.1
		all[1] = {
			lootKey = lootKey,
			name = def.name or lootKey,
			trait = "none",
			kg = kg,
			value_per_kg = def.value_per_kg or 0,
			value = kg * (def.value_per_kg or 0),
			rarity = def.rarity or 1,
			_meta = { pity = true, fallback = true },
		}
		break
	end
	return all
end

LootRNG.Defaults = Defaults

return LootRNG
