-- /bof farm: start, pause, resume, travel and stop farm runs (the farm window's buttons run the same
-- commands), list runs. Stopping saves the run at once: only looted items count (user decision 0.10.0,
-- no review step). Without a subcommand the farm window opens or closes.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local FarmRuns = ns.FarmRuns
local FarmCapture = ns.FarmCapture
local Slash = ns.Slash
local UIShared = ns.UIShared

local FarmCommands = {}
ns.FarmCommands = FarmCommands

local LIST_LIMIT = 5
local SECONDS_PER_MINUTE, SECONDS_PER_HOUR = 60, 3600
local STATE_NAMES = { FARM = "FARM_STATE_FARM", TRAVEL = "FARM_STATE_TRAVEL", PAUSED = "FARM_STATE_PAUSED", REVIEW = "FARM_STATE_PAUSED" }

local function now()
	return ns.Client:GetServerTime()
end

local function mapName(uiMapID)
	return uiMapID > 0 and ns.Client:GetMapName(uiMapID) or L.UNKNOWN_VALUE
end

-- Name of a farm route (GoldRoutes): its zone.
function FarmCommands.RouteName(route)
	return mapName(route.uiMapID)
end

local function itemTotal(items)
	local total = 0
	for _, amount in pairs(items) do
		total = total + amount
	end
	return total
end

-- Looted items of the run in id order, as "[Item]: 7" lines.
function FarmCommands.ItemLines(run)
	local ids = {}
	for itemID, entry in pairs(run.items) do
		if entry.confirmed > 0 then
			ids[#ids + 1] = itemID
		end
	end
	table.sort(ids)
	local lines = {}
	for i, itemID in ipairs(ids) do
		lines[i] = Util.Format(L.FARM_ITEM_LINE, UIShared.ItemText(itemID), run.items[itemID].confirmed)
	end
	return lines
end

-- Status line of a run with the times up to `at` (shared with the farm window and the minimap tooltip).
function FarmCommands.StatusLine(run, at)
	local active, travel = FarmRuns.Elapsed(run, at)
	local line = Util.Format(L.FARM_STATUS, L[STATE_NAMES[run.state]], mapName(run.uiMapID),
		Util.FormatDuration(active), Util.FormatDuration(travel))
	if run.targetItemID > 0 then
		line = line .. Util.Format(L.FARM_STATUS_TARGET, UIShared.ItemText(run.targetItemID))
	end
	return line
end

function FarmCommands.PrintStatus(charData)
	local run = FarmRuns.Current(charData)
	if not run then
		Log.Print(L.FARM_NONE)
		return
	end
	Log.Print(FarmCommands.StatusLine(run, now()))
	for _, line in ipairs(FarmCommands.ItemLines(run)) do
		Log.Print(line)
	end
end

-- "Ergebnis: 12 Gegenstände in 20 Min. Farmzeit (36 pro Stunde)" for a saved run.
local function printRunSummary(saved)
	local total = itemTotal(saved.items)
	local perHour = saved.activeSeconds > 0 and math.floor(total * SECONDS_PER_HOUR / saved.activeSeconds) or 0
	Log.Print(Util.Format(L.FARM_RUN_SUMMARY, total, Util.FormatDuration(saved.activeSeconds), perHour))
end

-- "start [item]": the optional item is the run's target material.
local function start(charData, argument)
	local targetItemID = Util.Trim(argument) ~= "" and Util.ParseItemArg(argument) or nil
	if Util.Trim(argument) ~= "" and not targetItemID then
		UIShared.PrintError("invalid_item")
		return
	end
	local run, err = FarmRuns.Start(charData, {
		targetItemID = targetItemID, uiMapID = ns.Client:GetCurrentMapID(), now = now(),
		idleSeconds = ns.db.settings.farmIdleMinutes * SECONDS_PER_MINUTE,
	})
	if not run then
		UIShared.PrintError(err)
		return
	end
	FarmCapture.Activate(true)
	Log.Print(Util.Format(L.FARM_STARTED, mapName(run.uiMapID)))
	ns.FarmWindow.Show()
end

local function stop(charData)
	local index, err = FarmRuns.Finish(ns.db, ns.charKey, charData, now())
	FarmCapture.Deactivate()
	if not index then
		UIShared.PrintError(err)
		return
	end
	Log.Print(L.FARM_SAVED)
	printRunSummary(ns.db.farmRuns[index])
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
		local run, err = FarmRuns.ToggleTravel(charData, now(), ns.Client:GetCurrentMapID())
		-- A clear line first: the mode is easy to forget, and then farm time counts as travel.
		if run then
			Log.Print(run.state == "TRAVEL" and L.FARM_NOW_TRAVEL or L.FARM_NOW_FARM)
		end
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
			Log.Print(Util.Format(L.FARM_LIST_LINE, Util.FormatAge(now() - run.endedAt), mapName(run.uiMapID),
				Util.FormatDuration(run.activeSeconds), itemTotal(run.items)))
		end
	end
	if shown == 0 then
		Log.Print(L.FARM_LIST_EMPTY)
	end
end

local function toggleScope()
	local settings = ns.db.settings
	settings.farmEstimateScope = settings.farmEstimateScope == "CHARACTER" and "ACCOUNT" or "CHARACTER"
	Log.Print(settings.farmEstimateScope == "ACCOUNT" and L.FARM_SCOPE_ACCOUNT or L.FARM_SCOPE_CHARACTER)
end

local WRITE_COMMANDS = {
	start = start,
	stop = stop,
	discard = discard,
	scope = toggleScope,
}

local READ_COMMANDS = {
	[""] = function()
		ns.FarmWindow.Toggle()
	end,
	status = FarmCommands.PrintStatus,
	list = list,
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
