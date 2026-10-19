-- Display texts of advisor suggestions and of the advisor window's summary rows: title, detail
-- line, value, colour category, icon, button label and tooltip lines, built from the suggestion kind
-- (Core/AdvisorSources.lua, Core/AdvisorSummary.lua). Only text, no frames.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local UIShared = ns.UIShared

local AdvisorText = {}
ns.AdvisorText = AdvisorText

-- Coin icon (also used by the minimap button and the TOC, confirmed in game).
AdvisorText.GOLD_ICON = "Interface\\Icons\\INV_Misc_Coin_01"
-- Items named in a bag task's tooltip.
local MAX_TOOLTIP_ITEMS = 12
-- Colour category of each kind: HERE (do it in this window), GOLD, INFO, WARN; NONE for empty rows.
local CATEGORY = {
	BUY_MERCHANT = "HERE", BANK_TAKE = "HERE", MAIL_SEND = "HERE", BUY_AUCTION = "HERE", PRICES_SCAN = "HERE",
	SELL_VENDOR = "GOLD", SELL_AUCTION = "GOLD", DISENCHANT = "GOLD", PLAN_HOUR = "GOLD", COOLDOWN_READY = "GOLD",
	CRAFT_NOW = "INFO", MAIL_ASK = "INFO", SAVINGS = "INFO", BAGS_FULL = "WARN", SUM_SELL = "GOLD", SUM_CRAFT = "GOLD",
}
local BUTTONS = {
	SELL_VENDOR = "ADVISOR_BTN_SELL", BUY_MERCHANT = "ADVISOR_BTN_BUY", SCAN = "ADVISOR_BTN_SCAN",
	OPEN_PLANNER = "ADVISOR_BTN_PLANNER", OPEN_SAVINGS = "ADVISOR_BTN_SAVINGS",
}
-- Texts of empty summary rows: kind -> reason -> { title, detail }.
local EMPTY = {
	SUM_SELL = { NOTHING = { "ADVISOR_SUM_SELL_NONE", "ADVISOR_SUM_SELL_NONE_DETAIL" } },
	DISENCHANT = {
		NOTHING = { "ADVISOR_DISENCHANT_NONE", "ADVISOR_DISENCHANT_NONE_DETAIL" },
		NO_PRICES = { "ADVISOR_DISENCHANT_NONE", "ADVISOR_DISENCHANT_NO_PRICES" },
	},
	SUM_CRAFT = {
		NO_RECIPES = { "ADVISOR_CRAFT_NONE", "ADVISOR_CRAFT_NO_RECIPES" },
		UNPRICED = { "ADVISOR_CRAFT_NONE", "ADVISOR_CRAFT_UNPRICED" },
		NO_PROFIT = { "ADVISOR_CRAFT_NONE", "ADVISOR_CRAFT_NO_PROFIT" },
	},
	SAVINGS = { NO_GOAL = { "ADVISOR_SAVINGS_NONE", "ADVISOR_SAVINGS_NONE_DETAIL" } },
	PLAN_HOUR = { NO_STEPS = { "ADVISOR_PLAN_HOUR", "ADVISOR_PLAN_HOUR_NONE" } },
}
-- Detail line of a craft row per reason of its first entry.
local CRAFT_REASONS = {
	CRAFT_NOW = "ADVISOR_CRAFT_REASON_GOAL", COOLDOWN_READY = "ADVISOR_CRAFT_REASON_COOLDOWN",
	PROFIT_BAGS = "ADVISOR_CRAFT_REASON_BAGS", PROFIT_BUY = "ADVISOR_CRAFT_REASON_BUY",
}

local function itemText(s)
	return s.itemID and UIShared.ItemText(s.itemID) or L.UNKNOWN_VALUE
end

local function craftName(entry)
	return entry.itemID and UIShared.ItemText(entry.itemID) or UIShared.GoalName(entry.goal)
end

