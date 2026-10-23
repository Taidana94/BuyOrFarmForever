-- Price history of the auction house: the lowest unit buyout per item and day, for every item the
-- player's searches show (not only tracked ones), plus the last lowest listing with its units. The
-- base of the resale check (Core/FlipTasks.lua). Pure logic on db.priceHistory:
-- { [realmKey] = { [itemID] = { lows = { [day] = copper }, last, lastCount, lastAt, supply, supplyAt } } }.
-- supply: units listed in the last search (pages of one search summed), the market's stock.
local _, ns = ...

local PriceHistory = {}
ns.PriceHistory = PriceHistory

local SECONDS_PER_DAY = 86400
PriceHistory.KEEP_DAYS = 14
-- Items per realm; the ones seen longest ago are dropped first.
PriceHistory.MAX_ITEMS = 1500

function PriceHistory.Day(now)
	return math.floor(now / SECONDS_PER_DAY)
end

-- Adds one auction to `lows` = { [itemID] = { unit (lowest unit buyout), count (units at it),
-- units (all units) } }; auctions without buyout are skipped. Used per auction of a full scan.
function PriceHistory.AddLow(lows, itemID, count, buyout)
	if count <= 0 or buyout <= 0 then
		return
	end
	local unit = buyout / count
	local entry = lows[itemID]
	if not entry then
		entry = { unit = unit, count = 0, units = 0 }
		lows[itemID] = entry
	end
	entry.units = entry.units + count
	if unit < entry.unit then
		entry.unit, entry.count = unit, count
	elseif unit == entry.unit then
		entry.count = entry.count + count
	end
end

-- The lows of one page of auction results ({ { itemID, count, buyout } }).
function PriceHistory.Lows(results)
	local lows = {}
	for _, auction in ipairs(results) do
		PriceHistory.AddLow(lows, auction.itemID, auction.count, auction.buyout)
	end
	return lows
end

-- Units on the market: pages of one search (within the merge time) add up, a new search starts over.
local function recordSupply(item, units, now)
	local sameSearch = item.supplyAt and now - item.supplyAt <= ns.Prices.AUCTION_MERGE_SECONDS
	item.supply = (sameSearch and item.supply or 0) + units
	item.supplyAt = now
end

local function record(item, low, day, now)
	recordSupply(item, low.units, now)
	local merge = item.lastAt and PriceHistory.Day(item.lastAt) == day and now - item.lastAt <= ns.Prices.AUCTION_MERGE_SECONDS
	if merge and item.last < low.unit then
		return
	end
	if merge and item.last == low.unit then
		item.lastCount = math.max(item.lastCount, low.count)
	else
		item.last, item.lastCount = low.unit, low.count
	end
	item.lastAt = now
	item.lows[day] = math.min(item.lows[day] or low.unit, low.unit)
end

local EMPTY_ITEM = { lows = {} }

-- Stores the lows of one search (PriceHistory.Lows). Pages of one search are merged like
-- Prices.RecordAuction.
function PriceHistory.RecordLows(db, realmKey, lows, now)
	local realm = ns.Util.Ensure(db.priceHistory, realmKey, {})
	local day = PriceHistory.Day(now)
	for itemID, low in pairs(lows) do
		record(ns.Util.Ensure(realm, itemID, EMPTY_ITEM), low, day, now)
	end
end

-- Stores one page of auction results ({ { itemID, count, buyout } }).
function PriceHistory.Record(db, realmKey, results, now)
	PriceHistory.RecordLows(db, realmKey, PriceHistory.Lows(results), now)
end

-- Median of the daily lows before `day`, and the number of such days.
function PriceHistory.Reference(item, day)
	local values = {}
	for d, copper in pairs(item.lows) do
		if d < day then
			values[#values + 1] = copper
		end
	end
	if #values == 0 then
		return nil, 0
	end
	table.sort(values)
	local mid = math.floor((#values + 1) / 2)
	local median = #values % 2 == 1 and values[mid] or (values[mid] + values[mid + 1]) / 2
	return median, #values
end

local function pruneRealm(realm, oldestDay)
	local keys = {}
	for itemID, item in pairs(realm) do
		for d in pairs(item.lows) do
			if d < oldestDay then
				item.lows[d] = nil
			end
		end
		if next(item.lows) == nil then
			realm[itemID] = nil
		else
			keys[#keys + 1] = itemID
		end
	end
	table.sort(keys, function(a, b)
		return realm[a].lastAt > realm[b].lastAt
	end)
	for i = PriceHistory.MAX_ITEMS + 1, #keys do
		realm[keys[i]] = nil
	end
end

-- Drops days older than KEEP_DAYS and, per realm, the items over MAX_ITEMS seen longest ago.
function PriceHistory.Prune(db, now)
	local oldestDay = PriceHistory.Day(now) - PriceHistory.KEEP_DAYS
	for _, realm in pairs(db.priceHistory) do
		pruneRealm(realm, oldestDay)
	end
end

local function validItem(item)
	if type(item) ~= "table" or type(item.lows) ~= "table" or type(item.last) ~= "number"
		or type(item.lastCount) ~= "number" or type(item.lastAt) ~= "number" then
		return false
	end
	for d, copper in pairs(item.lows) do
		if type(d) ~= "number" or type(copper) ~= "number" or copper <= 0 then
			return false
		end
	end
	return true
end

local function sanitizeRealm(realmKey, realm, repairs)
	for itemID, item in pairs(realm) do
		if type(itemID) ~= "number" or not validItem(item) then
			realm[itemID] = nil
			repairs[#repairs + 1] = "priceHistory." .. tostring(realmKey)
		end
	end
end

-- Validation (registered with DB.ROOT_VALIDATORS): broken realms and items are dropped.
function PriceHistory.Sanitize(db, repairs)
	for realmKey, realm in pairs(db.priceHistory) do
		if type(realm) ~= "table" then
			db.priceHistory[realmKey] = nil
			repairs[#repairs + 1] = "priceHistory"
		else
			sanitizeRealm(realmKey, realm, repairs)
		end
	end
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = PriceHistory.Sanitize
