-- Unit prices per realm and faction, one record per source (entered by hand, seen at a merchant,
-- seen in the auction house), each with its time. Stored in db.prices:
--   prices["<NormalizedRealm>-<Alliance|Horde>"][itemID] = { MANUAL = { copper, at }, MERCHANT = ..., AUCTION = ... }
-- Pure logic on plain tables; the event wiring is in Core/PriceCapture.lua.
local _, ns = ...

local Prices = {}
ns.Prices = Prices

Prices.SOURCES = { MANUAL = true, MERCHANT = true, AUCTION = true }
-- Sources read live from other addons (never stored): "AUCTIONATOR".
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

local function findItem(db, realmKey, itemID)
	local realm = db.prices[realmKey]
	return realm and realm[itemID]
end

local function ensureItem(db, realmKey, itemID)
	return ns.Util.Ensure(ns.Util.Ensure(db.prices, realmKey, {}), itemID, {})
end

-- Stores a unit price. Returns true, or nil plus "invalid_item" | "invalid_money".
function Prices.Set(db, realmKey, itemID, source, copper, now)
	if not ns.Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if not (Prices.SOURCES[source] and isValidCopper(copper)) then
		return nil, "invalid_money"
	end
	ensureItem(db, realmKey, itemID)[source] = { copper = copper, at = now or 0 }
	return true
end

-- Removes the price of one source. Returns true if there was one.
function Prices.Clear(db, realmKey, itemID, source)
	local item = findItem(db, realmKey, itemID)
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
	return findItem(db, realmKey, itemID)
end

-- Merchant prices are fixed, so they never become outdated.
function Prices.IsOutdated(source, record, now, maxAgeDays)
	if source == "MERCHANT" then
		return false
	end
	return now - record.at > maxAgeDays * SECONDS_PER_DAY
end

-- Keeps the cheapest current and the newest outdated record seen so far in `pick`.
local function consider(pick, source, record, now, maxAgeDays)
	if not record then
		return
	end
	if not Prices.IsOutdated(source, record, now, maxAgeDays) then
		if not pick.best or record.copper < pick.best.copper then
			pick.best, pick.bestSource = record, source
		end
	elseif not pick.newest or record.at > pick.newest.at then
		pick.newest, pick.newestSource = record, source
	end
end

-- The price to plan with: the cheapest current price; if all are outdated, the newest one.
-- `external` (optional) adds live records of other addons: { [source] = { copper, at } }.
-- Returns copper, source, at, isOutdated, or nil if there is no price.
function Prices.Best(db, realmKey, itemID, now, maxAgeDays, external)
	local item = findItem(db, realmKey, itemID) or {}
	local pick = {}
	for _, source in ipairs(Prices.SOURCE_ORDER) do
		consider(pick, source, item[source], now, maxAgeDays)
	end
	for source, record in pairs(external or {}) do
		consider(pick, source, record, now, maxAgeDays)
	end
	local best, bestSource, newest, newestSource = pick.best, pick.bestSource, pick.newest, pick.newestSource
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

-- Stores the lowest unit buyout per tracked item from the lows of a search (PriceHistory.Lows).
-- Pages of the same search (within AUCTION_MERGE_SECONDS) are merged by keeping the minimum.
function Prices.RecordAuction(db, realmKey, lows, tracked, now)
	for itemID, low in pairs(lows) do
		local item = tracked[itemID] and findItem(db, realmKey, itemID)
		local previous = item and item.AUCTION
		local recent = previous and now - previous.at <= Prices.AUCTION_MERGE_SECONDS
		if tracked[itemID] and not (recent and previous.copper <= low.unit) then
			Prices.Set(db, realmKey, itemID, "AUCTION", low.unit, now)
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
