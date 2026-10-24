-- /gc shop: the AH shopping list of the running plan ("Jetzt tun"; without one the gold plan of an
-- hour) and the wants. Printed in the chat; with Auctionator also created as its shopping list, which
-- it searches at the auction house (tab "Einkaufen").
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log
local UIShared = ns.UIShared

local ShopCommand = {}
ns.ShopCommand = ShopCommand

local HOUR = 3600

local function planSteps(charData)
	if charData.activePlan then
		return charData.activePlan.steps
	end
	return ns.GoldPlanCommands.Plan(charData, HOUR).steps
end

-- The current list ({ { itemID, units } }).
function ShopCommand.List(charData)
	local wants = ns.WantPlan.Current()
	return ns.ShoppingList.Collect(planSteps(charData), wants and ns.WantPlan.ToGet(wants) or {})
end

local function sendToAuctionator(list)
	if not ns.Client:HasExternalPrices() then
		return
	end
	local entries = {}
	for _, entry in ipairs(list) do
		local name = ns.Client:GetItemName(entry.itemID)
		entries[#entries + 1] = name and { name = name, units = entry.units } or nil
	end
	local ok, err = ns.Client:CreateShoppingList(L.SHOP_LIST_NAME, entries)
	if ok then
		Log.Print(Util.Format(L.SHOP_AUCTIONATOR, L.SHOP_LIST_NAME))
	else
		Log.Debug("Auctionator shopping list failed: " .. tostring(err))
	end
end

function ShopCommand.Run()
	local charData = UIShared.Character()
	if not charData then
		return
	end
	local list = ShopCommand.List(charData)
	if #list == 0 then
		Log.Print(L.SHOP_EMPTY)
		return
	end
	Log.Print(L.SHOP_HEADER)
	for _, entry in ipairs(list) do
		Log.Print(Util.Format(L.SHOP_LINE, entry.units, UIShared.ItemText(entry.itemID)))
	end
	sendToAuctionator(list)
end

if ns.Client then
	ns.Slash.AddCommand("shop", ShopCommand.Run, "HELP_LINE_SHOP")
end
