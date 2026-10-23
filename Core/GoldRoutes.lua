-- Gold routes: what farming brings in gold. A route is the zone a run started in (since 0.10.0;
-- target material no longer splits routes); fishing runs of a zone form their own route (0.11.0). From the saved runs of a route: gold per
-- hour of farm time, split into a sure part (vendor value of the loot plus looted coins) and an
-- auction part (what the auction house brings on top, after its cut; not guaranteed), and the
-- average travel per trip. Used by the gold planner, the farm tab and the time value of farming.
-- List works on db.farmRuns with a value function from the caller; SaleParts reads the prices.
local _, ns = ...

local GoldRoutes = {}
ns.GoldRoutes = GoldRoutes

-- Less farm time than this on a route is too little data to rate it.
GoldRoutes.MIN_SECONDS = 600
-- Classic auction house cut on sales; the deposit is not counted.
GoldRoutes.AUCTION_CUT = 0.05
local SECONDS_PER_HOUR = 3600
-- Reliability: with fewer runs a route is "FEW"; a spread (standard deviation / mean of the runs' gold
-- per hour) above VARIES_SPREAD makes it "VARIES", else "STABLE". From DAMP_MIN_RUNS runs on, a run
-- above OUTLIER_FACTOR x the median rate (a rare drop) counts only up to that cap.
GoldRoutes.RELIABLE_RUNS = 3
local VARIES_SPREAD = 0.5
local DAMP_MIN_RUNS = 3
local OUTLIER_FACTOR = 2
local PERCENT = 100
-- Price sources a sale on the auction house can reach (merchant prices are buy prices).
local SALE_SOURCES = { "AUCTION", "MANUAL" }

-- "1436" for a zone, "1436:FISHING" for fishing in it.
function GoldRoutes.Key(run)
	return run.activity == "FISHING" and run.uiMapID .. ":FISHING" or tostring(run.uiMapID)
end

-- Rating of gold with an uncertain auction part: sure + auction x (1 - discount%).
function GoldRoutes.Rating(sure, auction, discountPercent)
	return sure + auction * (1 - discountPercent / PERCENT)
end

