-- Provisional chat commands for material goals, recipes and stock (/bof goal, /bof recipe, /bof stock).
-- A bridge for in-game tests until the main window exists (plan stage 2d).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Stock = ns.Stock
local Slash = ns.Slash

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
}

local function printError(code)
	local message = ERRORS[code]
	Log.Print(message and message() or tostring(code))
end

-- Item link if cached, otherwise a placeholder (the adapter requests the item data).
local function itemText(itemID)
	return ns.Client:GetItemLink(itemID) or Util.Format(L.ITEM_UNKNOWN, itemID)
end

-- Name of a recipe from the client: output item link, else spell name, else a placeholder.
local function recipeName(key)
	local recipe = Recipes.Get(ns.db, key)
	if recipe and recipe.outputItemID ~= 0 then
		return itemText(recipe.outputItemID)
	end
	local keyType, id = Recipes.SplitKey(key)
	if keyType == "spell" then
		return ns.Client:GetSpellName(id) or Util.Format(L.RECIPE_UNKNOWN, id)
	end
	return itemText(id)
end

-- The user's label; goals from a recipe have none and show the recipe name.
local function goalName(goal)
	if goal.label ~= "" then
		return goal.label
	end
	if goal.recipeKey then
		return recipeName(goal.recipeKey)
	end
	return L.GOAL_UNNAMED
end

-- Character data of the logged-in character, or nil with a message.
local function character(forWriting)
	if forWriting and not Slash.CanWrite() then
		return nil
	end
	if not (ns.db and ns.charKey and ns.db.characters[ns.charKey]) then
		Log.Print(L.NOT_READY)
		return nil
	end
	return ns.db.characters[ns.charKey]
end

local function activeGoal(charData)
	local goal, id = Materials.GetActiveGoal(charData)
	if not goal then
		Log.Print(L.GOAL_NONE_ACTIVE)
	end
	return goal, id
end

-- /bof goal ... -----------------------------------------------------------------------

