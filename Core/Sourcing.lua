-- Sourcing plan: for every missing material, how much to buy and how much to farm, under one
-- budget and a strategy. Pure logic: inputs are plain numbers, built by Sourcing.Inputs from
-- stock, prices and farm estimates.
--
-- Strategies (settings.strategy):
--   SAVE_TIME  buy what has a price; if the budget is short, buy first where one copper saves the
--              most farm time (partial purchase of the last item), farm the rest
--   SAVE_GOLD  farm what has a farm estimate; buy only what cannot be farmed (budget permitting)
--   FARM_SELF  farm everything, buy nothing
local _, ns = ...

local Sourcing = {}
ns.Sourcing = Sourcing

Sourcing.STRATEGIES = { SAVE_TIME = true, SAVE_GOLD = true, FARM_SELF = true }

-- One input row per missing material:
-- { itemID, missing, unitPrice (copper or nil), secondsPerUnit (farm time or nil), travelSeconds }
function Sourcing.Inputs(charData, goals)
	local db = ns.db
	local realmKey = ns.PriceCapture.CurrentRealmKey()
	local now = ns.Client:GetServerTime()
	local scope = db.settings.farmEstimateScope
	local inputs = {}
	for _, row in ipairs(ns.Stock.Rows(charData, goals)) do
		if row.missing > 0 then
			local price, _, _, outdated = ns.Prices.Best(db, realmKey, row.itemID, now, db.settings.priceMaxAgeDays,
				ns.PriceCapture.External(row.itemID, now))
			local basis = ns.FarmEstimates.ForItem(db, row.itemID, scope, ns.charKey)
			local perUnit = basis and basis.amount > 0 and basis.seconds / basis.amount or nil
			inputs[#inputs + 1] = {
				itemID = row.itemID,
				missing = row.missing,
				unitPrice = price,
				priceOutdated = outdated,
				secondsPerUnit = perUnit,
				travelSeconds = perUnit and basis.travelSeconds or 0,
			}
		end
	end
	return inputs
end

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

-- Whatever is not bought is farmed if there is an estimate, otherwise it stays open.
local function settle(line, input)
	local rest = line.missing - line.buy
	if rest <= 0 then
		return
	end
	if input.secondsPerUnit then
		line.farm = rest
		line.farmSeconds = rest * input.secondsPerUnit + input.travelSeconds
	else
		line.open = rest
	end
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

local function orderForBuying(inputs)
	local order = {}
	for i = 1, #inputs do
		order[i] = i
	end
	table.sort(order, function(a, b)
		local ra, rb = timeSavedPerCopper(inputs[a]), timeSavedPerCopper(inputs[b])
		if ra ~= rb then
			return ra > rb
		end
		return a < b
	end)
	return order
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

-- Plan for the inputs. Returns { lines (in input order), cost, farmSeconds, budgetLeft, open }.
function Sourcing.Plan(inputs, strategy, budget)
	local shouldBuy = BUY_RULES[strategy] or BUY_RULES.SAVE_TIME
	local lines = {}
	for i, input in ipairs(inputs) do
		lines[i] = newLine(input)
	end
	local left = math.max(0, budget or 0)
	for _, i in ipairs(orderForBuying(inputs)) do
		if shouldBuy(inputs[i]) then
			left = buy(lines[i], inputs[i].missing, left)
		end
	end
	local plan = { lines = lines, cost = 0, farmSeconds = 0, budgetLeft = left, open = 0 }
	for i, line in ipairs(lines) do
		settle(line, inputs[i])
		plan.cost = plan.cost + line.cost
		plan.farmSeconds = plan.farmSeconds + line.farmSeconds
		plan.open = plan.open + line.open
	end
	return plan
end

-- The budget to plan with: the own budget if set, else the character's current gold. With
-- settings.useReservesInSourcing = false it is limited to the gold not reserved for savings goals.
-- Returns budget, isOwn.
function Sourcing.Budget()
	local settings = ns.db.settings
	local money = ns.Client:GetMoney() or 0
	local isOwn = settings.budgetCopper > 0
	local budget = isOwn and settings.budgetCopper or money
	local charData = ns.charKey and ns.db.characters[ns.charKey]
	if not settings.useReservesInSourcing and charData then
		budget = math.min(budget, ns.SavingsGoals.Overview(charData, money).free)
	end
	return budget, isOwn
end
