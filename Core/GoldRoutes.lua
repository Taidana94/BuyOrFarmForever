-- Gold routes: "farm something else, sell it and buy the material instead". From saved farm runs,
-- the sale value per hour of each route (runs with the same target item), farm and travel time
-- together. List works on db.farmRuns with a value function from the caller; SaleValue reads the
-- prices (auction prices minus the auction house cut, or the vendor price, whichever is higher).
local _, ns = ...

local GoldRoutes = {}
ns.GoldRoutes = GoldRoutes

-- Less time than this on a route is too little data to rate it.
GoldRoutes.MIN_SECONDS = 600
-- Classic auction house cut on sales; the deposit is not counted.
GoldRoutes.AUCTION_CUT = 0.05
local SECONDS_PER_HOUR = 3600
-- Price sources a sale on the auction house can reach (merchant prices are buy prices).
local SALE_SOURCES = { "AUCTION", "MANUAL" }

local function runValue(run, valueOf)
	local value = 0
	for itemID, amount in pairs(run.items) do
		value = value + amount * (valueOf(itemID) or 0)
	end
	return value
end

local function addRun(routes, run, valueOf)
	local route = routes[run.targetItemID]
	if not route then
		route = { targetItemID = run.targetItemID, value = 0, seconds = 0, runs = 0 }
		routes[run.targetItemID] = route
	end
	route.value = route.value + runValue(run, valueOf)
	route.seconds = route.seconds + run.activeSeconds + run.travelSeconds
	route.runs = route.runs + 1
end

-- Routes with enough data and a sale value, best first:
-- { { targetItemID, copperPerHour, value, seconds, runs } }. Runs without a target, of other
-- characters (scope "CHARACTER") and with a target in `excluded` ({ [itemID] = true }) are skipped.
function GoldRoutes.List(db, scope, charKey, valueOf, excluded)
	-- One value lookup per item, not per run (up to MAX_RUNS runs share few items).
	local values = {}
	local function cachedValue(itemID)
		if values[itemID] == nil then
			values[itemID] = valueOf(itemID) or false
		end
		return values[itemID] or nil
	end
	local routes = {}
	for _, run in ipairs(db.farmRuns) do
		local own = scope ~= "CHARACTER" or run.charKey == charKey
		if own and run.targetItemID > 0 and not excluded[run.targetItemID] then
			addRun(routes, run, cachedValue)
		end
	end
	local list = {}
	for _, route in pairs(routes) do
		if route.seconds >= GoldRoutes.MIN_SECONDS and route.value > 0 then
			route.copperPerHour = route.value / route.seconds * SECONDS_PER_HOUR
			list[#list + 1] = route
		end
	end
	table.sort(list, function(a, b)
		if a.copperPerHour ~= b.copperPerHour then
			return a.copperPerHour > b.copperPerHour
		end
		return a.targetItemID < b.targetItemID
	end)
	return list
end

-- Seconds on a route to earn `copper`.
function GoldRoutes.TimeToEarn(route, copper)
	return copper / route.copperPerHour * SECONDS_PER_HOUR
end

-- Lowest current auction-type price of an item (stored or from Auctionator), or nil.
local function auctionPrice(itemID, now)
	local db, maxAge = ns.db, ns.db.settings.priceMaxAgeDays
	local item = ns.Prices.Get(db, ns.PriceCapture.CurrentRealmKey(), itemID) or {}
	local records = ns.PriceCapture.External(itemID, now) or {}
	for _, source in ipairs(SALE_SOURCES) do
		records[source] = item[source]
	end
	local best
	for source, record in pairs(records) do
		if not ns.Prices.IsOutdated(source, record, now, maxAge) and (not best or record.copper < best) then
			best = record.copper
		end
	end
	return best
end

-- What one unit brings when sold: the auction price minus the cut, or the vendor price if higher.
-- nil if neither is known.
function GoldRoutes.SaleValue(itemID, now)
	local auction = auctionPrice(itemID, now)
	local vendor = ns.Client:GetSellPrice(itemID)
	if not (auction or vendor) then
		return nil
	end
	return math.max(auction and auction * (1 - GoldRoutes.AUCTION_CUT) or 0, vendor or 0)
end
