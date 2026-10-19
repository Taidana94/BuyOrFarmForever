-- SavedVariables: defaults, type validation, merge and migrations.
-- Schema description: docs/ARCHITECTURE.md. Pure logic, no WoW API calls.
local _, ns = ...

local Util = ns.Util

local DB = {}
ns.DB = DB

DB.SCHEMA_VERSION = 1

DB.DEFAULTS = {
	schemaVersion = 1,
	meta = {
		client = "",
		createdAt = 0,
		lastAddonVersion = "",
	},
	-- User settings with a schema entry (Core/Settings.lua) are added there.
	settings = {
		debug = false,
		strategy = "SAVE_TIME",
		farmEstimateScope = "CHARACTER",
		budgetCopper = 0, -- 0: plan with the character's current gold
		farmTimeLimitMinutes = 0, -- 0: no farm time limit in the sourcing plan
		window = {
			point = "CENTER",
			x = 0,
			y = 0,
			tab = "MATERIAL",
			allGoals = false,
		},
	},
	prices = {},
	recipes = {},
	farmRuns = {},
	characters = {},
	debugLog = {},
}

DB.CHARACTER_DEFAULTS = {
	faction = "",
	stock = {
		bags = {},
		bank = {},
		bagsAt = 0,
		bankAt = 0,
	},
	materialGoals = {},
	activeGoalID = 0,
	nextGoalID = 1,
	craftEval = {
		weights = { STR = 1, AGI = 1, STA = 1, INT = 1, SPI = 1, ARMOR = 0, DPS = 0 },
		alternatives = {},
	},
	savingsGoals = {},
	income = {},
	goldKeep = {}, -- { [itemID] = true }: never suggested for selling by the gold planner
	recipeBook = {}, -- { [recipeKey] = { cooldown = true?, readyAt? } }: recipes seen (Core/RecipeBook.lua)
}

-- Allowed values for enum-like fields, by path.
DB.ENUMS = {
	["settings.strategy"] = { SAVE_TIME = true, SAVE_GOLD = true, FARM_SELF = true },
	["settings.farmEstimateScope"] = { CHARACTER = true, ACCOUNT = true },
	["settings.window.tab"] = {
		MATERIAL = true, SOURCING = true, FARM = true, CRAFT = true, GOLD_BUFFER = true, SETTINGS = true, HELP = true,
	},
}

-- Minimum and maximum values for numeric fields, by path (filled by Core/Settings.lua).
DB.MIN = { ["settings.farmTimeLimitMinutes"] = 0 }
DB.MAX = { ["settings.farmTimeLimitMinutes"] = 1440 }

-- DB.MIGRATIONS[n](db) upgrades a database from schema n to n + 1 in place.
-- New fields with defaults need no migration: mergeDefaults adds them on load.
DB.MIGRATIONS = {}

-- Deeper checks of character data, registered by the modules that own the data:
-- fn(charData, path, repairs). They run after the defaults were merged.
DB.VALIDATORS = {}

-- Checks of account-wide data (e.g. recipes), registered by the owning modules:
-- fn(db, repairs). They run after the defaults were merged.
DB.ROOT_VALIDATORS = {}

