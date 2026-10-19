-- Bag tasks for the gold planner: what the items in the bags bring. Per stack the best way out of
-- selling to a vendor (sure gold), selling on the auction house (after the cut; not guaranteed) and
-- disenchanting (value of the materials from the price addon, after the cut; not guaranteed),
-- grouped into one task per way. Skipped: items without value, materials of the character's goals,
-- the keep list (characters[key].goldKeep). Bound items cannot go to the auction house.
-- Computed on demand from the adapter (bags, item data, prices); nothing is stored.
local _, ns = ...

local BagTasks = {}
ns.BagTasks = BagTasks

BagTasks.MAX_KEEP = 200
-- Time per action (design assumptions of this addon, not game data).
local SECONDS = {
	SELL_VENDOR = 2, -- per stack: right-click at the merchant
	SELL_AUCTION = 20, -- per stack: post one auction
	DISENCHANT = 10, -- per item: cast, loot and post a share of the materials
}
local PER_ITEM = { DISENCHANT = true }

-- Item IDs used by the character's goals (never suggested for selling).
local function goalMaterials(charData)
	local set = {}
	for _, goal in ipairs(ns.Materials.AllGoals(charData)) do
		for _, entry in ipairs(goal.items) do
			set[entry.itemID] = true
		end
	end
	return set
end

-- Ways out for one unit of a stack: { { kind, sure, auction } }.
local function waysOut(stack, now, canDisenchant)
	local ways = {}
	local vendor = ns.Client:GetSellPrice(stack.itemID)
	if vendor and vendor > 0 then
		ways[#ways + 1] = { kind = "SELL_VENDOR", sure = vendor, auction = 0 }
	end
	local net = not stack.isBound and ns.GoldRoutes.AuctionNet(stack.itemID, now)
	if net then
		ways[#ways + 1] = { kind = "SELL_AUCTION", sure = 0, auction = net }
	end
	local disenchant = canDisenchant and ns.Client:IsDisenchantable(stack.itemID) and ns.Client:GetDisenchantPrice(stack.itemID)
	if disenchant then
		ways[#ways + 1] = { kind = "DISENCHANT", sure = 0, auction = disenchant * (1 - ns.GoldRoutes.AUCTION_CUT) }
	end
	return ways
end

local function bestWay(ways, discount)
	local best, bestRating = nil, 0
	for _, way in ipairs(ways) do
		local rating = ns.GoldRoutes.Rating(way.sure, way.auction, discount)
		if rating > bestRating then
			best, bestRating = way, rating
		end
	end
	return best
end

local function addToTask(tasks, way, stack)
	local task = tasks[way.kind]
	if not task then
		task = { kind = way.kind, seconds = 0, sure = 0, auction = 0, units = 0, items = {} }
		tasks[way.kind] = task
	end
	task.sure = task.sure + way.sure * stack.count
	task.auction = task.auction + way.auction * stack.count
	task.units = task.units + stack.count
	task.seconds = task.seconds + SECONDS[way.kind] * (PER_ITEM[way.kind] and stack.count or 1)
	task.items[stack.itemID] = (task.items[stack.itemID] or 0) + stack.count
end

-- Tasks { kind = "SELL_VENDOR" | "SELL_AUCTION" | "DISENCHANT", seconds, sure, auction, units,
-- items = { [itemID] = count } } for the current bags, at most one per kind.
function BagTasks.Collect(charData, now, discountPercent)
	local skip = goalMaterials(charData)
	local canDisenchant = ns.Client:KnowsDisenchant()
	local byKind = {}
	for _, stack in ipairs(ns.Client:ListBagStacks()) do
		local wanted = not (stack.hasNoValue or skip[stack.itemID] or charData.goldKeep[stack.itemID])
		local way = wanted and bestWay(waysOut(stack, now, canDisenchant), discountPercent)
		if way then
			addToTask(byKind, way, stack)
		end
	end
	local tasks = {}
	for _, kind in ipairs({ "SELL_VENDOR", "SELL_AUCTION", "DISENCHANT" }) do
		tasks[#tasks + 1] = byKind[kind]
	end
	return tasks
end

-- Adds or removes an item on the keep list. Returns true if it is kept now, or nil plus
-- "invalid_item" | "too_many_keep".
function BagTasks.ToggleKeep(charData, itemID)
	if not ns.Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if charData.goldKeep[itemID] then
		charData.goldKeep[itemID] = nil
		return false
	end
	local count = 0
	for _ in pairs(charData.goldKeep) do
		count = count + 1
	end
	if count >= BagTasks.MAX_KEEP then
		return nil, "too_many_keep"
	end
	charData.goldKeep[itemID] = true
	return true
end

-- Validation of the stored keep list (registered with DB.VALIDATORS).
local function sanitizeKeep(charData, path, repairs)
	for itemID, value in pairs(charData.goldKeep) do
		if not (ns.Materials.IsValidItemID(itemID) and value == true) then
			charData.goldKeep[itemID] = nil
			repairs[#repairs + 1] = path .. ".goldKeep"
		end
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = sanitizeKeep
