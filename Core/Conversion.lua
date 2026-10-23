-- Conversion of farmed loot with the character's learned recipes (farm -> craft -> sell), for the
-- strategy comparison and the gold plan. For a looted item, every learned recipe that uses it (no
-- cooldown, makes an item) is a candidate: one unit of the loot is worth (sale value of the products
-- - the other reagents at their planning price) / units needed, minus nothing for time; the craft
-- and post time per unit is returned separately (Core/Strategies.lua takes it off the farm time).
-- A recipe whose product or another reagent has no price is skipped. Other reagents are bought, even
-- if the same route yields them (kept simple; it only makes the conversion look worse).
local _, ns = ...

local Conversion = {}
ns.Conversion = Conversion

-- { [itemID] = { recipe, ... } } of the learned recipes that can convert loot.
local function recipesByReagent(charData)
	local index = {}
	for key, entry in pairs(charData.recipeBook) do
		local recipe = not entry.cooldown and ns.Recipes.Get(ns.db, key)
		if recipe and recipe.outputItemID ~= 0 then
			for _, reagent in ipairs(recipe.reagents) do
				local list = index[reagent.itemID] or {}
				list[#list + 1] = recipe
				index[reagent.itemID] = list
			end
		end
	end
	return index
end

-- Per unit of `itemID` used in `recipe`: sure, auction, or nil without prices.
local function unitValue(recipe, itemID, now)
	local vendor, extra = ns.GoldRoutes.SaleParts(recipe.outputItemID, now)
	if not vendor then
		return nil
	end
	local made, cost, need = (recipe.outputMin + recipe.outputMax) / 2, 0, 0
	for _, reagent in ipairs(recipe.reagents) do
		if reagent.itemID == itemID then
			need = reagent.count
		else
			local price = ns.PriceCapture.Best(reagent.itemID, now)
			if not price then
				return nil
			end
			cost = cost + price * reagent.count
		end
	end
	return (made * vendor - cost) / need, made * extra / need, need
end

local function better(best, recipe, itemID, now, discount)
	local sure, auction, need = unitValue(recipe, itemID, now)
	if not sure then
		return best
	end
	local rating = ns.GoldRoutes.Rating(sure, auction, discount)
	if best and best.rating >= rating then
		return best
	end
	return { rating = rating, sure = sure, auction = auction, productItemID = recipe.outputItemID,
		secondsPerUnit = ns.CraftTasks.SECONDS_PER_CRAFT / need }
end

-- A function itemID -> conversion (see Core/Strategies.lua) for the character, or nil when selling
-- the loot raw is at least as good. Results are cached per call of this function.
function Conversion.ConvertOf(charData, now, discount)
	local index, cache = recipesByReagent(charData), {}
	return function(itemID)
		if cache[itemID] == nil then
			local best
			for _, recipe in ipairs(index[itemID] or {}) do
				best = better(best, recipe, itemID, now, discount)
			end
			local rawSure, rawAuction = ns.GoldRoutes.SaleParts(itemID, now)
			rawSure, rawAuction = rawSure or 0, rawAuction or 0
			local keep = best and best.rating > ns.GoldRoutes.Rating(rawSure, rawAuction, discount)
			if keep then
				best.rawSure, best.rawAuction = rawSure, rawAuction
			end
			cache[itemID] = keep and best or false
		end
		return cache[itemID] or nil
	end
end

local function buildMethods(charData, now)
	local routes = ns.GoldRoutes.Current()
	local discount = ns.db.settings.ahDiscountPercent
	local crafted = ns.Strategies.CraftedRoutes(routes, Conversion.ConvertOf(charData, now, discount), discount)
	for _, route in ipairs(crafted) do
		routes[#routes + 1] = route
	end
	return routes
end

-- The methods of the gold plan: the character's farm routes and the routes with crafted loot
-- (cached by Core/RouteCache.lua).
function Conversion.Methods(charData, now)
	return ns.RouteCache.Get("METHODS", function()
		return buildMethods(charData, now)
	end)
end
