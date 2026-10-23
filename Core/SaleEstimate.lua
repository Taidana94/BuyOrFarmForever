-- Sale chance on the auction house: how likely an auction of an item sells. Blizzard's Classic API
-- has no sales history of other players, so this is an estimate from what the addon sees:
--   own results  the player's auctions that sold or expired (Core/SalesLog.lua, from the mailbox)
--   realm sales  auctions of all players that sold or expired between full scans (Core/MarketWatch.lua),
--                also the units sold per day
--   market       units on offer at the last search (Core/PriceHistory.lua): many units, low chance
--   none         a cautious default
-- The own results are blended with the market (or default) chance as PRIOR_WEIGHT results, so a
-- single sale does not count as 100 %. Design values of this addon, not game data.
local _, ns = ...

local SaleEstimate = {}
ns.SaleEstimate = SaleEstimate

SaleEstimate.DEFAULT_CHANCE = 0.4
local PRIOR_WEIGHT = 3
local ROUND = 0.5
local SUPPLY_MAX_AGE_SECONDS = 3 * 86400
-- Units on offer -> chance, first matching row.
local SUPPLY_CHANCES = { { units = 5, chance = 0.7 }, { units = 20, chance = 0.5 }, { units = 60, chance = 0.3 } }
local CROWDED_CHANCE = 0.15
-- Without any seen sale or result (own mails or compared scans) only one unit is planned as a test.
local UNTESTED_UNITS = 1

local function historyItem(realmKey, itemID)
	local realm = realmKey and ns.db.priceHistory[realmKey]
	return realm and realm[itemID]
end

local function marketChance(item, now)
	if not (item and item.supply and item.supplyAt and now - item.supplyAt <= SUPPLY_MAX_AGE_SECONDS) then
		return nil
	end
	for _, row in ipairs(SUPPLY_CHANCES) do
		if item.supply <= row.units then
			return row.chance
		end
	end
	return CROWDED_CHANCE
end

local function sourceOf(own, realm, prior)
	if own.sold + own.expired > 0 then
		return "OWN"
	elseif realm and realm.sold + realm.expired > 0 then
		return "SALES"
	end
	return prior and "MARKET" or "NONE"
end

-- { chance (0..1), source ("OWN" | "SALES" | "MARKET" | "NONE"), sold, expired (own), realmSold,
-- realmExpired, perDay (units sold per observed day on the realm, or nil), supply (units on offer) }.
function SaleEstimate.For(itemID, now)
	local realmKey = ns.PriceCapture.CurrentRealmKey()
	local item = historyItem(realmKey, itemID)
	local prior = marketChance(item, now)
	local own = ns.SalesLog.Get(ns.db, realmKey, itemID) or { sold = 0, expired = 0 }
	local realm = ns.MarketWatch.Stats(ns.db, realmKey, itemID)
	local sold = own.sold + (realm and realm.sold or 0)
	local results = sold + own.expired + (realm and realm.expired or 0)
	local base = prior or SaleEstimate.DEFAULT_CHANCE
	local chance = results > 0 and (sold + base * PRIOR_WEIGHT) / (results + PRIOR_WEIGHT) or base
	return { chance = chance, source = sourceOf(own, realm, prior), sold = own.sold, expired = own.expired,
		realmSold = realm and realm.sold or 0, realmExpired = realm and realm.expired or 0,
		perDay = realm and realm.days > 0 and realm.soldUnits / realm.days or nil, supply = item and item.supply or nil }
end

-- True when the estimate rests on seen results (own auction mails or compared full scans).
function SaleEstimate.HasResults(estimate)
	return estimate.source == "OWN" or estimate.source == "SALES"
end

-- Just the chance (for the value calculations); 1 with the setting useSaleChance off.
function SaleEstimate.Chance(itemID, now)
	if not ns.db.settings.useSaleChance then
		return 1
	end
	return SaleEstimate.For(itemID, now).chance
end

-- How many of `max` to make or buy with `chance`: rounded, at least one.
function SaleEstimate.Units(max, chance)
	return math.max(1, math.floor(max * chance + ROUND))
end

-- Units of an item to make or buy for the auction house: `max` scaled by the sale chance and at most
-- what the realm sells in a day (when the market watch knows it); one test unit without any results.
-- Returns units, chance, untested (true when capped to the test unit).
function SaleEstimate.PlanUnits(itemID, max, now)
	if not ns.db.settings.useSaleChance then
		return max, 1, false
	end
	local estimate = SaleEstimate.For(itemID, now)
	local units = SaleEstimate.Units(max, estimate.chance)
	if not SaleEstimate.HasResults(estimate) then
		return math.min(units, UNTESTED_UNITS), estimate.chance, true
	elseif estimate.perDay then
		units = math.min(units, math.max(1, math.floor(estimate.perDay + ROUND)))
	end
	return units, estimate.chance, false
end
