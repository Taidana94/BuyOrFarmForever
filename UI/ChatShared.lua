-- Shared helpers of the provisional chat commands: error texts, item and goal names, and the
-- current character's data. A bridge for in-game tests until the main window exists (plan stage 2d).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Slash = ns.Slash

local Chat = {}
ns.Chat = Chat

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

function Chat.PrintError(code)
	local message = ERRORS[code]
	Log.Print(message and message() or tostring(code))
end

-- Item link if cached, otherwise a placeholder (the adapter requests the item data).
function Chat.ItemText(itemID)
	return ns.Client:GetItemLink(itemID) or Util.Format(L.ITEM_UNKNOWN, itemID)
end

-- Name of a recipe from the client: output item link, else spell name, else a placeholder.
local function recipeName(key)
	local recipe = Recipes.Get(ns.db, key)
	if recipe and recipe.outputItemID ~= 0 then
		return Chat.ItemText(recipe.outputItemID)
	end
	local keyType, id = Recipes.SplitKey(key)
	if keyType == "spell" then
		return ns.Client:GetSpellName(id) or Util.Format(L.RECIPE_UNKNOWN, id)
	end
	return Chat.ItemText(id)
end

-- The user's label; goals from a recipe have none and show the recipe name.
function Chat.GoalName(goal)
	if goal.label ~= "" then
		return goal.label
	end
	if goal.recipeKey then
		return recipeName(goal.recipeKey)
	end
	return L.GOAL_UNNAMED
end

-- Confirmation after a goal was created from a recipe (chat command and window button).
function Chat.PrintRecipeGoal(charData, id)
	local goal = charData.materialGoals[id]
	Log.Print(Util.Format(L.RECIPE_GOAL_CREATED, id, Chat.GoalName(goal), #goal.items, goal.crafts))
end

-- Character data of the logged-in character, or nil with a message. In read-only mode the
-- stored data may have an unknown layout (newer schema, failed migration), so it is not read.
function Chat.Character()
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
function Chat.WritableCharacter()
	if not Slash.CanWrite() then
		return nil
	end
	return Chat.Character()
end

-- The selected goal and its id, or nil with a message.
function Chat.ActiveGoal(charData)
	local goal, id = Materials.GetActiveGoal(charData)
	if not goal then
		Log.Print(L.GOAL_NONE_ACTIVE)
	end
	return goal, id
end
