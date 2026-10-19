-- Material tab of the main window: the selected goal (or all goals) with count per craft, need,
-- bag, bank and other characters' stock, missing amount and price per item. Everything can be
-- edited in place (UI/MaterialTabActions.lua): goal name, crafts, counts, prices, adding items by
-- drag and drop, recipe import with a count, new and deleted goals.
-- Events are registered only while the window is shown (Activate/Deactivate). Bursts of item
-- loads are coalesced into one refresh on the next frame. Widgets: UI/MaterialTabLayout.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Materials = ns.Materials
local Stock = ns.Stock
local UIShared = ns.UIShared
local Prices = ns.Prices
local Money = ns.Money
local PriceCapture = ns.PriceCapture
local Inputs = ns.Inputs
local Layout = ns.MaterialTabLayout

local MaterialTab = {}
ns.MaterialTab = MaterialTab

local VISIBLE_ROWS = Layout.VISIBLE_ROWS
local Widgets = ns.Widgets
local COLOR_MISSING = Widgets.COLOR_MISSING
local COLOR_DONE = Widgets.COLOR_DONE
local COLOR_NORMAL = Widgets.COLOR_NORMAL
local COLOR_OUTDATED = Widgets.COLOR_GRAY
local REFRESH_SIGNALS = { "BAGS_CHANGED", "BANK_OPENED", "BANK_CLOSED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED" }
MaterialTab.DEFAULT_COUNT = "1"
local DEFAULT_COUNT = MaterialTab.DEFAULT_COUNT

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)
-- The actions (buttons and boxes) are added by UI/MaterialTabActions.lua.
MaterialTab.Tab = Tab

local setEnabled = Widgets.SetEnabled
local setNumber = Widgets.SetText

local function currentCharacter()
	return ns.db and ns.charKey and ns.db.characters[ns.charKey]
end

local function canWrite()
	return ns.db ~= nil and not ns.readOnly
end

local setShown = Widgets.SetShown

function MaterialTab.Create(parent)
	local tab = setmetatable({ offset = 0, data = {}, rows = {} }, Tab)
	Layout.Build(tab, parent)
	Inputs.SetValue(tab.addCount, DEFAULT_COUNT)
	Inputs.SetValue(tab.importCount, DEFAULT_COUNT)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

