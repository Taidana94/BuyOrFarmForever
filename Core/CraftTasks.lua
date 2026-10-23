-- Craft tasks for the gold planner and the advisor: learned recipes (the character's recipe book,
-- filled from its own profession windows) that make a profit.
-- Profit = sale value of the products (vendor price, sure; auction gold on top after the cut, not
-- guaranteed) minus the reagents. Reagents in the bags count with their raw value (what they would
-- bring when sold, the same split into sure and auction gold), reagents to buy with their planning
-- price (Prices.Best). A reagent to get without a buy price but with measured farm runs is farmed:
-- no gold, its farm time (Core/FarmEstimates.lua, plus one run's travel) is added to the task's time.
-- A recipe with a reagent that has neither is skipped. Normal recipes count with as
-- many crafts as the bags allow, otherwise MAX_CRAFTS (the auction house's demand is unknown);
-- cooldown recipes with one craft once they are ready.
local _, ns = ...

local CraftTasks = {}
ns.CraftTasks = CraftTasks

CraftTasks.MAX_CRAFTS = 5
-- Only the best tasks go into a plan (the view shows a few steps).
CraftTasks.MAX_TASKS = 5
-- Time per action (design assumptions of this addon, not game data).
local CRAFT_SECONDS = 5
local POST_SECONDS = 20
local BUY_SECONDS_PER_REAGENT = 20
CraftTasks.SECONDS_PER_CRAFT = CRAFT_SECONDS + POST_SECONDS

-- Crafts the reagents in the bags allow right now.
local function craftsFromBags(recipe)
	local crafts
	for _, reagent in ipairs(recipe.reagents) do
		local possible = math.floor(ns.Client:GetBagCount(reagent.itemID) / reagent.count)
		crafts = math.min(crafts or possible, possible)
	end
	return crafts or 0
end

-- Seconds to farm `amount` units from measured runs (with one run's travel), or nil.
local function farmSeconds(itemID, amount)
	local basis = ns.FarmEstimates.ForItem(ns.db, itemID, ns.db.settings.farmEstimateScope, ns.charKey)
	local seconds = ns.FarmEstimates.TimeFor(basis, amount)
	return seconds and seconds + basis.travelSeconds
end

-- Value of `need` units of a reagent: units in the bags at their raw value (sure, auction), the rest
-- at the planning price, or farmed without one. Returns sure, auction, bought (units to buy),
-- farmed (seconds), spend (copper paid for the bought units), outdated (the buy price is old), or nil
-- if neither a price nor farm runs are known.
local function reagentValue(itemID, need, now)
	local have = math.min(need, ns.Client:GetBagCount(itemID))
	local buyPrice, _, _, outdated = ns.PriceCapture.Best(itemID, now)
	local sure, auction = 0, 0
	if have > 0 then
		local vendor, extra = ns.GoldRoutes.SaleParts(itemID, now)
		-- Without any sale value the buy price counts, so the profit is not overstated.
		if (vendor or 0) + (extra or 0) == 0 then
			vendor, extra = buyPrice, 0
		end
		if not vendor then
			return nil
		end
		sure, auction = vendor * have, extra * have
	end
	local missing = need - have
	if missing > 0 and not buyPrice then
		local seconds = farmSeconds(itemID, missing)
		if not seconds then
			return nil
		end
		return sure, auction, 0, seconds, 0
	end
	local spend = missing * (buyPrice or 0)
	return sure + spend, auction, missing, 0, spend, missing > 0 and outdated
end

-- Value of `crafts` crafts: { sure, auction (profit parts), saleVendor, saleAuction (products sold
-- to a vendor / on the auction house after the cut), reagents (their value), buys (reagents to
-- buy), farmSeconds (time to farm the others), spend (gold paid up front for bought reagents),
-- outdated (reagents bought at an old price) }, or nil if a price is missing.
function CraftTasks.Value(recipe, crafts, now)
	local vendor, extra = ns.GoldRoutes.SaleParts(recipe.outputItemID, now)
	if not vendor then
		return nil
	end
	local made = crafts * (recipe.outputMin + recipe.outputMax) / 2
	local costSure, costAuction, buys, farmed, spend, outdated = 0, 0, 0, 0, 0, 0
	for _, reagent in ipairs(recipe.reagents) do
		local sure, auction, bought, seconds, paid, old = reagentValue(reagent.itemID, reagent.count * crafts, now)
		if not sure then
			return nil
		end
		costSure, costAuction, farmed, spend = costSure + sure, costAuction + auction, farmed + seconds, spend + paid
		outdated = outdated + (old and 1 or 0)
		buys = buys + (bought > 0 and 1 or 0)
	end
	return { sure = made * vendor - costSure, auction = made * extra - costAuction, saleVendor = made * vendor,
		saleAuction = made * (vendor + extra), reagents = costSure + costAuction, buys = buys, farmSeconds = farmed,
		spend = spend, outdated = outdated }
end

local function isReady(entry, now)
	return not entry.cooldown or (entry.readyAt or 0) <= now
end

-- The craft task of one recipe book entry, or nil (not ready, no product or a price missing).
function CraftTasks.TaskFor(key, entry, now)
	local recipe = ns.Recipes.Get(ns.db, key)
	if not (recipe and recipe.outputItemID ~= 0 and isReady(entry, now)) then
		return nil
	end
	local fromBags = craftsFromBags(recipe)
	local crafts = entry.cooldown and 1 or (fromBags > 0 and math.min(fromBags, CraftTasks.MAX_CRAFTS))
		or CraftTasks.MAX_CRAFTS
	local value = CraftTasks.Value(recipe, crafts, now)
	if not value then
		return nil
	end
	value.kind = entry.cooldown and "COOLDOWN" or "CRAFT"
	value.itemID, value.crafts, value.fromBags = recipe.outputItemID, crafts, fromBags
	value.seconds = crafts * (CRAFT_SECONDS + POST_SECONDS) + value.buys * BUY_SECONDS_PER_REAGENT + value.farmSeconds
	return value
end

-- Learned cooldown recipes still waiting: { { itemID, seconds } }, soonest first.
function CraftTasks.Waiting(charData, now)
	local list = {}
	for key, entry in pairs(charData.recipeBook) do
		local recipe = entry.cooldown and not isReady(entry, now) and ns.Recipes.Get(ns.db, key)
		if recipe then
			list[#list + 1] = { itemID = recipe.outputItemID, seconds = entry.readyAt - now }
		end
	end
	table.sort(list, function(a, b)
		return a.seconds < b.seconds
	end)
	return list
end

-- Recipes of the recipe book that make an item but cannot be rated, because the product or a
-- reagent has no price yet.
function CraftTasks.CountUnpriced(charData, now)
	local count = 0
	for key in pairs(charData.recipeBook) do
		local recipe = ns.Recipes.Get(ns.db, key)
		if recipe and recipe.outputItemID ~= 0 and not CraftTasks.Value(recipe, 1, now) then
			count = count + 1
		end
	end
	return count
end

-- The most profitable craft tasks of the character (rating > 0, best rating per second first).
function CraftTasks.Collect(charData, now)
	local discount = ns.db.settings.ahDiscountPercent
	local tasks = {}
	for key, entry in pairs(charData.recipeBook) do
		local task = CraftTasks.TaskFor(key, entry, now)
		if task and ns.GoldRoutes.Rating(task.sure, task.auction, discount) > 0 then
			task.perSecond = ns.GoldRoutes.Rating(task.sure, task.auction, discount) / task.seconds
			tasks[#tasks + 1] = task
		end
	end
	table.sort(tasks, function(a, b)
		if a.perSecond ~= b.perSecond then
			return a.perSecond > b.perSecond
		end
		return a.itemID < b.itemID
	end)
	while #tasks > CraftTasks.MAX_TASKS do
		table.remove(tasks)
	end
	return tasks
end
