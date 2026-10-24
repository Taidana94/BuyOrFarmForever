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
-- A full scan older than this is suggested again at the auction house (sales are seen between scans).
AdvisorSources.FULL_SCAN_DUE_SECONDS = 3 * HOUR

-- Priority per kind; HERE is used when the suggestion can be done in the open window.
local PRIORITY = {
	BUY_MERCHANT = 100, BANK_TAKE = 100, MAIL_SEND = 95, BAGS_FULL = 95, CRAFT_NOW = 85, PRICES_SCAN = 85, FULL_SCAN = 75, SHOP_LIST = 92,
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

-- Stock rows of what the plan of the character's wants needs in the bags (Core/WantPlan.lua).
local function goalRows(env)
	if not env.rows then
		local plan = ns.WantPlan.Current()
		env.rows = plan and ns.Stock.Rows(env.charData, ns.WantPlan.Requirements(plan)) or {}
	end
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

-- Merchant: missing materials of the wants this merchant sells.
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

-- Bank: materials of the wants lying in the bank.
local function bankSuggestions(env, out)
	for _, row in ipairs(goalRows(env)) do
		local take = math.min(row.bank or 0, row.need - row.bags)
		if take > 0 then
			out[#out + 1] = suggestion(env, "BANK_TAKE", { itemID = row.itemID, count = take })
		end
	end
end

-- Auction house: purchases of the plan, and items without any way (no price, no farm run).
local function auctionSuggestions(env, out)
	local plan = ns.WantPlan.Current()
	local unpriced = 0
	for itemID, entry in pairs(plan and ns.WantPlan.ToGet(plan) or {}) do
		if entry.buy > 0 then
			out[#out + 1] = suggestion(env, "BUY_AUCTION", { itemID = itemID, count = entry.buy, cost = entry.copper })
		end
		if entry.open > 0 then
			unpriced = unpriced + 1
		end
	end
	if unpriced > 0 then
		out[#out + 1] = suggestion(env, "PRICES_SCAN", { count = unpriced, action = "SCAN" })
	end
	local steps = env.charData.activePlan and env.charData.activePlan.steps or {}
	local shopping = ns.ShoppingList.Collect(steps, plan and ns.WantPlan.ToGet(plan) or {})
	if #shopping > 0 then
		out[#out + 1] = suggestion(env, "SHOP_LIST", { count = #shopping, action = "SHOP" })
	end
	local age = ns.MarketWatch.ScanAge(ns.db, ns.PriceCapture.CurrentRealmKey(), env.now)
	if ns.db.settings.useSaleChance and not (age and age < AdvisorSources.FULL_SCAN_DUE_SECONDS) then
		out[#out + 1] = suggestion(env, "FULL_SCAN", { seconds = age })
	end
end

local function bagCount(itemID)
	return ns.Client:GetBagCount(itemID) or 0
end

-- Mailbox: send own items to other characters (same realm and faction) who want them or craft with
-- them in the running plan (Core/MailPrep.lua).
local function mailSuggestions(env, out)
	local steps = env.charData.activePlan and env.charData.activePlan.steps or {}
	for _, entry in ipairs(ns.MailPrep.Collect(env.charData, steps, bagCount)) do
		out[#out + 1] = suggestion(env, "MAIL_SEND", { itemID = entry.itemID, count = entry.count, name = entry.name,
			reason = entry.reason })
	end
end

-- Anywhere: materials other characters hold for this character's wants (to be mailed over).
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

-- Whether every reagent of a planned craft is in the bags now.
local function reagentsInBags(node)
	for _, child in ipairs(node.children) do
		if ns.Client:GetBagCount(child.itemID) < child.need then
			return false
		end
	end
	return true
end

-- Crafts of the plan this character can do now (all reagents in the bags), then ready cooldowns.
function AdvisorSources.CraftNow(env)
	local out = {}
	local plan = ns.WantPlan.Current()
	for _, node in ipairs(plan and plan.totals.crafts or {}) do
		if node.recipe.charKey == ns.charKey and reagentsInBags(node) then
			out[#out + 1] = suggestion(env, "CRAFT_NOW", { itemID = node.itemID, count = node.crafts,
				recipeKey = node.recipe.key })
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
	local plan = ns.GoldPlan.Plan({ seconds = HOUR, methods = ns.Conversion.Methods(env.charData, env.now), discountPercent = env.discount,
		tasks = ns.GoldPlan.Tasks(env.charData, env.now), capital = ns.GoldPlan.Capital(env.charData),
		withoutAuction = not ns.db.settings.planUseAuction })
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
