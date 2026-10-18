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
