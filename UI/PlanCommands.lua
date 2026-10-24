-- /bof plan: start the gold plan for a duration as a checklist ("Jetzt tun", Core/ActivePlan.lua),
-- show or hide its window, tick a step by hand, stop it. While a plan is active its steps are checked
-- after bag, zone and data changes; when every step is done the result is printed and the plan ends.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log
local Money = ns.Money
local Events = ns.Events
local UIShared = ns.UIShared
local ActivePlan = ns.ActivePlan

local PlanCommands = {}
ns.PlanCommands = PlanCommands

local DEFAULT_SECONDS = 3600
local CHECK_SIGNALS = { "BAGS_CHANGED", "ZONE_CHANGED", "DATA_CHANGED" }

local function runsSince(uiMapID, fishing, time)
	local count = 0
	for _, run in ipairs(ns.db.farmRuns) do
		local isFishing = run.activity == "FISHING"
		if run.charKey == ns.charKey and run.uiMapID == uiMapID and isFishing == (fishing == true) and run.endedAt >= time then
			count = count + 1
		end
	end
	return count
end

function PlanCommands.Context()
	local client = ns.Client
	return { bagCount = function(itemID)
		return client:GetBagCount(itemID) or 0
	end, mapID = function()
		return client:GetCurrentMapID()
	end, runsSince = runsSince, money = client:GetMoney() or 0, now = client:GetServerTime(), charKey = ns.charKey }
end

function PlanCommands.Active()
	local charData = UIShared.Character()
	return charData and charData.activePlan
end

-- Result line: gold since the start against the plan.
function PlanCommands.ResultText(active)
	local earned = (ns.Client:GetMoney() or 0) - active.startMoney
	return Util.Format(L.PLAN_RESULT, Money.Format(earned), Util.FormatDuration(ns.Client:GetServerTime() - active.startedAt),
		Money.Format(active.plannedSure), Money.Format(active.plannedAuction))
end

local function finish(charData, text)
	local now = ns.Client:GetServerTime()
	ns.WeekReview.RecordPlan(charData, charData.activePlan, (ns.Client:GetMoney() or 0) - charData.activePlan.startMoney, now)
	Log.Print(text .. " " .. PlanCommands.ResultText(charData.activePlan))
	charData.activePlan = nil
	Events.Emit("PLAN_CHANGED")
end

-- Checks the active plan's steps; ends it when all are done.
function PlanCommands.Check()
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	local active = charData and charData.activePlan
	if not active then
		return
	end
	if ActivePlan.Update(active, PlanCommands.Context()) > 0 then
		local done, total = ActivePlan.Progress(active)
		if done == total then
			finish(charData, L.PLAN_ALL_DONE)
			return
		end
		Events.Emit("PLAN_CHANGED")
	end
end

local function start(charData, argument)
	local seconds, err = DEFAULT_SECONDS, nil
	if Util.Trim(argument) ~= "" then
		seconds, err = Util.ParseDuration(argument)
	end
	if not seconds or seconds <= 0 then
		UIShared.PrintError(err or "invalid_duration")
		return
	end
	local active = ActivePlan.Start(charData, ns.GoldPlanCommands.Plan(charData, seconds), PlanCommands.Context())
	if not active then
		Log.Print(L.PLAN_NOTHING)
		return
	end
	ActivePlan.Update(active, PlanCommands.Context())
	Log.Print(Util.Format(L.PLAN_STARTED, #active.steps, Util.FormatDuration(seconds)))
	Events.Emit("PLAN_CHANGED")
	ns.PlanWindow.Show()
end

local function tick(charData, argument)
	local index = tonumber(argument)
	local state = charData.activePlan and index and ActivePlan.Toggle(charData.activePlan, index)
	if state == nil then
		Log.Print(L.PLAN_NO_STEP)
		return
	end
	local done, total = ActivePlan.Progress(charData.activePlan)
	if done == total then
		finish(charData, L.PLAN_ALL_DONE)
		return
	end
	Events.Emit("PLAN_CHANGED")
end

local function planCommand(argument)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	local sub, rest = ns.Slash.SplitCommand(argument)
	if sub == "start" then
		start(charData, rest)
	elseif sub == "stop" then
		if charData.activePlan then
			finish(charData, L.PLAN_STOPPED)
		end
	elseif tonumber(sub) then
		tick(charData, sub)
	else
		ns.PlanWindow.Toggle()
	end
end

if ns.Client then
	ns.Slash.AddCommand("plan", planCommand, "HELP_LINE_PLAN")
	for _, signal in ipairs(CHECK_SIGNALS) do
		Events.OnSignal(signal, PlanCommands.Check)
	end
end