local function listGoals(charData)
	local ids = Materials.ListGoalIDs(charData)
	if #ids == 0 then
		Log.Print(L.GOAL_LIST_EMPTY)
		return
	end
	Log.Print(L.GOAL_LIST_HEADER)
	for _, id in ipairs(ids) do
		local goal = charData.materialGoals[id]
		local marker = (id == charData.activeGoalID) and "* " or "  "
		Log.Print(Util.Format(L.GOAL_LIST_LINE, marker, id, goalName(goal), #goal.items, goal.crafts))
	end
end

local function goalNew(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local id = Materials.CreateGoal(charData, argument, ns.Client:GetServerTime())
	Log.Print(Util.Format(L.GOAL_CREATED, id, goalName(charData.materialGoals[id])))
end

local function goalSelect(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local id = Util.ParseInteger(argument)
	if not (id and Materials.SelectGoal(charData, id)) then
		Log.Print(Util.Format(L.GOAL_NOT_FOUND, argument))
		return
	end
	Log.Print(Util.Format(L.GOAL_SELECTED, id, goalName(charData.materialGoals[id])))
end

local function goalAdd(argument, setExact)
	local charData = character(true)
	if not charData then
		return
	end
	local goal = activeGoal(charData)
	if not goal then
		return
	end
	local itemID, rest = Util.ParseItemArg(argument)
	if not itemID then
		printError("invalid_item")
		return
	end
	local count = 1
	if rest ~= "" then
		count = Util.ParseInteger(rest)
	elseif setExact then
		count = nil
	end
	local result, err
	if setExact then
		result, err = Materials.SetItemCount(goal, itemID, count)
	else
		result, err = Materials.AddItem(goal, itemID, count)
	end
	if not result then
		printError(err)
	elseif result == 0 then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, itemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_ADDED, itemText(itemID), result))
	end
end

local function goalRemove(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local goal = activeGoal(charData)
	if not goal then
		return
	end
	local itemID = Util.ParseItemArg(argument)
	if not itemID then
		printError("invalid_item")
	elseif Materials.RemoveItem(goal, itemID) then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, itemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_NOT_IN_GOAL, itemText(itemID)))
	end
end

local function goalCrafts(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local goal = activeGoal(charData)
	if not goal then
		return
	end
	local result, err = Materials.SetCrafts(goal, Util.ParseInteger(argument))
	if not result then
		printError(err)
		return
	end
	Log.Print(Util.Format(L.GOAL_CRAFTS_SET, result))
end

local function goalDelete(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local idText, confirm = Slash.SplitCommand(argument)
	local id = Util.ParseInteger(idText)
	local goal = id and Materials.GetGoal(charData, id)
	if not goal then
		Log.Print(Util.Format(L.GOAL_NOT_FOUND, idText))
		return
	end
	if string.lower(confirm) ~= "confirm" then
		Log.Print(Util.Format(L.GOAL_DELETE_CONFIRM, id, goalName(goal)))
		return
	end
	Materials.DeleteGoal(charData, id)
	Log.Print(Util.Format(L.GOAL_DELETED, id))
end

local GOAL_SUBCOMMANDS = {
	new = goalNew,
	select = goalSelect,
	add = function(argument)
		goalAdd(argument, false)
	end,
	set = function(argument)
		goalAdd(argument, true)
	end,
	remove = goalRemove,
	crafts = goalCrafts,
	delete = goalDelete,
}

local function goalCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if sub == "" or sub == "list" then
		local charData = character(false)
		if charData then
			listGoals(charData)
		end
	elseif GOAL_SUBCOMMANDS[sub] then
		GOAL_SUBCOMMANDS[sub](rest)
	else
		Log.Print(L.GOAL_USAGE)
	end
end

-- /bof recipe [crafts] ------------------------------------------------------------------

local function recipeCommand(argument)
	local charData = character(true)
	if not charData then
		return
	end
	local crafts = 1
	if Util.Trim(argument) ~= "" then
		crafts = Util.ParseInteger(Util.Trim(argument))
	end
	if not Materials.IsValidCrafts(crafts) then
		printError("invalid_crafts")
		return
	end
	local raw, readError = ns.Client:ReadSelectedRecipe()
	if not raw then
		printError(readError)
		return
	end
	local recipe, err = Recipes.Normalize(raw)
	if not recipe then
		Log.Debug("recipe rejected (" .. tostring(err) .. "): " .. tostring(raw.key))
		printError(err)
		return
	end
	local now = ns.Client:GetServerTime()
	Recipes.Store(ns.db, recipe, now)
	local id = Materials.CreateRecipeGoal(charData, recipe, crafts, now)
	local goal = charData.materialGoals[id]
	Log.Print(Util.Format(L.RECIPE_GOAL_CREATED, id, goalName(goal), #goal.items, goal.crafts))
end

-- /bof stock [all] ----------------------------------------------------------------------

-- Other characters' stock of one item: counted total (same faction) and detail rows.
local function others(charData, itemID)
	if not ns.db.settings.countOtherCharacters then
		return 0, {}
	end
	return Stock.OthersFor(ns.db, ns.charKey, charData.faction, itemID)
end

local function printStock(charData, goals)
	local countOthers = ns.db.settings.countOtherCharacters
	local rows = Materials.Shortfall(Materials.Requirements(goals), function(itemID)
		local bags, bank = Stock.Count(itemID)
		return bags + (bank or 0) + (others(charData, itemID))
	end)
	if #rows == 0 then
		Log.Print(L.STOCK_EMPTY)
		return
	end
	local now = ns.Client:GetServerTime()
	for _, row in ipairs(rows) do
		local bags, bank = Stock.Count(row.itemID)
		local bankText = bank and tostring(bank) or L.UNKNOWN_SHORT
		local counted, details = others(charData, row.itemID)
		if countOthers then
			local template = row.missing > 0 and L.STOCK_LINE_ALTS or L.STOCK_LINE_ALTS_DONE
			Log.Print(Util.Format(template, itemText(row.itemID), row.need, bags, bankText, counted, row.missing))
		else
			local template = row.missing > 0 and L.STOCK_LINE or L.STOCK_LINE_DONE
			Log.Print(Util.Format(template, itemText(row.itemID), row.need, bags, bankText, row.missing))
		end
		for _, d in ipairs(details) do
			local template = d.sameFaction and L.STOCK_ALT_DETAIL or L.STOCK_ALT_OTHER_FACTION
			Log.Print(Util.Format(template, d.name, d.total, d.bags, d.bank, Util.FormatAge(now - d.at)))
		end
	end
end

local function toggleOthers()
	if not Slash.CanWrite() then
		return
	end
	local settings = ns.db.settings
	settings.countOtherCharacters = not settings.countOtherCharacters
	Log.Print(settings.countOtherCharacters and L.STOCK_OTHERS_ON or L.STOCK_OTHERS_OFF)
end

local function stockCommand(argument)
	local charData = character(false)
	if not charData then
		return
	end
	local option = string.lower(Util.Trim(argument))
	if option == "others" then
		toggleOthers()
		return
	end
	-- Lets an alt without bag changes this session store its stock with one command.
	Stock.CaptureCurrent("stock command")
	if option == "all" then
		local goals = {}
		for _, id in ipairs(Materials.ListGoalIDs(charData)) do
			goals[#goals + 1] = charData.materialGoals[id]
		end
		if #goals == 0 then
			Log.Print(L.GOAL_LIST_EMPTY)
			return
		end
		Log.Print(L.STOCK_ALL_HEADER)
		printStock(charData, goals)
		return
	end
	local goal, id = activeGoal(charData)
	if not goal then
		return
	end
	Log.Print(Util.Format(L.GOAL_HEADER, id, goalName(goal), goal.crafts))
	printStock(charData, { goal })
end

if ns.Client then
	Slash.AddCommand("goal", goalCommand, L.HELP_LINE_GOAL)
	Slash.AddCommand("recipe", recipeCommand, L.HELP_LINE_RECIPE)
	Slash.AddCommand("stock", stockCommand, L.HELP_LINE_STOCK)
end
