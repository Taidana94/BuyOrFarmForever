-- View model of the professions tab: the character's professions (from its recipe book), the recipes
-- of one profession grouped by category (Core/RecipeCategories.lua) and filtered by name and by the
-- reagents in the bags, and the economics of one craft.
-- Reads the book, stored recipes, bag counts, names and prices; changes nothing.
local _, ns = ...

local RecipeCategories = ns.RecipeCategories

local ProfessionView = {}
ns.ProfessionView = ProfessionView

-- Reagent filter: every recipe, recipes with at least one reagent in the bags, recipes the bags
-- allow at least once.
ProfessionView.MATS = { "ALL", "SOME", "COMPLETE" }

-- Professions with recipes in the book, in RecipeBook.PROFESSIONS order:
-- { { key, count, skill = { rank, maxRank, at } or nil } }.
function ProfessionView.Professions(charData)
	local counts = {}
	for _, entry in pairs(charData.recipeBook) do
		local key = entry.profession or "OTHER"
		counts[key] = (counts[key] or 0) + 1
	end
	local list = {}
	for _, key in ipairs(ns.RecipeBook.PROFESSIONS) do
		if counts[key] then
			list[#list + 1] = { key = key, count = counts[key], skill = charData.professions[key] }
		end
	end
	return list
end

-- Reagent state from bag counts (bagCount(itemID) -> number): have = reagents with enough units
-- for one craft, total = reagents of the recipe, crafts = how often the bags allow it.
function ProfessionView.ReagentState(recipe, bagCount)
	local have, crafts = 0, nil
	for _, reagent in ipairs(recipe.reagents) do
		local possible = math.floor(bagCount(reagent.itemID) / reagent.count)
		if possible > 0 then
			have = have + 1
		end
		crafts = math.min(crafts or possible, possible)
	end
	return { have = have, total = #recipe.reagents, crafts = crafts or 0 }
end

local MATS_CHECKS = {
	ALL = function()
		return true
	end,
	SOME = function(state)
		return state.have > 0
	end,
	COMPLETE = function(state)
		return state.total > 0 and state.have == state.total
	end,
}

function ProfessionView.PassesMats(state, mats)
	return (MATS_CHECKS[mats] or MATS_CHECKS.ALL)(state)
end

-- Localized product name (item or enchantment spell) from the client, or nil while loading.
function ProfessionView.ProductName(key, recipe)
	if recipe.outputItemID ~= 0 then
		return ns.Client:GetItemName(recipe.outputItemID)
	end
	local keyType, spellID = ns.Recipes.SplitKey(key)
	return keyType == "spell" and ns.Client:GetSpellName(spellID) or nil
end

-- Plain, case-insensitive substring search (string.lower only folds ASCII letters).
local function matchesSearch(name, search)
	return search == "" or (name ~= nil and string.find(string.lower(name), search, 1, true) ~= nil)
end

local function bagCount(itemID)
	return ns.Client:GetBagCount(itemID)
end

local function rowFor(key, entry, recipe, opts)
	local name = ProfessionView.ProductName(key, recipe)
	if not matchesSearch(name, opts.search) then
		return nil
	end
	local state = ProfessionView.ReagentState(recipe, bagCount)
	if not ProfessionView.PassesMats(state, opts.mats) then
		return nil
	end
	return {
		key = key, recipe = recipe, name = name, difficulty = entry.difficulty,
		have = state.have, total = state.total, crafts = state.crafts,
	}
end

local function byName(a, b)
	if a.name and b.name and a.name ~= b.name then
		return a.name < b.name
	end
	if (a.name == nil) ~= (b.name == nil) then
		return a.name ~= nil
	end
	return a.key < b.key
end

local function sortGroups(groups)
	table.sort(groups, function(a, b)
		return RecipeCategories.SortKey(a.category) < RecipeCategories.SortKey(b.category)
	end)
	for _, group in ipairs(groups) do
		table.sort(group.rows, byName)
	end
end

-- Recipes of one profession: { { category, rows = { { key, recipe, name, difficulty, have, total,
-- crafts } } } }, categories in display order, rows by name. opts = { search (lower case, "" = all),
-- mats ("ALL" | "SOME" | "COMPLETE") }.
function ProfessionView.Build(charData, profession, opts)
	local groups, byCategory = {}, {}
	for key, entry in pairs(charData.recipeBook) do
		local recipe = (entry.profession or "OTHER") == profession and ns.Recipes.Get(ns.db, key)
		local row = recipe and rowFor(key, entry, recipe, opts)
		if row then
			local category = RecipeCategories.ForRecipe(key, recipe)
			if not byCategory[category] then
				byCategory[category] = { category = category, rows = {} }
				groups[#groups + 1] = byCategory[category]
			end
			table.insert(byCategory[category].rows, row)
		end
	end
	sortGroups(groups)
	return groups
end

-- Value of `count` units of a reagent, like the advisor's craft tasks (Core/CraftTasks.lua): units in
-- the bags at what selling them would bring (GoldRoutes.SaleValue, auction after the cut), the rest
-- at the buy price. Returns copper (known part), whether every unit has a price, units from the bags.
local function reagentCost(itemID, count, now)
	local owned = math.min(count, ns.Client:GetBagCount(itemID))
	local buyPrice = ns.PriceCapture.Best(itemID, now)
	local saleValue = ns.GoldRoutes.SaleValue(itemID, now)
	-- Without a sale value (or one of 0) the buy price counts, so the profit is not overstated.
	local ownedPrice = (saleValue and saleValue > 0) and saleValue or buyPrice
	local missing = count - owned
	local complete = (owned == 0 or ownedPrice ~= nil) and (missing == 0 or buyPrice ~= nil)
	return owned * (ownedPrice or 0) + missing * (buyPrice or 0), complete, owned
end

-- Economics of one craft: { cost (copper of the reagents, see reagentCost), costComplete (every
-- reagent has a price), owned (units taken from the bags), made (average units made), vendor (vendor
-- price of the products) or nil, auction (auction value after the cut) or nil, profit (best sale minus
-- cost) or nil }.
function ProfessionView.Economics(recipe, now)
	local cost, complete, owned = 0, true, 0
	for _, reagent in ipairs(recipe.reagents) do
		local copper, known, fromBags = reagentCost(reagent.itemID, reagent.count, now)
		cost, owned = cost + copper, owned + fromBags
		complete = complete and known
	end
	local made = (recipe.outputMin + recipe.outputMax) / 2
	local result = { cost = cost, costComplete = complete, owned = owned, made = made }
	if recipe.outputItemID == 0 then
		return result
	end
	local sell = ns.Client:GetSellPrice(recipe.outputItemID)
	local net = ns.GoldRoutes.AuctionNet(recipe.outputItemID, now)
	result.vendor = sell and sell * made
	result.auction = net and net * made
	if complete and (sell or net) then
		result.profit = math.max(result.vendor or 0, result.auction or 0) - cost
	end
	return result
end
