-- Localization: locale tables, active locale and the read-only lookup table ns.L.
-- Fallback chain: active locale -> base locale (deDE) -> the key itself.
-- The active locale is set from the client's language when the adapter registers and again from
-- the setting "language" once the saved variables are loaded (Locale.Resolve).
local _, ns = ...

local Locale = {}
ns.Locale = Locale

Locale.BASE = "deDE"

local tables = {}
local active = Locale.BASE

-- Keys that were looked up but are missing in every locale, for debug output later.
Locale.missing = {}

-- Returns the table a locale file fills with its strings.
function Locale.NewLocale(code)
	local t = tables[code]
	if not t then
		t = {}
		tables[code] = t
	end
	return t
end

-- Selects the locale for lookups. Unknown locales fall back to the base locale.
function Locale.SetActive(code)
	if type(code) == "string" and tables[code] then
		active = code
	else
		active = Locale.BASE
	end
	return active
end

-- The locale for a choice of the setting "language": a German client gets German, every other
-- client English, unless the player picked one.
function Locale.Resolve(choice, clientLocale)
	if choice == "deDE" or choice == "enUS" then
		return choice
	end
	return clientLocale == "deDE" and "deDE" or "enUS"
end

function Locale.GetActive()
	return active
end

local function lookup(_, key)
	local current = tables[active]
	local value = current and current[key]
	if value == nil and active ~= Locale.BASE then
		local base = tables[Locale.BASE]
		value = base and base[key]
	end
	if value == nil then
		Locale.missing[key] = true
		return tostring(key)
	end
	return value
end

ns.L = setmetatable({}, {
	__index = lookup,
	__newindex = function()
		error("ns.L is read-only; add strings to Locales/<code>.lua", 2)
	end,
})
