-- /bof farm: start, pause, resume, travel, stop, review and save farm runs; list runs and show
-- farm time estimates for missing materials.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local FarmRuns = ns.FarmRuns
local FarmCapture = ns.FarmCapture
local FarmEstimates = ns.FarmEstimates
local Stock = ns.Stock
local Slash = ns.Slash
local UIShared = ns.UIShared

local FarmCommands = {}
ns.FarmCommands = FarmCommands

local LIST_LIMIT = 5
local ACTIVITY_WORDS = { gather = "GATHER", mobs = "MOBS", other = "OTHER" }
local ACTIVITY_NAMES = { GATHER = "FARM_ACTIVITY_GATHER", MOBS = "FARM_ACTIVITY_MOBS", OTHER = "FARM_ACTIVITY_OTHER" }
local STATE_NAMES = { FARM = "FARM_STATE_FARM", TRAVEL = "FARM_STATE_TRAVEL", PAUSED = "FARM_STATE_PAUSED", REVIEW = "FARM_STATE_REVIEW" }

local function now()
	return ns.Client:GetServerTime()
end

local function mapName(uiMapID)
	return uiMapID > 0 and ns.Client:GetMapName(uiMapID) or L.UNKNOWN_VALUE
end

local function printItems(run)
	for itemID, entry in pairs(run.items) do
		Log.Print(Util.Format(L.FARM_ITEM_LINE, UIShared.ItemText(itemID), entry.confirmed, entry.unclear))
	end
end

function FarmCommands.PrintStatus(charData)
	local run = FarmRuns.Current(charData)
	if not run then
		Log.Print(L.FARM_NONE)
		return
	end
	local active, travel = FarmRuns.Elapsed(run, now())
	local target = run.targetItemID > 0 and UIShared.ItemText(run.targetItemID) or L.FARM_NO_TARGET
	Log.Print(Util.Format(L.FARM_STATUS, L[STATE_NAMES[run.state]], L[ACTIVITY_NAMES[run.activity]],
		Util.FormatDuration(active), Util.FormatDuration(travel), target, mapName(run.uiMapID)))
	printItems(run)
	if run.state == "REVIEW" then
		Log.Print(L.FARM_REVIEW_HINT)
	end
end

-- "start [gather|mobs|other] [item]"
local function start(charData, argument)
	local word, rest = Slash.SplitCommand(argument)
	local activity = ACTIVITY_WORDS[word]
	if not activity then
		activity, rest = "GATHER", argument
	end
	local targetItemID = Util.Trim(rest) ~= "" and Util.ParseItemArg(rest) or nil
	if Util.Trim(rest) ~= "" and not targetItemID then
		UIShared.PrintError("invalid_item")
		return
	end
	local run, err = FarmRuns.Start(charData, {
		activity = activity, targetItemID = targetItemID, uiMapID = ns.Client:GetCurrentMapID(), now = now(),
	})
	if not run then
		UIShared.PrintError(err)
		return
	end
	FarmCapture.Activate(true)
	Log.Print(Util.Format(L.FARM_STARTED, L[ACTIVITY_NAMES[activity]], mapName(run.uiMapID)))
end

-- Commands that change the state and print the status afterwards.
local STEPS = {
	pause = function(charData)
		local run, err = FarmRuns.Pause(charData, now())
		FarmCapture.Deactivate()
		return run, err
	end,
	resume = function(charData)
		local run, err = FarmRuns.Resume(charData, now())
		if run then
			FarmCapture.Activate(true)
		end
		return run, err
	end,
	travel = function(charData)
		return FarmRuns.ToggleTravel(charData, now(), ns.Client:GetCurrentMapID())
	end,
	stop = function(charData)
		local run, err = FarmRuns.Stop(charData, now())
		FarmCapture.Deactivate()
		return run, err
	end,
}

local function step(charData, name)
	local run, err = STEPS[name](charData)
	if not run then
		UIShared.PrintError(err)
		return
	end
	FarmCommands.PrintStatus(charData)
end

