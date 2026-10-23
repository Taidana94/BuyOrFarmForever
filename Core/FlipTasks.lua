-- Resale tasks (buy low on the auction house, post again): an item whose last lowest listing
-- (Core/PriceHistory.lua) lies clearly below the median of its daily lows on earlier days. The
-- listing must be recent (FRESH_SECONDS), the history at least MIN_DAYS long, and the gain after the
-- auction house cut at least MIN_MARGIN of the price paid. The gain is auction gold only (not
-- guaranteed: the listing may be gone, the item may not sell); units are capped by MAX_UNITS
-- because the demand is unknown. Pure logic; task { kind = "FLIP", itemID, units, buy, sell, sure,
-- auction, seconds, spend }.
local _, ns = ...

local FlipTasks = {}
ns.FlipTasks = FlipTasks

FlipTasks.MIN_DAYS = 3
FlipTasks.MIN_MARGIN = 0.2
FlipTasks.MAX_UNITS = 20
FlipTasks.MAX_TASKS = 3
FlipTasks.FRESH_SECONDS = 1800
-- Design assumption: search, buy and post one item.
FlipTasks.SECONDS_PER_FLIP = 60

local function taskFor(itemID, item, now)
	if now - item.lastAt > FlipTasks.FRESH_SECONDS then
		return nil
	end
	local reference, days = ns.PriceHistory.Reference(item, ns.PriceHistory.Day(now))
	if not reference or days < FlipTasks.MIN_DAYS then
		return nil
	end
	-- Expected per unit: resold with the sale chance, else sold to the vendor.
	local chance = ns.SaleEstimate.Chance(itemID, now)
	local resale = chance * reference * (1 - ns.GoldRoutes.AUCTION_CUT) + (1 - chance) * (ns.Client:GetSellPrice(itemID) or 0)
	local gain = resale - item.last
	if gain < item.last * FlipTasks.MIN_MARGIN then
		return nil
	end
	local units = math.min(item.lastCount, ns.SaleEstimate.Units(FlipTasks.MAX_UNITS, chance))
	return { kind = "FLIP", itemID = itemID, units = units, buy = item.last * units, sell = reference,
		sure = 0, auction = math.floor(gain * units), seconds = FlipTasks.SECONDS_PER_FLIP, spend = item.last * units,
		chance = chance }
end

-- The best resale tasks on the realm (largest gain first), at most MAX_TASKS.
function FlipTasks.Collect(db, realmKey, now)
	local tasks = {}
	for itemID, item in pairs(realmKey and db.priceHistory[realmKey] or {}) do
		tasks[#tasks + 1] = taskFor(itemID, item, now)
	end
	table.sort(tasks, function(a, b)
		if a.auction ~= b.auction then
			return a.auction > b.auction
		end
		return a.itemID < b.itemID
	end)
	while #tasks > FlipTasks.MAX_TASKS do
		table.remove(tasks)
	end
	return tasks
end
