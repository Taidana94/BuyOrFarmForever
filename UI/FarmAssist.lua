-- Farm run assistance that needs no player input: tells once when the run's target material
-- covers all goals (setting farmNotifyComplete). Listens to FARM_CHANGED, an internal signal that
-- the capture raises only while a run is running, so it costs nothing outside runs.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Events = ns.Events
local FarmRuns = ns.FarmRuns
local Materials = ns.Materials
local Stock = ns.Stock
local UIShared = ns.UIShared

local FarmAssist = {}
ns.FarmAssist = FarmAssist

local function writableCharacter()
	return ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
end

-- Missing amount of an item over all goals of the character, or nil if no goal needs it.
function FarmAssist.MissingForGoals(charData, itemID)
	for _, row in ipairs(Stock.Rows(charData, Materials.AllGoals(charData))) do
		if row.itemID == itemID then
			return row.missing
		end
	end
	return nil
end

local function checkTarget()
	local charData = writableCharacter()
	local run = charData and charData.currentRun
	if not (FarmRuns.IsRunning(run) and run.targetItemID > 0 and not run.targetNotified) then
		return
	end
	if not ns.db.settings.farmNotifyComplete then
		return
	end
	if FarmAssist.MissingForGoals(charData, run.targetItemID) == 0 then
		run.targetNotified = true
		Log.Print(Util.Format(L.FARM_TARGET_REACHED, UIShared.ItemText(run.targetItemID)))
	end
end

if ns.Client then
	Events.OnSignal("FARM_CHANGED", checkTarget)
end
