-- Display texts of advisor suggestions: title, detail line, value, colour category, icon and the
-- button label, built from the suggestion kind (Core/AdvisorSources.lua). Only text, no frames.
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
-- Colour category of each kind: HERE (do it in this window), GOLD, INFO, WARN.
local CATEGORY = {
	BUY_MERCHANT = "HERE", BANK_TAKE = "HERE", MAIL_SEND = "HERE", BUY_AUCTION = "HERE", PRICES_SCAN = "HERE",
	SELL_VENDOR = "GOLD", SELL_AUCTION = "GOLD", DISENCHANT = "GOLD", PLAN_HOUR = "GOLD", COOLDOWN_READY = "GOLD",
	CRAFT_NOW = "INFO", MAIL_ASK = "INFO", SAVINGS = "INFO", BAGS_FULL = "WARN",
}
local BUTTONS = {
	SELL_VENDOR = "ADVISOR_BTN_SELL", BUY_MERCHANT = "ADVISOR_BTN_BUY", SCAN = "ADVISOR_BTN_SCAN",
	OPEN_PLANNER = "ADVISOR_BTN_PLANNER",
}

local function itemText(s)
	return s.itemID and UIShared.ItemText(s.itemID) or L.UNKNOWN_VALUE
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
	DISENCHANT = function(s)
		return Util.Format(L.ADVISOR_DISENCHANT, s.count), L.ADVISOR_DISENCHANT_DETAIL
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

-- View of a suggestion in a context: { title, detail, value, category, icon, button (label or nil) }.
function AdvisorText.View(s, context)
	local title, detail = TEXTS[s.kind](s, context)
	return {
		title = title,
		detail = detail,
		value = valueText(s),
		category = CATEGORY[s.kind],
		icon = s.itemID and ns.Client:GetItemIcon(s.itemID) or AdvisorText.GOLD_ICON,
		button = s.action and L[BUTTONS[s.action]] or nil,
	}
end

-- Tooltip lines: the items of a bag task with counts, or nil (item suggestions show the item).
function AdvisorText.TooltipLines(s)
	if not s.items then
		return nil
	end
	local lines = {}
	for itemID, count in pairs(s.items) do
		if #lines < MAX_TOOLTIP_ITEMS then
			lines[#lines + 1] = Util.Format(L.GOLDPLAN_ITEM_PART, UIShared.ItemText(itemID), count)
		end
	end
	table.sort(lines)
	return lines
end
