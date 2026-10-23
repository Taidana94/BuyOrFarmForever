-- Settings schema: one entry per user setting with type, default, range, group and label key.
-- The schema adds its defaults and ranges to DB.DEFAULTS.settings / DB.MIN / DB.MAX (so loading
-- validates them), drives the settings tab and /bof set. Account-wide, one profile (db.settings).
-- Pure logic, no WoW API calls. Loaded right after Core/DB.lua.
local _, ns = ...

local DB = ns.DB

local Settings = {}
ns.Settings = Settings

-- Groups in display order (label keys in the locale).
Settings.GROUPS = {
	{ key = "FARM", label = "SET_GROUP_FARM" },
	{ key = "MATERIAL", label = "SET_GROUP_MATERIAL" },
	{ key = "GOLD", label = "SET_GROUP_GOLD" },
	{ key = "DISPLAY", label = "SET_GROUP_DISPLAY" },
	-- Shown in the advisor window, not in the settings tab (no room left there).
	{ key = "ADVISOR", label = "SET_GROUP_ADVISOR" },
}

-- type "boolean" or "number" (whole numbers in [min, max]).
Settings.SCHEMA = {
	{ key = "farmIdleMinutes", type = "number", default = 5, min = 0, max = 60, group = "FARM", label = "SET_FARM_IDLE" },
	{ key = "farmAutoPauseAfk", type = "boolean", default = true, group = "FARM", label = "SET_FARM_PAUSE_AFK" },
	{ key = "farmAutoPauseResting", type = "boolean", default = true, group = "FARM", label = "SET_FARM_PAUSE_RESTING" },
	{ key = "farmAutoTravelTaxi", type = "boolean", default = true, group = "FARM", label = "SET_FARM_TAXI" },
	{ key = "farmAutoStart", type = "boolean", default = true, group = "FARM", label = "SET_FARM_AUTO_START" },
	{ key = "farmSuggestStart", type = "boolean", default = true, group = "FARM", label = "SET_FARM_SUGGEST" },
	{ key = "farmNotifyComplete", type = "boolean", default = true, group = "FARM", label = "SET_FARM_COMPLETE" },
	{ key = "countOtherCharacters", type = "boolean", default = true, group = "MATERIAL", label = "SET_COUNT_OTHERS" },
	{ key = "priceMaxAgeDays", type = "number", default = 7, min = 1, max = 60, group = "MATERIAL", label = "SET_PRICE_AGE" },
	{ key = "useAuctionator", type = "boolean", default = true, group = "MATERIAL", label = "SET_USE_AUCTIONATOR" },
	{ key = "priceKeepDays", type = "number", default = 60, min = 0, max = 365, group = "MATERIAL", label = "SET_PRICE_KEEP" },
	-- What one hour of farming is worth when choosing the cheapest way (Core/WantPlan.lua); 0 = the gold per
	-- hour of the best measured farm route.
	{ key = "hourValueGold", type = "number", default = 0, min = 0, max = 10000, group = "GOLD", label = "SET_HOUR_VALUE" },
	{ key = "goldAutoDistribute", type = "boolean", default = false, group = "GOLD", label = "SET_AUTO_DISTRIBUTE" },
	{ key = "goldMerchantHint", type = "boolean", default = true, group = "GOLD", label = "SET_MERCHANT_HINT" },
	{ key = "ahDiscountPercent", type = "number", default = 25, min = 0, max = 100, group = "GOLD", label = "SET_AH_DISCOUNT" },
	{ key = "goldReserveWarning", type = "boolean", default = true, group = "GOLD", label = "SET_RESERVE_WARNING" },
	{ key = "tooltipEnabled", type = "boolean", default = true, group = "DISPLAY", label = "SET_TOOLTIP" },
	{ key = "auctionHint", type = "boolean", default = true, group = "DISPLAY", label = "SET_AUCTION_HINT" },
	{ key = "tooltipRecipes", type = "boolean", default = true, group = "DISPLAY", label = "SET_TOOLTIP_RECIPES" },
	{ key = "tooltipReagents", type = "boolean", default = true, group = "DISPLAY", label = "SET_TOOLTIP_REAGENTS" },
	{ key = "minimapButton", type = "boolean", default = true, group = "DISPLAY", label = "SET_MINIMAP" },
	{ key = "minimapAngle", type = "number", default = 225, min = 0, max = 359, group = "DISPLAY", label = "SET_MINIMAP_ANGLE" },
	{ key = "loginSummary", type = "boolean", default = true, group = "DISPLAY", label = "SET_LOGIN_SUMMARY" },
	{ key = "advisorCards", type = "boolean", default = true, group = "ADVISOR", label = "SET_ADVISOR_CARDS" },
	{ key = "advisorAtLogin", type = "boolean", default = true, group = "ADVISOR", label = "SET_ADVISOR_AT_LOGIN" },
}

local byKey = {}
for _, entry in ipairs(Settings.SCHEMA) do
	byKey[entry.key] = entry
	DB.DEFAULTS.settings[entry.key] = entry.default
	if entry.type == "number" then
		DB.MIN["settings." .. entry.key] = entry.min
		DB.MAX["settings." .. entry.key] = entry.max
	end
end

-- The schema entry of a setting key (case-insensitive), or nil.
function Settings.Find(key)
	if type(key) ~= "string" then
		return nil
	end
	local lower = string.lower(key)
	for _, entry in ipairs(Settings.SCHEMA) do
		if string.lower(entry.key) == lower then
			return entry
		end
	end
	return nil
end

-- Entries of one group in schema order.
function Settings.InGroup(group)
	local list = {}
	for _, entry in ipairs(Settings.SCHEMA) do
		if entry.group == group then
			list[#list + 1] = entry
		end
	end
	return list
end

local function isValid(entry, value)
	if entry.type == "boolean" then
		return type(value) == "boolean"
	end
	return type(value) == "number" and value == math.floor(value) and value >= entry.min and value <= entry.max
end

-- Stores a setting. Returns true, or nil plus "unknown_setting" | "invalid_value".
function Settings.Set(settings, key, value)
	local entry = byKey[key]
	if not entry then
		return nil, "unknown_setting"
	end
	if not isValid(entry, value) then
		return nil, "invalid_value"
	end
	settings[key] = value
	return true
end

local BOOLEAN_WORDS = { on = true, an = true, ja = true, ["1"] = true, off = false, aus = false, nein = false, ["0"] = false }

-- Reads user text for a setting: on/off words for booleans, whole numbers for numbers.
-- Returns the value or nil.
function Settings.ParseValue(entry, text)
	text = string.lower(ns.Util.Trim(text or ""))
	if entry.type == "boolean" then
		return BOOLEAN_WORDS[text]
	end
	return ns.Util.ParseInteger(text)
end
