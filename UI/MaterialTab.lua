-- Material tab of the main window: the selected goal (or all goals) with need, bag, bank and
-- other characters' stock and the missing amount per item, plus recipe import.
-- Events are registered only while the window is shown (Activate/Deactivate). Bursts of item
-- loads are coalesced into one refresh on the next frame. Widgets: UI/MaterialTabLayout.lua.
local _, ns = ...

local L = ns.L
local Materials = ns.Materials
local Recipes = ns.Recipes
local Stock = ns.Stock
local UIShared = ns.UIShared
local Prices = ns.Prices
local Money = ns.Money
local PriceCapture = ns.PriceCapture
local Layout = ns.MaterialTabLayout

local MaterialTab = {}
ns.MaterialTab = MaterialTab

local VISIBLE_ROWS = Layout.VISIBLE_ROWS
local Widgets = ns.Widgets
local COLOR_MISSING = Widgets.COLOR_MISSING
local COLOR_DONE = Widgets.COLOR_DONE
local COLOR_NORMAL = Widgets.COLOR_NORMAL
local REFRESH_SIGNALS = { "BAGS_CHANGED", "BANK_OPENED", "BANK_CLOSED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED" }
local COLOR_OUTDATED = Widgets.COLOR_GRAY

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local setEnabled = Widgets.SetEnabled
local function currentCharacter()
	return ns.db and ns.charKey and ns.db.characters[ns.charKey]
end

local function canWrite()
	return ns.db ~= nil and not ns.readOnly
end

function MaterialTab.Create(parent)
	local tab = setmetatable({ offset = 0, data = {}, rows = {} }, Tab)
	Layout.Build(tab, parent)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

-- Adds the planning price (Prices.Best) and the tooltip lines of all price sources to each row.
local function addPrices(rows)
	local realmKey = PriceCapture.CurrentRealmKey()
	local now = ns.Client:GetServerTime()
	local maxAge = ns.db.settings.priceMaxAgeDays
	for _, row in ipairs(rows) do
		row.price, _, _, row.priceOutdated = Prices.Best(ns.db, realmKey, row.itemID, now, maxAge)
		row.priceLines = {}
		local item = Prices.Get(ns.db, realmKey, row.itemID)
		for _, source in ipairs(Prices.SOURCE_ORDER) do
			if item and item[source] then
				row.priceLines[#row.priceLines + 1] = UIShared.DescribePrice(source, item[source], now)
			end
		end
	end
end

function Tab:Refresh()
	local charData = currentCharacter()
	if not charData then
		self:ShowEmpty("", L.NOT_READY)
		return
	end
	local goals, headerText, emptyText = UIShared.GoalSelection(charData)
	local all = ns.db.settings.window.allGoals
	self.allGoals:SetChecked(all)
	local hasGoals = #Materials.ListGoalIDs(charData) > 0
	setEnabled(self.prev, hasGoals and not all and canWrite())
	setEnabled(self.next, hasGoals and not all and canWrite())
	setEnabled(self.allGoals, canWrite())
	setEnabled(self.import, canWrite())
	setEnabled(self.scan, canWrite() and PriceCapture.IsAuctionOpen())
	if not goals then
		self:ShowEmpty(headerText, emptyText)
		return
	end
	self.data = Stock.Rows(charData, goals)
	addPrices(self.data)
	self.goalText:SetText(headerText)
	if #self.data == 0 then
		self:ShowEmpty(headerText, L.STOCK_EMPTY)
		return
	end
	self.emptyText:SetText("")
	self:Scroll(0)
end

function Tab:ShowEmpty(headerText, text)
	self.data = {}
	self.goalText:SetText(headerText)
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

local setNumber = Widgets.SetText

function Tab:DrawRow(row, data)
	row.data = data
	if not data then
		row:Hide()
		return
	end
	row.icon:SetTexture(ns.Client:GetItemIcon(data.itemID))
	row.name:SetText(UIShared.ItemText(data.itemID))
	local countOthers = ns.db.settings.countOtherCharacters
	setNumber(row.numbers.need, tostring(data.need), COLOR_NORMAL)
	setNumber(row.numbers.bags, tostring(data.bags), COLOR_NORMAL)
	setNumber(row.numbers.bank, data.bank and tostring(data.bank) or L.UNKNOWN_SHORT, COLOR_NORMAL)
	setNumber(row.numbers.others, countOthers and tostring(data.others) or L.WINDOW_OFF, COLOR_NORMAL)
	setNumber(row.numbers.missing, tostring(data.missing), data.missing > 0 and COLOR_MISSING or COLOR_DONE)
	if data.price then
		setNumber(row.numbers.price, Money.Format(data.price), data.priceOutdated and COLOR_OUTDATED or COLOR_NORMAL)
	else
		setNumber(row.numbers.price, L.WINDOW_OFF, COLOR_OUTDATED)
	end
	row:Show()
end

-- Actions -------------------------------------------------------------------------------

-- Selects the previous (-1) or next (1) goal, wrapping around.
function Tab:StepGoal(step)
	local charData = currentCharacter()
	if not (charData and canWrite()) then
		return
	end
	local ids = Materials.ListGoalIDs(charData)
	if #ids == 0 then
		return
	end
	local current = 0
	for i, id in ipairs(ids) do
		if id == charData.activeGoalID then
			current = i
		end
	end
	local nextIndex = (current - 1 + step) % #ids + 1
	if current == 0 then
		nextIndex = step > 0 and 1 or #ids
	end
	Materials.SelectGoal(charData, ids[nextIndex])
	self.offset = 0
	self:Refresh()
end

function Tab:SetAllGoals(all)
	if not canWrite() then
		self:Refresh()
		return
	end
	ns.db.settings.window.allGoals = all
	self.offset = 0
	self:Refresh()
end

function Tab:ImportRecipe()
	local charData = currentCharacter()
	if not (charData and canWrite()) then
		return
	end
	local id, err = Recipes.ImportSelected(charData, 1)
	if id then
		UIShared.PrintRecipeGoal(charData, id)
		ns.db.settings.window.allGoals = false
	else
		UIShared.PrintError(err)
	end
	self.offset = 0
	self:Refresh()
end

function Tab:ScanAuction()
	ns.PriceCommands.Scan()
end
