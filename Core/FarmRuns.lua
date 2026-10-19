-- Farm runs: a small state machine with active farm time, travel time and yield per item.
-- The current run of a character lives in characters[charKey].currentRun; finished runs are
-- stored account-wide in db.farmRuns (newest last, capped at MAX_RUNS). Pure logic on plain
-- tables; times are server time in seconds, passed in by the caller.
--
-- States: FARM (farming), TRAVEL (on the way), PAUSED, REVIEW (stopped, unclear gains can be
-- kept before saving). Yield per item: confirmed (looted) and unclear (other bag gains).
-- Idle time: with run.idleSeconds > 0, farm time without any activity (loot, bag change, combat;
-- reported with NoteActivity) counts only up to idleSeconds. The gap is cut when the next
-- activity arrives or the segment ends, so no timer is needed.
local _, ns = ...

local FarmRuns = {}
ns.FarmRuns = FarmRuns

FarmRuns.ACTIVITIES = { GATHER = true, MOBS = true, OTHER = true }
FarmRuns.MAX_RUNS = 500
-- A run that was running at login continues if the last sign of life is this recent (a /reload);
-- otherwise it is paused at that moment (logout or crash).
FarmRuns.RELOAD_GRACE_SECONDS = 60

local RUNNING = { FARM = true, TRAVEL = true }

function FarmRuns.IsRunning(run)
	return run ~= nil and RUNNING[run.state] == true
end

function FarmRuns.Current(charData)
	return charData.currentRun
end

-- End of the counted farm time: at most idleSeconds after the last activity.
local function countedUntil(run, now)
	local idle = run.idleSeconds or 0
	if run.state ~= "FARM" or idle <= 0 or not run.lastActivityAt then
		return now
	end
	return math.max(run.segmentStart, math.min(now, run.lastActivityAt + idle))
end

-- Adds the time since segmentStart to the farm or travel time.
local function closeSegment(run, now)
	if not RUNNING[run.state] then
		return
	end
	local seconds = math.max(0, countedUntil(run, now) - run.segmentStart)
	if run.state == "TRAVEL" then
		run.travelSeconds = run.travelSeconds + seconds
	else
		run.activeSeconds = run.activeSeconds + seconds
	end
	run.segmentStart = now
end

-- Farm and travel seconds including the running segment (for display; changes nothing).
function FarmRuns.Elapsed(run, now)
	local active, travel = run.activeSeconds, run.travelSeconds
	local running = math.max(0, countedUntil(run, now) - run.segmentStart)
	if run.state == "FARM" then
		active = active + running
	elseif run.state == "TRAVEL" then
		travel = travel + running
	end
	return active, travel
end

-- Starts a run. opts = { activity, targetItemID (optional), uiMapID (optional), idleSeconds
-- (optional, 0 = count all time), now }.
-- Returns the run, or nil plus "run_exists" | "invalid_activity".
function FarmRuns.Start(charData, opts)
	if charData.currentRun then
		return nil, "run_exists"
	end
	if not FarmRuns.ACTIVITIES[opts.activity] then
		return nil, "invalid_activity"
	end
	charData.currentRun = {
		state = "FARM",
		activity = opts.activity,
		targetItemID = opts.targetItemID or 0,
		uiMapID = opts.uiMapID or 0,
		items = {},
		activeSeconds = 0,
		travelSeconds = 0,
		startedAt = opts.now,
		segmentStart = opts.now,
		lastSeenAt = opts.now,
		lastActivityAt = opts.now,
		idleSeconds = opts.idleSeconds or 0,
		endedAt = 0,
		lootCopper = 0,
	}
	return charData.currentRun
end

-- Coins looted during a running run (from gold changes with an open loot window).
function FarmRuns.AddLootCopper(run, copper)
	if FarmRuns.IsRunning(run) and copper > 0 then
		run.lootCopper = (run.lootCopper or 0) + copper
	end
end

-- An activity (loot, bag change, combat) during the run. A farm gap longer than idleSeconds since
-- the previous activity is removed by moving the segment start forward.
function FarmRuns.NoteActivity(run, now)
	local idle = run.idleSeconds or 0
	if run.state == "FARM" and idle > 0 and run.lastActivityAt then
		local gap = now - math.max(run.lastActivityAt, run.segmentStart)
		if gap > idle then
			run.segmentStart = math.min(now, run.segmentStart + gap - idle)
		end
	end
	run.lastActivityAt = now
end

local function requireState(charData, allowed)
	local run = charData.currentRun
	if not run then
		return nil, "no_run"
	end
	if not allowed[run.state] then
		return nil, "wrong_state"
	end
	return run
end

function FarmRuns.Pause(charData, now)
	local run, err = requireState(charData, RUNNING)
	if not run then
		return nil, err
	end
	closeSegment(run, now)
	run.resumeState = run.state
	run.state = "PAUSED"
	run.lastSeenAt = now
	return run
