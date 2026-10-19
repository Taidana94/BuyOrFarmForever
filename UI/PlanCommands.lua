-- /bof plan, /bof strategy, /bof budget, /bof timelimit: the sourcing plan (buy, farm or both) for
-- the missing materials of the selected goal or all goals, under the chosen strategy, budget and
-- farm time limit.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Sourcing = ns.Sourcing
local Materials = ns.Materials
local Slash = ns.Slash
local UIShared = ns.UIShared

local PlanCommands = {}
ns.PlanCommands = PlanCommands

local SECONDS_PER_MINUTE = 60
local STRATEGY_WORDS = { time = "SAVE_TIME", gold = "SAVE_GOLD", farm = "FARM_SELF" }
PlanCommands.STRATEGY_NAMES = { SAVE_TIME = "STRATEGY_SAVE_TIME", SAVE_GOLD = "STRATEGY_SAVE_GOLD", FARM_SELF = "STRATEGY_FARM_SELF" }

-- "kaufen 10 für 1g, farmen 20 (etwa 25 Min.)", "offen: 3 (kein Preis, keine Farmmessung)"
function PlanCommands.DescribeLine(line)
	local parts = {}
	if line.buy > 0 then
		parts[#parts + 1] = Util.Format(L.PLAN_BUY, line.buy, Money.Format(line.cost))
	end
	if line.farm > 0 then
		parts[#parts + 1] = Util.Format(L.PLAN_FARM, line.farm, Util.FormatDuration(line.farmSeconds))
	end
	if line.byproduct > 0 then
		parts[#parts + 1] = Util.Format(L.PLAN_BYPRODUCT, line.byproduct)
	end
	if line.open > 0 then
		parts[#parts + 1] = Util.Format(L.PLAN_OPEN, line.open)
	end
	return table.concat(parts, L.PLAN_SEPARATOR)
end

-- Header and summary lines shared by the chat command and the window.
function PlanCommands.BudgetText(budget, isOwn)
	return Util.Format(isOwn and L.PLAN_BUDGET_OWN or L.PLAN_BUDGET_GOLD, Money.Format(budget))
end

-- Notes about the plan's cost: use of reserves and time value (gold buffer). Empty without cost.
function PlanCommands.CostNotes(charData, plan)
	if plan.cost <= 0 then
		return {}
	end
	return { ns.GoldCommands.ReserveText(charData, plan.cost), ns.GoldCommands.TimeValueText(charData, plan.cost) }
end

function PlanCommands.SummaryText(plan)
	return Util.Format(L.PLAN_SUMMARY, Money.Format(plan.cost), Util.FormatDuration(plan.farmSeconds),
		Money.Format(plan.budgetLeft))
end

-- "Zeitlimit 2 Std. eingehalten." / "... überschritten ..."; "" without a limit.
function PlanCommands.LimitText(plan)
	if not plan.limitSeconds then
		return ""
	end
	local limit = Util.FormatDuration(plan.limitSeconds)
	if plan.overLimitSeconds > 0 then
		return Util.Format(L.PLAN_LIMIT_OVER, limit, Util.FormatDuration(plan.overLimitSeconds))
	end
	return Util.Format(L.PLAN_LIMIT_OK, limit)
end

-- The plan of the current settings for the goals.
function PlanCommands.CurrentPlan(charData, goals)
	local inputs = Sourcing.Inputs(charData, goals)
	return Sourcing.Plan(inputs, ns.db.settings.strategy, (Sourcing.Budget()), Sourcing.TimeLimit()), inputs
end

local function printPlan(charData, goals)
	local budget, isOwn = Sourcing.Budget()
	local strategy = ns.db.settings.strategy
	local plan = PlanCommands.CurrentPlan(charData, goals)
	Log.Print(Util.Format(L.PLAN_HEADER, L[PlanCommands.STRATEGY_NAMES[strategy]], PlanCommands.BudgetText(budget, isOwn)))
	if #plan.lines == 0 then
		Log.Print(L.FARM_NOTHING_MISSING)
		return
	end
	for _, line in ipairs(plan.lines) do
		Log.Print(Util.Format(L.PLAN_LINE, UIShared.ItemText(line.itemID), line.missing, PlanCommands.DescribeLine(line)))
	end
	Log.Print(PlanCommands.SummaryText(plan))
	if plan.limitSeconds then
		Log.Print(PlanCommands.LimitText(plan))
	end
	for _, note in ipairs(PlanCommands.CostNotes(charData, plan)) do
		Log.Print(note)
	end
end

local function planCommand(argument)
	local charData = UIShared.Character()
	if not charData then
		return
	end
	if string.lower(Util.Trim(argument)) == "all" then
		local goals = Materials.AllGoals(charData)
		if #goals == 0 then
			Log.Print(L.GOAL_LIST_EMPTY)
			return
		end
		printPlan(charData, goals)
		return
	end
	local goal = UIShared.ActiveGoal(charData)
	if goal then
		printPlan(charData, { goal })
	end
end

local function strategyCommand(argument)
	local strategy = STRATEGY_WORDS[string.lower(Util.Trim(argument))]
	if not strategy then
		Log.Print(L.STRATEGY_USAGE)
		return
	end
	if not UIShared.WritableCharacter() then
		return
	end
	ns.db.settings.strategy = strategy
	Log.Print(Util.Format(L.STRATEGY_SET, L[PlanCommands.STRATEGY_NAMES[strategy]]))
end

local function budgetCommand(argument)
	if not UIShared.WritableCharacter() then
		return
	end
	argument = Util.Trim(argument)
	if argument == "" then
		local budget, isOwn = Sourcing.Budget()
		Log.Print(PlanCommands.BudgetText(budget, isOwn))
		return
	end
	if string.lower(argument) == "clear" then
		ns.db.settings.budgetCopper = 0
		Log.Print(L.BUDGET_CLEARED)
		return
	end
	local copper, err = Money.Parse(argument)
	if not copper or copper <= 0 then
		UIShared.PrintError(err or "invalid_money")
		return
	end
	ns.db.settings.budgetCopper = copper
	Log.Print(Util.Format(L.BUDGET_SET, Money.Format(copper)))
end

-- Farm time limit: a duration ("2h", "1h 30m") or "clear"; without argument the current limit.
local function timeLimitCommand(argument)
	if not UIShared.WritableCharacter() then
		return
	end
	argument = Util.Trim(argument)
	local settings = ns.db.settings
	if argument == "" then
		local limit = Sourcing.TimeLimit()
		Log.Print(limit and Util.Format(L.TIME_LIMIT_SET, Util.FormatDuration(limit)) or L.TIME_LIMIT_NONE)
		return
	end
	if string.lower(argument) == "clear" then
		settings.farmTimeLimitMinutes = 0
		Log.Print(L.TIME_LIMIT_CLEARED)
		return
	end
	local seconds, err = Util.ParseDuration(argument)
	if not seconds then
		UIShared.PrintError(err)
		return
	end
	local minutes, maxMinutes = Util.Round(seconds / SECONDS_PER_MINUTE), ns.DB.MAX["settings.farmTimeLimitMinutes"]
	if minutes < 1 or minutes > maxMinutes then
		Log.Print(Util.Format(L.TIME_LIMIT_RANGE, Util.FormatDuration(maxMinutes * SECONDS_PER_MINUTE)))
		return
	end
	settings.farmTimeLimitMinutes = minutes
	Log.Print(Util.Format(L.TIME_LIMIT_SET, Util.FormatDuration(minutes * SECONDS_PER_MINUTE)))
end

if ns.Client then
	Slash.AddCommand("timelimit", timeLimitCommand, L.HELP_LINE_TIMELIMIT)
	Slash.AddCommand("plan", planCommand, L.HELP_LINE_PLAN)
	Slash.AddCommand("strategy", strategyCommand, L.HELP_LINE_STRATEGY)
	Slash.AddCommand("budget", budgetCommand, L.HELP_LINE_BUDGET)
end
