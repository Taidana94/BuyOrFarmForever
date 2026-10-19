-- Actions of advisor cards, always started by a click and confirmed first where gold or items
-- change hands: sell the suggested bag items to the open merchant, buy missing goal materials from
-- it, scan auction prices, open the gold planner or the gold buffer. Selling goes in small batches, because the
-- server rejects many sales in one moment; each batch re-checks that the merchant is still open
-- and that every slot still holds the expected item (Client:SellStack).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Inputs = ns.Inputs

local AdvisorActions = {}
ns.AdvisorActions = AdvisorActions

AdvisorActions.SELL_BATCH = 6
AdvisorActions.SELL_DELAY_SECONDS = 0.3

-- Stacks of the bags that the vendor task of the suggestion contains (re-read now).
local function stacksToSell(suggestion)
	local list = {}
	for _, stack in ipairs(ns.Client:ListBagStacks()) do
		if suggestion.items[stack.itemID] then
			list[#list + 1] = stack
		end
	end
	return list
end

local function sellBatch(stacks, from, sold)
	if ns.Advisor.Context() ~= "MERCHANT" then
		Log.Print(Util.Format(L.ADVISOR_SELL_STOPPED, sold))
		return
	end
	local last = math.min(#stacks, from + AdvisorActions.SELL_BATCH - 1)
	for i = from, last do
		if ns.Client:SellStack(stacks[i].bag, stacks[i].slot, stacks[i].itemID) then
			sold = sold + 1
		end
	end
	if last < #stacks then
		C_Timer.After(AdvisorActions.SELL_DELAY_SECONDS, function()
			sellBatch(stacks, last + 1, sold)
		end)
		return
	end
	Log.Print(Util.Format(L.ADVISOR_SOLD, sold))
end

local function sell(suggestion)
	local stacks = stacksToSell(suggestion)
	Inputs.Confirm(Util.Format(L.ADVISOR_SELL_CONFIRM, #stacks, Money.Format(suggestion.sure)), function()
		sellBatch(stacks, 1, 0)
	end)
end

local function buy(suggestion)
	local text = Util.Format(L.ADVISOR_BUY_CONFIRM, suggestion.count, ns.UIShared.ItemText(suggestion.itemID),
		Money.Format(suggestion.cost))
	Inputs.Confirm(text, function()
		local bought = ns.Client:BuyFromMerchant(suggestion.itemID, suggestion.count)
		Log.Print(Util.Format(L.ADVISOR_BOUGHT, bought, ns.UIShared.ItemText(suggestion.itemID)))
	end)
end

-- Opens the gold buffer tab in a view ("BUFFER" or "PLANNER").
local function openGold(mode)
	ns.MainWindow.Show()
	ns.MainWindow.SelectTab("GOLD_BUFFER")
	local frame = ns.MainWindow.GetFrame()
	if frame then
		frame.gold:SetMode(mode)
	end
end

local ACTIONS = {
	SELL_VENDOR = sell,
	BUY_MERCHANT = buy,
	SCAN = function()
		Inputs.Run("price scan")
	end,
	OPEN_PLANNER = function()
		openGold("PLANNER")
	end,
	OPEN_SAVINGS = function()
		openGold("BUFFER")
	end,
}

-- Runs the action of a suggestion (button click).
function AdvisorActions.Run(suggestion)
	local action = suggestion and ACTIONS[suggestion.action]
	if action then
		action(suggestion)
	end
end
