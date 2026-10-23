-- Market watch: sales of all players on the realm, estimated by comparing full auction house scans.
-- Blizzard's Classic API has no sales history, so between two full scans every auction of a watched
-- item that is gone although its time left could not have run out yet counts as sold (a seller who
-- cancelled looks the same, so this is an upper estimate); one that may have run out counts as
-- expired. An auction is identified by seller, stack size and buyout. Pure logic on
-- db.market = { [realmKey] = { scanAt, items = { [itemID] = { listings = { [key] = { count, unit,
-- timeLeft } }, days = { [day] = { sold, soldUnits, soldCopper, expired } } } } } }.
local _, ns = ...

local MarketWatch = {}
ns.MarketWatch = MarketWatch

-- A result list with at least this many auctions is a full scan (a search shows at most 50 per page).
MarketWatch.FULL_SCAN_MIN = 500
MarketWatch.KEEP_DAYS = 14
-- Shortest time left of the client's classes 1..4 (under 30 min, 30 min to 2 h, 2 to 8 h, 8 to 24 h).
local MIN_SECONDS_LEFT = { 0, 1800, 7200, 28800 }
-- Scans further apart than this are not compared (most auctions would have run out between them).
local MAX_SCAN_GAP_SECONDS = 86400

local function listingKey(listing)
	return table.concat({ listing.owner, listing.count, listing.buyout }, "|")
end

local EMPTY_DAY = { sold = 0, soldUnits = 0, soldCopper = 0, expired = 0 }
local EMPTY_MARKET = { scanAt = 0, items = {} }
local EMPTY_ITEM = { listings = {}, days = {} }

local function dayStats(item, day)
	return ns.Util.Ensure(item.days, day, EMPTY_DAY)
end

-- Listings per item in this scan: { [itemID] = { [key] = { count, unit, timeLeft } } }.
local function current(listings)
	local byItem = {}
	for _, listing in ipairs(listings) do
		if listing.count > 0 and listing.buyout > 0 then
			local list = byItem[listing.itemID] or {}
			byItem[listing.itemID] = list
			list[listingKey(listing)] = { count = listing.count, unit = listing.buyout / listing.count,
				timeLeft = listing.timeLeft }
		end
	end
	return byItem
end

-- Counts the auctions of one item that are gone since the last scan `gap` seconds ago.
local function compare(item, gap, listings, day)
	local stats = dayStats(item, day)
	for key, old in pairs(item.listings) do
		if not listings[key] then
			if gap < (MIN_SECONDS_LEFT[old.timeLeft] or 0) then
				stats.sold, stats.soldUnits = stats.sold + 1, stats.soldUnits + old.count
				stats.soldCopper = stats.soldCopper + old.unit * old.count
			else
				stats.expired = stats.expired + 1
			end
		end
	end
end

-- Compares a full scan (the listings of the watched items, with owner and timeLeft) with the
-- previous one and stores it; watched ({ [itemID] = true }) finds items whose auctions
-- are all gone. Returns the number of auctions counted as sold.
function MarketWatch.RecordScan(db, realmKey, listings, watched, now)
	local market = ns.Util.Ensure(db.market, realmKey, EMPTY_MARKET)
	local gap, day, sold = now - market.scanAt, ns.PriceHistory.Day(now), 0
	local compareScans = market.scanAt > 0 and gap <= MAX_SCAN_GAP_SECONDS
	local byItem = current(listings)
	-- Items whose auctions are all gone are compared too.
	for itemID, item in pairs(market.items) do
		if watched[itemID] and next(item.listings) ~= nil and not byItem[itemID] then
			byItem[itemID] = {}
		end
	end
	for itemID, list in pairs(byItem) do
		local item = ns.Util.Ensure(market.items, itemID, EMPTY_ITEM)
		-- A day counts only once two scans were compared on it (a single scan says nothing about sales).
		if compareScans then
			local before = dayStats(item, day).sold
			compare(item, gap, list, day)
			sold = sold + dayStats(item, day).sold - before
		end
		item.listings = list
	end
	market.scanAt = now
	return sold
end

-- Seconds since the last full scan of the realm, or nil when there was none.
function MarketWatch.ScanAge(db, realmKey, now)
	local market = realmKey and db.market[realmKey]
	return market and market.scanAt > 0 and now - market.scanAt or nil
end

-- Sales seen for an item over the kept days: { sold, soldUnits, soldCopper, expired, days } or nil.
function MarketWatch.Stats(db, realmKey, itemID)
	local market = realmKey and db.market[realmKey]
	local item = market and market.items[itemID]
	if not item then
		return nil
	end
	local total = { sold = 0, soldUnits = 0, soldCopper = 0, expired = 0, days = 0 }
	for _, stats in pairs(item.days) do
		total.sold, total.soldUnits = total.sold + stats.sold, total.soldUnits + stats.soldUnits
		total.soldCopper, total.expired = total.soldCopper + stats.soldCopper, total.expired + stats.expired
		total.days = total.days + 1
	end
	return total
end

local function pruneItem(item, oldest)
	for day in pairs(item.days) do
		if day < oldest then
			item.days[day] = nil
		end
	end
	return next(item.days) == nil and next(item.listings) == nil
end

-- Drops days older than KEEP_DAYS and items without any days or auctions.
function MarketWatch.Prune(db, now)
	local oldest = ns.PriceHistory.Day(now) - MarketWatch.KEEP_DAYS
	for _, market in pairs(db.market) do
		for itemID, item in pairs(market.items) do
			if pruneItem(item, oldest) then
				market.items[itemID] = nil
			end
		end
	end
end

-- Validation (registered with DB.ROOT_VALIDATORS): a broken realm entry is dropped.
function MarketWatch.Sanitize(db, repairs)
	for realmKey, market in pairs(db.market) do
		if type(market) ~= "table" or type(market.items) ~= "table" or type(market.scanAt) ~= "number" then
			db.market[realmKey] = nil
			repairs[#repairs + 1] = "market"
		end
	end
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = MarketWatch.Sanitize
