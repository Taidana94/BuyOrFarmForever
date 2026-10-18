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

-- Reads a whole number from user input, or nil.
function Util.ParseInteger(text)
	local n = tonumber(text)
	if n and n == math.floor(n) then
		return n
	end
	return nil
end

-- "vor 5 Min." etc. for a duration in seconds (localized).
function Util.FormatAge(seconds)
	local L = ns.L
	seconds = math.max(0, seconds or 0)
	if seconds < 60 then
		return L.AGE_NOW
	elseif seconds < 3600 then
		return Util.Format(L.AGE_MINUTES, math.floor(seconds / 60))
	elseif seconds < 86400 then
		return Util.Format(L.AGE_HOURS, math.floor(seconds / 3600))
	end
	local days = math.floor(seconds / 86400)
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
