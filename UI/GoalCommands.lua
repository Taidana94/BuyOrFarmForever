-- Provisional chat commands for material goals and recipe import (/bof goal, /bof recipe).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Slash = ns.Slash
local UIShared = ns.UIShared

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
		Log.Print(Util.Format(L.GOAL_LIST_LINE, marker, id, UIShared.GoalName(goal), #goal.items, goal.crafts))
	end
end

local function goalNew(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local id = Materials.CreateGoal(charData, argument, ns.Client:GetServerTime())
	Log.Print(Util.Format(L.GOAL_CREATED, id, UIShared.GoalName(charData.materialGoals[id])))
end

local function goalName(argument)
	local charData = UIShared.WritableCharacter()
	local goal = charData and UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	Materials.RenameGoal(goal, argument)
	Log.Print(Util.Format(L.GOAL_RENAMED, UIShared.GoalName(goal)))
end

local function goalSelect(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local id = Util.ParseInteger(argument)
	if not (id and Materials.SelectGoal(charData, id)) then
		Log.Print(Util.Format(L.GOAL_NOT_FOUND, argument))
		return
	end
	Log.Print(Util.Format(L.GOAL_SELECTED, id, UIShared.GoalName(charData.materialGoals[id])))
end

local function goalAdd(argument, setExact)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	local itemID, rest = Util.ParseItemArg(argument)
	if not itemID then
		UIShared.PrintError("invalid_item")
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
		UIShared.PrintError(err)
	elseif result == 0 then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, UIShared.ItemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_ADDED, UIShared.ItemText(itemID), result))
	end
end

local function goalRemove(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	local itemID = Util.ParseItemArg(argument)
	if not itemID then
		UIShared.PrintError("invalid_item")
	elseif Materials.RemoveItem(goal, itemID) then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, UIShared.ItemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_NOT_IN_GOAL, UIShared.ItemText(itemID)))
	end
end

local function goalCrafts(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	local result, err = Materials.SetCrafts(goal, Util.ParseInteger(argument))
	if not result then
		UIShared.PrintError(err)
		return
	end
	Log.Print(Util.Format(L.GOAL_CRAFTS_SET, result))
end

local function goalDelete(argument)
	local charData = UIShared.WritableCharacter()
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
		Log.Print(Util.Format(L.GOAL_DELETE_CONFIRM, id, UIShared.GoalName(goal)))
		return
	end
	Materials.DeleteGoal(charData, id)
	Log.Print(Util.Format(L.GOAL_DELETED, id))
end

local GOAL_SUBCOMMANDS = {
	new = goalNew,
	name = goalName,
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
		local charData = UIShared.Character()
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
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local crafts = 1
	if Util.Trim(argument) ~= "" then
		crafts = Util.ParseInteger(Util.Trim(argument))
	end
	local id, err = Recipes.ImportSelected(charData, crafts)
	if not id then
		UIShared.PrintError(err)
		return
	end
	UIShared.PrintRecipeGoal(charData, id)
end

if ns.Client then
	Slash.AddCommand("goal", goalCommand, L.HELP_LINE_GOAL)
	Slash.AddCommand("recipe", recipeCommand, L.HELP_LINE_RECIPE)
end
