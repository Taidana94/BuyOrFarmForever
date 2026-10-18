-- /bof price: show the prices of the selected goal's items, set or clear an own price, and
-- scan the auction house for missing materials.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Prices = ns.Prices
local PriceCapture = ns.PriceCapture
local Materials = ns.Materials
local Slash = ns.Slash
local UIShared = ns.UIShared

local PriceCommands = {}
ns.PriceCommands = PriceCommands

local function describeItem(realmKey, itemID, now)
	local item = Prices.Get(ns.db, realmKey, itemID)
	if not item then
		return L.PRICE_NONE
	end
	local parts = {}
	for _, source in ipairs(Prices.SOURCE_ORDER) do
		if item[source] then
			parts[#parts + 1] = UIShared.DescribePrice(source, item[source], now)
		end
	end
	return table.concat(parts, L.PRICE_SEPARATOR)
end

local function listPrices(charData, realmKey)
	local goal = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	if #goal.items == 0 then
		Log.Print(L.STOCK_EMPTY)
		return
	end
	local now = ns.Client:GetServerTime()
	for _, entry in ipairs(goal.items) do
		Log.Print(Util.Format(L.PRICE_LINE, UIShared.ItemText(entry.itemID), describeItem(realmKey, entry.itemID, now)))
	end
end

local function setPrice(realmKey, itemID, rest)
	if string.lower(rest) == "clear" then
		local cleared = Prices.Clear(ns.db, realmKey, itemID, "MANUAL")
		Log.Print(Util.Format(cleared and L.PRICE_CLEARED or L.PRICE_NOTHING_TO_CLEAR, UIShared.ItemText(itemID)))
		return
	end
	local copper, err = Money.Parse(rest)
	local stored = false
	if copper then
		stored, err = Prices.Set(ns.db, realmKey, itemID, "MANUAL", copper, ns.Client:GetServerTime())
	end
	if not stored then
		UIShared.PrintError(err)
		return
	end
	Log.Print(Util.Format(L.PRICE_SET, UIShared.ItemText(itemID), Money.Format(copper)))
end

-- Scans the next missing material (also used by the window button). Prints the result.
function PriceCommands.Scan()
	local itemID, positionOrError, total = PriceCapture.ScanNext()
	if not itemID then
		UIShared.PrintError(positionOrError)
		return
	end
	Log.Print(Util.Format(L.SCAN_SENT, UIShared.ItemText(itemID), positionOrError, total))
end

local function priceCommand(argument)
	local sub = Slash.SplitCommand(argument)
	if sub == "scan" then
		PriceCommands.Scan()
		return
	end
	local charData
	if argument == "" then
		charData = UIShared.Character()
	else
		charData = UIShared.WritableCharacter()
	end
	if not charData then
		return
	end
	local realmKey = PriceCapture.CurrentRealmKey()
	if not realmKey then
		Log.Print(L.NOT_READY)
		return
	end
	if argument == "" then
		listPrices(charData, realmKey)
		return
	end
	local itemID, rest = Util.ParseItemArg(argument)
	if not (itemID and Materials.IsValidItemID(itemID)) then
		Log.Print(L.PRICE_USAGE)
		return
	end
	setPrice(realmKey, itemID, rest)
end

if ns.Client then
	Slash.AddCommand("price", priceCommand, L.HELP_LINE_PRICE)
end
