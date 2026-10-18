-- Stock: live bag and bank counts of the current character, and stored snapshots of every
-- character for the items used in any goal, so other characters' stock can be shown.
-- The live bank count is correct with a closed bank (confirmed in game, Classic Era 70003).
local _, ns = ...

local Log = ns.Log

local Stock = {}
ns.Stock = Stock

local bankOpen = false

function Stock.IsBankOpen()
	return bankOpen
end

-- "Name-NormalizedRealm" -> name, realm. Normalized realm names contain no hyphens.
function Stock.SplitKey(key)
	local name, realm = tostring(key):match("^([^-]+)%-(.+)$")
	return name, realm
end

-- Live counts of the current character: bags (number) and bank (number, or nil).
function Stock.Count(itemID)
	local client = ns.Client
	local bags = client:GetBagCount(itemID) or 0
	local total = client:GetBagAndBankCount(itemID)
	local bank = total and math.max(0, total - bags) or nil
	return bags, bank
end

-- Stores bag and bank counts of the given items (also zeros, so "0" and "never seen" differ).
-- Items that are no longer tracked are dropped from the snapshot.
function Stock.Capture(charData, itemIDs, now)
	local bags, bank = {}, {}
	for _, itemID in ipairs(itemIDs) do
		local b, k = Stock.Count(itemID)
		bags[itemID] = b
		if k then
			bank[itemID] = k
		end
	end
	charData.stock.bags = bags
	charData.stock.bank = bank
	charData.stock.bagsAt = now
	charData.stock.bankAt = now
end

-- Other characters on the same realm that have a snapshot with this item.
-- Returns counted (sum over characters of the same faction) and rows sorted by name:
-- { key, name, bags, bank, total, at, sameFaction }. Characters with 0 are left out.
function Stock.OthersFor(db, currentKey, currentFaction, itemID)
	local _, realm = Stock.SplitKey(currentKey)
	local rows, counted = {}, 0
	for key, data in pairs(db.characters) do
		local name, otherRealm = Stock.SplitKey(key)
		if key ~= currentKey and otherRealm == realm then
			local bags = data.stock.bags[itemID]
			local bank = data.stock.bank[itemID]
			local total = (bags or 0) + (bank or 0)
			if (bags or bank) and total > 0 then
				local sameFaction = currentFaction ~= "" and data.faction == currentFaction
				rows[#rows + 1] = {
					key = key,
					name = name,
					bags = bags or 0,
					bank = bank or 0,
					total = total,
					at = math.max(data.stock.bagsAt, data.stock.bankAt),
					sameFaction = sameFaction,
				}
				if sameFaction then
					counted = counted + total
				end
			end
		end
	end
	table.sort(rows, function(a, b)
		return a.name < b.name
	end)
	return counted, rows
end

-- Counted stock of other characters, or 0 and no rows when counting is switched off.
local function othersOf(charData, itemID)
	if not ns.db.settings.countOtherCharacters then
		return 0, {}
	end
	return Stock.OthersFor(ns.db, ns.charKey, charData.faction, itemID)
end

-- Requirement rows of the given goals for the current character:
-- { itemID, need, bags, bank (nil = unknown), others (counted), details (OthersFor rows), missing }.
function Stock.Rows(charData, goals)
	local rows = ns.Materials.Shortfall(ns.Materials.Requirements(goals), function(itemID)
		local bags, bank = Stock.Count(itemID)
		return bags + (bank or 0) + (othersOf(charData, itemID))
	end)
	for _, row in ipairs(rows) do
		row.bags, row.bank = Stock.Count(row.itemID)
		row.others, row.details = othersOf(charData, row.itemID)
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
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Stock.Sanitize

-- Snapshot of the current character ---------------------------------------------------

-- Stores the current character's counts of all tracked items. Only call it while bag data is
-- loaded (after a bag change, at the bank, or on a user command).
function Stock.CaptureCurrent(reason)
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return
	end
	local charData = ns.db.characters[ns.charKey]
	if not charData then
		return
	end
	local ids = ns.Materials.TrackedItemIDsAll(ns.db)
	Stock.Capture(charData, ids, ns.Client:GetServerTime())
	Log.Trace("stock snapshot (" .. reason .. ") for " .. #ids .. " items")
end

if ns.Client then
	-- Not on login (bag data may not be loaded yet) and not on PLAYER_LOGOUT: in game the
	-- counts were already 0 there (Classic Era 70003) and overwrote good snapshots.
	ns.Events.OnSignal("BAGS_CHANGED", function()
		Stock.CaptureCurrent("bags")
	end)
	ns.Events.OnSignal("BANK_OPENED", function()
		bankOpen = true
		Stock.CaptureCurrent("bank opened")
	end)
	ns.Events.OnSignal("BANK_CLOSED", function()
		Stock.CaptureCurrent("bank closed")
		bankOpen = false
	end)
end
