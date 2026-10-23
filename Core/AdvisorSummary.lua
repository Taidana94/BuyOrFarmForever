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

-- Copies the value of a craft task (CraftTasks.Value fields) into an entry; none for goals.
local function withValue(entry, value)
	entry.sure, entry.auction = value.sure or 0, value.auction or 0
	entry.saleVendor, entry.saleAuction, entry.reagents = value.saleVendor, value.saleAuction, value.reagents
	entry.farmSeconds = value.farmSeconds
	return entry
end

-- Craft entries: planned crafts with all reagents in the bags, ready cooldowns (with their value when priced and
-- profitable), then profitable recipes whose reagents are in the bags, then those to buy or farm for.
local function craftEntries(env, tasks)
	local cooldownValue = {}
	for _, task in ipairs(tasks) do
		cooldownValue[task.kind == "COOLDOWN" and task.itemID or false] = task
	end
	local entries, buy = {}, {}
	for _, s in ipairs(Sources.CraftNow(env)) do
		local value = s.kind == "COOLDOWN_READY" and cooldownValue[s.itemID] or {}
		entries[#entries + 1] = withValue({ reason = s.kind, itemID = s.itemID, crafts = s.count or 1 },
			value)
	end
	for _, task in ipairs(tasks) do
		if task.kind == "CRAFT" then
			local list = task.fromBags > 0 and entries or buy
			local reason = (task.fromBags > 0 and "PROFIT_BAGS") or (task.farmSeconds > 0 and "PROFIT_FARM")
				or "PROFIT_BUY"
			list[#list + 1] = withValue({ reason = reason, itemID = task.itemID, crafts = task.crafts }, task)
		end
	end
	for _, entry in ipairs(buy) do
		entries[#entries + 1] = entry
	end
	return entries
end

local function craftEmptyReason(env, waiting)
	if next(env.charData.recipeBook) == nil then
		return "NO_RECIPES", 0
	end
	local unpriced = ns.CraftTasks.CountUnpriced(env.charData, env.now)
	if unpriced > 0 then
		return "UNPRICED", unpriced
	end
	return #waiting > 0 and "WAITING" or "NO_PROFIT", 0
end

-- Craft: the first entry on the card, all entries and the waiting cooldowns in the tooltip.
local function craftRow(env)
	local entries = craftEntries(env, ns.CraftTasks.Collect(env.charData, env.now))
	local waiting = ns.CraftTasks.Waiting(env.charData, env.now)
	local first = entries[1]
	if not first then
		local reason, unpriced = craftEmptyReason(env, waiting)
		return Sources.Suggestion(env, "SUM_CRAFT", { entries = entries, waiting = waiting, empty = reason,
			count = unpriced })
	end
	local row = withValue({ entries = entries, waiting = waiting, reason = first.reason, itemID = first.itemID,
		count = first.crafts, more = #entries - 1 }, first)
	return Sources.Suggestion(env, "SUM_CRAFT", row)
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
