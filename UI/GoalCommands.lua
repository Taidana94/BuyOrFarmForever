-- Provisional chat commands for material goals and recipe import (/bof goal, /bof recipe).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Slash = ns.Slash
local Chat = ns.Chat

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
		Log.Print(Util.Format(L.GOAL_LIST_LINE, marker, id, Chat.GoalName(goal), #goal.items, goal.crafts))
	end
end

local function goalNew(argument)
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local id = Materials.CreateGoal(charData, argument, ns.Client:GetServerTime())
	Log.Print(Util.Format(L.GOAL_CREATED, id, Chat.GoalName(charData.materialGoals[id])))
end

local function goalSelect(argument)
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local id = Util.ParseInteger(argument)
	if not (id and Materials.SelectGoal(charData, id)) then
		Log.Print(Util.Format(L.GOAL_NOT_FOUND, argument))
		return
	end
	Log.Print(Util.Format(L.GOAL_SELECTED, id, Chat.GoalName(charData.materialGoals[id])))
end

local function goalAdd(argument, setExact)
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local goal = Chat.ActiveGoal(charData)
	if not goal then
		return
	end
	local itemID, rest = Util.ParseItemArg(argument)
	if not itemID then
		Chat.PrintError("invalid_item")
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
		Chat.PrintError(err)
	elseif result == 0 then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, Chat.ItemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_ADDED, Chat.ItemText(itemID), result))
	end
end

local function goalRemove(argument)
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local goal = Chat.ActiveGoal(charData)
	if not goal then
		return
	end
	local itemID = Util.ParseItemArg(argument)
	if not itemID then
		Chat.PrintError("invalid_item")
	elseif Materials.RemoveItem(goal, itemID) then
		Log.Print(Util.Format(L.GOAL_ITEM_REMOVED, Chat.ItemText(itemID)))
	else
		Log.Print(Util.Format(L.GOAL_ITEM_NOT_IN_GOAL, Chat.ItemText(itemID)))
	end
end

local function goalCrafts(argument)
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local goal = Chat.ActiveGoal(charData)
	if not goal then
		return
	end
	local result, err = Materials.SetCrafts(goal, Util.ParseInteger(argument))
	if not result then
		Chat.PrintError(err)
		return
	end
	Log.Print(Util.Format(L.GOAL_CRAFTS_SET, result))
end

local function goalDelete(argument)
	local charData = Chat.WritableCharacter()
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
		Log.Print(Util.Format(L.GOAL_DELETE_CONFIRM, id, Chat.GoalName(goal)))
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
		local charData = Chat.Character()
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
	local charData = Chat.WritableCharacter()
	if not charData then
		return
	end
	local crafts = 1
	if Util.Trim(argument) ~= "" then
		crafts = Util.ParseInteger(Util.Trim(argument))
	end
	local id, err = Recipes.ImportSelected(charData, crafts)
	if not id then
		Chat.PrintError(err)
		return
	end
	Chat.PrintRecipeGoal(charData, id)
end

if ns.Client then
	Slash.AddCommand("goal", goalCommand, L.HELP_LINE_GOAL)
	Slash.AddCommand("recipe", recipeCommand, L.HELP_LINE_RECIPE)
end
