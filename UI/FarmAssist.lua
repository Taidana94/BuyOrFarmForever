-- Farm run assistance that needs no player input:
-- * tells once when the run's target material covers all goals (farmNotifyComplete);
-- * pauses the run while the player is AFK or resting in a city or inn and resumes it afterwards
--   (farmAutoPauseAfk, farmAutoPauseResting; only runs it paused itself);
-- * switches to travel on a flight path and back on landing (farmAutoTravelTaxi).
-- The player state signals are registered only while a run exists (not in review). FARM_CHANGED
-- is an internal signal raised by the capture during runs.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Events = ns.Events
local FarmRuns = ns.FarmRuns
local Stock = ns.Stock
local UIShared = ns.UIShared

local FarmAssist = {}
ns.FarmAssist = FarmAssist

-- The flight state is read shortly after control is lost, when the taxi flag is set.
FarmAssist.TAXI_CHECK_DELAY = 1

-- Character data and current run, or nil (no data yet, or read-only data of a newer version).
local function currentRun()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil, nil
	end
	local charData = ns.db.characters[ns.charKey]
	return charData, charData and charData.currentRun
end

local function command(line)
	ns.Slash.Handle(line)
end

-- Missing amount of an item the plan of the character's wants needs, or nil if the plan does not need it.
function FarmAssist.MissingForGoals(charData, itemID)
	local plan = ns.WantPlan.Current()
	for _, row in ipairs(plan and Stock.Rows(charData, ns.WantPlan.Requirements(plan)) or {}) do
		if row.itemID == itemID then
			return row.missing
		end
	end
	return nil
end

local function checkTarget()
	local charData, run = currentRun()
	if not (FarmRuns.IsRunning(run) and run.targetItemID > 0 and not run.targetNotified) then
		return
	end
	if ns.db.settings.farmNotifyComplete and FarmAssist.MissingForGoals(charData, run.targetItemID) == 0 then
		run.targetNotified = true
		Log.Print(Util.Format(L.FARM_TARGET_REACHED, UIShared.ItemText(run.targetItemID)))
	end
end

-- Pause and travel -------------------------------------------------------------------------

local function pauseReason(settings)
	if settings.farmAutoPauseAfk and ns.Client:IsAFK() then
		return "FARM_AUTO_PAUSED_AFK"
	end
	if settings.farmAutoPauseResting and ns.Client:IsResting() then
		return "FARM_AUTO_PAUSED_RESTING"
	end
	return nil
end

local function onPlayerState()
	local _, run = currentRun()
	if not run then
		return
	end
	local reason = pauseReason(ns.db.settings)
	if reason and FarmRuns.IsRunning(run) then
		Log.Print(L[reason])
		command("farm pause")
		run.autoPaused = true
	elseif not reason and run.state == "PAUSED" and run.autoPaused then
		Log.Print(L.FARM_AUTO_RESUMED)
		command("farm resume")
	end
end

local function checkTaxi()
	local _, run = currentRun()
	if ns.db.settings.farmAutoTravelTaxi and run and run.state == "FARM" and ns.Client:IsOnTaxi() then
		command("farm travel")
		run.autoTravel = true
	end
end

local function onControlLost()
	C_Timer.After(FarmAssist.TAXI_CHECK_DELAY, checkTaxi)
end

local function onControlGained()
	local _, run = currentRun()
	if run and run.state == "TRAVEL" and run.autoTravel and not ns.Client:IsOnTaxi() then
		command("farm travel")
	end
end

local STATE_HANDLERS = {
	PLAYER_FLAGS_CHANGED = onPlayerState,
	RESTING_CHANGED = onPlayerState,
	CONTROL_LOST = onControlLost,
	CONTROL_GAINED = onControlGained,
}

local watching = false

-- Registers the player state signals while a run exists, unregisters them otherwise.
local function syncWatching()
	local _, run = currentRun()
	local wanted = run ~= nil and run.state ~= "REVIEW"
	if wanted == watching then
		return
	end
	watching = wanted
	for signal, handler in pairs(STATE_HANDLERS) do
		if wanted then
			Events.OnSignal(signal, handler)
		else
			Events.OffSignal(signal, handler)
		end
	end
end

-- True while the player state signals are registered (for tests and /bof perf reviews).
function FarmAssist.IsWatching()
	return watching
end

if ns.Client then
	Events.OnSignal("FARM_CHANGED", checkTarget)
	Events.OnSignal("DATA_CHANGED", syncWatching)
	Events.OnSignal("CHARACTER_READY", syncWatching)
end
