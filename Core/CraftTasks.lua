-- Craft tasks for the gold planner: recipes of the character's recipe book that make a profit.
-- Profit per craft = sale value of the product (vendor price, sure; auction gold on top, not
-- guaranteed) minus the reagents at their planning price (Prices.Best; a recipe with a reagent
-- without price is skipped). Normal recipes count with up to MAX_CRAFTS crafts (the auction
-- house's demand is unknown), cooldown recipes with one craft once they are ready. fromBags: how
-- many crafts the reagents in the bags already allow (the advisor puts those first).
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

local function reagentCost(recipe, now)
	local cost = 0
	for _, reagent in ipairs(recipe.reagents) do
		local price = ns.PriceCapture.Best(reagent.itemID, now)
		if not price then
			return nil
		end
		cost = cost + price * reagent.count
	end
	return cost
end

-- Profit of one craft: sure, auction (nil if a price is missing).
local function profitPerCraft(recipe, now)
	local sure, auction = ns.GoldRoutes.SaleParts(recipe.outputItemID, now)
	local cost = sure and reagentCost(recipe, now)
	if not cost then
		return nil
	end
	local made = (recipe.outputMin + recipe.outputMax) / 2
	return made * sure - cost, made * auction
end

-- Crafts the reagents in the bags allow right now.
local function craftsFromBags(recipe)
	local crafts
	for _, reagent in ipairs(recipe.reagents) do
		local possible = math.floor(ns.Client:GetBagCount(reagent.itemID) / reagent.count)
		crafts = math.min(crafts or possible, possible)
	end
	return crafts or 0
end

local function taskFor(key, entry, now)
	local recipe = ns.Recipes.Get(ns.db, key)
	local ready = not entry.cooldown or (entry.readyAt or 0) <= now
	if not (recipe and recipe.outputItemID ~= 0 and ready) then
		return nil
	end
	local sure, auction = profitPerCraft(recipe, now)
	if not sure then
		return nil
	end
	local crafts = entry.cooldown and 1 or CraftTasks.MAX_CRAFTS
	return {
		kind = entry.cooldown and "COOLDOWN" or "CRAFT",
		itemID = recipe.outputItemID,
		crafts = crafts,
		seconds = crafts * (CRAFT_SECONDS + POST_SECONDS) + #recipe.reagents * BUY_SECONDS_PER_REAGENT,
		sure = crafts * sure,
		auction = crafts * auction,
		fromBags = craftsFromBags(recipe),
	}
end

-- All one-off tasks of the character now: bags (vendor, auction, disenchant) and crafts. Lives
-- here because CraftTasks loads after BagTasks and GoldPlan.
function ns.GoldPlan.Tasks(charData, now)
	local tasks = ns.BagTasks.Collect(charData, now, ns.db.settings.ahDiscountPercent)
	for _, task in ipairs(CraftTasks.Collect(charData, now)) do
		tasks[#tasks + 1] = task
	end
	return tasks
end

-- Recipes of the recipe book that make an item but cannot be rated, because the product or a
-- reagent has no price yet.
function CraftTasks.CountUnpriced(charData, now)
	local count = 0
	for key in pairs(charData.recipeBook) do
		local recipe = ns.Recipes.Get(ns.db, key)
		if recipe and recipe.outputItemID ~= 0 and not profitPerCraft(recipe, now) then
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
		local task = taskFor(key, entry, now)
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
