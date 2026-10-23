-- Own auction results from the mailbox: per item how many of the player's auctions sold, expired or
-- were cancelled, and what the sales brought. The base of the sale chance (Core/SaleEstimate.lua).
-- Mails stay in the inbox until taken, so each mail is counted once: its signature (subject, money
-- and the moment it expires, which does not change while it waits) is remembered until it is gone.
-- Pure logic on db.salesLog = { [realmKey] = { items = { [itemID] = { sold, expired, cancelled,
-- soldCopper, lastAt } }, seen = { [signature] = expiresAt } } }.
local _, ns = ...

local SalesLog = {}
ns.SalesLog = SalesLog

local SECONDS_PER_DAY = 86400
-- Expiry times are rounded to this, so the same mail gives the same signature on every visit.
local SIGNATURE_STEP = 600
local COUNTERS = { SOLD = "sold", EXPIRED = "expired", CANCELLED = "cancelled" }

local function signature(mail, now)
	local expiresAt = math.floor((now + mail.daysLeft * SECONDS_PER_DAY) / SIGNATURE_STEP)
	return table.concat({ mail.subject, mail.money, expiresAt }, "|"), expiresAt * SIGNATURE_STEP
end

local function realmLog(db, realmKey)
	local log = db.salesLog[realmKey]
	if not log then
		log = { items = {}, seen = {} }
		db.salesLog[realmKey] = log
	end
	return log
end

local function count(log, mail, now)
	local item = log.items[mail.itemID] or { sold = 0, expired = 0, cancelled = 0, soldCopper = 0, lastAt = 0 }
	log.items[mail.itemID] = item
	local field = COUNTERS[mail.kind]
	item[field] = item[field] + 1
	if mail.kind == "SOLD" then
		item.soldCopper = item.soldCopper + mail.money
	end
	item.lastAt = now
end

-- Counts the auction mails ({ kind, itemID?, money, daysLeft, subject }) not seen before. Returns the
-- number of new results.
function SalesLog.Record(db, realmKey, mails, now)
	local log, added = realmLog(db, realmKey), 0
	for _, mail in ipairs(mails) do
		local key, expiresAt = signature(mail, now)
		if mail.itemID and COUNTERS[mail.kind] and not log.seen[key] then
			log.seen[key] = expiresAt
			count(log, mail, now)
			added = added + 1
		end
	end
	for key, expiresAt in pairs(log.seen) do
		if expiresAt < now then
			log.seen[key] = nil
		end
	end
	return added
end

-- The player's results for an item: { sold, expired, cancelled, soldCopper, lastAt }, or nil.
function SalesLog.Get(db, realmKey, itemID)
	local log = realmKey and db.salesLog[realmKey]
	return log and log.items[itemID]
end

local function validItem(item)
	return type(item) == "table" and type(item.sold) == "number" and type(item.expired) == "number"
		and type(item.cancelled) == "number" and type(item.soldCopper) == "number" and type(item.lastAt) == "number"
end

local function sanitizeLog(realmKey, log, repairs)
	if type(log.items) ~= "table" or type(log.seen) ~= "table" then
		log.items, log.seen = {}, {}
		repairs[#repairs + 1] = "salesLog." .. tostring(realmKey)
	end
	for itemID, item in pairs(log.items) do
		if type(itemID) ~= "number" or not validItem(item) then
			log.items[itemID] = nil
			repairs[#repairs + 1] = "salesLog." .. tostring(realmKey)
		end
	end
end

-- Validation (registered with DB.ROOT_VALIDATORS): broken realms and items are dropped.
function SalesLog.Sanitize(db, repairs)
	for realmKey, log in pairs(db.salesLog) do
		if type(log) ~= "table" then
			db.salesLog[realmKey] = nil
			repairs[#repairs + 1] = "salesLog"
		else
			sanitizeLog(realmKey, log, repairs)
		end
	end
end

ns.DB.ROOT_VALIDATORS[#ns.DB.ROOT_VALIDATORS + 1] = SalesLog.Sanitize

-- At the mailbox: count new auction results of the current character's realm and faction.
local function capture()
	local realmKey = ns.PriceCapture.CurrentRealmKey()
	if not (ns.db and not ns.readOnly and realmKey and ns.Stock.IsMailOpen()) then
		return
	end
	if SalesLog.Record(ns.db, realmKey, ns.Client:ReadAuctionMails(), ns.Client:GetServerTime()) > 0 then
		ns.Events.Emit("PRICES_CHANGED")
	end
end

if ns.Client then
	ns.Events.OnSignal("MAIL_CHANGED", capture)
end