end

function FarmRuns.Resume(charData, now)
	local run, err = requireState(charData, { PAUSED = true })
	if not run then
		return nil, err
	end
	run.state = run.resumeState or "FARM"
	run.resumeState = nil
	run.autoPaused = nil
	run.segmentStart = now
	run.lastSeenAt = now
	run.lastActivityAt = now
	return run
end

-- Switches between farming and travel. Arriving (TRAVEL -> FARM) sets the run's location.
function FarmRuns.ToggleTravel(charData, now, uiMapID)
	local run, err = requireState(charData, RUNNING)
	if not run then
		return nil, err
	end
	closeSegment(run, now)
	run.autoTravel = nil
	if run.state == "TRAVEL" then
		run.state = "FARM"
		run.uiMapID = uiMapID or run.uiMapID
	else
		run.state = "TRAVEL"
	end
	run.lastSeenAt = now
	run.lastActivityAt = now
	return run
end

function FarmRuns.Stop(charData, now)
	local run, err = requireState(charData, { FARM = true, TRAVEL = true, PAUSED = true })
	if not run then
		return nil, err
	end
	closeSegment(run, now)
	run.state = "REVIEW"
	run.resumeState = nil
	run.endedAt = now
	return run
end

-- Records a bag gain of an item during a running run. isLoot = true counts it as confirmed.
-- The caller only reports gains while FarmRuns.IsRunning(run).
function FarmRuns.AddGain(run, itemID, amount, isLoot, now)
	local entry = run.items[itemID]
	if not entry then
		entry = { confirmed = 0, unclear = 0 }
		run.items[itemID] = entry
	end
	if isLoot then
		entry.confirmed = entry.confirmed + amount
	else
		entry.unclear = entry.unclear + amount
	end
	run.lastSeenAt = now
end

-- True if any item of the run has an unclear amount.
function FarmRuns.HasUnclear(run)
	for _, entry in pairs(run.items) do
		if entry.unclear > 0 then
			return true
		end
	end
	return false
end

-- In REVIEW: counts the unclear amount of an item as confirmed. Returns the new confirmed amount.
function FarmRuns.KeepUnclear(charData, itemID)
	local run, err = requireState(charData, { REVIEW = true })
	if not run then
		return nil, err
	end
	local entry = run.items[itemID]
	if not (entry and entry.unclear > 0) then
		return nil, "nothing_unclear"
	end
	entry.confirmed = entry.confirmed + entry.unclear
	entry.unclear = 0
	return entry.confirmed
end

-- In REVIEW: counts all unclear amounts as confirmed. Returns the number of items changed.
function FarmRuns.KeepAllUnclear(charData)
	local run, err = requireState(charData, { REVIEW = true })
	if not run then
		return nil, err
	end
	local changed = 0
	for _, entry in pairs(run.items) do
		if entry.unclear > 0 then
			entry.confirmed = entry.confirmed + entry.unclear
			entry.unclear = 0
			changed = changed + 1
		end
	end
	return changed
end

-- Saves a reviewed run: unclear amounts are dropped, the run goes to db.farmRuns.
function FarmRuns.Save(db, charKey, charData)
	local run, err = requireState(charData, { REVIEW = true })
	if not run then
		return nil, err
	end
	local items = {}
	for itemID, entry in pairs(run.items) do
		if entry.confirmed > 0 then
			items[itemID] = entry.confirmed
		end
	end
	db.farmRuns[#db.farmRuns + 1] = {
		charKey = charKey,
		activity = run.activity,
		targetItemID = run.targetItemID,
		uiMapID = run.uiMapID,
		items = items,
		activeSeconds = run.activeSeconds,
		travelSeconds = run.travelSeconds,
		startedAt = run.startedAt,
		endedAt = run.endedAt,
		lootCopper = run.lootCopper or 0, -- nil in runs saved before 0.6.0 (coins not recorded)
	}
	while #db.farmRuns > FarmRuns.MAX_RUNS do
		table.remove(db.farmRuns, 1)
	end
	charData.currentRun = nil
	return #db.farmRuns
end

function FarmRuns.Discard(charData)
	if not charData.currentRun then
		return nil, "no_run"
	end
	charData.currentRun = nil
	return true
end

-- Marks the run as alive (bag events, logout), so a crash is cut at the last known moment.
function FarmRuns.Touch(run, now)
	run.lastSeenAt = now
end

-- At login: a running run continues after a /reload; after a longer gap it is paused at the
-- last sign of life, so the time offline does not count.
function FarmRuns.Recover(charData, now)
	local run = charData.currentRun
	if not FarmRuns.IsRunning(run) then
		return nil
	end
	if now - run.lastSeenAt <= FarmRuns.RELOAD_GRACE_SECONDS then
		return "continued"
	end
	closeSegment(run, run.lastSeenAt)
	run.resumeState = run.state
	run.state = "PAUSED"
	return "paused"
end
