-- The acquisition plan of the logged-in character's wants (Core/Acquire.lua) with what the addon
-- knows: stock of all characters (Core/Stock.lua), prices (Core/PriceCapture.lua), farm runs
-- (Core/FarmEstimates.lua), the learned recipes of the characters on the realm and faction, and the
-- value of an hour of farming. The plan is cached and rebuilt only after a signal that can change it,
-- so tooltips and the advisor can ask often.
local _, ns = ...

local Events = ns.Events

local WantPlan = {}
ns.WantPlan = WantPlan

local COPPER_PER_GOLD = 10000
local INVALIDATING_SIGNALS = {
	"BAGS_CHANGED", "BANK_CLOSED", "MAIL_CLOSED", "PRICES_CHANGED", "DATA_CHANGED", "RECIPES_CHANGED", "SETTINGS_CHANGED",
}

local cached


-- Learned recipes by product over the characters of the realm and faction (the current one first):
-- { [itemID] = { { key, reagents, outputMin, outputMax, charKey } } }.
local function learnedRecipes(charData)
	local byProduct = {}
	for _, key in ipairs(ns.Stock.SameRealmAndFaction(charData)) do
		for recipeKey in pairs(ns.db.characters[key].recipeBook) do
			local recipe = ns.Recipes.Get(ns.db, recipeKey)
			if recipe and recipe.outputItemID ~= 0 then
				local list = byProduct[recipe.outputItemID] or {}
				list[#list + 1] = { key = recipeKey, reagents = recipe.reagents, outputMin = recipe.outputMin,
					outputMax = recipe.outputMax, charKey = key }
				byProduct[recipe.outputItemID] = list
			end
		end
	end
	return byProduct
end

-- What an hour of farming is worth: the setting hourValueGold, else the rating of the best measured
-- farm route. Returns copper, source ("SETTING" | "ROUTE" | "NONE"), route.
function WantPlan.HourValue()
	local gold = ns.db.settings.hourValueGold
	if gold > 0 then
		return gold * COPPER_PER_GOLD, "SETTING"
	end
	local route = ns.GoldRoutes.Current()[1]
	if route then
		return math.floor(route.ratingPerHour), "ROUTE", route
	end
	return 0, "NONE"
end

local function available(charData, itemID)
	local bags, bank, mail = ns.Stock.Count(itemID)
	local others = ns.db.settings.countOtherCharacters
		and ns.Stock.OthersFor(ns.db, ns.charKey, charData.faction, itemID) or 0
	return bags + (bank or 0) + mail + others
end

local function farmFor(itemID)
	local scope = ns.db.settings.farmEstimateScope
	local basis = ns.FarmEstimates.ForItem(ns.db, itemID, scope, ns.charKey)
	if not (basis and basis.amount > 0) then
		return nil
	end
	return { secondsPerUnit = basis.seconds / basis.amount, travelSeconds = basis.travelSeconds,
		uiMapID = ns.FarmEstimates.MainZone(ns.db, itemID, scope, ns.charKey) or 0 }
end

-- The planner's context for the character (see Core/Acquire.lua).
function WantPlan.Context(charData, now)
	local recipes = learnedRecipes(charData)
	return {
		available = function(itemID)
			return available(charData, itemID)
		end,
		buyPrice = function(itemID)
			local price, source = ns.PriceCapture.Best(itemID, now)
			return price, source
		end,
		saleValue = function(itemID)
			return ns.GoldRoutes.SaleValue(itemID, now)
		end,
		farm = farmFor,
		recipesFor = function(itemID)
			return recipes[itemID]
		end,
		hourValue = (WantPlan.HourValue()),
	}
end

-- The plan of the logged-in character (Acquire.Plan result plus hourValue, hourSource, hourRoute),
-- or nil before the data is loaded. Cached until a signal invalidates it.
function WantPlan.Current()
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	if not charData then
		return nil
	end
	if not cached then
		cached = ns.Acquire.Plan(charData.wants, WantPlan.Context(charData, ns.Client:GetServerTime()))
		cached.hourValue, cached.hourSource, cached.hourRoute = WantPlan.HourValue()
	end
	return cached
end

function WantPlan.Invalidate()
	cached = nil
end

local function visit(node, fn)
	fn(node)
	for _, child in ipairs(node.children or {}) do
		visit(child, fn)
	end
end

-- Calls fn(node) for every node of the plan, parents before children.
function WantPlan.EachNode(plan, fn)
	for _, node in ipairs(plan.nodes) do
		visit(node, fn)
	end
end

-- What the plan needs in the bags (everything but the items it crafts): { { itemID, need } } in
-- order of first appearance, duplicates merged (the shape Stock.Rows takes).
function WantPlan.Requirements(plan)
	local list, byID = {}, {}
	WantPlan.EachNode(plan, function(node)
		if node.method ~= "CRAFT" then
			local row = byID[node.itemID]
			if not row then
				row = { itemID = node.itemID, need = 0 }
				byID[node.itemID] = row
				list[#list + 1] = row
			end
			row.need = row.need + node.need
		end
	end)
	return list
end

-- What is still to get per item: { [itemID] = { buy, copper, farm, seconds, open } }.
function WantPlan.ToGet(plan)
	local result = {}
	WantPlan.EachNode(plan, function(node)
		if node.method == "BUY" or node.method == "FARM" or node.method == "OPEN" then
			local entry = result[node.itemID] or { buy = 0, copper = 0, farm = 0, seconds = 0, open = 0 }
			result[node.itemID] = entry
			if node.method == "BUY" then
				entry.buy, entry.copper = entry.buy + node.rest, entry.copper + node.copper
			elseif node.method == "FARM" then
				entry.farm, entry.seconds = entry.farm + node.rest, entry.seconds + node.seconds
			else
				entry.open = entry.open + node.rest
			end
		end
	end)
	return result
end

if ns.Client then
	for _, signal in ipairs(INVALIDATING_SIGNALS) do
		Events.OnSignal(signal, WantPlan.Invalidate)
	end
end
