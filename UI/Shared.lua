-- Shared helpers of the chat commands and the main window: error texts, item and goal names,
-- and the current character's data. Output goes to the chat (Log.Print).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Slash = ns.Slash

local UIShared = {}
ns.UIShared = UIShared

local ERRORS = {
	invalid_item = function()
		return L.ERR_INVALID_ITEM
	end,
	invalid_count = function()
		return Util.Format(L.ERR_INVALID_COUNT, Materials.MAX_COUNT)
	end,
	too_many = function()
		return Util.Format(L.ERR_TOO_MANY, Materials.MAX_COUNT)
	end,
	invalid_crafts = function()
		return Util.Format(L.ERR_INVALID_CRAFTS, Materials.MAX_CRAFTS)
	end,
	no_window = function()
		return L.RECIPE_NO_WINDOW
	end,
	no_selection = function()
		return L.RECIPE_NO_SELECTION
	end,
	loading = function()
		return L.RECIPE_LOADING
	end,
	no_reagents = function()
		return L.RECIPE_NO_REAGENTS
	end,
	invalid_recipe = function()
		return L.RECIPE_INVALID
	end,
	invalid_money = function()
		return L.ERR_INVALID_MONEY
	end,
	no_auction = function()
		return L.SCAN_NO_AUCTION
	end,
	auction_busy = function()
		return L.SCAN_BUSY
	end,
	scan_done = function()
		return L.SCAN_DONE
	end,
	run_exists = function()
		return L.FARM_ERR_RUN_EXISTS
	end,
	no_run = function()
		return L.FARM_NONE
	end,
	wrong_state = function()
		return L.FARM_ERR_WRONG_STATE
	end,
	nothing_unclear = function()
		return L.FARM_ERR_NOTHING_UNCLEAR
	end,
}

function UIShared.PrintError(code)
	local message = ERRORS[code]
	Log.Print(message and message() or tostring(code))
end

-- Item link if cached, otherwise a placeholder (the adapter requests the item data).
function UIShared.ItemText(itemID)
	return ns.Client:GetItemLink(itemID) or Util.Format(L.ITEM_UNKNOWN, itemID)
end

-- Name of a recipe from the client: output item link, else spell name, else a placeholder.
local function recipeName(key)
	local recipe = Recipes.Get(ns.db, key)
	if recipe and recipe.outputItemID ~= 0 then
		return UIShared.ItemText(recipe.outputItemID)
	end
	local keyType, id = Recipes.SplitKey(key)
	if keyType == "spell" then
		return ns.Client:GetSpellName(id) or Util.Format(L.RECIPE_UNKNOWN, id)
	end
	return UIShared.ItemText(id)
end

-- The user's label; goals from a recipe have none and show the recipe name.
function UIShared.GoalName(goal)
	if goal.label ~= "" then
		return goal.label
	end
	if goal.recipeKey then
		return recipeName(goal.recipeKey)
	end
	return L.GOAL_UNNAMED
end

-- Confirmation after a goal was created from a recipe (chat command and window button).
function UIShared.PrintRecipeGoal(charData, id)
	local goal = charData.materialGoals[id]
	Log.Print(Util.Format(L.RECIPE_GOAL_CREATED, id, UIShared.GoalName(goal), #goal.items, goal.crafts))
end

local PRICE_SOURCE_NAMES = { MERCHANT = "PRICE_SOURCE_MERCHANT", AUCTION = "PRICE_SOURCE_AUCTION", MANUAL = "PRICE_SOURCE_MANUAL" }

-- One stored price for display: "25s (Händler)", "30s (AH, vor 2 Std., veraltet)".
function UIShared.DescribePrice(source, record, now)
	local name = L[PRICE_SOURCE_NAMES[source]]
	local amount = ns.Money.Format(record.copper)
	if source == "MERCHANT" then
		return Util.Format(L.PRICE_PART, amount, name)
	end
	local outdated = ns.Prices.IsOutdated(source, record, now, ns.db.settings.priceMaxAgeDays)
	local template = outdated and L.PRICE_PART_OUTDATED or L.PRICE_PART_AGED
	return Util.Format(template, amount, name, Util.FormatAge(now - record.at))
end

-- Character data of the logged-in character, or nil with a message. In read-only mode the
-- stored data may have an unknown layout (newer schema, failed migration), so it is not read.
function UIShared.Character()
	if ns.readOnly then
		Log.Print(L.READ_ONLY_NO_ACCESS)
		return nil
	end
	if not (ns.db and ns.charKey and ns.db.characters[ns.charKey]) then
		Log.Print(L.NOT_READY)
		return nil
	end
	return ns.db.characters[ns.charKey]
end

-- Same, but nil with a message in read-only mode (for commands that change data).
function UIShared.WritableCharacter()
	if not Slash.CanWrite() then
		return nil
	end
	return UIShared.Character()
end

-- The selected goal and its id, or nil with a message.
function UIShared.ActiveGoal(charData)
	local goal, id = Materials.GetActiveGoal(charData)
	if not goal then
		Log.Print(L.GOAL_NONE_ACTIVE)
	end
	return goal, id
end
