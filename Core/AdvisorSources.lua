-- Sources of advisor suggestions ("Ratgeber"): each looks at one part of the character's data and
-- returns suggestions { kind, priority, itemID?, count?, sure, auction, action?, ... }. Texts are
-- built by the UI from the kind. Priorities depend on the open window (context): what can be done
-- right here comes first. Uses the core modules and the adapter; changes nothing.
local _, ns = ...

local AdvisorSources = {}
ns.AdvisorSources = AdvisorSources

-- Bags with at most this many free slots count as almost full.
AdvisorSources.BAGS_FULL_SLOTS = 3
local HOUR = 3600

-- Priority per kind; HERE is used when the suggestion can be done in the open window.
local PRIORITY = {
	BUY_MERCHANT = 100, BANK_TAKE = 100, MAIL_SEND = 95, BAGS_FULL = 95, CRAFT_NOW = 85, PRICES_SCAN = 85,
	BUY_AUCTION = 90, COOLDOWN_READY = 80, SELL_VENDOR = 60, SELL_AUCTION = 55, DISENCHANT = 50, MAIL_ASK = 45,
	SAVINGS = 40, PLAN_HOUR = 30,
}
local HERE = { SELL_VENDOR = "MERCHANT", SELL_AUCTION = "AUCTION", CRAFT_NOW = "PROFESSION", COOLDOWN_READY = "PROFESSION" }
local HERE_BONUS = 40

-- Turns `fields` into a suggestion of `kind` (kinds without a priority, like the advisor window's
-- summary rows, get 0).
local function suggestion(env, kind, fields)
	fields.kind = kind
	fields.priority = (PRIORITY[kind] or 0) + (HERE[kind] == env.context and HERE_BONUS or 0)
	fields.sure, fields.auction = fields.sure or 0, fields.auction or 0
	return fields
end
AdvisorSources.Suggestion = suggestion

local function goalRows(env)
	env.rows = env.rows or ns.Stock.Rows(env.charData, ns.Materials.AllGoals(env.charData))
	return env.rows
end

-- Bags: sell to a vendor (button at the merchant), post on the auction house, disenchant.
local function bagSuggestions(env, out)
	for _, task in ipairs(ns.BagTasks.Collect(env.charData, env.now, env.discount)) do
		out[#out + 1] = suggestion(env, task.kind, { count = task.units, sure = task.sure, auction = task.auction,
			items = task.items, gains = task.gains, action = task.kind == "SELL_VENDOR" and env.context == "MERCHANT" and "SELL_VENDOR" or nil })
	end
	local free = ns.Client:GetFreeBagSlots()
	if free and free <= AdvisorSources.BAGS_FULL_SLOTS then
		out[#out + 1] = suggestion(env, "BAGS_FULL", { count = free })
	end
end

-- Merchant: missing goal materials this merchant sells.
local function merchantSuggestions(env, out)
	local offers = {}
	for _, offer in ipairs(ns.Client:ReadMerchantPrices()) do
		offers[offer.itemID] = offer.copper
	end
	for _, row in ipairs(goalRows(env)) do
		local price = offers[row.itemID]
		local toBuy = math.max(0, row.need - row.bags - (row.bank or 0))
		if price and toBuy > 0 then
			out[#out + 1] = suggestion(env, "BUY_MERCHANT", { itemID = row.itemID, count = toBuy, cost = toBuy * price,
				action = "BUY_MERCHANT" })
		end
	end
end

