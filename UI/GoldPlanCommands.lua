-- Gold planner commands: /bof goldplan [duration] (what to do in that time), /bof compare [duration]
-- (the strategies side by side), /bof goldsources (the character's farm routes with gold per hour),
-- /bof goldkeep [item] (items never to sell), and the text lines shared with the planner view of the
-- Gold buffer tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Slash = ns.Slash
local UIShared = ns.UIShared

local GoldPlanCommands = {}
ns.GoldPlanCommands = GoldPlanCommands

local HOUR = 3600
-- Unused plan time below this is not mentioned (rounding, short tasks).
local MIN_UNUSED_SECONDS = 60
-- Durations of the overview without argument, and the buttons of the planner view.
GoldPlanCommands.DURATIONS = { HOUR, 2 * HOUR, 4 * HOUR }
-- Items named per task line in the chat.
local MAX_ITEMS_NAMED = 5

-- "Gegner in Westfall: 2g pro Std. sicher + 1g im AH, Anreise 3 Min. (2 Runden, 40 Min.)"
function GoldPlanCommands.RouteLine(route)
	local line = Util.Format(L.GOLD_SOURCE_LINE, ns.FarmCommands.RouteName(route), Money.Format(route.surePerHour),
		Money.Format(route.auctionPerHour), Util.FormatDuration(route.travelSeconds), route.runs,
		Util.FormatDuration(route.activeSeconds))
	if route.runsWithoutCoins > 0 then
		line = line .. Util.Format(L.GOLD_SOURCE_NO_COINS, route.runsWithoutCoins)
	end
	return line
end

-- Lines of all routes (best first), or one line explaining that data is missing.
function GoldPlanCommands.SourceLines()
	local routes = ns.GoldRoutes.Current()
	if #routes == 0 then
		return { Util.Format(L.GOLD_SOURCES_NONE, Util.FormatDuration(ns.GoldRoutes.MIN_SECONDS)) }
	end
	local lines = {}
	for i, route in ipairs(routes) do
		lines[i] = Util.Format(L.GOLD_SOURCE_NUMBERED, i, GoldPlanCommands.RouteLine(route))
	end
	return lines
end

local function planOptions(charData, seconds)
	local now = ns.Client:GetServerTime()
	return { seconds = seconds, tasks = ns.GoldPlan.Tasks(charData, now),
		methods = ns.Conversion.Methods(charData, now), discountPercent = ns.db.settings.ahDiscountPercent }
end

-- The plan for `seconds` with the current tasks, routes and routes with crafted loot.
function GoldPlanCommands.Plan(charData, seconds)
	return ns.GoldPlan.Plan(planOptions(charData, seconds))
end

local TASK_TEXTS = {
	SELL_VENDOR = "GOLDPLAN_SELL_VENDOR", SELL_AUCTION = "GOLDPLAN_SELL_AUCTION", DISENCHANT = "GOLDPLAN_DISENCHANT",
}

local function taskText(task)
	if task.kind == "CRAFT" or task.kind == "COOLDOWN" then
		local text = Util.Format(L["GOLDPLAN_" .. task.kind], task.crafts, UIShared.ItemText(task.itemID),
			Money.Format(task.sure + task.auction), Util.FormatDuration(task.seconds))
		return task.charKey and text .. Util.Format(L.GOLDPLAN_ON_ALT, (ns.Stock.SplitKey(task.charKey))) or text
	end
	if task.kind == "FLIP" then
		return Util.Format(L.GOLDPLAN_FLIP, task.units, UIShared.ItemText(task.itemID), Money.Format(task.buy),
			Money.Format(task.sell), Money.Format(task.auction))
	end
	local amount = task.kind == "SELL_VENDOR" and task.sure or task.auction
	return Util.Format(L[TASK_TEXTS[task.kind]], task.units, Money.Format(amount), Util.FormatDuration(task.seconds))
end

local STEP_TEXTS = {
	TASK = function(step)
		return taskText(step.task)
	end,
	TRAVEL = function(step)
		return Util.Format(L.GOLDPLAN_TRAVEL, ns.FarmCommands.RouteName(step.method), Util.FormatDuration(step.seconds))
	end,
	METHOD = function(step)
		return Util.Format(L.GOLDPLAN_FARM, ns.FarmCommands.RouteName(step.method), Util.FormatDuration(step.seconds),
			Money.Format(step.sure), Money.Format(step.auction))
	end,
}

-- Numbered step lines, the summary line and the alternatives line ("" without alternatives).
function GoldPlanCommands.PlanTexts(plan, seconds)
	if #plan.steps == 0 then
		return {}, Util.Format(L.GOLDPLAN_EMPTY, Util.FormatDuration(ns.GoldRoutes.MIN_SECONDS)), ""
	end
	local steps = {}
	for i, step in ipairs(plan.steps) do
		steps[i] = Util.Format(L.GOLD_SOURCE_NUMBERED, i, STEP_TEXTS[step.kind](step))
	end
	-- Without a measured farm route the rest of the time stays open; say so instead of showing
	-- the same steps for every duration without explanation.
	local unused = seconds - plan.seconds
	if unused >= MIN_UNUSED_SECONDS then
		steps[#steps + 1] = Util.Format(L.GOLDPLAN_UNUSED, Util.FormatDuration(unused),
			Util.FormatDuration(ns.GoldRoutes.MIN_SECONDS))
	end
	local summary = Util.Format(L.GOLDPLAN_SUMMARY, Util.FormatDuration(seconds), Money.Format(plan.sure),
		Money.Format(plan.auction), Money.Format(plan.rating))
	local others = {}
	for _, alternative in ipairs(plan.alternatives) do
		others[#others + 1] = Util.Format(L.GOLDPLAN_ALTERNATIVE_PART, ns.FarmCommands.RouteName(alternative.method),
			Money.Format(alternative.rating))
	end
	return steps, summary, #others > 0 and Util.Format(L.GOLDPLAN_ALTERNATIVES, table.concat(others, L.PLAN_SEPARATOR)) or ""
end

-- The step that names a plan: the first one that is not travel.
local function mainStep(plan)
	for _, step in ipairs(plan.steps) do
		if step.kind ~= "TRAVEL" then
			return step
		end
	end
end

local function familyName(family)
	return Util.Format(L["STRATEGY_" .. family], ns.CraftTasks.MAX_CRAFTS)
end

-- Header line and one line per strategy (best first), then one line naming the strategies without
-- data and what they need.
function GoldPlanCommands.CompareLines(charData, seconds)
	local ranked, empty = ns.Strategies.Compare(planOptions(charData, seconds))
	local lines = { Util.Format(L.STRATEGY_HEADER, Util.FormatDuration(seconds), ns.db.settings.ahDiscountPercent) }
	for i, entry in ipairs(ranked) do
		local plan = entry.plan
		lines[#lines + 1] = Util.Format(L.STRATEGY_LINE, i, familyName(entry.family), Money.Format(plan.rating),
			Money.Format(plan.sure), Money.Format(plan.auction), STEP_TEXTS[mainStep(plan).kind](mainStep(plan)))
	end
	local missing = {}
	for _, family in ipairs(empty) do
		missing[#missing + 1] = Util.Format(L.STRATEGY_MISSING_PART, familyName(family), L["STRATEGY_NEEDS_" .. family])
	end
	if #missing > 0 then
		lines[#lines + 1] = Util.Format(L.STRATEGY_MISSING, table.concat(missing, L.STRATEGY_SEPARATOR))
	end
	return lines
end

-- "   Wollstoff ×20, Leichtes Leder ×5" for a bag task (chat only).
local function itemsLine(task)
	local parts = {}
	for itemID, count in pairs(task.items or {}) do
		if #parts < MAX_ITEMS_NAMED then
			parts[#parts + 1] = Util.Format(L.GOLDPLAN_ITEM_PART, UIShared.ItemText(itemID), count)
		end
	end
	return #parts > 0 and Util.Format(L.GOLDPLAN_ITEMS, table.concat(parts, L.PLAN_SEPARATOR)) or nil
end

local function printPlan(charData, seconds)
	local plan = GoldPlanCommands.Plan(charData, seconds)
	local steps, summary, alternatives = GoldPlanCommands.PlanTexts(plan, seconds)
	Log.Print(summary)
	for i, line in ipairs(steps) do
		Log.Print(line)
		local step = plan.steps[i] -- nil for the unused-time line
		local items = step and step.task and itemsLine(step.task)
		if items then
			Log.Print(items)
		end
	end
	if alternatives ~= "" then
		Log.Print(alternatives)
	end
end

local function planCommand(argument)
	local charData = UIShared.Character()
	if not charData then
		return
	end
	argument = Util.Trim(argument)
	if argument == "" then
		for _, seconds in ipairs(GoldPlanCommands.DURATIONS) do
			printPlan(charData, seconds)
		end
		return
	end
	local seconds, err = Util.ParseDuration(argument)
	if not seconds or seconds <= 0 then
		UIShared.PrintError(err or "invalid_duration")
		return
	end
	printPlan(charData, seconds)
end

local function compareCommand(argument)
	local charData = UIShared.Character()
	if not charData then
		return
	end
	argument = Util.Trim(argument)
	local seconds, err = HOUR, nil
	if argument ~= "" then
		seconds, err = Util.ParseDuration(argument)
	end
	if not seconds or seconds <= 0 then
		UIShared.PrintError(err or "invalid_duration")
		return
	end
	for _, line in ipairs(GoldPlanCommands.CompareLines(charData, seconds)) do
		Log.Print(line)
	end
end

local function sourcesCommand()
	if not UIShared.Character() then
		return
	end
	Log.Print(Util.Format(L.GOLD_SOURCES_HEADER, ns.db.settings.ahDiscountPercent))
	for _, line in ipairs(GoldPlanCommands.SourceLines()) do
		Log.Print(line)
	end
end

local function keepCommand(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local itemID = Util.ParseItemArg(argument)
	if Util.Trim(argument) == "" then
		local names = {}
		for keptID in pairs(charData.goldKeep) do
			names[#names + 1] = UIShared.ItemText(keptID)
		end
		Log.Print(#names > 0 and Util.Format(L.GOLD_KEEP_LIST, table.concat(names, L.PLAN_SEPARATOR)) or L.GOLD_KEEP_EMPTY)
		return
	end
	local kept, err = ns.BagTasks.ToggleKeep(charData, itemID)
	if kept == nil then
		Log.Print(err == "too_many_keep" and Util.Format(L.GOLD_KEEP_TOO_MANY, ns.BagTasks.MAX_KEEP) or L.ERR_INVALID_ITEM)
		return
	end
	Log.Print(Util.Format(kept and L.GOLD_KEEP_ADDED or L.GOLD_KEEP_REMOVED, UIShared.ItemText(itemID)))
end

if ns.Client then
	Slash.AddCommand("goldplan", planCommand, L.HELP_LINE_GOLDPLAN)
	Slash.AddCommand("compare", compareCommand, L.HELP_LINE_COMPARE)
	Slash.AddCommand("goldsources", sourcesCommand, L.HELP_LINE_GOLDSOURCES)
	Slash.AddCommand("goldkeep", keepCommand, L.HELP_LINE_GOLDKEEP)
end
