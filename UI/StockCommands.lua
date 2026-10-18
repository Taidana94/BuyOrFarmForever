-- Provisional chat command for stock and shortfall (/bof stock).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Materials = ns.Materials
local Stock = ns.Stock
local Slash = ns.Slash
local Chat = ns.Chat

-- /bof stock [all] ----------------------------------------------------------------------

local function printStock(charData, goals)
	local countOthers = ns.db.settings.countOtherCharacters
	local rows = Stock.Rows(charData, goals)
	if #rows == 0 then
		Log.Print(L.STOCK_EMPTY)
		return
	end
	local now = ns.Client:GetServerTime()
	for _, row in ipairs(rows) do
		local bankText = row.bank and tostring(row.bank) or L.UNKNOWN_SHORT
		local name = Chat.ItemText(row.itemID)
		if countOthers then
			local template = row.missing > 0 and L.STOCK_LINE_ALTS or L.STOCK_LINE_ALTS_DONE
			Log.Print(Util.Format(template, name, row.need, row.bags, bankText, row.others, row.missing))
		else
			local template = row.missing > 0 and L.STOCK_LINE or L.STOCK_LINE_DONE
			Log.Print(Util.Format(template, name, row.need, row.bags, bankText, row.missing))
		end
		for _, d in ipairs(row.details) do
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
	local charData = Chat.Character()
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
		local goals = Materials.AllGoals(charData)
		if #goals == 0 then
			Log.Print(L.GOAL_LIST_EMPTY)
			return
		end
		Log.Print(L.STOCK_ALL_HEADER)
		printStock(charData, goals)
		return
	end
	local goal, id = Chat.ActiveGoal(charData)
	if not goal then
		return
	end
	Log.Print(Util.Format(L.GOAL_HEADER, id, Chat.GoalName(goal), goal.crafts))
	printStock(charData, { goal })
end

if ns.Client then
	Slash.AddCommand("stock", stockCommand, L.HELP_LINE_STOCK)
end
