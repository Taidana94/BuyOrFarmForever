-- Provisional chat commands for material goals and stock (/bof goal, /bof stock).
-- A bridge for in-game tests until the main window exists (plan stage 2d).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
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
}

local function printError(code)
	local message = ERRORS[code]
	Log.Print(message and message() or tostring(code))
end

-- Item link if cached, otherwise a placeholder (the adapter requests the item data).
local function itemText(itemID)
	return ns.Client:GetItemLink(itemID) or Util.Format(L.ITEM_UNKNOWN, itemID)
end

local function goalName(goal)
	if goal.label == "" then
		return L.GOAL_UNNAMED
	end
	return goal.label
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

-- /bof stock [all] ----------------------------------------------------------------------

local function printStock(charData, goals)
	local rows = Materials.Shortfall(Materials.Requirements(goals), function(itemID)
		local bags, bank = Stock.Count(itemID)
		return bags + (bank or 0)
	end)
	if #rows == 0 then
		Log.Print(L.STOCK_EMPTY)
		return
	end
	local now = ns.Client:GetServerTime()
	for _, row in ipairs(rows) do
		local bags, bank = Stock.Count(row.itemID)
		local bankText = bank and tostring(bank) or L.UNKNOWN_SHORT
		local template = row.missing > 0 and L.STOCK_LINE or L.STOCK_LINE_DONE
		Log.Print(Util.Format(template, itemText(row.itemID), row.need, bags, bankText, row.missing))
		-- Bank check (Q-T6): show the snapshot from the last bank visit next to the live value.
		if Log.IsDebug() and not Stock.IsBankOpen() then
			local snapshot, at = Stock.BankSnapshot(charData, row.itemID)
			if at > 0 then
				local snapshotText = snapshot and tostring(snapshot) or L.UNKNOWN_SHORT
				Log.Print(Util.Format(L.STOCK_BANK_SNAPSHOT, snapshotText, Util.FormatAge(now - at)))
			else
				Log.Print(L.STOCK_BANK_NEVER)
			end
		end
	end
end

local function stockCommand(argument)
	local charData = character(false)
	if not charData then
		return
	end
	if string.lower(Util.Trim(argument)) == "all" then
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
	Slash.AddCommand("stock", stockCommand, L.HELP_LINE_STOCK)
end
