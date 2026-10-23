-- Wants: the items a character wants ("Ich will dieses Item", 0.10.0), with a count each, in the
-- order they were added (earlier wants get the stock first in the plan, Core/Acquire.lua).
-- charData.wants = { { itemID, count, createdAt, baseline? } }. baseline (only new items count): the
-- units in stock when the player chose it; they stay reserved, only what comes on top counts. Pure logic on the SavedVariables tables; the
-- schema 1 -> 2 migration turns the material goals of older versions into wants.
local _, ns = ...

local Materials = ns.Materials

local Wants = {}
ns.Wants = Wants

Wants.MAX_WANTS = 50

function Wants.Find(charData, itemID)
	for index, entry in ipairs(charData.wants) do
		if entry.itemID == itemID then
			return entry, index
		end
	end
	return nil
end

-- Adds count to the want of an item (a new want at the end if there is none). Returns the new count,
-- or nil plus "invalid_item" | "invalid_count" | "too_many" | "too_many_wants".
function Wants.Add(charData, itemID, count, now)
	if not Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if not Materials.IsValidCount(count) then
		return nil, "invalid_count"
	end
	local entry = Wants.Find(charData, itemID)
	if not entry and #charData.wants >= Wants.MAX_WANTS then
		return nil, "too_many_wants"
	end
	local newCount = (entry and entry.count or 0) + count
	if newCount > Materials.MAX_COUNT then
		return nil, "too_many"
	end
	if entry then
		entry.count = newCount
	else
		charData.wants[#charData.wants + 1] = { itemID = itemID, count = newCount, createdAt = now or 0 }
	end
	return newCount
end

-- Sets the count of a want; 0 removes it. Returns the new count, or nil plus an error code (as Add).
function Wants.Set(charData, itemID, count, now)
	if count == 0 then
		Wants.Remove(charData, itemID)
		return 0
	end
	local entry = Wants.Find(charData, itemID)
	if not entry then
		return Wants.Add(charData, itemID, count, now)
	end
	if not Materials.IsValidCount(count) then
		return nil, "invalid_count"
	end
	entry.count = count
	return count
end

-- Only new items count (true: the current stock `available` becomes the baseline) or all (false).
-- Returns true, or nil plus "not_found".
function Wants.SetOnlyNew(charData, itemID, onlyNew, available)
	local entry = Wants.Find(charData, itemID)
	if not entry then
		return nil, "not_found"
	end
	entry.baseline = onlyNew and math.max(0, math.floor(available or 0)) or nil
	return true
end

-- Lowers baselines to the stock (availableOf(itemID)) when old units were used or sold, so the
-- items counted as new are never taken back.
function Wants.ClampBaselines(charData, availableOf)
	for _, entry in ipairs(charData.wants) do
		if entry.baseline then
			entry.baseline = math.min(entry.baseline, math.max(0, availableOf(entry.itemID)))
		end
	end
end

function Wants.Remove(charData, itemID)
	local _, index = Wants.Find(charData, itemID)
	if not index then
		return false
	end
	table.remove(charData.wants, index)
	return true
end

-- The wants a recipe stands for: its product x crafts x the smallest output, or for recipes without
-- a product (enchantments) their reagents x crafts. Returns { { itemID, count } }.
function Wants.OfRecipe(recipe, crafts)
	if recipe.outputItemID ~= 0 then
		return { { itemID = recipe.outputItemID, count = crafts * recipe.outputMin } }
	end
	local list = {}
	for _, reagent in ipairs(recipe.reagents) do
		list[#list + 1] = { itemID = reagent.itemID, count = reagent.count * crafts }
	end
	return list
end

-- Stored recipes by the item they make: { [itemID] = { recipeKey, ... } } (enchantments left out).
function Wants.RecipesByProduct(db)
	local byProduct = {}
	for key, recipe in pairs(db.recipes) do
		if recipe.outputItemID ~= 0 then
			local list = byProduct[recipe.outputItemID] or {}
			list[#list + 1] = key
			byProduct[recipe.outputItemID] = list
		end
	end
	for _, list in pairs(byProduct) do
		table.sort(list)
	end
	return byProduct
end

local function addWithReagents(db, byProduct, set, itemID, depth)
	set[itemID] = true
	if depth >= ns.Acquire.MAX_DEPTH then
		return
	end
	for _, key in ipairs(byProduct[itemID] or {}) do
		for _, reagent in ipairs(db.recipes[key].reagents) do
			if not set[reagent.itemID] then
				addWithReagents(db, byProduct, set, reagent.itemID, depth + 1)
			end
		end
	end
end

-- Fills `set` (cleared first) with { [itemID] = true } for every wanted item of the given characters
-- (all characters if charKeys is nil) and the reagents of the stored recipes that make them, as deep
-- as the planner looks: the items whose prices and stock matter.
function Wants.TrackedItems(db, set, charKeys)
	for itemID in pairs(set) do
		set[itemID] = nil
	end
	local byProduct = Wants.RecipesByProduct(db)
	for key, charData in pairs(db.characters) do
		if not charKeys or charKeys[key] then
			for _, want in ipairs(charData.wants) do
				addWithReagents(db, byProduct, set, want.itemID, 0)
			end
		end
	end
	return set
end

-- Validation (registered with DB.VALIDATORS): drops invalid wants, merges duplicates, caps the list.
function Wants.Sanitize(charData, path, repairs)
	local clean, byID = {}, {}
	for _, entry in ipairs(charData.wants) do
		local ok = type(entry) == "table" and Materials.IsValidItemID(entry.itemID) and Materials.IsValidCount(entry.count)
		if ok and byID[entry.itemID] then
			byID[entry.itemID].count = math.min(Materials.MAX_COUNT, byID[entry.itemID].count + entry.count)
		elseif ok and #clean < Wants.MAX_WANTS then
			local want = { itemID = entry.itemID, count = entry.count,
				createdAt = type(entry.createdAt) == "number" and entry.createdAt or 0,
				baseline = Materials.IsValidCount(entry.baseline) and entry.baseline or nil }
			byID[entry.itemID] = want
			clean[#clean + 1] = want
		end
	end
	if #clean ~= #charData.wants then
		repairs[#repairs + 1] = path .. ".wants"
	end
	charData.wants = clean
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Wants.Sanitize

-- Migration 1 -> 2 ------------------------------------------------------------------------
-- Runs on a copy of the stored data before the defaults are merged, so every value is checked.

local function migratedCount(value)
	return type(value) == "number" and value >= 1 and math.floor(value) or nil
end

-- The wants of one old goal: a recipe goal that makes an item becomes that item (crafts x the
-- smallest output), every other goal (enchantments, hand-made lists) its materials x crafts.
local function wantsOfGoal(db, goal)
	local crafts = migratedCount(goal.crafts) or 1
	local recipe = type(goal.recipeKey) == "string" and type(db.recipes) == "table" and db.recipes[goal.recipeKey]
	local product = type(recipe) == "table" and migratedCount(recipe.outputItemID)
	if product then
		return { { itemID = product, count = crafts * (migratedCount(recipe.outputMin) or 1) } }
	end
	local list = {}
	for _, entry in ipairs(type(goal.items) == "table" and goal.items or {}) do
		local count = type(entry) == "table" and migratedCount(entry.count)
		if count and migratedCount(entry.itemID) then
			list[#list + 1] = { itemID = entry.itemID, count = count * crafts }
		end
	end
	return list
end

local function migrateCharacter(db, charData)
	local ids, wants = {}, {}
	for id, goal in pairs(type(charData.materialGoals) == "table" and charData.materialGoals or {}) do
		if type(id) == "number" and type(goal) == "table" then
			ids[#ids + 1] = id
		end
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		for _, want in ipairs(wantsOfGoal(db, charData.materialGoals[id])) do
			want.createdAt = 0
			wants[#wants + 1] = want
		end
	end
	charData.wants = wants -- duplicates and the cap: Wants.Sanitize on load
	charData.materialGoals, charData.activeGoalID, charData.nextGoalID = nil, nil, nil
	if type(charData.craftEval) == "table" then
		charData.craftEval.alternatives = nil
	end
end

ns.DB.MIGRATIONS[1] = function(db)
	for _, charData in pairs(type(db.characters) == "table" and db.characters or {}) do
		if type(charData) == "table" then
			migrateCharacter(db, charData)
		end
	end
	local settings = type(db.settings) == "table" and db.settings or {}
	settings.strategy, settings.budgetCopper, settings.farmTimeLimitMinutes = nil, nil, nil
	settings.useReservesInSourcing, settings.farmAutoReview, settings.questAlternatives = nil, nil, nil
	if type(settings.window) == "table" then
		settings.window.allGoals, settings.window.tab = nil, nil
	end
end
