-- Yield capture of the running farm run: compares the carried bags after every bag update with
-- the previous state. A gain is confirmed (looted) if a loot window is open or was closed at most
-- LOOT_GRACE_SECONDS ago (autoloot and gathering also use the loot window); other gains (mail,
-- trade, bank, purchases) are unclear and can be kept or dropped when the run is reviewed.
-- Language-independent: no chat messages are parsed.
-- The bag, loot and logout signals are registered only while a run is running.
local _, ns = ...

local Events = ns.Events
local FarmRuns = ns.FarmRuns

local FarmCapture = {}
ns.FarmCapture = FarmCapture

FarmCapture.LOOT_GRACE_SECONDS = 2

local active = false
local lootOpen = false
local lootClosedAt -- client uptime
-- Two reused count tables: baseline is one of them (or nil), each scan fills the other.
local tableA, tableB = {}, {}
local baseline

local function freeTable()
	return baseline == tableA and tableB or tableA
end

local function currentRun()
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	return charData and charData.currentRun
end

local function isLootGain()
	if lootOpen then
		return true
	end
	return lootClosedAt ~= nil and ns.Client:GetUptime() - lootClosedAt <= FarmCapture.LOOT_GRACE_SECONDS
end

-- First scan after activation only sets the baseline (bag data may have been loading).
local function onBagsChanged()
	local run = currentRun()
	if not FarmRuns.IsRunning(run) then
		return
	end
	local now = ns.Client:GetServerTime()
	local counts = ns.Client:ScanBags(freeTable())
	if baseline then
		local isLoot = isLootGain()
		for itemID, count in pairs(counts) do
			local gain = count - (baseline[itemID] or 0)
			if gain > 0 then
				FarmRuns.AddGain(run, itemID, gain, isLoot, now)
			end
		end
	end
	FarmRuns.Touch(run, now)
	baseline = counts
	Events.Emit("FARM_CHANGED")
end

local function onLootOpened()
	lootOpen = true
end

local function onLootClosed()
	lootOpen = false
	lootClosedAt = ns.Client:GetUptime()
end

local function onLogout()
	local run = currentRun()
	if FarmRuns.IsRunning(run) then
		FarmRuns.Touch(run, ns.Client:GetServerTime())
	end
end

local HANDLERS = {
	BAGS_CHANGED = onBagsChanged,
	LOOT_OPENED = onLootOpened,
	LOOT_CLOSED = onLootClosed,
	LOGOUT = onLogout,
}

-- Starts capturing. takeBaselineNow = true when the bags are known to be loaded (a command);
-- false right after login, where the first bag update provides the baseline.
function FarmCapture.Activate(takeBaselineNow)
	if not active then
		active = true
		for signal, handler in pairs(HANDLERS) do
			Events.OnSignal(signal, handler)
		end
	end
	baseline = nil
	if takeBaselineNow then
		baseline = ns.Client:ScanBags(tableA)
	end
end

function FarmCapture.Deactivate()
	if not active then
		return
	end
	active = false
	for signal, handler in pairs(HANDLERS) do
		Events.OffSignal(signal, handler)
	end
	baseline = nil
	lootOpen = false
end

function FarmCapture.IsActive()
	return active
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", function()
		local charData = ns.db.characters[ns.charKey]
		if FarmRuns.Recover(charData, ns.Client:GetServerTime()) == "continued" then
			FarmCapture.Activate(false)
		end
	end)
end
