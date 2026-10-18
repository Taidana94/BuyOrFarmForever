-- Stock of the current character: bag and bank counts per item, plus a bank snapshot that is
-- taken while the bank is open. The live bank count is correct with a closed bank (confirmed in
-- game, Classic Era 70003); the snapshot serves as the bank stock of other characters (stage 2b).
local _, ns = ...

local Log = ns.Log

local Stock = {}
ns.Stock = Stock

local bankOpen = false

function Stock.IsBankOpen()
	return bankOpen
end

-- Live counts: bags (number) and bank (number, or nil if the client gives no total).
function Stock.Count(itemID)
	local client = ns.Client
	local bags = client:GetBagCount(itemID) or 0
	local total = client:GetBagAndBankCount(itemID)
	local bank = total and math.max(0, total - bags) or nil
	return bags, bank
end

-- Stores the bank count of the given items in the character's stock snapshot.
function Stock.CaptureBank(charData, itemIDs, now)
	local snapshot = charData.stock.bank
	for _, itemID in ipairs(itemIDs) do
		local _, bank = Stock.Count(itemID)
		if bank then
			snapshot[itemID] = bank
		end
	end
	charData.stock.bankAt = now
end

-- Returns the snapshot count (or nil) and the time it was taken (0 = never).
function Stock.BankSnapshot(charData, itemID)
	return charData.stock.bank[itemID], charData.stock.bankAt
end

local function currentCharacter()
	if ns.db and not ns.readOnly and ns.charKey then
		return ns.db.characters[ns.charKey]
	end
	return nil
end

local function capture()
	local charData = currentCharacter()
	if not charData then
		return
	end
	local ids = ns.Materials.TrackedItemIDs(charData)
	Stock.CaptureBank(charData, ids, ns.Client:GetServerTime())
	Log.Trace("bank snapshot for " .. #ids .. " items")
end

if ns.Client then
	ns.Events.OnSignal("BANK_OPENED", function()
		bankOpen = true
		capture()
	end)
	ns.Events.OnSignal("BAGS_CHANGED", function()
		if bankOpen then
			capture()
		end
	end)
	ns.Events.OnSignal("BANK_CLOSED", function()
		if bankOpen then
			capture()
		end
		bankOpen = false
	end)
end