local function addRun(routes, run, partsOf)
	local key = GoldRoutes.Key(run)
	local route = routes[key]
	if not route then
		route = { key = key, uiMapID = run.uiMapID, fishing = run.activity == "FISHING", items = {}, sure = 0, auction = 0, activeSeconds = 0,
			travelSeconds = 0, runs = 0, runsWithoutCoins = 0, samples = {} }
		routes[key] = route
	end
	local runSure, runAuction = run.lootCopper or 0, 0
	for itemID, amount in pairs(run.items) do
		route.items[itemID] = (route.items[itemID] or 0) + amount
		local sure, auction = partsOf(itemID)
		runSure, runAuction = runSure + amount * sure, runAuction + amount * auction
	end
	route.sure, route.auction = route.sure + runSure, route.auction + runAuction
	route.samples[#route.samples + 1] = { sure = runSure, auction = runAuction, seconds = run.activeSeconds }
	if run.lootCopper == nil then
		route.runsWithoutCoins = route.runsWithoutCoins + 1
	end
	route.activeSeconds = route.activeSeconds + run.activeSeconds
	route.travelSeconds = route.travelSeconds + run.travelSeconds
	route.runs = route.runs + 1
end

-- One lookup per item, not per run (up to MAX_RUNS runs share few items).
local function cachedParts(partsOf)
	local cache = {}
	return function(itemID)
		local entry = cache[itemID]
		if not entry then
			local sure, auction = partsOf(itemID)
			entry = { sure or 0, auction or 0 }
			cache[itemID] = entry
		end
		return entry[1], entry[2]
	end
end

local function sampleRate(sample)
	return (sample.sure + sample.auction) / sample.seconds
end

local function median(values)
	table.sort(values)
	local mid = math.floor((#values + 1) / 2)
	return #values % 2 == 1 and values[mid] or (values[mid] + values[mid + 1]) / 2
end

-- Caps runs far above the median rate (rare drops) and sets route.dampedRuns.
local function dampOutliers(route)
	route.dampedRuns = 0
	if #route.samples < DAMP_MIN_RUNS then
		return
	end
	local rates = {}
	for i, sample in ipairs(route.samples) do
		rates[i] = sampleRate(sample)
	end
	local cap = OUTLIER_FACTOR * median(rates)
	for _, sample in ipairs(route.samples) do
		local value = sampleRate(sample)
		if cap > 0 and value > cap then
			local cut = 1 - cap / value
			route.sure, route.auction = route.sure - sample.sure * cut, route.auction - sample.auction * cut
			route.dampedRuns = route.dampedRuns + 1
		end
	end
end

-- "FEW" | "VARIES" | "STABLE" from the runs' spread of gold per hour.
local function reliability(route)
	local count = #route.samples
	if count < GoldRoutes.RELIABLE_RUNS then
		return "FEW"
	end
	local sum, squares = 0, 0
	for _, sample in ipairs(route.samples) do
		local value = sampleRate(sample)
		sum, squares = sum + value, squares + value * value
	end
	local mean = sum / count
	local spread = mean > 0 and math.sqrt(math.max(0, squares / count - mean * mean)) / mean or 0
	return spread > VARIES_SPREAD and "VARIES" or "STABLE"
end

local function rate(route, discountPercent)
	route.reliability = reliability(route)
	dampOutliers(route)
	route.samples = nil
	local perSecond = SECONDS_PER_HOUR / route.activeSeconds
	route.surePerHour = route.sure * perSecond
	route.auctionPerHour = route.auction * perSecond
	route.ratingPerHour = GoldRoutes.Rating(route.surePerHour, route.auctionPerHour, discountPercent)
	route.travelSeconds = route.travelSeconds / route.runs
end

-- Routes with enough data (opts.minSeconds of farm time, default MIN_SECONDS) and some value
-- (opts.minCopper, default 1), best rating first. opts = { scope ("CHARACTER" | "ACCOUNT"), charKey,
-- partsOf (itemID -> sure, auction copper per unit), excluded ({ [target itemID] = true }, optional),
-- discountPercent, minSeconds, minCopper }.
-- Each route: { key, uiMapID, fishing, items ({ [itemID] = amount }), surePerHour, auctionPerHour,
-- ratingPerHour, travelSeconds (per trip), activeSeconds, runs, runsWithoutCoins, reliability ("FEW" |
-- "VARIES" | "STABLE"), dampedRuns (runs capped as outliers) }.
function GoldRoutes.List(db, opts)
	local partsOf, excluded = cachedParts(opts.partsOf), opts.excluded or {}
	local routes = {}
	for _, run in ipairs(db.farmRuns) do
		local own = opts.scope ~= "CHARACTER" or run.charKey == opts.charKey
		if own and run.activeSeconds > 0 and not excluded[run.targetItemID] then
			addRun(routes, run, partsOf)
		end
	end
	local list, minSeconds, minCopper = {}, opts.minSeconds or GoldRoutes.MIN_SECONDS, opts.minCopper or 1
	for _, route in pairs(routes) do
		if route.activeSeconds >= minSeconds and route.activeSeconds > 0 and route.sure + route.auction >= minCopper then
			rate(route, opts.discountPercent)
			list[#list + 1] = route
		end
	end
	table.sort(list, function(a, b)
		if a.ratingPerHour ~= b.ratingPerHour then
			return a.ratingPerHour > b.ratingPerHour
		end
		return a.key < b.key
	end)
	return list
end

-- Seconds to earn `copper` on a route: one trip plus farm time at its rating.
function GoldRoutes.TimeToEarn(route, copper)
	return route.travelSeconds + copper / route.ratingPerHour * SECONDS_PER_HOUR
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

-- What one unit brings on the auction house after its cut, or nil without a current price.
function GoldRoutes.AuctionNet(itemID, now)
	local auction = auctionPrice(itemID, now)
	return auction and auction * (1 - GoldRoutes.AUCTION_CUT)
end

-- What one unit brings when sold: the vendor price (sure) and what the auction house brings on top
-- after its cut (0 if it brings less or no price is known). nil, nil if neither is known.
function GoldRoutes.SaleParts(itemID, now)
	local net = GoldRoutes.AuctionNet(itemID, now)
	local vendor = ns.Client:GetSellPrice(itemID)
	if not (net or vendor) then
		return nil, nil
	end
	return vendor or 0, math.max(0, (net or 0) - (vendor or 0))
end

-- The best price of one unit (vendor or auction after the cut), or nil if neither is known.
function GoldRoutes.SaleValue(itemID, now)
	local sure, auction = GoldRoutes.SaleParts(itemID, now)
	return sure and sure + auction
end

-- The route list of the current character with the settings (scope, auction discount); opts as
-- for List (excluded, minSeconds), optional. Without opts the list comes from Core/RouteCache.lua.
function GoldRoutes.Current(opts)
	if not opts then
		return ns.RouteCache.Get("ROUTES", function()
			return GoldRoutes.Current({})
		end)
	end
	local now = ns.Client:GetServerTime()
	local settings = ns.db.settings
	return GoldRoutes.List(ns.db, {
		scope = settings.farmEstimateScope, charKey = ns.charKey, excluded = opts.excluded, minSeconds = opts.minSeconds,
		minCopper = opts.minCopper,
		discountPercent = settings.ahDiscountPercent,
		partsOf = function(itemID)
			return GoldRoutes.SaleParts(itemID, now)
		end,
	})
end
