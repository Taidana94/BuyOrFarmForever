-- Sourcing plan: how much of each missing material to buy and to farm, under one budget, a
-- strategy and an optional farm time limit. Pure logic on the inputs of Sourcing.Inputs.
--
-- By-products: farming one material for some time also yields other missing materials (measured
-- in the same runs). Lines are settled from the longest farm time down; each farmed line credits
-- its by-products to the lines not settled yet, so materials of one route are not counted twice.
-- Time limit: after the strategy's purchases, more is bought (best time saved per copper first,
-- budget permitting) until the farm time fits. Greedy, not an optimum.
local _, ns = ...

local Sourcing = ns.Sourcing

local function newLine(input)
	return {
		itemID = input.itemID,
		missing = input.missing,
		unitPrice = input.unitPrice,
		priceOutdated = input.priceOutdated,
		buy = 0,
		farm = 0,
		cost = 0,
		farmSeconds = 0,
		byproduct = 0, -- covered by farming other materials of the plan
		open = 0, -- neither bought nor farmable (no price within budget and no estimate)
	}
end

-- Buys up to `count` units of a line within the remaining budget. Returns the remaining budget.
local function buy(line, count, budget)
	if not line.unitPrice or count <= 0 then
		return budget
	end
	local affordable = line.unitPrice > 0 and math.min(count, math.floor(budget / line.unitPrice)) or count
	line.buy = line.buy + affordable
	line.cost = line.cost + affordable * line.unitPrice
	return budget - affordable * line.unitPrice
end

-- Farm seconds saved per copper when buying instead of farming (higher first).
local function timeSavedPerCopper(input)
	if not (input.unitPrice and input.secondsPerUnit) then
		return math.huge -- not farmable: buying is the only way, so it goes first
	end
	if input.unitPrice == 0 then
		return math.huge
	end
	return input.secondsPerUnit / input.unitPrice
end

local function sortedIndexes(inputs, valueOf)
	local order = {}
	for i = 1, #inputs do
		order[i] = i
	end
	table.sort(order, function(a, b)
		local va, vb = valueOf(a), valueOf(b)
		if va ~= vb then
			return va > vb
		end
		return a < b
	end)
	return order
end

-- Settles one line: by-product credit first, then farm (with an estimate) or open.
-- Returns the active farm seconds (without travel) of the line.
local function settleLine(line, input, credit)
	line.farm, line.farmSeconds, line.open = 0, 0, 0
	local rest = math.max(0, line.missing - line.buy)
	line.byproduct = math.min(rest, math.floor(credit))
	rest = rest - line.byproduct
	if rest <= 0 then
		return 0
	end
	if not input.secondsPerUnit then
		line.open = rest
		return 0
	end
	line.farm = rest
	local active = rest * input.secondsPerUnit
	line.farmSeconds = active + input.travelSeconds
	return active
end

-- Settles all lines (longest farm time first) and returns the total farm seconds.
local function settleAll(lines, inputs)
	local order = sortedIndexes(inputs, function(i)
		local perUnit = inputs[i].secondsPerUnit
		return perUnit and (lines[i].missing - lines[i].buy) * perUnit or -1
	end)
	local credit, total = {}, 0
	for _, i in ipairs(order) do
		local active = settleLine(lines[i], inputs[i], credit[lines[i].itemID] or 0)
		total = total + lines[i].farmSeconds
		for itemID, perSecond in pairs(inputs[i].byproducts or {}) do
			credit[itemID] = (credit[itemID] or 0) + perSecond * active
		end
	end
	return total
end

-- Buys farmed units (best time saved per copper first) until the farm time fits the limit or the
-- budget is used up. Returns the remaining budget and the farm seconds.
local function enforceLimit(lines, inputs, budget, limit)
	local total = settleAll(lines, inputs)
	for _, i in ipairs(sortedIndexes(inputs, function(i)
		return timeSavedPerCopper(inputs[i])
	end)) do
		if total <= limit then
			break
		end
		local line, input = lines[i], inputs[i]
		if line.farm > 0 and input.unitPrice then
			budget = buy(line, math.min(line.farm, math.ceil((total - limit) / input.secondsPerUnit)), budget)
			total = settleAll(lines, inputs)
		end
	end
	return budget, total
end

local BUY_RULES = {
	SAVE_TIME = function()
		return true
	end,
	SAVE_GOLD = function(input)
		return input.secondsPerUnit == nil
	end,
	FARM_SELF = function()
		return false
	end,
}

-- Plan for the inputs. limitSeconds (optional) is the farm time limit.
-- Returns { lines (in input order), cost, farmSeconds, budgetLeft, open, limitSeconds,
-- overLimitSeconds (farm time above the limit the budget could not buy away, else 0) }.
function Sourcing.Plan(inputs, strategy, budget, limitSeconds)
	local shouldBuy = BUY_RULES[strategy] or BUY_RULES.SAVE_TIME
	local lines = {}
	for i, input in ipairs(inputs) do
		lines[i] = newLine(input)
	end
	local left = math.max(0, budget or 0)
	for _, i in ipairs(sortedIndexes(inputs, function(i)
		return timeSavedPerCopper(inputs[i])
	end)) do
		if shouldBuy(inputs[i]) then
			left = buy(lines[i], inputs[i].missing, left)
		end
	end
	local farmSeconds
	if limitSeconds then
		left, farmSeconds = enforceLimit(lines, inputs, left, limitSeconds)
	else
		farmSeconds = settleAll(lines, inputs)
	end
	local plan = { lines = lines, cost = 0, farmSeconds = farmSeconds, budgetLeft = left, open = 0,
		limitSeconds = limitSeconds, overLimitSeconds = limitSeconds and math.max(0, farmSeconds - limitSeconds) or 0 }
	for _, line in ipairs(lines) do
		plan.cost = plan.cost + line.cost
		plan.open = plan.open + line.open
	end
	return plan
end
