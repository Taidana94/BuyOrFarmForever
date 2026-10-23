-- Automatic price capture: merchant offers while a merchant window is open, auction results
-- while the auction house is open (whatever the user searches, plus the scan of missing
-- materials started by the user). Only items in goals of any character are stored.
-- MERCHANT_CHANGED and AUCTION_RESULTS are registered only while the window is open.
-- Raises the internal signal PRICES_CHANGED after storing prices.
local _, ns = ...

local Events = ns.Events
local Prices = ns.Prices
local Log = ns.Log

local PriceCapture = {}
ns.PriceCapture = PriceCapture

local auctionOpen = false
local merchantOpen = false
local scanned = {} -- itemID -> true: already scanned during this auction house visit
local trackedScratch = {}

-- Database, current character's price key and the tracked item set, or nil when not writable.
local function context()
	local db = ns.db
	if not (db and not ns.readOnly and ns.charKey and db.characters[ns.charKey]) then
		return nil
	end
	local realmKey = Prices.RealmKey(ns.charKey, db.characters[ns.charKey].faction)
	if not realmKey then
		return nil
	end
	return db, realmKey, ns.Wants.TrackedItems(db, trackedScratch)
end

function PriceCapture.CurrentRealmKey()
	local db = ns.db
	if not (db and ns.charKey and db.characters[ns.charKey]) then
		return nil
	end
	return Prices.RealmKey(ns.charKey, db.characters[ns.charKey].faction)
end

local function captureMerchant()
	local db, realmKey, tracked = context()
	if not db then
		return
	end
	Prices.RecordMerchant(db, realmKey, ns.Client:ReadMerchantPrices(), tracked, ns.Client:GetServerTime())
	Events.Emit("PRICES_CHANGED")
end

local function captureAuction()
	local db, realmKey, tracked = context()
	if not db then
		return
	end
	Prices.RecordAuction(db, realmKey, ns.Client:ReadAuctionResults(), tracked, ns.Client:GetServerTime())
	Events.Emit("PRICES_CHANGED")
end

PriceCapture.PRUNE_DELAY_SECONDS = 10
-- Auctionator reports no age for prices older than 21 days; such prices count as this old.
PriceCapture.EXTERNAL_UNKNOWN_AGE_DAYS = 22
local SECONDS_PER_DAY = 86400

-- Live price of another addon (Auctionator) as { AUCTIONATOR = { copper, at } }, or nil when it is
-- not installed, has no price or the setting useAuctionator is off. Read on demand, never stored.
function PriceCapture.External(itemID, now)
	if not (ns.db and ns.db.settings.useAuctionator) then
		return nil
	end
	local copper, ageDays, err = ns.Client:GetExternalPrice(itemID)
	if err then
		ns.Log.Debug("Auctionator price failed: " .. tostring(err))
	end
	if not copper then
		return nil
	end
	local days = ageDays or PriceCapture.EXTERNAL_UNKNOWN_AGE_DAYS
	return { AUCTIONATOR = { copper = copper, at = now - days * SECONDS_PER_DAY } }
end

-- Prices.Best for the current realm with the settings and the external source.
function PriceCapture.Best(itemID, now)
	return Prices.Best(ns.db, PriceCapture.CurrentRealmKey(), itemID, now, ns.db.settings.priceMaxAgeDays,
		PriceCapture.External(itemID, now))
end

-- Removes captured prices older than the setting priceKeepDays. Returns the number removed.
function PriceCapture.PruneOld()
	if not ns.db or ns.readOnly then
		return 0
	end
	local removed = Prices.Prune(ns.db, ns.Client:GetServerTime(), ns.db.settings.priceKeepDays)
	if removed > 0 then
		ns.Log.Debug("removed " .. removed .. " old prices")
	end
	return removed
end

function PriceCapture.IsAuctionOpen()
	return auctionOpen
end

-- Items the current character's plan may buy (wanted items and the reagents that could make them)
-- without a current price, in id order.
local function missingItems()
	local list, now = {}, ns.Client:GetServerTime()
	for itemID in pairs(ns.Wants.TrackedItems(ns.db, {}, { [ns.charKey] = true })) do
		local price, _, _, outdated = PriceCapture.Best(itemID, now)
		if not price or outdated then
			list[#list + 1] = itemID
		end
	end
	table.sort(list)
	return list
end

-- Sends the auction search for the next missing material not yet scanned during this visit.
-- Call only from a click or slash command. Returns itemID, position, total, or nil plus
-- "no_auction" | "auction_busy" | "scan_done" | "loading".
function PriceCapture.ScanNext()
	if not auctionOpen then
		return nil, "no_auction"
	end
	local list = ns.db and ns.charKey and ns.db.characters[ns.charKey] and missingItems() or {}
	for position, itemID in ipairs(list) do
		if not scanned[itemID] then
			if not ns.Client:CanQueryAuction() then
				return nil, "auction_busy"
			end
			local name = ns.Client:GetItemName(itemID)
			if not name then
				return nil, "loading"
			end
			ns.Client:QueryAuction(name)
			scanned[itemID] = true
			Log.Debug("auction scan " .. itemID)
			return itemID, position, #list
		end
	end
	return nil, "scan_done"
end

if ns.Client then
	-- The open flags keep a second "opened" event (without "closed" in between) from adding
	-- the handler twice.
	Events.OnSignal("MERCHANT_OPENED", function()
		if not merchantOpen then
			merchantOpen = true
			Events.OnSignal("MERCHANT_CHANGED", captureMerchant)
		end
		captureMerchant()
	end)
	Events.OnSignal("MERCHANT_CLOSED", function()
		merchantOpen = false
		Events.OffSignal("MERCHANT_CHANGED", captureMerchant)
	end)
	Events.OnSignal("AUCTION_OPENED", function()
		if not auctionOpen then
			auctionOpen = true
			Events.OnSignal("AUCTION_RESULTS", captureAuction)
		end
		for itemID in pairs(scanned) do
			scanned[itemID] = nil
		end
		Events.Emit("PRICES_CHANGED")
	end)
	Events.OnSignal("AUCTION_CLOSED", function()
		auctionOpen = false
		Events.OffSignal("AUCTION_RESULTS", captureAuction)
		Events.Emit("PRICES_CHANGED")
	end)
	-- Old captured prices are removed after login (setting priceKeepDays), not during loading.
	Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(PriceCapture.PRUNE_DELAY_SECONDS, PriceCapture.PruneOld)
	end)
end
