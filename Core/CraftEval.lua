-- Craft evaluation: compares an item (the output of a recipe goal, or any item) with the gear the
-- character wears, using the character's stat weights, and puts the gain next to the sourcing
-- cost and farm time, the value of materials already owned and planned or possible alternatives.
-- Rated stats: STR, AGI, STA, INT, SPI. Armor, weapon damage, procs and set bonuses are not rated.
-- Item data comes from the adapter (GetItemStats, GetEquipSlots, GetEquippedItemID, GetSellPrice).
local _, ns = ...

local CraftEval = {}
ns.CraftEval = CraftEval

CraftEval.STATS = { "STR", "AGI", "STA", "INT", "SPI" }
CraftEval.MAX_WEIGHT = 10
CraftEval.MAX_ALTERNATIVES = 20
CraftEval.KINDS = { PLANNED = true, POSSIBLE = true }

local STAT_SET = {}
for _, stat in ipairs(CraftEval.STATS) do
	STAT_SET[stat] = true
end

function CraftEval.Score(stats, weights)
	local score = 0
	for _, stat in ipairs(CraftEval.STATS) do
		score = score + (stats[stat] or 0) * (weights[stat] or 0)
	end
	return score
end

-- Sets one weight (0..MAX_WEIGHT). Returns the value, or nil plus "invalid_weight".
function CraftEval.SetWeight(charData, stat, value)
	if not (STAT_SET[stat] and type(value) == "number" and value >= 0 and value <= CraftEval.MAX_WEIGHT) then
		return nil, "invalid_weight"
	end
	charData.craftEval.weights[stat] = value
	return value
end

local function scoreOf(itemID, weights)
	local stats = ns.Client:GetItemStats(itemID)
	return stats and CraftEval.Score(stats, weights)
end

