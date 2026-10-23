-- Acquisition planner: for every wanted item the cheapest way to get it (user request 0.10.0, see
-- work/notes/wants-plan.md). Pure logic: everything it knows comes from a context of functions.
--
-- Per item: stock comes first (bags, bank, other characters; one shared pool, so two wants never use
-- the same stack). For the rest it compares
--   BUY    price x rest
--   FARM   (farm time + travel) valued at ctx.hourValue (copper per hour of farming)
--   CRAFT  per learned recipe: crafts = rest / average output, rounded up; every reagent is planned
--          the same way (recursively, at most MAX_DEPTH levels, no cycles). Stock a reagent takes
--          counts at its sale value (selling it would bring that much), as in the professions tab.
-- The lowest value wins; ties go to BUY (fastest), then CRAFT, then FARM. Without any way: OPEN. A
-- craft whose reagents cannot all be obtained loses to any other way, but beats OPEN.
--
-- ctx = {
--   available(itemID) -> count in stock,
--   buyPrice(itemID) -> copper per unit, source (or nil),
--   saleValue(itemID) -> copper per unit (or nil),
--   farm(itemID) -> { secondsPerUnit, travelSeconds, uiMapID } (or nil),
--   recipesFor(itemID) -> { { key, reagents = { { itemID, count } }, outputMin, outputMax, charKey } },
--   hourValue = copper per hour of farming (0: farming costs no gold),
-- }
local _, ns = ...

local Acquire = {}
ns.Acquire = Acquire

Acquire.MAX_DEPTH = 3
local SECONDS_PER_HOUR = 3600
local UNREACHABLE = math.huge
-- Tie order: lower wins.
local METHOD_RANK = { BUY = 1, CRAFT = 2, FARM = 3 }

local planItem

local function takeFromPool(pool, ctx, itemID, need)
	if pool[itemID] == nil then
		pool[itemID] = math.max(0, ctx.available(itemID) or 0)
	end
	local take = math.min(pool[itemID], need)
	pool[itemID] = pool[itemID] - take
	return take
end

local function copyPool(pool)
	local copy = {}
	for itemID, count in pairs(pool) do
		copy[itemID] = count
	end
	return copy
end

local function replacePool(pool, from)
	for itemID in pairs(pool) do
		pool[itemID] = nil
	end
	for itemID, count in pairs(from) do
		pool[itemID] = count
	end
end

local function buyOption(ctx, itemID, rest)
	local price, source = ctx.buyPrice(itemID)
	if not price then
		return nil
	end
	return { method = "BUY", value = price * rest, copper = price * rest, unitPrice = price, source = source }
end

local function farmOption(ctx, itemID, rest)
	local farm = ctx.farm(itemID)
	if not farm then
		return nil
	end
	local seconds = farm.secondsPerUnit * rest
	return { method = "FARM", value = (seconds + farm.travelSeconds) * ctx.hourValue / SECONDS_PER_HOUR,
		seconds = seconds, travelSeconds = farm.travelSeconds, uiMapID = farm.uiMapID }
end

-- One craft option: its reagents planned on a copy of the pool (kept only if this option wins).
local function craftOption(ctx, recipe, rest, depth, path, pool)
	local perCraft = (recipe.outputMin + recipe.outputMax) / 2
	local crafts = math.ceil(rest / perCraft)
	local option = { method = "CRAFT", value = 0, crafts = crafts, recipe = recipe, children = {},
		pool = copyPool(pool) }
	for _, reagent in ipairs(recipe.reagents) do
		local child = planItem(ctx, reagent.itemID, reagent.count * crafts, depth + 1, path, option.pool)
		option.children[#option.children + 1] = child
		option.value = option.value + child.value
	end
	return option
end

local function isBetter(option, best)
	if not best then
		return true
	end
	if option.value ~= best.value then
		return option.value < best.value
	end
	return METHOD_RANK[option.method] < METHOD_RANK[best.method]
end

-- The best option for `rest` units, or nil.
local function bestOption(ctx, itemID, rest, depth, path, pool)
	local best
	for _, option in ipairs({ buyOption(ctx, itemID, rest) or false, farmOption(ctx, itemID, rest) or false }) do
		if option and isBetter(option, best) then
			best = option
		end
	end
	if depth >= Acquire.MAX_DEPTH or path[itemID] then
		return best
	end
	path[itemID] = true
	for _, recipe in ipairs(ctx.recipesFor(itemID) or {}) do
		local option = craftOption(ctx, recipe, rest, depth, path, pool)
		if isBetter(option, best) then
			best = option
		end
	end
	path[itemID] = nil
	return best
end

local function applyOption(node, option, pool)
	for key, value in pairs(option) do
		if key ~= "pool" and key ~= "value" then
			node[key] = value
		end
	end
	node.value = node.value + math.min(option.value, UNREACHABLE)
	if option.pool then
		replacePool(pool, option.pool)
	end
end

-- Plans `need` units of an item. Returns the node:
-- { itemID, need, have, rest, method ("HAVE" | "BUY" | "FARM" | "CRAFT" | "OPEN"), value,
--   copper/unitPrice/source (BUY), seconds/travelSeconds/uiMapID (FARM),
--   crafts/recipe/children (CRAFT) }
function planItem(ctx, itemID, need, depth, path, pool)
	local have = takeFromPool(pool, ctx, itemID, need)
	local node = { itemID = itemID, need = need, have = have, rest = need - have,
		value = depth > 0 and have * (ctx.saleValue(itemID) or 0) or 0 }
	if node.rest == 0 then
		node.method = "HAVE"
		return node
	end
	local option = bestOption(ctx, itemID, node.rest, depth, path, pool)
	if option then
		applyOption(node, option, pool)
	else
		node.method = "OPEN"
		node.value = UNREACHABLE
	end
	return node
end

-- Sums a planned tree into totals: { copper, farmSeconds, travelByMap = { [uiMapID] = seconds },
-- crafts = { node, ... } (reagents before the items made from them), open = { node, ... } }.
local function addTotals(totals, node)
	for _, child in ipairs(node.children or {}) do
		addTotals(totals, child)
	end
	if node.method == "BUY" then
		totals.copper = totals.copper + node.copper
	elseif node.method == "FARM" then
		totals.farmSeconds = totals.farmSeconds + node.seconds
		totals.travelByMap[node.uiMapID] = math.max(totals.travelByMap[node.uiMapID] or 0, node.travelSeconds)
	elseif node.method == "CRAFT" then
		totals.crafts[#totals.crafts + 1] = node
	elseif node.method == "OPEN" then
		totals.open[#totals.open + 1] = node
	end
end

-- Plans every want ({ { itemID, count } }, in order; earlier wants get the stock first).
-- Returns { nodes = { node per want }, totals = { copper, farmSeconds, travelSeconds, crafts, open } }.
function Acquire.Plan(wants, ctx)
	local pool, nodes = {}, {}
	local totals = { copper = 0, farmSeconds = 0, travelByMap = {}, crafts = {}, open = {} }
	-- Stock kept back by wants that count only new items (want.baseline) is used for nothing.
	for _, want in ipairs(wants) do
		if want.baseline then
			takeFromPool(pool, ctx, want.itemID, want.baseline)
		end
	end
	for i, want in ipairs(wants) do
		nodes[i] = planItem(ctx, want.itemID, want.count, 0, {}, pool)
		addTotals(totals, nodes[i])
	end
	totals.travelSeconds = 0
	for _, seconds in pairs(totals.travelByMap) do
		totals.travelSeconds = totals.travelSeconds + seconds
	end
	return { nodes = nodes, totals = totals }
end
