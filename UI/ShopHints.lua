-- Hints at merchants and the auction house:
-- * merchant (goldMerchantHint): a line under the merchant frame with free gold and reserves,
--   red once purchases reach the reserves;
-- * reserve warning (goldReserveWarning): one chat line per merchant visit when the gold drops
--   below the reserves;
-- * auction house (auctionHint): one chat line per visit naming how many missing materials of
--   the selected goal have no current price (the AH scan button in the Material tab finds them).
-- The gold signal is registered only while a merchant is open.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Events = ns.Events
local SavingsGoals = ns.SavingsGoals

local ShopHints = {}
ns.ShopHints = ShopHints

local HINT_Y, HINT_WIDTH, HINT_HEIGHT = -2, 330, 20
local COLOR_OK = { 1, 1, 1 }
local COLOR_ATTACKED = { 1, 0.35, 0.35 }

local hint, warned

local function charData()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey]
end

local function createHint(parent)
	hint = CreateFrame("Frame", nil, parent)
	hint:SetSize(HINT_WIDTH, HINT_HEIGHT)
	hint:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, HINT_Y)
	hint.text = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint.text:SetAllPoints()
	hint.text:SetJustifyH("LEFT")
end

-- Gold, reserves and whether purchases have reached the reserves.
local function goldState(data)
	local money = ns.Client:GetMoney() or 0
	local reserved = SavingsGoals.ReservedTotal(data)
	return money, reserved, reserved > 0 and money < reserved
end

local function updateMerchant()
	local data = charData()
	if not data then
		return
	end
	local money, reserved, attacked = goldState(data)
	local settings = ns.db.settings
	if hint and settings.goldMerchantHint then
		local color = attacked and COLOR_ATTACKED or COLOR_OK
		hint.text:SetText(Util.Format(L.MERCHANT_HINT, Money.Format(math.max(0, money - reserved)), Money.Format(reserved)))
		hint.text:SetTextColor(color[1], color[2], color[3])
	end
	if attacked and settings.goldReserveWarning and not warned then
		warned = true
		Log.Print(Util.Format(L.GOLD_RESERVE_WARNING, Money.Format(reserved - money)))
	end
end

local function onMerchantOpened()
	warned = false
	local frame = ns.Client:GetMerchantFrame()
	if ns.db and ns.db.settings.goldMerchantHint and frame then
		if not hint then
			createHint(frame)
		end
		hint:Show()
	end
	Events.OnSignal("MONEY_CHANGED", updateMerchant)
	updateMerchant()
end

local function onMerchantClosed()
	if hint then
		hint:Hide()
	end
	Events.OffSignal("MONEY_CHANGED", updateMerchant)
end

-- Missing materials of the selected goal without a current price.
function ShopHints.UnpricedMissing(data)
	local goal = ns.Materials.GetActiveGoal(data)
	local count, now = 0, ns.Client:GetServerTime()
	local realmKey = ns.PriceCapture.CurrentRealmKey()
	for _, row in ipairs(goal and ns.Stock.Rows(data, { goal }) or {}) do
		local price, _, _, outdated = ns.Prices.Best(ns.db, realmKey, row.itemID, now, ns.db.settings.priceMaxAgeDays)
		if row.missing > 0 and (not price or outdated) then
			count = count + 1
		end
	end
	return count
end

local function onAuctionOpened()
	local data = charData()
	if not (data and ns.db.settings.auctionHint) then
		return
	end
	local count = ShopHints.UnpricedMissing(data)
	if count > 0 then
		Log.Print(Util.Format(L.AUCTION_HINT, count))
	end
end

-- The merchant hint frame, or nil before the first merchant visit (for tests).
function ShopHints.GetHint()
	return hint
end

if ns.Client then
	Events.OnSignal("MERCHANT_OPENED", onMerchantOpened)
	Events.OnSignal("MERCHANT_CLOSED", onMerchantClosed)
	Events.OnSignal("AUCTION_OPENED", onAuctionOpened)
end
