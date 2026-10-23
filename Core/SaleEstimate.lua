-- Sale chance on the auction house: how likely an auction of an item sells. Blizzard's Classic API
-- has no sales history of other players, so this is an estimate from what the addon sees:
--   own results  the player's auctions that sold or expired (Core/SalesLog.lua, from the mailbox)
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

-- { chance (0..1), source ("OWN" | "MARKET" | "NONE"), sold, expired, supply (units on offer or nil) }.
function SaleEstimate.For(itemID, now)
	local realmKey = ns.PriceCapture.CurrentRealmKey()
	local item = historyItem(realmKey, itemID)
	local prior = marketChance(item, now)
	local own = ns.SalesLog.Get(ns.db, realmKey, itemID)
	local sold, expired = own and own.sold or 0, own and own.expired or 0
	local base = prior or SaleEstimate.DEFAULT_CHANCE
	local results = sold + expired
	local chance = results > 0 and (sold + base * PRIOR_WEIGHT) / (results + PRIOR_WEIGHT) or base
	local source = (results > 0 and "OWN") or (prior and "MARKET") or "NONE"
	return { chance = chance, source = source, sold = sold, expired = expired,
		supply = item and item.supply or nil }
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
