-- /bof gold: gold buffer – savings goals, distribution of the current gold, budget overview,
-- check of a planned purchase against the reserves, and the net income. The text builders are
-- shared with the Gold tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local SavingsGoals = ns.SavingsGoals
local Income = ns.Income
local Slash = ns.Slash
local UIShared = ns.UIShared

local GoldCommands = {}
ns.GoldCommands = GoldCommands

GoldCommands.INCOME_DAYS = 14
local PERCENT = 100

local function money()
	return ns.Client:GetMoney() or 0
end

function GoldCommands.OverviewLine(charData)
	local overview = SavingsGoals.Overview(charData, money())
	return Util.Format(L.GOLD_OVERVIEW, Money.Format(overview.money), Money.Format(overview.reserved),
		Money.Format(overview.free), Money.Format(overview.uncovered))
end

function GoldCommands.GoalLines(charData)
	local lines = {}
	for index, goal in ipairs(charData.savingsGoals) do
		local name = goal.label ~= "" and goal.label or L.GOAL_UNNAMED
		if goal.done then
			lines[#lines + 1] = Util.Format(L.GOLD_GOAL_DONE, index, name, Money.Format(goal.copper))
		else
			lines[#lines + 1] = Util.Format(L.GOLD_GOAL_LINE, index, name, Money.Format(goal.copper),
				Money.Format(goal.reserved), math.floor(goal.reserved * PERCENT / goal.copper))
		end
	end
	if #lines == 0 then
		lines[1] = L.GOLD_NO_GOALS
	end
	return lines
end

function GoldCommands.IncomeLine(charData)
	local summary = Income.Summary(charData, ns.Client:GetServerTime(), GoldCommands.INCOME_DAYS)
	if not summary.perHour then
		return Util.Format(L.GOLD_INCOME_LITTLE, GoldCommands.INCOME_DAYS, Util.FormatDuration(summary.seconds))
	end
	local net = (summary.net < 0 and "-" or "+") .. Money.Format(math.abs(summary.net))
	local perHour = (summary.perHour < 0 and "-" or "") .. Money.Format(math.abs(summary.perHour))
	return Util.Format(L.GOLD_INCOME, GoldCommands.INCOME_DAYS, net, Util.FormatDuration(summary.seconds), perHour)
end

-- Time value of an amount: "etwa 1 Std. 20 Min. Spielzeit", or the reason why it is unknown.
function GoldCommands.TimeValueText(charData, cost)
	local summary = Income.Summary(charData, ns.Client:GetServerTime(), GoldCommands.INCOME_DAYS)
	local seconds = Income.TimeToEarn(summary, cost)
	if seconds then
		return Util.Format(L.GOLD_TIME_VALUE, Money.Format(cost), Util.FormatDuration(seconds))
	end
	if summary.perHour then
		return L.GOLD_TIME_VALUE_NO_GAIN
	end
	return L.GOLD_TIME_VALUE_NONE
end

-- "Ein Einkauf für 3g greift 1g deiner Rücklagen an." or "… lässt deine Rücklagen unberührt."
function GoldCommands.ReserveText(charData, cost)
	local use = SavingsGoals.ReserveUse(SavingsGoals.Overview(charData, money()), cost)
	if use > 0 then
		return Util.Format(L.GOLD_RESERVE_USE, Money.Format(cost), Money.Format(use))
	end
	return Util.Format(L.GOLD_RESERVE_SAFE, Money.Format(cost))
end

-- "+3g" / "-50s" / "+3g/-50s" for the gained and spent amounts of a source.
local function amountsText(entry)
	local parts = {}
	if entry.gained > 0 then
		parts[#parts + 1] = "+" .. Money.Format(entry.gained)
	end
	if entry.spent > 0 then
		parts[#parts + 1] = "-" .. Money.Format(entry.spent)
	end
	return table.concat(parts, "/")
end

-- "Quellen (14 Tage): Beute +3g · Händler +1g/-50s …", or nil without data by source.
function GoldCommands.SourcesLine(charData)
	local totals = Income.SourceTotals(charData, ns.Client:GetServerTime(), GoldCommands.INCOME_DAYS)
	local parts = {}
	for _, source in ipairs(ns.MoneyContext.SOURCES) do
		local entry = totals[source]
		if entry and (entry.gained > 0 or entry.spent > 0) then
			parts[#parts + 1] = L["SOURCE_" .. source] .. " " .. amountsText(entry)
		end
	end
	if #parts == 0 then
		return nil
	end
	return Util.Format(L.GOLD_SOURCES, GoldCommands.INCOME_DAYS, table.concat(parts, L.PRICE_SEPARATOR))
end

local function printOverview(charData)
	Log.Print(GoldCommands.OverviewLine(charData))
	for _, line in ipairs(GoldCommands.GoalLines(charData)) do
		Log.Print(line)
	end
	Log.Print(GoldCommands.IncomeLine(charData))
	local sources = GoldCommands.SourcesLine(charData)
	if sources then
		Log.Print(sources)
	end
end

-- Subcommands that change data: function(charData, rest).
local WRITE = {}

function WRITE.add(charData, rest)
	local copper, name = Money.ParseLeading(rest)
	if not copper then
		Log.Print(L.GOLD_USAGE)
		return
	end
	local index, err = SavingsGoals.Add(charData, name, copper, ns.Client:GetServerTime())
	if not index then
		Log.Print(err == "too_many_savings" and Util.Format(L.GOLD_TOO_MANY, SavingsGoals.MAX_GOALS) or L.GOLD_USAGE)
		return
	end
	Log.Print(Util.Format(L.GOLD_ADDED, index, Money.Format(copper)))
end

function WRITE.set(charData, rest)
	local indexText, amount = Slash.SplitCommand(rest)
	local copper = Money.Parse(amount)
	local goal = copper and SavingsGoals.SetAmount(charData, Util.ParseInteger(indexText), copper)
	if not goal then
		Log.Print(L.GOLD_USAGE)
		return
	end
	Log.Print(Util.Format(L.GOLD_CHANGED, indexText, Money.Format(copper)))
end

function WRITE.name(charData, rest)
	local indexText, label = Slash.SplitCommand(rest)
	if not SavingsGoals.Rename(charData, Util.ParseInteger(indexText), label) then
		Log.Print(Util.Format(L.GOLD_NOT_FOUND, indexText))
		return
	end
	Log.Print(Util.Format(L.GOLD_RENAMED, indexText))
end

local function byIndex(fn, message)
	return function(charData, rest)
		local index = Util.ParseInteger(Util.Trim(rest))
		local result = fn(charData, index)
		if not result then
			Log.Print(Util.Format(L.GOLD_NOT_FOUND, Util.Trim(rest)))
			return
		end
		Log.Print(Util.Format(L[message], type(result) == "number" and result or index))
	end
end

WRITE.up = byIndex(SavingsGoals.MoveUp, "GOLD_MOVED")
WRITE.done = byIndex(SavingsGoals.Complete, "GOLD_COMPLETED")
WRITE.delete = byIndex(SavingsGoals.Delete, "GOLD_DELETED")

-- Reserves before the last distribution (manual or automatic), for /bof gold undo. In memory only.
local undoSnapshot

-- Distributes the current gold and keeps the old reserves for undo. Returns the amount assigned.
function GoldCommands.Distribute(charData)
	undoSnapshot = SavingsGoals.SnapshotReserves(charData)
	return SavingsGoals.Distribute(charData, money())
end

function GoldCommands.CanUndo()
	return undoSnapshot ~= nil
end

function WRITE.distribute(charData)
	local assigned = GoldCommands.Distribute(charData)
	Log.Print(Util.Format(L.GOLD_DISTRIBUTED, Money.Format(assigned)))
	Log.Print(GoldCommands.OverviewLine(charData))
end

function WRITE.undo(charData)
	if not undoSnapshot then
		Log.Print(L.GOLD_NOTHING_TO_UNDO)
		return
	end
	SavingsGoals.RestoreReserves(charData, undoSnapshot)
	undoSnapshot = nil
	Log.Print(L.GOLD_UNDONE)
	Log.Print(GoldCommands.OverviewLine(charData))
end

local function check(charData, rest)
	local copper = Money.Parse(rest)
	if not copper then
		UIShared.PrintError("invalid_money")
		return
	end
	Log.Print(GoldCommands.ReserveText(charData, copper))
	Log.Print(GoldCommands.TimeValueText(charData, copper))
end

local function goldCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if sub == "" or sub == "check" then
		local charData = UIShared.Character()
		if charData and sub == "" then
			printOverview(charData)
		elseif charData then
			check(charData, rest)
		end
		return
	end
	if not WRITE[sub] then
		Log.Print(L.GOLD_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if charData then
		WRITE[sub](charData, rest)
	end
end

if ns.Client then
	Slash.AddCommand("gold", goldCommand, L.HELP_LINE_GOLD)
end
