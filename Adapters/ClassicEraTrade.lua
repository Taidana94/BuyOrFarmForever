-- Classic Era adapter part: merchant window and auction house (old auction API of the Vanilla
-- UI). Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- The functions are called by Blizzard's Vanilla UI code in build 70003 (MerchantFrame.lua,
-- Blizzard_AuctionUI); they are not in the generated docs. Forever has a different auction API.
local _, ns = ...

local Trade = {}
ns.ClassicEraTrade = Trade

-- QueryAuctionItems arguments as Blizzard_AuctionUI uses them: no level filter, first page,
-- all qualities (FILTER_ALL_INDEX = -1 in Blizzard_AuctionUI.lua), no "getAll", exact name.
local NO_LEVEL = 0
local FIRST_PAGE = 0
local ALL_QUALITIES = -1

-- Offers of the open merchant with a plain gold price: { { itemID, copper (per unit) } }.
-- Items that cost other currencies (extendedCost) are skipped.
-- Buys `count` units of an item from the open merchant (BuyMerchantItem with units, as the
-- Vanilla MerchantFrame's stack split does; at most GetMerchantItemMaxStack per call, whole merchant
-- stacks). Returns the units bought (0 if the merchant does not sell it).
function Trade.BuyFromMerchant(itemID, count)
	if not (GetMerchantNumItems and GetMerchantItemInfo and GetMerchantItemLink and BuyMerchantItem) then
		return 0
	end
	for i = 1, GetMerchantNumItems() or 0 do
		local _, linkedID = ns.Util.ParseLink(GetMerchantItemLink(i))
		if linkedID == itemID then
			local _, _, _, stackCount = GetMerchantItemInfo(i)
			local stack = math.max(1, stackCount or 1)
			local perCall = math.max(stack, math.floor((GetMerchantItemMaxStack and GetMerchantItemMaxStack(i) or stack) / stack) * stack)
			local left = math.ceil(count / stack) * stack
			local bought = left
			while left > 0 do
				BuyMerchantItem(i, math.min(left, perCall))
				left = left - math.min(left, perCall)
			end
			return bought
		end
	end
	return 0
end

function Trade.ReadMerchantPrices()
	local offers = {}
	if not (GetMerchantNumItems and GetMerchantItemInfo and GetMerchantItemLink) then
		return offers
	end
	for i = 1, GetMerchantNumItems() or 0 do
		local _, _, price, stackCount, _, _, _, extendedCost = GetMerchantItemInfo(i)
		local _, itemID = ns.Util.ParseLink(GetMerchantItemLink(i))
		local ok = itemID and type(price) == "number" and price > 0 and not extendedCost
		if ok and type(stackCount) == "number" and stackCount > 0 then
			offers[#offers + 1] = { itemID = itemID, copper = price / stackCount }
		end
	end
	return offers
end

-- Current page of auction search results: { { itemID, count, buyout } } (buyout 0 = none).
-- Rows whose data is not loaded yet are skipped; the client sends another update when it is.
function Trade.ReadAuctionResults()
	local results = {}
	if not (GetNumAuctionItems and GetAuctionItemInfo) then
		return results
	end
	local batch = GetNumAuctionItems("list") or 0
	for i = 1, batch do
		local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID, hasAllInfo = GetAuctionItemInfo("list", i)
		if hasAllInfo ~= false and type(itemID) == "number" and type(count) == "number" and type(buyout) == "number" then
			results[#results + 1] = { itemID = itemID, count = count, buyout = buyout }
		end
	end
	return results
end

-- Reads a full scan (the current result list holds the whole auction house). GetAuctionItemInfo
-- returns the owner as 14th value, GetAuctionItemTimeLeft 1..4 short..very long; both used this
-- way by the Classic Era AuctionUI, 70003. Returns lows (ns.PriceHistory.AddLow) of every item,
-- the listings { { itemID, count, buyout, owner, timeLeft } } of the watched items ({ [itemID] =
-- true }) and the number of auctions read. Only watched items get a table per auction.
function Trade.ReadAuctionScan(watched)
	local lows, listings, total = {}, {}, 0
	if not (GetNumAuctionItems and GetAuctionItemInfo and GetAuctionItemTimeLeft) then
		return lows, listings, total
	end
	for i = 1, GetNumAuctionItems("list") or 0 do
		local _, _, count, _, _, _, _, _, _, buyout, _, _, _, owner, _, _, itemID, hasAllInfo = GetAuctionItemInfo("list", i)
		if hasAllInfo ~= false and type(itemID) == "number" and type(count) == "number" and type(buyout) == "number" then
			total = total + 1
			ns.PriceHistory.AddLow(lows, itemID, count, buyout)
			if watched[itemID] then
				listings[#listings + 1] = { itemID = itemID, count = count, buyout = buyout, owner = owner or "",
					timeLeft = GetAuctionItemTimeLeft("list", i) or 0 }
			end
		end
	end
	return lows, listings, total
end

-- Number of auctions in the current result list (a full scan returns the whole house at once).
function Trade.GetAuctionBatchSize()
	return GetNumAuctionItems and (GetNumAuctionItems("list")) or 0
end

function Trade.CanQueryAuction()
	return CanSendAuctionQuery ~= nil and CanSendAuctionQuery("list") and true or false
end

-- Exact-name search on the first page. Only call it from a click or slash command: whether the
-- client requires a hardware event for it is not documented. Returns true if it was sent.
function Trade.QueryAuction(itemName)
	if not (QueryAuctionItems and Trade.CanQueryAuction()) then
		return false
	end
	QueryAuctionItems(itemName, NO_LEVEL, NO_LEVEL, FIRST_PAGE, false, ALL_QUALITIES, false, true, nil)
	return true
end