-- Compares an item with the equipped item(s) of its slot(s).
-- Returns { itemID, score, equipped = { { slot (key from the adapter, e.g. "CHEST"), itemID (or nil
-- = empty), score } }, current, gain },
-- or nil plus "not_equippable" | "loading".
function CraftEval.CompareWithEquipped(itemID, weights)
	local slots = ns.Client:GetEquipSlots(itemID)
	if not slots then
		return nil, "not_equippable"
	end
	local score = scoreOf(itemID, weights)
	if not score then
		return nil, "loading"
	end
	local result = { itemID = itemID, score = score, equipped = {} }
	local current
	for _, slot in ipairs(slots) do
		local equippedID = ns.Client:GetEquippedItemID(slot)
		local equippedScore = 0
		if equippedID then
			equippedScore = scoreOf(equippedID, weights)
			if not equippedScore then
				return nil, "loading"
			end
		end
		result.equipped[#result.equipped + 1] = { slot = slot, itemID = equippedID, score = equippedScore }
		if slots.sum then
			current = (current or 0) + equippedScore
		elseif not current or equippedScore < current then
			current = equippedScore
		end
	end
	result.current = current or 0
	result.gain = score - result.current
	return result
end

-- The crafted item of a goal created from a recipe, or nil (enchantments, manual goals).
function CraftEval.GoalItemID(goal)
	local recipe = goal.recipeKey and ns.Recipes.Get(ns.db, goal.recipeKey)
	if recipe and recipe.outputItemID ~= 0 then
		return recipe.outputItemID
	end
	return nil
end

-- Value of the goal's materials the character already has (bags and bank, up to the need):
-- { vendor = copper (sell to a merchant), market = copper (planning price) or nil, complete }.
-- complete = false if a sell price or a market price is missing for an owned material.
function CraftEval.OwnedValue(charData, goal, realmKey, now)
	local value = { vendor = 0, market = 0, complete = true, owned = 0 }
	local maxAge = ns.db.settings.priceMaxAgeDays
	for _, row in ipairs(ns.Stock.Rows(charData, { goal })) do
		local have = math.min(row.need, row.bags + (row.bank or 0))
		if have > 0 then
			value.owned = value.owned + have
			local sell = ns.Client:GetSellPrice(row.itemID)
			local market = ns.Prices.Best(ns.db, realmKey, row.itemID, now, maxAge)
			value.vendor = value.vendor + have * (sell or 0)
			value.market = value.market + have * (market or 0)
			if not (sell and market) then
				value.complete = false
			end
		end
	end
	return value
end

-- Alternatives ---------------------------------------------------------------------------

-- Adds an alternative item: kind "PLANNED" (e.g. a quest reward you will get) or "POSSIBLE"
-- (an uncertain drop). The note is user text. Returns the new index, or nil plus an error code.
function CraftEval.AddAlternative(charData, itemID, kind, note, now)
	local list = charData.craftEval.alternatives
	if not ns.Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if not CraftEval.KINDS[kind] then
		return nil, "invalid_kind"
	end
	if #list >= CraftEval.MAX_ALTERNATIVES then
		return nil, "too_many_alternatives"
	end
	list[#list + 1] = { itemID = itemID, kind = kind, note = CraftEval.CleanNote(note), at = now or 0 }
	return #list
end

function CraftEval.RemoveAlternative(charData, index)
	local list = charData.craftEval.alternatives
	if not list[index] then
		return false
	end
	table.remove(list, index)
	return true
end

-- Optional details of an alternative, all set by the user: cost in copper, time effort in
-- seconds and the requirements as text. Absent fields mean "unknown".
local DETAIL_CHECKS = {
	copper = function(value)
		return type(value) == "number" and value >= 0 and value <= ns.Money.MAX_COPPER
	end,
	seconds = function(value)
		return type(value) == "number" and value >= 0 and value <= ns.Util.MAX_DURATION_SECONDS
	end,
	requires = function(value)
		return type(value) == "string" and value ~= ""
	end,
}

-- Sets detail `field` ("copper", "seconds" or "requires") of alternative `index`; nil clears it.
-- Returns true, or nil plus "alternative_not_found" / "invalid_value".
function CraftEval.SetAlternativeDetail(charData, index, field, value)
	local alt = charData.craftEval.alternatives[index]
	if not alt then
		return nil, "alternative_not_found"
	end
	assert(DETAIL_CHECKS[field], "unknown alternative detail")
	if field == "requires" and value ~= nil then
		value = CraftEval.CleanNote(value)
	end
	if value ~= nil and not DETAIL_CHECKS[field](value) then
		return nil, "invalid_value"
	end
	alt[field] = value
	return true
end

-- Notes are user text: same cleaning and length limit as goal labels.
function CraftEval.CleanNote(note)
	return ns.Materials.CleanLabel(note)
end

-- Validation of stored craft evaluation data (registered with DB.VALIDATORS).
local function sanitizeWeights(weights, path, repairs)
	for _, stat in ipairs(CraftEval.STATS) do
		local value = weights[stat]
		if not (type(value) == "number" and value >= 0 and value <= CraftEval.MAX_WEIGHT) then
			weights[stat] = 1
			repairs[#repairs + 1] = path .. ".weights." .. stat
		end
	end
end

local function validAlternative(alt)
	return type(alt) == "table" and ns.Materials.IsValidItemID(alt.itemID) and CraftEval.KINDS[alt.kind] == true
		and type(alt.note) == "string" and type(alt.at) == "number"
end

-- Drops invalid optional details; returns true if something was dropped.
local function sanitizeDetails(alt)
	local repaired = false
	for field, check in pairs(DETAIL_CHECKS) do
		if alt[field] ~= nil and not check(alt[field]) then
			alt[field] = nil
			repaired = true
		end
	end
	return repaired
end

function CraftEval.Sanitize(charData, path, repairs)
	local eval = charData.craftEval
	sanitizeWeights(eval.weights, path .. ".craftEval", repairs)
	local clean = {}
	for _, alt in ipairs(eval.alternatives) do
		if validAlternative(alt) and #clean < CraftEval.MAX_ALTERNATIVES then
			alt.note = CraftEval.CleanNote(alt.note)
			if sanitizeDetails(alt) then
				repairs[#repairs + 1] = path .. ".craftEval.alternatives[" .. (#clean + 1) .. "]"
			end
			clean[#clean + 1] = alt
		end
	end
	if #clean ~= #eval.alternatives then
		repairs[#repairs + 1] = path .. ".craftEval.alternatives"
	end
	eval.alternatives = clean
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = CraftEval.Sanitize