local function keep(charData, argument)
	local itemID = Util.ParseItemArg(argument)
	if not itemID then
		UIShared.PrintError("invalid_item")
		return
	end
	local confirmed, err = FarmRuns.KeepUnclear(charData, itemID)
	if not confirmed then
		UIShared.PrintError(err)
		return
	end
	Log.Print(Util.Format(L.FARM_KEPT, UIShared.ItemText(itemID), confirmed))
end

local function save(charData)
	local count, err = FarmRuns.Save(ns.db, ns.charKey, charData)
	if not count then
		UIShared.PrintError(err)
		return
	end
	Log.Print(L.FARM_SAVED)
end

local function discard(charData)
	local ok, err = FarmRuns.Discard(charData)
	if not ok then
		UIShared.PrintError(err)
		return
	end
	FarmCapture.Deactivate()
	Log.Print(L.FARM_DISCARDED)
end

-- Last runs of this character, newest first.
local function list()
	local shown = 0
	for i = #ns.db.farmRuns, 1, -1 do
		local run = ns.db.farmRuns[i]
		if run.charKey == ns.charKey and shown < LIST_LIMIT then
			shown = shown + 1
			local total = 0
			for _, amount in pairs(run.items) do
				total = total + amount
			end
			Log.Print(Util.Format(L.FARM_LIST_LINE, Util.FormatAge(now() - run.endedAt), L[ACTIVITY_NAMES[run.activity]],
				mapName(run.uiMapID), Util.FormatDuration(run.activeSeconds), total))
		end
	end
	if shown == 0 then
		Log.Print(L.FARM_LIST_EMPTY)
	end
end

-- Estimate line for one missing material.
function FarmCommands.EstimateText(itemID, missing)
	local scope = ns.db.settings.farmEstimateScope
	local basis = FarmEstimates.ForItem(ns.db, itemID, scope, ns.charKey)
	if not basis then
		return L.FARM_ESTIMATE_NONE
	end
	local seconds, low, high = FarmEstimates.TimeFor(basis, missing)
	local source = Util.Format(L.FARM_ESTIMATE_BASIS, basis.runs, Util.FormatDuration(basis.seconds))
	if not seconds then
		return Util.Format(L.FARM_ESTIMATE_NO_YIELD, source)
	end
	local travel = Util.FormatDuration(basis.travelSeconds)
	if low then
		return Util.Format(L.FARM_ESTIMATE_RANGE, Util.FormatDuration(seconds), Util.FormatDuration(low),
			Util.FormatDuration(high), travel, source)
	end
	return Util.Format(L.FARM_ESTIMATE, Util.FormatDuration(seconds), travel, source)
end

local function estimate(charData)
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	local printed = 0
	for _, row in ipairs(Stock.Rows(charData, { goal })) do
		if row.missing > 0 then
			printed = printed + 1
			Log.Print(Util.Format(L.FARM_ESTIMATE_LINE, UIShared.ItemText(row.itemID), row.missing,
				FarmCommands.EstimateText(row.itemID, row.missing)))
		end
	end
	if printed == 0 then
		Log.Print(L.FARM_NOTHING_MISSING)
	end
end

local function toggleScope()
	local settings = ns.db.settings
	settings.farmEstimateScope = settings.farmEstimateScope == "CHARACTER" and "ACCOUNT" or "CHARACTER"
	Log.Print(settings.farmEstimateScope == "ACCOUNT" and L.FARM_SCOPE_ACCOUNT or L.FARM_SCOPE_CHARACTER)
end

local WRITE_COMMANDS = {
	start = start,
	keep = keep,
	save = save,
	discard = discard,
	scope = toggleScope,
}

local READ_COMMANDS = {
	[""] = FarmCommands.PrintStatus,
	status = FarmCommands.PrintStatus,
	list = list,
	estimate = estimate,
}

local function farmCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if READ_COMMANDS[sub] then
		local charData = UIShared.Character()
		if charData then
			READ_COMMANDS[sub](charData)
		end
		return
	end
	if not (STEPS[sub] or WRITE_COMMANDS[sub]) then
		Log.Print(L.FARM_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	if STEPS[sub] then
		step(charData, sub)
	else
		WRITE_COMMANDS[sub](charData, rest)
	end
end

if ns.Client then
	Slash.AddCommand("farm", farmCommand, L.HELP_LINE_FARM)
end