local function sellDetail(s, context)
	if s.freeSlots then
		return Util.Format(L.ADVISOR_BAGS_FULL, s.freeSlots)
	end
	if s.auctionUnits > 0 then
		return s.vendorUnits > 0 and Util.Format(L.ADVISOR_SUM_SELL_SPLIT, s.vendorUnits, s.auctionUnits)
			or L.ADVISOR_SELL_AUCTION_DETAIL
	end
	return context == "MERCHANT" and L.ADVISOR_SELL_VENDOR_HERE or L.ADVISOR_SELL_VENDOR_LATER
end

local function savingsDetail(s)
	if not s.seconds then
		return L.ADVISOR_SAVINGS_NO_ROUTE
	end
	return Util.Format(L.ADVISOR_SAVINGS_DETAIL, ns.FarmCommands.RouteName(s.route), Util.FormatDuration(s.seconds))
end

-- kind -> function(s, context) returning title, detail.
local TEXTS = {
	SELL_VENDOR = function(s, context)
		local detail = context == "MERCHANT" and L.ADVISOR_SELL_VENDOR_HERE or L.ADVISOR_SELL_VENDOR_LATER
		return Util.Format(L.ADVISOR_SELL_VENDOR, s.count), detail
	end,
	SELL_AUCTION = function(s)
		return Util.Format(L.ADVISOR_SELL_AUCTION, s.count), L.ADVISOR_SELL_AUCTION_DETAIL
	end,
	DISENCHANT = function(s, context)
		local detail = context == "MERCHANT" and L.ADVISOR_DISENCHANT_NOT_SELL or L.ADVISOR_DISENCHANT_DETAIL
		return Util.Format(L.ADVISOR_DISENCHANT, s.count), detail
	end,
	SUM_SELL = function(s, context)
		return Util.Format(L.ADVISOR_SELL_VENDOR, s.count), sellDetail(s, context), s.freeSlots and "WARN" or nil
	end,
	SUM_CRAFT = function(s)
		local detail = L[CRAFT_REASONS[s.reason]]
		if s.more > 0 then
			detail = Util.Format(L.ADVISOR_CRAFT_MORE, detail, s.more)
		end
		return Util.Format(L.ADVISOR_CRAFT, s.count, craftName(s)), detail
	end,
	BAGS_FULL = function(s)
		return Util.Format(L.ADVISOR_BAGS_FULL, s.count), L.ADVISOR_BAGS_FULL_DETAIL
	end,
	BUY_MERCHANT = function(s)
		return Util.Format(L.ADVISOR_BUY_MERCHANT, s.count, itemText(s)), L.ADVISOR_BUY_MERCHANT_DETAIL
	end,
	BANK_TAKE = function(s)
		return Util.Format(L.ADVISOR_BANK_TAKE, s.count, itemText(s)), L.ADVISOR_FOR_GOALS
	end,
	BUY_AUCTION = function(s)
		return Util.Format(L.ADVISOR_BUY_AUCTION, s.count, itemText(s)), L.ADVISOR_BUY_AUCTION_DETAIL
	end,
	PRICES_SCAN = function(s)
		return Util.Format(L.ADVISOR_PRICES_SCAN, s.count), L.ADVISOR_PRICES_SCAN_DETAIL
	end,
	MAIL_SEND = function(s)
		return Util.Format(L.ADVISOR_MAIL_SEND, s.name, s.count, itemText(s)), Util.Format(L.ADVISOR_MAIL_SEND_DETAIL, s.name)
	end,
	MAIL_ASK = function(s)
		return Util.Format(L.ADVISOR_MAIL_ASK, s.name, s.count, itemText(s)), Util.Format(L.ADVISOR_MAIL_ASK_DETAIL, s.name)
	end,
	CRAFT_NOW = function(s)
		return Util.Format(L.ADVISOR_CRAFT_NOW, s.count, s.itemID and itemText(s) or UIShared.GoalName(s.goal)),
			L.ADVISOR_CRAFT_NOW_DETAIL
	end,
	COOLDOWN_READY = function(s)
		return Util.Format(L.ADVISOR_COOLDOWN, itemText(s)), L.ADVISOR_COOLDOWN_DETAIL
	end,
	PLAN_HOUR = function()
		return L.ADVISOR_PLAN_HOUR, L.ADVISOR_PLAN_HOUR_DETAIL
	end,
	SAVINGS = function(s)
		return Util.Format(L.ADVISOR_SAVINGS, s.label ~= "" and s.label or L.GOAL_UNNAMED), savingsDetail(s)
	end,
}

