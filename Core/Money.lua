-- Money amounts in copper: parsing user input ("1g 20s 5k") and formatting for display.
-- Pure logic; unit letters come from the locale (L.MONEY_*), so translations can change them.
local _, ns = ...

local Money = {}
ns.Money = Money

Money.COPPER_PER_SILVER = 100
Money.COPPER_PER_GOLD = 10000
-- Upper limit for entered amounts (well above the Classic Era gold cap of 214748 g).
Money.MAX_COPPER = 10000000000

local function lower(text)
	return string.lower(text or "")
end

-- Copper value of one unit letter, from the locale ("g", "s", "k") plus "c" for copper.
local function unitValues()
	local L = ns.L
	return {
		[lower(L.MONEY_GOLD_LETTER)] = Money.COPPER_PER_GOLD,
		[lower(L.MONEY_SILVER_LETTER)] = Money.COPPER_PER_SILVER,
		[lower(L.MONEY_COPPER_LETTER)] = 1,
		c = 1,
	}
end

-- Parses amounts like "1g 20s 5k", "20s", "3g50s" (each unit once, any order, spaces optional).
-- Returns copper, or nil plus "invalid_money" (plain numbers without unit are rejected because
-- they are ambiguous).
function Money.Parse(text)
	text = lower(ns.Util.Trim(text))
	if text == "" then
		return nil, "invalid_money"
	end
	local values, seen, total = unitValues(), {}, 0
	local rest = text:gsub("(%d+)%s*(%a)", function(amount, unit)
		local value = values[unit]
		if not value or seen[unit] then
			return nil
		end
		seen[unit] = true
		total = total + tonumber(amount) * value
		return ""
	end)
	if rest:match("%S") or next(seen) == nil or total > Money.MAX_COPPER then
		return nil, "invalid_money"
	end
	return total
end

-- "1g 20s 5k"; zero parts are left out, 0 is shown as "0k".
function Money.Format(copper)
	local L = ns.L
	copper = ns.Util.Round(math.max(0, copper or 0))
	local gold = math.floor(copper / Money.COPPER_PER_GOLD)
	local silver = math.floor((copper % Money.COPPER_PER_GOLD) / Money.COPPER_PER_SILVER)
	local rest = copper % Money.COPPER_PER_SILVER
	local parts = {}
	if gold > 0 then
		parts[#parts + 1] = gold .. L.MONEY_GOLD_LETTER
	end
	if silver > 0 then
		parts[#parts + 1] = silver .. L.MONEY_SILVER_LETTER
	end
	if rest > 0 or #parts == 0 then
		parts[#parts + 1] = rest .. L.MONEY_COPPER_LETTER
	end
	return table.concat(parts, " ")
end