-- Adds the planning price (Prices.Best), the own price and the tooltip lines of all price sources.
local function addPrices(rows)
	local realmKey = PriceCapture.CurrentRealmKey()
	local now = ns.Client:GetServerTime()
	local maxAge = ns.db.settings.priceMaxAgeDays
	for _, row in ipairs(rows) do
		local external = PriceCapture.External(row.itemID, now)
		row.price, _, _, row.priceOutdated = Prices.Best(ns.db, realmKey, row.itemID, now, maxAge, external)
		row.priceLines = {}
		local item = Prices.Get(ns.db, realmKey, row.itemID)
		row.manualPrice = item and item.MANUAL and item.MANUAL.copper
		for _, source in ipairs(Prices.SOURCE_ORDER) do
			if item and item[source] then
				row.priceLines[#row.priceLines + 1] = UIShared.DescribePrice(source, item[source], now)
			end
		end
		for source, record in pairs(external or {}) do
			row.priceLines[#row.priceLines + 1] = UIShared.DescribePrice(source, record, now)
		end
	end
end

-- Count per craft of each item of the selected goal ({ [itemID] = count }); nil for "all goals",
-- where the rows merge several goals and cannot be edited.
local function perCraftCounts(goals)
	if ns.db.settings.window.allGoals then
		return nil
	end
	local counts = {}
	for _, entry in ipairs(goals[1].items) do
		counts[entry.itemID] = entry.count
	end
	return counts
end

-- Goal line: name and crafts boxes only for a single selected goal.
function Tab:UpdateGoalLine(charData, headerText)
	local goal, id = Materials.GetActiveGoal(charData)
	local single = goal ~= nil and not ns.db.settings.window.allGoals
	self.goalID = single and id or nil
	self.goalText:SetText(single and Util.Format(L.MATERIAL_GOAL_POSITION, self:GoalPosition(charData, id)) or headerText)
	setShown(self.nameBox, single)
	setShown(self.craftsLabel, single)
	setShown(self.craftsBox, single)
	if single then
		Inputs.SetValue(self.nameBox, UIShared.GoalPlainName(goal))
		Inputs.SetValue(self.craftsBox, tostring(goal.crafts))
	end
	setEnabled(self.deleteGoal, single and canWrite())
	setEnabled(self.newGoal, canWrite())
end

function Tab:GoalPosition(charData, id)
	local ids = Materials.ListGoalIDs(charData)
	for i, goalID in ipairs(ids) do
		if goalID == id then
			return i, #ids
		end
	end
	return 0, #ids
end

function Tab:UpdateControls(charData)
	local all = ns.db.settings.window.allGoals
	local hasGoals = #Materials.ListGoalIDs(charData) > 0
	self.allGoals:SetChecked(all)
	self.countOthers:SetChecked(ns.db.settings.countOtherCharacters)
	setEnabled(self.prev, hasGoals and not all and canWrite())
	setEnabled(self.next, hasGoals and not all and canWrite())
	setEnabled(self.allGoals, canWrite())
	setEnabled(self.countOthers, canWrite())
	setEnabled(self.import, canWrite())
	setEnabled(self.add, canWrite() and self.pendingItemID ~= nil)
	setEnabled(self.scan, canWrite() and PriceCapture.IsAuctionOpen())
end

function Tab:Refresh()
	local charData = currentCharacter()
	if not charData then
		self:ShowEmpty("", L.NOT_READY)
		return
	end
	local goals, headerText, emptyText = UIShared.GoalSelection(charData)
	self:UpdateControls(charData)
	self:UpdateGoalLine(charData, headerText)
	if not goals then
		self:ShowEmpty(headerText, emptyText)
		return
	end
	self.counts = perCraftCounts(goals)
	self.data = Stock.Rows(charData, goals)
	addPrices(self.data)
	if #self.data == 0 then
		self:ShowEmpty(nil, L.MATERIAL_EMPTY_GOAL)
		return
	end
	self.emptyText:SetText("")
	self:Scroll(0)
end

function Tab:ShowEmpty(headerText, text)
	self.data = {}
	if headerText then
		self.goalText:SetText(headerText)
	end
	self.emptyText:SetText(text)
	self:Scroll(0)
end

-- Moves the visible part of the list by delta rows and redraws it.
function Tab:Scroll(delta)
	local maxOffset = math.max(0, #self.data - VISIBLE_ROWS)
	self.offset = math.min(maxOffset, math.max(0, self.offset + delta))
	for i, row in ipairs(self.rows) do
		self:DrawRow(row, self.data[self.offset + i])
	end
end

local function drawPrice(row, data)
	if data.price then
		setNumber(row.numbers.price, Money.Format(data.price), data.priceOutdated and COLOR_OUTDATED or COLOR_NORMAL)
	else
		setNumber(row.numbers.price, L.WINDOW_OFF, COLOR_OUTDATED)
	end
end

function Tab:DrawRow(row, data)
	row.data = data
	if not data then
		row:Hide()
		return
	end
	row.icon:SetTexture(ns.Client:GetItemIcon(data.itemID))
	row.name:SetText(UIShared.ItemText(data.itemID))
	local editable = self.counts ~= nil and canWrite()
	setShown(row.countBox, editable)
	setShown(row.remove, editable)
	setNumber(row.numbers.perCraft, editable and "" or L.WINDOW_OFF, COLOR_NORMAL)
	if editable then
		Inputs.SetValue(row.countBox, tostring(self.counts[data.itemID] or 0))
	end
	local countOthers = ns.db.settings.countOtherCharacters
	setNumber(row.numbers.need, tostring(data.need), COLOR_NORMAL)
	setNumber(row.numbers.bags, tostring(data.bags), COLOR_NORMAL)
	setNumber(row.numbers.bank, data.bank and tostring(data.bank) or L.UNKNOWN_SHORT, COLOR_NORMAL)
	setNumber(row.numbers.others, countOthers and tostring(data.others) or L.WINDOW_OFF, COLOR_NORMAL)
	setNumber(row.numbers.missing, tostring(data.missing), data.missing > 0 and COLOR_MISSING or COLOR_DONE)
	drawPrice(row, data)
	row:Show()
end