-- Fills missing fields from defaults and replaces values of the wrong type or outside the
-- allowed values. Unknown fields are kept. Records the path of every replaced value.
local function mergeDefaults(target, defaults, path, repairs)
	for key, default in pairs(defaults) do
		local fullPath = path == "" and key or (path .. "." .. key)
		local value = target[key]
		local valid = value ~= nil and type(value) == type(default)
		if valid and DB.ENUMS[fullPath] then
			valid = DB.ENUMS[fullPath][value] == true
		end
		if valid and DB.MIN[fullPath] then
			valid = value >= DB.MIN[fullPath]
		end
		if valid and DB.MAX[fullPath] then
			valid = value <= DB.MAX[fullPath]
		end
		if not valid then
			if value ~= nil then
				repairs[#repairs + 1] = fullPath
			end
			target[key] = Util.CopyTable(default)
		elseif type(default) == "table" and next(default) ~= nil then
			mergeDefaults(value, default, fullPath, repairs)
		end
	end
end

local function validateCharacters(db, repairs)
	for key, data in pairs(db.characters) do
		if type(key) ~= "string" or type(data) ~= "table" then
			repairs[#repairs + 1] = "characters." .. tostring(key)
			db.characters[key] = nil
		else
			local path = "characters." .. key
			mergeDefaults(data, DB.CHARACTER_DEFAULTS, path, repairs)
			for _, validate in ipairs(DB.VALIDATORS) do
				validate(data, path, repairs)
			end
		end
	end
end

local function validateDebugLog(db, repairs)
	local clean = {}
	for _, entry in ipairs(db.debugLog) do
		if type(entry) == "table" and type(entry.msg) == "string" then
			clean[#clean + 1] = entry
		end
	end
	if #clean ~= #db.debugLog then
		repairs[#repairs + 1] = "debugLog"
	end
	-- Log.lua loads before DB.lua (TOC order), so the limit is always defined.
	while #clean > ns.Log.MAX_ENTRIES do
		table.remove(clean, 1)
	end
	db.debugLog = clean
end

-- Runs all migrations from fromVersion up to the current schema on a copy.
-- Returns true, migratedCopy or false, errorMessage. The input is never modified.
-- pcall is deliberate here: a failed migration must leave the stored data untouched.
function DB.Migrate(stored, fromVersion)
	local work = Util.CopyTable(stored)
	for n = fromVersion, DB.SCHEMA_VERSION - 1 do
		local step = DB.MIGRATIONS[n]
		if not step then
			return false, "no migration from schema " .. tostring(n)
		end
		local ok, err = pcall(step, work)
		if not ok then
			return false, "migration " .. n .. " -> " .. (n + 1) .. " failed: " .. tostring(err)
		end
		work.schemaVersion = n + 1
	end
	return true, work
end

-- Loads the stored SavedVariables value.
-- context = { client = "classic_era", now = <server time>, addonVersion = "0.1.0" }
-- Returns db, status, info.
--   status: "new" | "ok" | "migrated" | "newer" (stored schema is newer, data untouched)
--           | "migration_failed" (data untouched)
--   info: { repairs = { path, ... }, otherClient = <id or nil>, error = <message or nil> }
local function newDatabase(context)
	local db = Util.CopyTable(DB.DEFAULTS)
	db.schemaVersion = DB.SCHEMA_VERSION
	db.meta.client = context.client
	db.meta.createdAt = context.now or 0
	db.meta.lastAddonVersion = context.addonVersion or ""
	return db
end

-- Defaults, type checks and module validators on a database of the current schema.
local function validate(db, context, info)
	db.schemaVersion = DB.SCHEMA_VERSION
	mergeDefaults(db, DB.DEFAULTS, "", info.repairs)
	validateCharacters(db, info.repairs)
	for _, validateRoot in ipairs(DB.ROOT_VALIDATORS) do
		validateRoot(db, info.repairs)
	end
	validateDebugLog(db, info.repairs)
	if db.meta.client == "" then
		db.meta.client = context.client
	elseif db.meta.client ~= context.client then
		info.otherClient = db.meta.client
	end
	db.meta.lastAddonVersion = context.addonVersion or db.meta.lastAddonVersion
end

function DB.Load(stored, context)
	local info = { repairs = {} }
	if type(stored) ~= "table" then
		return newDatabase(context), "new", info
	end

	local version = stored.schemaVersion
	if type(version) ~= "number" then
		info.repairs[#info.repairs + 1] = "schemaVersion"
		version = DB.SCHEMA_VERSION
	end
	if version > DB.SCHEMA_VERSION then
		return stored, "newer", info
	end

	local db, status = stored, "ok"
	if version < DB.SCHEMA_VERSION then
		local ok, result = DB.Migrate(stored, version)
		if not ok then
			info.error = result
			return stored, "migration_failed", info
		end
		db, status = result, "migrated"
	end
	validate(db, context, info)
	return db, status, info
end

-- Returns the character table, creating it with defaults if needed.
function DB.EnsureCharacter(db, charKey, faction)
	local data = db.characters[charKey]
	if type(data) ~= "table" then
		data = Util.CopyTable(DB.CHARACTER_DEFAULTS)
		db.characters[charKey] = data
	end
	if type(faction) == "string" and faction ~= "" then
		data.faction = faction
	end
	return data
end

-- Resets all settings to their defaults. Goals, prices, recipes and measurements stay.
function DB.ResetSettings(db)
	db.settings = Util.CopyTable(DB.DEFAULTS.settings)
end
