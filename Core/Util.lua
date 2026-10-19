-- Pure helpers without WoW API calls.
local _, ns = ...

local Util = {}
ns.Util = Util

-- Deep copy of plain data (tables, strings, numbers, booleans).
function Util.CopyTable(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[Util.CopyTable(k)] = Util.CopyTable(v)
	end
	return copy
end

function Util.Trim(text)
	local result = text:gsub("^%s+", "")
	result = result:gsub("%s+$", "")
	return result
end

-- Reads an item from user input. Accepts an item link (shift-click), "item:123" or a plain
-- item id. Returns itemID (number) and the remaining text, or nil if no item was found.
function Util.ParseItemArg(text)
	text = Util.Trim(text or "")
	local id, rest = text:match("^|c[^|]*|Hitem:(%d+)[^|]*|h.-|h|r%s*(.*)$")
	if not id then
		id, rest = text:match("^|Hitem:(%d+)[^|]*|h.-|h%s*(.*)$")
	end
	if not id then
		id, rest = text:match("^item:(%d+)%S*%s*(.*)$")
	end
	if not id then
		id, rest = text:match("^(%d+)%s*(.*)$")
	end
	if not id then
		return nil, text
	end
	return tonumber(id), rest
end

-- Type and id of a client hyperlink ("|Hitem:2589:...|h", "|Henchant:7418|h"), or nil.
function Util.ParseLink(link)
	if type(link) ~= "string" then
		return nil
	end
	local linkType, id = link:match("|H(%a+):(%d+)")
	if not linkType then
		return nil
	end
	return linkType, tonumber(id)
end

local HALF = 0.5

-- Nearest whole number (halves round up).
function Util.Round(value)
	return math.floor(value + HALF)
end

-- Number with a fixed count of decimals and the locale's decimal separator ("1,25").
function Util.FormatDecimal(value, decimals)
	local text = string.format("%." .. decimals .. "f", value)
	return (text:gsub("%.", ns.L.DECIMAL_SEPARATOR))
end

-- Reads a whole number from user input, or nil.
function Util.ParseInteger(text)
	local n = tonumber(text)
	if n and n == math.floor(n) then
		return n
	end
	return nil
end

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400

-- "unter 1 Min.", "25 Min.", "1 Std. 10 Min." for a duration in seconds (localized, rounded).
function Util.FormatDuration(seconds)
	local L = ns.L
	local minutes = Util.Round(math.max(0, seconds or 0) / SECONDS_PER_MINUTE)
	if minutes < 1 then
		return L.DURATION_UNDER_MINUTE
	end
	local hours = math.floor(minutes * SECONDS_PER_MINUTE / SECONDS_PER_HOUR)
	minutes = minutes - hours * SECONDS_PER_HOUR / SECONDS_PER_MINUTE
	if hours == 0 then
		return Util.Format(L.DURATION_MINUTES, minutes)
	elseif minutes == 0 then
		return Util.Format(L.DURATION_HOURS, hours)
	end
	return Util.Format(L.DURATION_HOURS_MINUTES, hours, minutes)
end

-- Upper limit for entered durations (no plan needs more than this).
Util.MAX_DURATION_SECONDS = 1000 * SECONDS_PER_HOUR

-- Parses durations like "1h 30m", "45m", "2h" (each unit once, unit letters from the locale).
-- Returns seconds, or nil plus "invalid_duration" (plain numbers are ambiguous and rejected).
function Util.ParseDuration(text)
	local L = ns.L
	local units = {
		[string.lower(L.DURATION_HOUR_LETTER)] = SECONDS_PER_HOUR,
		[string.lower(L.DURATION_MINUTE_LETTER)] = SECONDS_PER_MINUTE,
	}
	local seen, total = {}, 0
	local rest = string.lower(Util.Trim(text)):gsub("(%d+)%s*(%a)", function(amount, unit)
		if not units[unit] or seen[unit] then
			return nil
		end
		seen[unit] = true
		total = total + tonumber(amount) * units[unit]
		return ""
	end)
	if rest:match("%S") or next(seen) == nil or total > Util.MAX_DURATION_SECONDS then
		return nil, "invalid_duration"
	end
	return total
end

-- "vor 5 Min." etc. for a duration in seconds (localized).
function Util.FormatAge(seconds)
	local L = ns.L
	seconds = math.max(0, seconds or 0)
	if seconds < SECONDS_PER_MINUTE then
		return L.AGE_NOW
	elseif seconds < SECONDS_PER_HOUR then
		return Util.Format(L.AGE_MINUTES, math.floor(seconds / SECONDS_PER_MINUTE))
	elseif seconds < SECONDS_PER_DAY then
		return Util.Format(L.AGE_HOURS, math.floor(seconds / SECONDS_PER_HOUR))
	end
	local days = math.floor(seconds / SECONDS_PER_DAY)
	if days == 1 then
		return L.AGE_DAY
	end
	return Util.Format(L.AGE_DAYS, days)
end

-- Fills a localized template. Supports "%s"/"%d" in order and "%1$s"/"%2$d" by position,
-- so translations can reorder arguments. "%%" is a literal percent sign.
-- A placeholder without a matching argument is left as it is.
function Util.Format(template, ...)
	local args = { ... }
	local count = select("#", ...)
	local nextArg = 0

	local function value(index, kind)
		if index < 1 or index > count then
			return nil
		end
		local v = args[index]
		if kind == "d" then
			local n = tonumber(v)
			if n then
				return string.format("%d", n)
			end
		end
		return tostring(v)
	end

	local result = template:gsub("%%(%d*)(%$?)([sd%%])", function(position, dollar, kind)
		if kind == "%" then
			if position == "" and dollar == "" then
				return "%"
			end
			return nil
		end
		if position ~= "" then
			if dollar == "" then
				return nil
			end
			return value(tonumber(position), kind)
		end
		nextArg = nextArg + 1
		return value(nextArg, kind)
	end)
	return result
end
