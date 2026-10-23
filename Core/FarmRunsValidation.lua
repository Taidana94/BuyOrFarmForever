-- Validation of stored farm runs (db.farmRuns, registered with DB.ROOT_VALIDATORS) and of the
-- current run of a character (registered with DB.VALIDATORS). Runs on load. Pure logic.
local _, ns = ...

local FarmRuns = ns.FarmRuns

local STATES = { FARM = true, TRAVEL = true, PAUSED = true, REVIEW = true }
local TIME_FIELDS = { "activeSeconds", "travelSeconds", "startedAt", "endedAt" }
local RUN_TIME_FIELDS = { "activeSeconds", "travelSeconds", "startedAt", "segmentStart", "lastSeenAt", "endedAt" }

local function isCount(value)
	return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function hasNumbers(record, fields)
	for _, field in ipairs(fields) do
		if type(record[field]) ~= "number" or record[field] < 0 then
			return false
		end
	end
	return true
end

-- Saved run items: { [itemID] = confirmed count }.
local function validSavedItems(items)
	if type(items) ~= "table" then
		return false
	end
	for itemID, count in pairs(items) do
		if not (ns.Materials.IsValidItemID(itemID) and isCount(count)) then
			return false
		end
	end
	return true
end

local function validSavedRun(run)
	return type(run) == "table" and type(run.charKey) == "string" and FarmRuns.ACTIVITIES[run.activity] == true
		and isCount(run.targetItemID) and isCount(run.uiMapID) and hasNumbers(run, TIME_FIELDS)
		and validSavedItems(run.items)
end

-- Optional lootCopper (0.6.0): a wrong value is dropped, the run is kept.
local function keepRun(clean, run, repairs)
	if run.lootCopper ~= nil and not isCount(run.lootCopper) then
		run.lootCopper = nil
		repairs[#repairs + 1] = "farmRuns.lootCopper"
	end
	clean[#clean + 1] = run
end

function FarmRuns.SanitizeSaved(db, repairs)
	local clean = {}
	for _, run in ipairs(db.farmRuns) do
		if validSavedRun(run) then
			keepRun(clean, run, repairs)
		end
	end
	if #clean ~= #db.farmRuns then
		repairs[#repairs + 1] = "farmRuns"
	end
	while #clean > FarmRuns.MAX_RUNS do
		table.remove(clean, 1)
	end
	db.farmRuns = clean
end

-- Current run items: { [itemID] = { confirmed, unclear } }.
local function validRunItems(items)
	if type(items) ~= "table" then
		return false
	end
	for itemID, entry in pairs(items) do
		local ok = ns.Materials.IsValidItemID(itemID) and type(entry) == "table" and isCount(entry.confirmed)
			and isCount(entry.unclear)
		if not ok then
			return false
		end
	end
	return true
end

local function validCurrentRun(run)
	return type(run) == "table" and STATES[run.state] == true and FarmRuns.ACTIVITIES[run.activity] == true
		and isCount(run.targetItemID) and isCount(run.uiMapID) and hasNumbers(run, RUN_TIME_FIELDS)
		and validRunItems(run.items) and (run.resumeState == nil or STATES[run.resumeState] == true)
end

-- Optional fields of a current run (older runs have none): field -> check. Wrong values are dropped.
local OPTIONAL_RUN_FIELDS = {
	idleSeconds = isCount,
	lastActivityAt = isCount,
	lootCopper = isCount,
	loots = isCount,
	fishingLoots = isCount,
	targetNotified = function(value)
		return type(value) == "boolean"
	end,
	autoPaused = function(value)
		return type(value) == "boolean"
	end,
	autoTravel = function(value)
		return type(value) == "boolean"
	end,
}

local function dropInvalidOptionals(run, path, repairs)
	for field, check in pairs(OPTIONAL_RUN_FIELDS) do
		if run[field] ~= nil and not check(run[field]) then
			run[field] = nil
			repairs[#repairs + 1] = path .. ".currentRun." .. field
		end
	end
end

function FarmRuns.SanitizeCurrent(charData, path, repairs)
	if charData.currentRun == nil then
		return
	end
	if not validCurrentRun(charData.currentRun) then
		charData.currentRun = nil
		repairs[#repairs + 1] = path .. ".currentRun"
		return
	end
	dropInvalidOptionals(charData.currentRun, path, repairs)
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = FarmRuns.SanitizeSaved
ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = FarmRuns.SanitizeCurrent
