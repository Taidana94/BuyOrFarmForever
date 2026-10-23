-- Gear rating: compares an item (a crafted or wanted item, or any item) with the gear the character
-- wears, using the character's stat weights (shown in the professions detail, the item tooltip of
-- wanted gear and /bof craft <item>).
-- Rated stats: STR, AGI, STA, INT, SPI, ARMOR (points) and DPS (weapon damage per second); procs,
-- other effects and set bonuses are not rated. ARMOR and DPS weigh 0 unless a template or the
-- player sets them, so evaluations from before 0.5.0 stay the same.
-- Item data comes from the adapter (GetItemStats, GetEquipSlots, GetEquippedItemID, GetSellPrice).
local _, ns = ...

local CraftEval = {}
ns.CraftEval = CraftEval

CraftEval.STATS = { "STR", "AGI", "STA", "INT", "SPI", "ARMOR", "DPS" }
CraftEval.MAX_WEIGHT = 10

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

-- The level needed for an item if the character is below it, else nil (also while loading).
function CraftEval.LevelLock(itemID)
	local needed, level = ns.Client:GetItemMinLevel(itemID), ns.Client:GetLevel()
	if needed and level and needed > level then
		return needed
	end
	return nil
end

-- Validation of stored craft evaluation data (registered with DB.VALIDATORS).
local function sanitizeWeights(weights, path, repairs)
	for _, stat in ipairs(CraftEval.STATS) do
		local value = weights[stat]
		if not (type(value) == "number" and value >= 0 and value <= CraftEval.MAX_WEIGHT) then
			weights[stat] = ns.DB.CHARACTER_DEFAULTS.craftEval.weights[stat]
			repairs[#repairs + 1] = path .. ".weights." .. stat
		end
	end
end

function CraftEval.Sanitize(charData, path, repairs)
	sanitizeWeights(charData.craftEval.weights, path .. ".craftEval", repairs)
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = CraftEval.Sanitize
