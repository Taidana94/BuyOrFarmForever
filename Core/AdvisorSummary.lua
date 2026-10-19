-- Advisor summary (the "Ratgeber" window): fixed rows in the order the user asked for (2026-10-19):
-- sell, disenchant (only for characters who can), craft, savings goal, best hour. Each row is a
-- suggestion like those of Core/AdvisorSources.lua (kind, sure, auction, ...); a row with nothing
-- to do carries `empty` (a reason key), so the window always shows the same rows. Changes nothing.
local _, ns = ...

local Sources = ns.AdvisorSources

local AdvisorSummary = {}
ns.AdvisorSummary = AdvisorSummary

local function tasksByKind(tasks)
	local byKind = {}
	for _, task in ipairs(tasks) do
		byKind[task.kind] = task
	end
	return byKind
end

-- Sell: vendor junk (sold on click at a merchant) and auction goods; warns about full bags.
local function sellRow(env, bagTasks)
	local vendor, auction = bagTasks.SELL_VENDOR, bagTasks.SELL_AUCTION
	local free = ns.Client:GetFreeBagSlots()
	local row = Sources.Suggestion(env, "SUM_SELL", {
		vendorUnits = vendor and vendor.units or 0,
		auctionUnits = auction and auction.units or 0,
		sure = vendor and vendor.sure,
		auction = auction and auction.auction,
		items = vendor and vendor.items,
		auctionItems = auction and auction.items,
		freeSlots = free and free <= Sources.BAGS_FULL_SLOTS and free or nil,
	})
	row.count = row.vendorUnits + row.auctionUnits
	row.empty = row.count == 0 and "NOTHING" or nil
	row.action = vendor and env.context == "MERCHANT" and "SELL_VENDOR" or nil
	return row
end

-- Disenchant: items that bring more as enchanting materials than sold; nil if the character cannot
-- disenchant.
local function disenchantRow(env, bagTasks)
	if not ns.Client:KnowsDisenchant() then
		return nil
	end
	local task = bagTasks.DISENCHANT
	if not task then
		local reason = ns.Client:HasExternalPrices() and "NOTHING" or "NO_PRICES"
		return Sources.Suggestion(env, "DISENCHANT", { count = 0, empty = reason })
	end
	return Sources.Suggestion(env, "DISENCHANT", { count = task.units, auction = task.auction, items = task.items,
		gains = task.gains })
end

-- Craft entries: ready goals and cooldowns, then profitable recipes whose reagents are in the bags,
-- then those whose reagents must be bought.
local function craftEntries(env)
	local entries = {}
	for _, s in ipairs(Sources.CraftNow(env)) do
		entries[#entries + 1] = { reason = s.kind, itemID = s.itemID, goal = s.goal, crafts = s.count or 1, sure = 0,
			auction = 0 }
	end
	local buy = {}
	for _, task in ipairs(ns.CraftTasks.Collect(env.charData, env.now)) do
		if task.kind == "CRAFT" then
			local crafts = task.fromBags > 0 and math.min(task.fromBags, task.crafts) or task.crafts
			local share = crafts / task.crafts
			local entry = { reason = task.fromBags > 0 and "PROFIT_BAGS" or "PROFIT_BUY", itemID = task.itemID,
				crafts = crafts, sure = task.sure * share, auction = task.auction * share }
			local list = task.fromBags > 0 and entries or buy
			list[#list + 1] = entry
		end
	end
	for _, entry in ipairs(buy) do
		entries[#entries + 1] = entry
	end
	return entries
end

local function craftEmptyReason(env)
	if next(env.charData.recipeBook) == nil then
		return "NO_RECIPES", 0
	end
	local unpriced = ns.CraftTasks.CountUnpriced(env.charData, env.now)
	return unpriced > 0 and "UNPRICED" or "NO_PROFIT", unpriced
end

-- Craft: the first entry on the card, all entries in the tooltip.
local function craftRow(env)
	local entries = craftEntries(env)
	local first = entries[1]
	if not first then
		local reason, unpriced = craftEmptyReason(env)
		return Sources.Suggestion(env, "SUM_CRAFT", { entries = entries, empty = reason, count = unpriced })
	end
	return Sources.Suggestion(env, "SUM_CRAFT", { entries = entries, reason = first.reason, itemID = first.itemID,
		goal = first.goal, count = first.crafts, sure = first.sure, auction = first.auction, more = #entries - 1 })
end

local function savingsRow(env)
	return Sources.NextSavings(env) or Sources.Suggestion(env, "SAVINGS", { empty = "NO_GOAL", action = "OPEN_SAVINGS" })
end

local function hourRow(env)
	return Sources.BestHour(env) or Sources.Suggestion(env, "PLAN_HOUR", { empty = "NO_STEPS", action = "OPEN_PLANNER" })
end

-- The rows for the character in a context (Advisor.Context()).
function AdvisorSummary.Rows(charData, context, now)
	local env = { charData = charData, context = context, now = now, discount = ns.db.settings.ahDiscountPercent }
	local bagTasks = tasksByKind(ns.BagTasks.Collect(charData, now, env.discount))
	local rows = { sellRow(env, bagTasks) }
	rows[#rows + 1] = disenchantRow(env, bagTasks)
	rows[#rows + 1] = craftRow(env)
	rows[#rows + 1] = savingsRow(env)
	rows[#rows + 1] = hourRow(env)
	return rows
end
