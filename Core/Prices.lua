-- Unit prices per realm and faction, one record per source (entered by hand, seen at a merchant,
-- seen in the auction house), each with its time. Stored in db.prices:
--   prices["<NormalizedRealm>-<Alliance|Horde>"][itemID] = { MANUAL = { copper, at }, MERCHANT = ..., AUCTION = ... }
-- Pure logic on plain tables; the event wiring is in Core/PriceCapture.lua.
local _, ns = ...

local Prices = {}
ns.Prices = Prices

Prices.SOURCES = { MANUAL = true, MERCHANT = true, AUCTION = true }
-- Order for display and for equal prices.
Prices.SOURCE_ORDER = { "MERCHANT", "AUCTION", "MANUAL" }
-- Auction results of one search come page by page; within this window they are merged (minimum).
Prices.AUCTION_MERGE_SECONDS = 600
local SECONDS_PER_DAY = 86400

local function isValidCopper(copper)
	return type(copper) == "number" and copper >= 0 and copper <= ns.Money.MAX_COPPER
end

-- "RealmA-Alliance" from the character key and faction, or nil.
function Prices.RealmKey(charKey, faction)
	local _, realm = ns.Stock.SplitKey(charKey)
	if not (realm and (faction == "Alliance" or faction == "Horde")) then
		return nil
	end
	return realm .. "-" .. faction
end

local function itemPrices(db, realmKey, itemID, create)
	local realm = db.prices[realmKey]
	if not realm then
		if not create then
			return nil
		end
		realm = {}
		db.prices[realmKey] = realm
	end
	local item = realm[itemID]
	if not item and create then
		item = {}
		realm[itemID] = item
	end
	return item
end

-- Stores a unit price. Returns true, or nil plus "invalid_item" | "invalid_money".
function Prices.Set(db, realmKey, itemID, source, copper, now)
	if not ns.Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if not (Prices.SOURCES[source] and isValidCopper(copper)) then
		return nil, "invalid_money"
	end
	itemPrices(db, realmKey, itemID, true)[source] = { copper = copper, at = now or 0 }
	return true
end

-- Removes the price of one source. Returns true if there was one.
function Prices.Clear(db, realmKey, itemID, source)
	local item = itemPrices(db, realmKey, itemID, false)
	if not (item and item[source]) then
		return false
	end
	item[source] = nil
	if next(item) == nil then
		db.prices[realmKey][itemID] = nil
	end
	return true
end

-- Records of all sources for an item: { MANUAL = { copper, at }, ... } or nil.
function Prices.Get(db, realmKey, itemID)
	return itemPrices(db, realmKey, itemID, false)
end

-- Merchant prices are fixed, so they never become outdated.
function Prices.IsOutdated(source, record, now, maxAgeDays)
	if source == "MERCHANT" then
		return false
	end
	return now - record.at > maxAgeDays * SECONDS_PER_DAY
end

-- The price to plan with: the cheapest current price; if all are outdated, the newest one.
-- Returns copper, source, at, isOutdated, or nil if there is no price.
function Prices.Best(db, realmKey, itemID, now, maxAgeDays)
	local item = itemPrices(db, realmKey, itemID, false)
	if not item then
		return nil
	end
	local best, bestSource, newest, newestSource
	for _, source in ipairs(Prices.SOURCE_ORDER) do
		local record = item[source]
		local current = record and not Prices.IsOutdated(source, record, now, maxAgeDays)
		if current and (not best or record.copper < best.copper) then
			best, bestSource = record, source
		elseif record and not current and (not newest or record.at > newest.at) then
			newest, newestSource = record, source
		end
	end
	if best then
		return best.copper, bestSource, best.at, false
	end
	if newest then
		return newest.copper, newestSource, newest.at, true
	end
	return nil
end

-- Merchant offers { { itemID, copper (per unit) } }: stores the tracked items.
function Prices.RecordMerchant(db, realmKey, offers, tracked, now)
	for _, offer in ipairs(offers) do
		if tracked[offer.itemID] then
			Prices.Set(db, realmKey, offer.itemID, "MERCHANT", offer.copper, now)
		end
	end
end

-- Lowest unit buyout per tracked item in one page of auction results
-- ({ { itemID, count, buyout } }; auctions without buyout are skipped).
local function lowestUnitPrices(results, tracked)
	local lowest = {}
	for _, auction in ipairs(results) do
		local ok = tracked[auction.itemID] and auction.count > 0 and auction.buyout > 0
		local unit = ok and auction.buyout / auction.count
		if unit and (not lowest[auction.itemID] or unit < lowest[auction.itemID]) then
			lowest[auction.itemID] = unit
		end
	end
	return lowest
end

-- Stores the lowest unit buyout per tracked item. Pages of the same search (within
-- AUCTION_MERGE_SECONDS) are merged by keeping the minimum.
function Prices.RecordAuction(db, realmKey, results, tracked, now)
	for itemID, unit in pairs(lowestUnitPrices(results, tracked)) do
		local item = itemPrices(db, realmKey, itemID, false)
		local previous = item and item.AUCTION
		local recent = previous and now - previous.at <= Prices.AUCTION_MERGE_SECONDS
		if not (recent and previous.copper <= unit) then
			Prices.Set(db, realmKey, itemID, "AUCTION", unit, now)
		end
	end
end

-- Removes captured prices (merchant, auction house) older than keepDays; own prices stay, the
-- player typed them. keepDays 0 keeps everything. Returns the number of removed prices.
local function pruneItem(item, limit)
	local removed = 0
	for source, record in pairs(item) do
		if source ~= "MANUAL" and record.at < limit then
			item[source] = nil
			removed = removed + 1
		end
	end
	return removed
end

function Prices.Prune(db, now, keepDays)
	if keepDays <= 0 then
		return 0
	end
	local limit, removed = now - keepDays * SECONDS_PER_DAY, 0
	for realmKey, realm in pairs(db.prices) do
		for itemID, item in pairs(realm) do
			removed = removed + pruneItem(item, limit)
			if next(item) == nil then
				realm[itemID] = nil
			end
		end
		if next(realm) == nil then
			db.prices[realmKey] = nil
		end
	end
	return removed
end

-- Validation of stored prices (registered with DB.ROOT_VALIDATORS).
local function sanitizeItem(item)
	local changed = false
	for source, record in pairs(item) do
		local ok = Prices.SOURCES[source] and type(record) == "table" and isValidCopper(record.copper)
			and type(record.at) == "number"
		if not ok then
			item[source] = nil
			changed = true
		end
	end
	return changed
end

local function sanitizeRealm(realmKey, realm, repairs)
	for itemID, item in pairs(realm) do
		local bad = not ns.Materials.IsValidItemID(itemID) or type(item) ~= "table"
		if bad or sanitizeItem(item) then
			repairs[#repairs + 1] = "prices." .. realmKey .. "." .. tostring(itemID)
		end
		if bad or next(item) == nil then
			realm[itemID] = nil
		end
	end
end

function Prices.Sanitize(db, repairs)
	for realmKey, realm in pairs(db.prices) do
		if type(realmKey) ~= "string" or type(realm) ~= "table" then
			db.prices[realmKey] = nil
			repairs[#repairs + 1] = "prices." .. tostring(realmKey)
		else
			sanitizeRealm(realmKey, realm, repairs)
		end
	end
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = Prices.Sanitize
