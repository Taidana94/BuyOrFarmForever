-- /bof want: the wanted items and their plan (the cheapest way to get each, Core/WantPlan.lua);
-- /bof recipe: want what a recipe makes (the selected one in the profession window, or a stored one by
-- key, used by the professions tab). The plan texts are shared with the Wants tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Wants = ns.Wants
local Slash = ns.Slash
local UIShared = ns.UIShared

local WantCommands = {}
ns.WantCommands = WantCommands

local INDENT = "   "

local function itemCount(node)
	return Util.Format(L.WANT_ITEM_COUNT, UIShared.ItemText(node.itemID), node.need)
end

local function haveText(node)
	return node.have > 0 and Util.Format(L.WANT_HAVE_PART, node.have) or ""
end

local function characterName(charKey)
	return (ns.Stock.SplitKey(charKey)) or charKey
end

local METHOD_TEXTS = {
	HAVE = function()
		return L.WANT_METHOD_HAVE
	end,
	BUY = function(node)
		return Util.Format(L.WANT_METHOD_BUY, node.rest, Money.Format(node.copper), UIShared.PriceSourceName(node.source))
	end,
	FARM = function(node)
		local zone = node.uiMapID > 0 and ns.Client:GetMapName(node.uiMapID) or L.UNKNOWN_VALUE
		return Util.Format(L.WANT_METHOD_FARM, node.rest, Util.FormatDuration(node.seconds), zone)
	end,
	CRAFT = function(node)
		if node.recipe.charKey ~= ns.charKey then
			return Util.Format(L.WANT_METHOD_CRAFT_OTHER, node.crafts, characterName(node.recipe.charKey))
		end
		return Util.Format(L.WANT_METHOD_CRAFT, node.crafts)
	end,
	OPEN = function(node)
		return Util.Format(L.WANT_METHOD_OPEN, node.rest)
	end,
}

-- "[Item] ×4 – kaufen 3 für 60s (AH), 1 vorhanden" without indentation.
function WantCommands.NodeText(node)
	return Util.Format(L.WANT_NODE, itemCount(node), METHOD_TEXTS[node.method](node), haveText(node))
end

-- The plan as lines with indentation by depth: { { text, node, depth } }.
function WantCommands.PlanLines(plan)
	local lines = {}
	local function add(node, depth)
		lines[#lines + 1] = { text = WantCommands.NodeText(node), node = node, depth = depth }
		for _, child in ipairs(node.children or {}) do
			add(child, depth + 1)
		end
	end
	for _, node in ipairs(plan.nodes) do
		add(node, 0)
	end
	return lines
end

-- What an hour of farming is worth and why.
function WantCommands.HourLine(plan)
	if plan.hourSource == "SETTING" then
		return Util.Format(L.WANT_HOUR_SETTING, Money.Format(plan.hourValue))
	end
	if plan.hourSource == "ROUTE" then
		return Util.Format(L.WANT_HOUR_ROUTE, Money.Format(plan.hourValue), ns.FarmCommands.RouteName(plan.hourRoute))
	end
	return L.WANT_HOUR_NONE
end

-- Summary lines: totals, gold warning, open items, hour value.
function WantCommands.SummaryLines(charData, plan)
	local totals = plan.totals
	local lines = { Util.Format(L.WANT_TOTAL, Money.Format(totals.copper), Util.FormatDuration(totals.farmSeconds),
		Util.FormatDuration(totals.travelSeconds), #totals.crafts) }
	local free = ns.SavingsGoals.Overview(charData, ns.Client:GetMoney() or 0).free
	if totals.copper > free then
		lines[#lines + 1] = Util.Format(L.WANT_GOLD_SHORT, Money.Format(free), Money.Format(totals.copper - free))
	end
	if #totals.open > 0 then
		lines[#lines + 1] = Util.Format(L.WANT_OPEN_HINT, #totals.open)
	end
	lines[#lines + 1] = WantCommands.HourLine(plan)
	return lines
end

local function printPlan(charData)
	if #charData.wants == 0 then
		Log.Print(L.WANT_LIST_EMPTY)
		return
	end
	local plan = ns.WantPlan.Current()
	Log.Print(L.WANT_PLAN_HEADER)
	for _, line in ipairs(WantCommands.PlanLines(plan)) do
		Log.Print(string.rep(INDENT, line.depth + 1) .. line.text)
	end
	for _, line in ipairs(WantCommands.SummaryLines(charData, plan)) do
		Log.Print(line)
	end
end

local function report(itemID, count, err)
	if not count then
		UIShared.PrintError(err)
	elseif count == 0 then
		Log.Print(Util.Format(L.WANT_REMOVED, UIShared.ItemText(itemID)))
	else
		Log.Print(Util.Format(L.WANT_SET, UIShared.ItemText(itemID), count))
	end
end

-- "add <item> [n]" adds n (default 1); "set <item> <n>" sets the count (0 removes).
local function changeWant(charData, argument, setExact)
	local itemID, rest = Util.ParseItemArg(argument)
	if not itemID then
		UIShared.PrintError("invalid_item")
		return
	end
	local count
	if Util.Trim(rest) ~= "" then
		count = Util.ParseInteger(rest)
	elseif not setExact then
		count = 1
	end
	local now = ns.Client:GetServerTime()
	if setExact then
		report(itemID, Wants.Set(charData, itemID, count, now))
	else
		report(itemID, Wants.Add(charData, itemID, count, now))
	end
end

local WRITE = {
	add = function(charData, rest)
		changeWant(charData, rest, false)
	end,
	set = function(charData, rest)
		changeWant(charData, rest, true)
	end,
	remove = function(charData, rest)
		local itemID = Util.ParseItemArg(rest)
		if itemID and Wants.Remove(charData, itemID) then
			report(itemID, 0)
		else
			Log.Print(L.WANT_NOT_FOUND)
		end
	end,
}

local function wantCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if sub == "" or sub == "list" then
		local charData = UIShared.Character()
		if charData then
			printPlan(charData)
		end
		return
	end
	if not WRITE[sub] then
		Log.Print(L.WANT_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if charData then
		WRITE[sub](charData, rest)
	end
end

-- /bof recipe [crafts] | key <recipeKey> [crafts] ------------------------------------------

local function parseCrafts(text)
	text = Util.Trim(text)
	return text == "" and 1 or Util.ParseInteger(text)
end

local function addRecipe(charData, recipe, crafts)
	if not ns.Materials.IsValidCrafts(crafts) then
		UIShared.PrintError("invalid_crafts")
		return
	end
	local now = ns.Client:GetServerTime()
	for _, want in ipairs(Wants.OfRecipe(recipe, crafts)) do
		report(want.itemID, Wants.Add(charData, want.itemID, want.count, now))
	end
end

local function recipeCommand(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local word, rest = Slash.SplitCommand(argument)
	local recipe, err
	if word == "key" then
		local key
		key, rest = Slash.SplitCommand(rest)
		recipe = ns.Recipes.Stored(ns.db, key)
		err = "invalid_recipe"
	else
		recipe, err = ns.Recipes.ReadSelected()
		rest = argument
	end
	if not recipe then
		UIShared.PrintError(err)
		return
	end
	addRecipe(charData, recipe, parseCrafts(rest))
end

if ns.Client then
	Slash.AddCommand("want", wantCommand, L.HELP_LINE_WANT)
	Slash.AddCommand("recipe", recipeCommand, L.HELP_LINE_RECIPE)
end
