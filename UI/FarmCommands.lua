-- /bof farm: start, pause, resume, travel, stop, review and save farm runs; list runs and show
-- farm time estimates for missing materials.
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
local SECONDS_PER_MINUTE = 60
local ACTIVITY_WORDS = { gather = "GATHER", mobs = "MOBS", other = "OTHER" }
local ACTIVITY_NAMES = { GATHER = "FARM_ACTIVITY_GATHER", MOBS = "FARM_ACTIVITY_MOBS", OTHER = "FARM_ACTIVITY_OTHER" }
local STATE_NAMES = { FARM = "FARM_STATE_FARM", TRAVEL = "FARM_STATE_TRAVEL", PAUSED = "FARM_STATE_PAUSED", REVIEW = "FARM_STATE_REVIEW" }

local function now()
	return ns.Client:GetServerTime()
end

local function mapName(uiMapID)
	return uiMapID > 0 and ns.Client:GetMapName(uiMapID) or L.UNKNOWN_VALUE
end

-- Items of the run in id order: { { itemID, unclear, line = "[Item]: 7 geplündert, 2 unklar" } }
-- (shared with the Farm tab).
function FarmCommands.ItemEntries(run)
	local entries = {}
	for itemID, entry in pairs(run.items) do
		entries[#entries + 1] = {
			itemID = itemID,
			unclear = entry.unclear,
			line = Util.Format(L.FARM_ITEM_LINE, UIShared.ItemText(itemID), entry.confirmed, entry.unclear),
		}
	end
	table.sort(entries, function(a, b)
		return a.itemID < b.itemID
	end)
	return entries
end

function FarmCommands.ItemLines(run)
	local lines = {}
	for i, entry in ipairs(FarmCommands.ItemEntries(run)) do
		lines[i] = entry.line
	end
	return lines
end

-- Status line of a run with the times up to `at` (shared with the Farm tab).
function FarmCommands.StatusLine(run, at)
	local active, travel = FarmRuns.Elapsed(run, at)
	local target = run.targetItemID > 0 and UIShared.ItemText(run.targetItemID) or L.FARM_NO_TARGET
	return Util.Format(L.FARM_STATUS, L[STATE_NAMES[run.state]], L[ACTIVITY_NAMES[run.activity]],
		Util.FormatDuration(active), Util.FormatDuration(travel), target, mapName(run.uiMapID))
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
		idleSeconds = ns.db.settings.farmIdleMinutes * SECONDS_PER_MINUTE,
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
		local run, err = FarmRuns.ToggleTravel(charData, now(), ns.Client:GetCurrentMapID())
		-- A clear line first: the mode is easy to forget, and then farm time counts as travel.
		if run then
			Log.Print(run.state == "TRAVEL" and L.FARM_NOW_TRAVEL or L.FARM_NOW_FARM)
		end
		return run, err
	end,
	stop = function(charData)
		local run, err = FarmRuns.Stop(charData, now())
		FarmCapture.Deactivate()
		return run, err
	end,
}

-- With farmAutoReview, a stopped run without unclear gains needs no review and is saved.
local function autoSave(charData, run)
	if not (ns.db.settings.farmAutoReview and run.state == "REVIEW" and not FarmRuns.HasUnclear(run)) then
		return false
	end
	FarmCommands.PrintStatus(charData)
	FarmRuns.Save(ns.db, ns.charKey, charData)
	Log.Print(L.FARM_AUTO_SAVED)
	return true
end

local function step(charData, name)
	local run, err = STEPS[name](charData)
	if not run then
		UIShared.PrintError(err)
		return
	end
	if not autoSave(charData, run) then
		FarmCommands.PrintStatus(charData)
	end
end

local function keep(charData, argument)
	if string.lower(Util.Trim(argument)) == "all" then
		local changed, err = FarmRuns.KeepAllUnclear(charData)
		if not changed then
			UIShared.PrintError(err)
			return
		end
		Log.Print(Util.Format(L.FARM_KEPT_ALL, changed))
		return
	end
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

local function estimate(charData)
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	for _, line in ipairs(ns.FarmReports.EstimateLines(charData, goal)) do
		Log.Print(line)
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
