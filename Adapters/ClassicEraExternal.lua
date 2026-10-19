-- Classic Era adapter part: prices of other addons. Supported: Auctionator, through its public API
-- (Source/API/v1, documented by Auctionator as stable; checked in a copy with Interface 11509,
-- see work/notes/price-addons.md). Optional: without Auctionator everything returns nil.
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
local _, ns = ...

local External = {}
ns.ClassicEraExternal = External

-- Auctionator wants the calling addon's name.
local CALLER_ID = "BuyOrFarmForever"

local function api()
	local v1 = Auctionator and Auctionator.API and Auctionator.API.v1
	if v1 and type(v1.GetAuctionPriceByItemID) == "function" then
		return v1
	end
	return nil
end

function External.HasExternalPrices()
	return api() ~= nil
end

-- Last scanned auction price in copper and its age in days (nil: unknown, e.g. over 21 days).
-- Errors inside Auctionator are returned as the third value, not raised (pcall on purpose: a
-- broken other addon must not break this one).
function External.GetExternalPrice(itemID)
	local v1 = api()
	if not v1 then
		return nil
	end
	local ok, copper = pcall(v1.GetAuctionPriceByItemID, CALLER_ID, itemID)
	if not ok then
		return nil, nil, copper
	end
	if type(copper) ~= "number" then
		return nil
	end
	local ageDays
	if type(v1.GetAuctionAgeByItemID) == "function" then
		local okAge, days = pcall(v1.GetAuctionAgeByItemID, CALLER_ID, itemID)
		ageDays = okAge and type(days) == "number" and days or nil
	end
	return copper, ageDays
end
