-- Sourcing plan inputs and budget: for every missing material its price, farm rate and the other
-- missing materials the same farm runs yield (by-products). The plan itself: Core/SourcingPlan.lua.
--
-- Strategies (settings.strategy):
--   SAVE_TIME  buy what has a price; if the budget is short, buy first where one copper saves the
--              most farm time (partial purchase of the last item), farm the rest
--   SAVE_GOLD  farm what has a farm estimate; buy only what cannot be farmed (budget permitting)
--   FARM_SELF  farm everything, buy nothing
-- A time limit (settings.farmTimeLimitMinutes, 0 = none) buys more until the farm time fits.
local _, ns = ...

local Sourcing = {}
ns.Sourcing = Sourcing

Sourcing.STRATEGIES = { SAVE_TIME = true, SAVE_GOLD = true, FARM_SELF = true }
local SECONDS_PER_MINUTE = 60

local function inputFor(row, now, scope)
	local db = ns.db
	local price, _, _, outdated = ns.Prices.Best(db, ns.PriceCapture.CurrentRealmKey(), row.itemID, now,
		db.settings.priceMaxAgeDays, ns.PriceCapture.External(row.itemID, now))
	local basis = ns.FarmEstimates.ForItem(db, row.itemID, scope, ns.charKey)
	local perUnit = basis and basis.amount > 0 and basis.seconds / basis.amount or nil
	return {
		itemID = row.itemID,
		missing = row.missing,
		unitPrice = price,
		priceOutdated = outdated,
		secondsPerUnit = perUnit,
		travelSeconds = perUnit and basis.travelSeconds or 0,
	}
end

-- One input row per missing material:
-- { itemID, missing, unitPrice (copper or nil), secondsPerUnit (farm time or nil), travelSeconds,
--   byproducts = { [other missing itemID] = units per farm second } }
function Sourcing.Inputs(charData, goals)
	local now = ns.Client:GetServerTime()
	local scope = ns.db.settings.farmEstimateScope
	local inputs, missing = {}, {}
	for _, row in ipairs(ns.Stock.Rows(charData, goals)) do
		if row.missing > 0 then
			inputs[#inputs + 1] = inputFor(row, now, scope)
			missing[row.itemID] = true
		end
	end
	for _, input in ipairs(inputs) do
		if input.secondsPerUnit then
			input.byproducts = ns.FarmEstimates.Byproducts(ns.db, input.itemID, scope, ns.charKey, missing)
		end
	end
	return inputs
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

-- The farm time limit in seconds, or nil without a limit.
function Sourcing.TimeLimit()
	local minutes = ns.db.settings.farmTimeLimitMinutes
	return minutes > 0 and minutes * SECONDS_PER_MINUTE or nil
end