-- "+3g 20s", "bis zu 1g", "+3g · bis zu 1g", "-50s" (costs) or "".
local function valueText(s)
	if s.cost then
		return Util.Format(L.ADVISOR_VALUE_COST, Money.Format(s.cost))
	end
	local parts = {}
	if s.sure > 0 then
		parts[#parts + 1] = Util.Format(L.ADVISOR_VALUE_SURE, Money.Format(s.sure))
	end
	if s.auction > 0 then
		parts[#parts + 1] = Util.Format(L.ADVISOR_VALUE_AUCTION, Money.Format(s.auction))
	end
	return table.concat(parts, L.ADVISOR_VALUE_SEPARATOR)
end

-- Title and detail of an empty summary row (UNPRICED names the number of recipes).
local function emptyTexts(s)
	local keys = EMPTY[s.kind][s.empty]
	return L[keys[1]], Util.Format(L[keys[2]], s.count)
end

-- View of a suggestion in a context: { title, detail, value, category, icon, button (label or nil) }.
function AdvisorText.View(s, context)
	local title, detail, category
	if s.empty then
		title, detail = emptyTexts(s)
		category = "NONE"
	else
		title, detail, category = TEXTS[s.kind](s, context)
	end
	return {
		title = title,
		detail = detail,
		value = s.empty and "" or valueText(s),
		category = category or CATEGORY[s.kind],
		icon = s.itemID and ns.Client:GetItemIcon(s.itemID) or AdvisorText.GOLD_ICON,
		button = s.action and L[BUTTONS[s.action]] or nil,
	}
end

-- Sorted lines "name ×count" (with the disenchanting gain if `gains` is given), at most
-- MAX_TOOLTIP_ITEMS, appended to `lines` after an optional heading.
local function addItemLines(lines, items, heading, gains)
	local block = {}
	for itemID, count in pairs(items or {}) do
		local line = Util.Format(L.GOLDPLAN_ITEM_PART, UIShared.ItemText(itemID), count)
		if gains and (gains[itemID] or 0) > 0 then
			line = Util.Format(L.ADVISOR_TIP_GAIN, line, Money.Format(math.floor(gains[itemID])))
		end
		block[#block + 1] = line
	end
	table.sort(block)
	if #block > 0 and heading then
		lines[#lines + 1] = heading
	end
	for i = 1, math.min(#block, MAX_TOOLTIP_ITEMS) do
		lines[#lines + 1] = block[i]
	end
end

local TIPS = {
	SUM_SELL = function(s, lines)
		addItemLines(lines, s.items, L.ADVISOR_TIP_VENDOR)
		addItemLines(lines, s.auctionItems, L.ADVISOR_TIP_AUCTION)
	end,
	DISENCHANT = function(s, lines)
		addItemLines(lines, s.items, nil, s.gains)
	end,
	SUM_CRAFT = function(s, lines)
		for _, entry in ipairs(s.entries or {}) do
			local value = valueText(entry)
			lines[#lines + 1] = Util.Format(L.ADVISOR_TIP_CRAFT, entry.crafts, craftName(entry),
				value ~= "" and value or L[CRAFT_REASONS[entry.reason]])
		end
	end,
}

-- Tooltip lines: the items of a bag task, the sell row's two lists, the craft row's recipes; nil
-- when there are none (item suggestions show the item).
function AdvisorText.TooltipLines(s)
	local lines = {}
	local tips = TIPS[s.kind] or function()
		addItemLines(lines, s.items)
	end
	tips(s, lines)
	return #lines > 0 and lines or nil
end