-- Bank: goal materials lying in the bank.
local function bankSuggestions(env, out)
	for _, row in ipairs(goalRows(env)) do
		local take = math.min(row.bank or 0, row.need - row.bags)
		if take > 0 then
			out[#out + 1] = suggestion(env, "BANK_TAKE", { itemID = row.itemID, count = take })
		end
	end
end

-- Auction house: purchases of the sourcing plan and materials without a current price.
local function auctionSuggestions(env, out)
	local goals = ns.Materials.AllGoals(env.charData)
	local unpriced = 0
	for _, line in ipairs((ns.Sourcing.CurrentPlan(env.charData, goals)).lines) do
		if line.buy > 0 then
			out[#out + 1] = suggestion(env, "BUY_AUCTION", { itemID = line.itemID, count = line.buy, cost = line.cost })
		end
		if not line.unitPrice or line.priceOutdated then
			unpriced = unpriced + 1
		end
	end
	if unpriced > 0 then
		out[#out + 1] = suggestion(env, "PRICES_SCAN", { count = unpriced, action = "SCAN" })
	end
end

-- What another character of the same realm and faction still misses for its goals: { [itemID] = n }.
local function missingOf(other)
	local missing = {}
	for _, req in ipairs(ns.Materials.Requirements(ns.Materials.AllGoals(other))) do
		local have = (other.stock.bags[req.itemID] or 0) + (other.stock.bank[req.itemID] or 0)
		if req.need > have then
			missing[req.itemID] = req.need - have
		end
	end
	return missing
end

local function addMailFor(env, out, other, name)
	for itemID, count in pairs(missingOf(other)) do
		local send = math.min(count, ns.Client:GetBagCount(itemID))
		if send > 0 then
			out[#out + 1] = suggestion(env, "MAIL_SEND", { itemID = itemID, count = send, name = name })
		end
	end
end

-- Mailbox: send own materials to other characters (same realm and faction) whose goals need them.
local function mailSuggestions(env, out)
	local _, realm = ns.Stock.SplitKey(ns.charKey)
	for key, other in pairs(ns.db.characters) do
		local name, otherRealm = ns.Stock.SplitKey(key)
		if key ~= ns.charKey and otherRealm == realm and other.faction == env.charData.faction then
			addMailFor(env, out, other, name)
		end
	end
end

-- Anywhere: materials other characters hold for this character's goals (to be mailed over).
local function mailAskSuggestions(env, out)
	for _, row in ipairs(goalRows(env)) do
		local short = row.need - row.bags - (row.bank or 0)
		local donor = row.details and row.details[1]
		if short > 0 and donor and donor.sameFaction then
			out[#out + 1] = suggestion(env, "MAIL_ASK", { itemID = row.itemID, count = math.min(short, donor.total),
				name = donor.name })
		end
	end
end

-- Recipe goals whose materials are all in the bags now, then ready cooldowns.
function AdvisorSources.CraftNow(env)
	local out = {}
	for _, goal in ipairs(ns.Materials.AllGoals(env.charData)) do
		local ready = goal.recipeKey ~= nil and #goal.items > 0
		for _, row in ipairs(ready and ns.Stock.Rows(env.charData, { goal }) or {}) do
			ready = ready and row.bags >= row.need
		end
		if ready then
			out[#out + 1] = suggestion(env, "CRAFT_NOW", { goal = goal, itemID = ns.CraftEval.GoalItemID(goal), count = goal.crafts })
		end
	end
	for _, key in ipairs(ns.RecipeBook.ReadyCooldowns(env.charData, env.now)) do
		local recipe = ns.Recipes.Get(ns.db, key)
		out[#out + 1] = suggestion(env, "COOLDOWN_READY", { itemID = recipe and recipe.outputItemID })
	end
	return out
end

local function craftSuggestions(env, out)
	for _, s in ipairs(AdvisorSources.CraftNow(env)) do
		out[#out + 1] = s
	end
end

-- The best hour of the gold planner, or nil when the plan has no step.
function AdvisorSources.BestHour(env)
	local plan = ns.GoldPlan.Plan({ seconds = HOUR, methods = ns.GoldRoutes.Current(), discountPercent = env.discount,
		tasks = ns.GoldPlan.Tasks(env.charData, env.now) })
	if #plan.steps > 0 then
		return suggestion(env, "PLAN_HOUR", { sure = plan.sure, auction = plan.auction, action = "OPEN_PLANNER" })
	end
	return nil
end

-- The next open savings goal, or nil.
function AdvisorSources.NextSavings(env)
	local routes = ns.GoldRoutes.Current()
	for _, goal in ipairs(env.charData.savingsGoals) do
		if not goal.done and goal.copper > goal.reserved then
			local rest = goal.copper - goal.reserved
			return suggestion(env, "SAVINGS", { label = goal.label, cost = rest, action = "OPEN_SAVINGS",
				seconds = routes[1] and ns.GoldRoutes.TimeToEarn(routes[1], rest), route = routes[1] })
		end
	end
	return nil
end

-- Gold: the best hour and the next savings goal.
local function goldSuggestions(env, out)
	out[#out + 1] = AdvisorSources.BestHour(env)
	out[#out + 1] = AdvisorSources.NextSavings(env)
end

-- Sources per context; "ANY" sources run in every context.
AdvisorSources.BY_CONTEXT = {
	ANY = { bagSuggestions, craftSuggestions, mailAskSuggestions, goldSuggestions },
	MERCHANT = { merchantSuggestions },
	BANK = { bankSuggestions },
	AUCTION = { auctionSuggestions },
	MAIL = { mailSuggestions },
}
