-- Stock: live bag and bank counts of the current character, and stored snapshots of every item in the
-- bags and the bank of every character, so other characters' stock is known without asking the player.
-- The live bank count is correct with a closed bank (confirmed in game, Classic Era 70003); the bank's
-- contents can only be listed while it is open, so a character's bank snapshot needs one bank visit.
-- Items and gold attached to received mail are stored at every mailbox visit (MAIL_CHANGED).
local _, ns = ...

local Log = ns.Log

local Stock = {}
ns.Stock = Stock

-- After login, the bags are captured once this many seconds later (the bag data may not be loaded
-- at login), so a character that only logs in is known to the others too.
Stock.LOGIN_DELAY_SECONDS = 10

local bankOpen = false
local mailOpen = false
-- Items seen in the bags while the bank is open: candidates for deposits, recounted on close.
local seenAtBank = {}

function Stock.IsBankOpen()
	return bankOpen
end

-- "Name-NormalizedRealm" -> name, realm. Normalized realm names contain no hyphens.
function Stock.SplitKey(key)
	local name, realm = tostring(key):match("^([^-]+)%-(.+)$")
	return name, realm
end

local function mailCount(charData, itemID)
	return charData and charData.stock.mail[itemID] or 0
end

-- Keys of the current character (first) and the characters of its realm and faction, by name.
function Stock.SameRealmAndFaction(charData)
	local _, realm = Stock.SplitKey(ns.charKey)
	local keys = {}
	for key, other in pairs(ns.db.characters) do
		local _, otherRealm = Stock.SplitKey(key)
		if key == ns.charKey or (otherRealm == realm and other.faction == charData.faction and charData.faction ~= "") then
			keys[#keys + 1] = key
		end
	end
	table.sort(keys, function(a, b)
		if (a == ns.charKey) ~= (b == ns.charKey) then
			return a == ns.charKey
		end
		return a < b
	end)
	return keys
end

-- Counts of the current character: bags (number) and bank (number, or nil) live, mail (number)
-- from the last mailbox visit.
function Stock.Count(itemID)
	local client = ns.Client
	local bags = client:GetBagCount(itemID) or 0
	local total = client:GetBagAndBankCount(itemID)
	local bank = total and math.max(0, total - bags) or nil
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	return bags, bank, mailCount(charData, itemID)
end

-- Units of an item in a stored snapshot (bags + bank + mail) of any character.
function Stock.SnapshotCount(charData, itemID)
	local stock = charData.stock
	return (stock.bags[itemID] or 0) + (stock.bank[itemID] or 0) + (stock.mail[itemID] or 0)
end

local function noteSeen(bags)
	for itemID in pairs(bags) do
		seenAtBank[itemID] = true
	end
end

-- Snapshot of every item in the bags (a full scan, stored in place, no new table per bag event). While
-- the bank is open, the bank is scanned too.
function Stock.CaptureBags(charData, now)
	ns.Client:ScanBags(charData.stock.bags)
	charData.stock.bagsAt = now
	if bankOpen then
		noteSeen(charData.stock.bags)
		ns.Client:ScanBank(charData.stock.bank)
		charData.stock.bankAt = now
	end
end

-- On closing the bank: recount the bank snapshot's items and everything seen in the bags meanwhile
-- from the live counts (correct with a closed bank), in case the last container scan missed a change.
function Stock.CaptureBankClosed(charData, now)
	local bank = charData.stock.bank
	for itemID in pairs(bank) do
		seenAtBank[itemID] = true
	end
	for itemID in pairs(seenAtBank) do
		local _, count = Stock.Count(itemID)
		bank[itemID] = count and count > 0 and count or nil
		seenAtBank[itemID] = nil
	end
	charData.stock.bankAt = now
end

-- Other characters on the same realm that have a snapshot with this item.
-- Returns counted (sum over characters of the same faction) and rows sorted by name:
-- { key, name, bags, bank, mail, total, at, sameFaction }. Characters with 0 are left out.
-- Row for one other character's snapshot of the item, or nil if it has none (or 0).
local function otherRow(key, name, data, currentFaction, itemID)
	local bags = data.stock.bags[itemID]
	local bank = data.stock.bank[itemID]
	local mail = data.stock.mail[itemID]
	local total = Stock.SnapshotCount(data, itemID)
	if total <= 0 then
		return nil
	end
	return {
		key = key,
		name = name,
		bags = bags or 0,
		bank = bank or 0,
		mail = mail or 0,
		total = total,
		at = math.max(data.stock.bagsAt, data.stock.bankAt, data.stock.mailAt),
		sameFaction = currentFaction ~= "" and data.faction == currentFaction,
	}
end

local function byName(a, b)
	return a.name < b.name
end

function Stock.OthersFor(db, currentKey, currentFaction, itemID)
	local _, realm = Stock.SplitKey(currentKey)
	local rows, counted = {}, 0
	for key, data in pairs(db.characters) do
		local name, otherRealm = Stock.SplitKey(key)
		local row = key ~= currentKey and otherRealm == realm and otherRow(key, name, data, currentFaction, itemID)
		if row then
			rows[#rows + 1] = row
			if row.sameFaction then
				counted = counted + row.total
			end
		end
	end
	table.sort(rows, byName)
	return counted, rows
end

-- Counted stock of other characters, or 0 and no rows when counting is switched off.
local function othersOf(charData, itemID)
	if not ns.db.settings.countOtherCharacters then
		return 0, {}
	end
	return Stock.OthersFor(ns.db, ns.charKey, charData.faction, itemID)
end

-- Stock rows of requirements ({ { itemID, need } }, e.g. WantPlan.Requirements) for the current
-- character: { itemID, need, bags, bank (nil = unknown), mail, others (counted), details (OthersFor
-- rows), missing }.
function Stock.Rows(charData, requirements)
	local rows = {}
	for i, req in ipairs(requirements) do
		local bags, bank, mail = Stock.Count(req.itemID)
		local others, details = othersOf(charData, req.itemID)
		rows[i] = { itemID = req.itemID, need = req.need, bags = bags, bank = bank, mail = mail, others = others,
			details = details, missing = math.max(0, req.need - bags - (bank or 0) - mail - others) }
	end
	return rows
end

-- Validation of stored snapshots (registered with DB.VALIDATORS).
local function cleanCounts(counts)
	local changed = false
	for itemID, count in pairs(counts) do
		local okKey = type(itemID) == "number" and itemID >= 1 and itemID == math.floor(itemID)
		local okValue = type(count) == "number" and count >= 0 and count == math.floor(count)
		if not (okKey and okValue) then
			counts[itemID] = nil
			changed = true
		end
	end
	return changed
end

function Stock.Sanitize(charData, path, repairs)
	if cleanCounts(charData.stock.bags) then
		repairs[#repairs + 1] = path .. ".stock.bags"
	end
	if cleanCounts(charData.stock.bank) then
		repairs[#repairs + 1] = path .. ".stock.bank"
	end
	if cleanCounts(charData.stock.mail) then
		repairs[#repairs + 1] = path .. ".stock.mail"
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Stock.Sanitize

-- Snapshot of the current character ---------------------------------------------------

local function currentCharacter()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey]
end

-- Stores the current character's bags (and the bank while open). Only call it while bag data is
-- loaded (after a bag change, at the bank, or on a user command).
function Stock.CaptureCurrent(reason)
	local charData = currentCharacter()
	if not charData then
		return
	end
	Stock.CaptureBags(charData, ns.Client:GetServerTime())
	if Log.IsDebug() then
		Log.Trace("stock snapshot (" .. reason .. ")")
	end
end

-- Stores the items and gold attached to the current character's received mail.
function Stock.CaptureMail()
	local charData = currentCharacter()
	if not charData then
		return
	end
	local _, money = ns.Client:ScanMail(charData.stock.mail)
	charData.stock.mailMoney = money
	charData.stock.mailAt = ns.Client:GetServerTime()
end

-- The delayed login capture: an empty scan does not replace a stored snapshot with items, in case the
-- bag data is still missing then.
local function captureAfterLogin()
	local charData = currentCharacter()
	if not charData then
		return
	end
	local scanned = ns.Client:ScanBags({})
	if next(scanned) == nil and next(charData.stock.bags) ~= nil then
		return
	end
	Stock.CaptureCurrent("login")
end

if ns.Client then
	-- Not at login itself (bag data may not be loaded yet) and not on PLAYER_LOGOUT: in game the
	-- counts were already 0 there (Classic Era 70003) and overwrote good snapshots.
	ns.Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(Stock.LOGIN_DELAY_SECONDS, captureAfterLogin)
	end)
	ns.Events.OnSignal("BAGS_CHANGED", function()
		Stock.CaptureCurrent("bags")
	end)
	ns.Events.OnSignal("BANK_OPENED", function()
		bankOpen = true
		Stock.CaptureCurrent("bank opened")
	end)
	ns.Events.OnSignal("MAIL_OPENED", function()
		mailOpen = true
	end)
	ns.Events.OnSignal("MAIL_CLOSED", function()
		mailOpen = false
	end)
	-- Inbox updates outside the mailbox (new mail notices) carry no readable inbox.
	ns.Events.OnSignal("MAIL_CHANGED", function()
		if mailOpen then
			Stock.CaptureMail()
		end
	end)
	ns.Events.OnSignal("BANK_CLOSED", function()
		local charData = bankOpen and currentCharacter()
		bankOpen = false
		if charData then
			Stock.CaptureBankClosed(charData, ns.Client:GetServerTime())
		end
	end)
end
