-- Strategies: ways to spend a given time on gold, compared with each other. Pure logic.
--
-- CraftedRoutes: a farm route whose loot is better crafted than sold raw (farm -> craft -> sell).
-- convertOf(itemID) gives per unit of loot { sure, auction, rawSure, rawAuction, secondsPerUnit,
-- productItemID } or nil; the route's rates change by the difference, and the craft time is taken
-- off the farm time (each farmed hour needs its crafting on top).
--
-- Compare: one gold plan (Core/GoldPlan.lua) per family of tasks and methods, best rating first:
-- BAGS (sell or disenchant what the bags hold), CRAFT (learned recipes, reagents from the bags or
-- bought), FARM (farm routes, loot sold), FISHING (fishing routes), FARM_CRAFT (routes with crafted
-- loot), FLIP (buy below the usual price on the auction house and post again) and BEST (everything together, the gold plan itself).
local _, ns = ...

local Strategies = {}
ns.Strategies = Strategies

local SECONDS_PER_HOUR = 3600
Strategies.FAMILIES = { "BEST", "BAGS", "CRAFT", "FARM", "FISHING", "FARM_CRAFT", "FLIP" }
local TASK_FAMILIES = { SELL_VENDOR = "BAGS", SELL_AUCTION = "BAGS", DISENCHANT = "BAGS", CRAFT = "CRAFT",
	COOLDOWN = "CRAFT", FLIP = "FLIP" }

-- Adds the converted loot of a route: changes per hour, craft seconds per hour, main product.
local function convertLoot(route, convertOf)
	local change = { sure = 0, auction = 0, craftSeconds = 0, gain = 0 }
	for itemID, amount in pairs(route.items) do
		local conversion = convertOf(itemID)
		if conversion then
			local perHour = amount * SECONDS_PER_HOUR / route.activeSeconds
			local sure = perHour * (conversion.sure - conversion.rawSure)
			local auction = perHour * (conversion.auction - conversion.rawAuction)
			change.sure, change.auction = change.sure + sure, change.auction + auction
			change.craftSeconds = change.craftSeconds + perHour * conversion.secondsPerUnit
			if sure + auction > change.gain then
				change.gain, change.productItemID = sure + auction, conversion.productItemID
				change.crafterKey = conversion.crafterKey
			end
		end
	end
	return change
end

local function craftedRoute(route, change, discountPercent)
	local share = SECONDS_PER_HOUR / (SECONDS_PER_HOUR + change.craftSeconds)
	local crafted = { key = route.key .. ":CRAFT", uiMapID = route.uiMapID, fishing = route.fishing, crafted = true,
		productItemID = change.productItemID, crafterKey = change.crafterKey, items = route.items, runs = route.runs,
		activeSeconds = route.activeSeconds, runsWithoutCoins = route.runsWithoutCoins, travelSeconds = route.travelSeconds,
		surePerHour = (route.surePerHour + change.sure) * share, auctionPerHour = (route.auctionPerHour + change.auction) * share }
	crafted.ratingPerHour = ns.GoldRoutes.Rating(crafted.surePerHour, crafted.auctionPerHour, discountPercent)
	return crafted
end

-- Routes whose rating per hour gets better when their loot is crafted, best first.
function Strategies.CraftedRoutes(routes, convertOf, discountPercent)
	local list = {}
	for _, route in ipairs(routes) do
		local change = convertLoot(route, convertOf)
		local crafted = change.productItemID and craftedRoute(route, change, discountPercent)
		if crafted and crafted.ratingPerHour > route.ratingPerHour then
			list[#list + 1] = crafted
		end
	end
	table.sort(list, function(a, b)
		return a.ratingPerHour > b.ratingPerHour
	end)
	return list
end

local function methodFamily(method)
	if method.crafted then
		return "FARM_CRAFT"
	end
	return method.fishing and "FISHING" or "FARM"
end

local function pick(list, family, familyOf)
	local out = {}
	for _, entry in ipairs(list) do
		if family == "BEST" or familyOf(entry) == family then
			out[#out + 1] = entry
		end
	end
	return out
end

local function taskFamily(task)
	return TASK_FAMILIES[task.kind]
end

-- opts = { seconds, tasks, methods (routes and crafted routes), discountPercent }.
-- Returns { { family, plan } } with the families that have a plan step, best rating first, and
-- the list of families without any data ({ family, ... }).
function Strategies.Compare(opts)
	local ranked, empty = {}, {}
	for _, family in ipairs(Strategies.FAMILIES) do
		local plan = ns.GoldPlan.Plan({ seconds = opts.seconds, discountPercent = opts.discountPercent, capital = opts.capital,
			withoutAuction = opts.withoutAuction,
			tasks = pick(opts.tasks, family, taskFamily), methods = pick(opts.methods, family, methodFamily) })
		if #plan.steps > 0 then
			ranked[#ranked + 1] = { family = family, plan = plan }
		else
			empty[#empty + 1] = family
		end
	end
	table.sort(ranked, function(a, b)
		if a.plan.rating ~= b.plan.rating then
			return a.plan.rating > b.plan.rating
		end
		return a.family == "BEST"
	end)
	return ranked, empty
end
