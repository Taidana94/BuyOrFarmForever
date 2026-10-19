-- Recipes imported from the profession window: output and fixed reagents, stored account-wide
-- in db.recipes by a stable key ("spell:<id>" or "item:<id>"). Names are never stored (they are
-- localized); they are fetched from the client for display.
-- Pure logic on plain tables, no WoW API calls. Failures return nil plus an error code.
local _, ns = ...

local Recipes = {}
ns.Recipes = Recipes

-- Classic Era recipes have at most 8 reagents; the limit only rejects broken data.
Recipes.MAX_REAGENTS = 16
local MAX_ID = 10000000
local MAX_OUTPUT = 1000
local KEY_TYPES = { spell = true, item = true }
-- MANUAL is reserved in the schema for recipes entered by hand (plan section 7).
local ORIGINS = { IMPORT = true, MANUAL = true }

local function isPositiveInteger(value, max)
	return type(value) == "number" and value >= 1 and value <= max and value == math.floor(value)
end

-- "spell:7418" -> "spell", 7418; nil for anything else.
function Recipes.SplitKey(key)
	if type(key) ~= "string" then
		return nil
	end
	local keyType, id = key:match("^(%a+):(%d+)$")
	id = tonumber(id)
	if not (keyType and KEY_TYPES[keyType] and isPositiveInteger(id, MAX_ID)) then
		return nil
	end
	return keyType, id
end

function Recipes.IsValidKey(key)
	return Recipes.SplitKey(key) ~= nil
end

-- Merges duplicate reagents and checks ids and counts. Returns a new list or nil, error code.
local function cleanReagents(reagents)
	if type(reagents) ~= "table" or #reagents == 0 then
		return nil, "no_reagents"
	end
	if #reagents > Recipes.MAX_REAGENTS then
		return nil, "invalid_recipe"
	end
	local list, byID = {}, {}
	for _, reagent in ipairs(reagents) do
		local ok = type(reagent) == "table"
			and ns.Materials.IsValidItemID(reagent.itemID)
			and ns.Materials.IsValidCount(reagent.count)
		if not ok then
			return nil, "invalid_recipe"
		end
		local row = byID[reagent.itemID]
		if row then
			row.count = row.count + reagent.count
		else
			row = { itemID = reagent.itemID, count = reagent.count }
			byID[reagent.itemID] = row
			list[#list + 1] = row
		end
	end
	return list
end

-- Checks a recipe read by the adapter and returns a clean copy, or nil, error code
-- ("no_reagents" | "invalid_recipe").
-- recipe = { key, outputItemID (0 = no item, e.g. an enchantment), outputMin, outputMax, reagents }
function Recipes.Normalize(recipe)
	if type(recipe) ~= "table" or not Recipes.IsValidKey(recipe.key) then
		return nil, "invalid_recipe"
	end
	local reagents, err = cleanReagents(recipe.reagents)
	if not reagents then
		return nil, err
	end
	local outputItemID = recipe.outputItemID or 0
	if outputItemID ~= 0 and not ns.Materials.IsValidItemID(outputItemID) then
		return nil, "invalid_recipe"
	end
	local outputMin, outputMax = recipe.outputMin or 1, recipe.outputMax or recipe.outputMin or 1
	if not (isPositiveInteger(outputMin, MAX_OUTPUT) and isPositiveInteger(outputMax, MAX_OUTPUT)) then
		return nil, "invalid_recipe"
	end
	return {
		key = recipe.key,
		outputItemID = outputItemID,
		outputMin = outputMin,
		outputMax = math.max(outputMin, outputMax),
		reagents = reagents,
	}
end

-- Stores a normalized recipe (replacing an older import of the same key).
function Recipes.Store(db, recipe, now)
	db.recipes[recipe.key] = {
		outputItemID = recipe.outputItemID,
		outputMin = recipe.outputMin,
		outputMax = recipe.outputMax,
		reagents = ns.Util.CopyTable(recipe.reagents),
		origin = "IMPORT",
		at = now or 0,
	}
end

function Recipes.Get(db, key)
	return db.recipes[key]
end

-- Reads the recipe selected in the client's profession window and stores it. Returns the
-- normalized recipe, or nil plus an error code (from the adapter or Recipes.Normalize).
function Recipes.ReadSelected()
	local raw, readError = ns.Client:ReadSelectedRecipe()
	if not raw then
		return nil, readError
	end
	local recipe, err = Recipes.Normalize(raw)
	if not recipe then
		ns.Log.Debug("recipe rejected (" .. tostring(err) .. "): " .. tostring(raw.key))
		return nil, err
	end
	Recipes.Store(ns.db, recipe, ns.Client:GetServerTime())
	return recipe
end

-- Creates a new goal from the selected recipe with the given number of crafts. Returns the goal
-- id, or nil plus an error code.
function Recipes.ImportSelected(charData, crafts)
	if not ns.Materials.IsValidCrafts(crafts) then
		return nil, "invalid_crafts"
	end
	local recipe, err = Recipes.ReadSelected()
	if not recipe then
		return nil, err
	end
	return ns.Materials.CreateRecipeGoal(charData, recipe, crafts, ns.Client:GetServerTime())
end

-- Like ImportSelected, but if a goal of the character already has this recipe, its crafts are
-- increased (and it is selected) instead of creating a duplicate. Returns the goal id and true if
-- an existing goal was increased (false if a goal was created), or nil plus an error code.
function Recipes.ImportOrIncrease(charData, crafts)
	if not ns.Materials.IsValidCrafts(crafts) then
		return nil, "invalid_crafts"
	end
	local recipe, err = Recipes.ReadSelected()
	if not recipe then
		return nil, err
	end
	local id = ns.Materials.FindRecipeGoal(charData, recipe.key)
	if not id then
		local newID, createError = ns.Materials.CreateRecipeGoal(charData, recipe, crafts, ns.Client:GetServerTime())
		return newID, newID and false or createError
	end
	local goal = charData.materialGoals[id]
	local _, setError = ns.Materials.SetCrafts(goal, goal.crafts + crafts)
	if setError then
		return nil, setError
	end
	ns.Materials.SelectGoal(charData, id)
	return id, true
end

-- Validation of stored recipes (registered with DB.ROOT_VALIDATORS).
function Recipes.Sanitize(db, repairs)
	for key, stored in pairs(db.recipes) do
		local clean = type(stored) == "table" and Recipes.Normalize({
			key = key,
			outputItemID = stored.outputItemID,
			outputMin = stored.outputMin,
			outputMax = stored.outputMax,
			reagents = stored.reagents,
		})
		if not clean then
			db.recipes[key] = nil
			repairs[#repairs + 1] = "recipes." .. tostring(key)
		else
			stored.outputItemID = clean.outputItemID
			stored.outputMin = clean.outputMin
			stored.outputMax = clean.outputMax
			stored.reagents = clean.reagents
			if type(stored.at) ~= "number" then
				stored.at = 0
			end
			if not ORIGINS[stored.origin] then
				stored.origin = "IMPORT"
			end
		end
	end
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = Recipes.Sanitize
