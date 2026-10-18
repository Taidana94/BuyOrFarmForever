-- Material tab of the main window: the selected goal (or all goals) with need, bag, bank and
-- other characters' stock and the missing amount per item, plus recipe import.
-- Events are registered only while the window is shown (Activate/Deactivate). Bursts of item
-- loads are coalesced into one refresh on the next frame. Widgets: UI/MaterialTabLayout.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Materials = ns.Materials
local Recipes = ns.Recipes
local Stock = ns.Stock
local Events = ns.Events
local UIShared = ns.UIShared
local Layout = ns.MaterialTabLayout

local MaterialTab = {}
ns.MaterialTab = MaterialTab

local VISIBLE_ROWS = Layout.VISIBLE_ROWS
local COLOR_MISSING = { 1, 0.35, 0.35 }
local COLOR_DONE = { 0.4, 1, 0.4 }
local COLOR_NORMAL = { 1, 1, 1 }
local REFRESH_SIGNALS = { "BAGS_CHANGED", "BANK_OPENED", "BANK_CLOSED", "ITEM_LOADED", "DATA_CHANGED" }

local Tab = {}
Tab.__index = Tab

local function setEnabled(widget, enabled)
	if enabled then
		widget:Enable()
	else
		widget:Disable()
	end
end

local function currentCharacter()
	return ns.db and ns.charKey and ns.db.characters[ns.charKey]
end

local function canWrite()
	return ns.db ~= nil and not ns.readOnly
end

function MaterialTab.Create(parent)
	local tab = setmetatable({ offset = 0, data = {}, rows = {} }, Tab)
	Layout.Build(tab, parent)
	-- One handler object, so OffSignal can remove exactly what Activate added.
	tab.refreshHandler = function()
		tab:RequestRefresh()
	end
	return tab
end

-- Activation and refresh -----------------------------------------------------------------

function Tab:Activate()
	for _, signal in ipairs(REFRESH_SIGNALS) do
		Events.OnSignal(signal, self.refreshHandler)
	end
	self:Refresh()
end

function Tab:Deactivate()
	for _, signal in ipairs(REFRESH_SIGNALS) do
		Events.OffSignal(signal, self.refreshHandler)
	end
end

-- Coalesces bursts (e.g. many ITEM_LOADED events) into one refresh on the next frame.
function Tab:RequestRefresh()
	if self.refreshPending then
		return
	end
	self.refreshPending = true
	C_Timer.After(0, function()
		self.refreshPending = false
		if self.frame:IsVisible() then
			self:Refresh()
		end
	end)
end

-- Goals to show and the header line; nil goals means "show emptyText".
local function selection(charData)
	local ids = Materials.ListGoalIDs(charData)
	if #ids == 0 then
		return nil, "", L.GOAL_LIST_EMPTY
	end
	if ns.db.settings.window.allGoals then
		return Materials.AllGoals(charData), L.STOCK_ALL_HEADER
	end
	local goal, id = Materials.GetActiveGoal(charData)
	if not goal then
		return nil, "", L.WINDOW_NO_GOAL_SELECTED
	end
	local position = 1
	for i, goalID in ipairs(ids) do
		if goalID == id then
			position = i
		end
	end
	return { goal }, Util.Format(L.WINDOW_GOAL_LINE, position, #ids, UIShared.GoalName(goal), goal.crafts)
end

function Tab:Refresh()
	local charData = currentCharacter()
	if not charData then
		self:ShowEmpty("", L.NOT_READY)
		return
	end
	local goals, headerText, emptyText = selection(charData)
	local all = ns.db.settings.window.allGoals
	self.allGoals:SetChecked(all)
	local hasGoals = #Materials.ListGoalIDs(charData) > 0
	setEnabled(self.prev, hasGoals and not all and canWrite())
	setEnabled(self.next, hasGoals and not all and canWrite())
	setEnabled(self.allGoals, canWrite())
	setEnabled(self.import, canWrite())
	if not goals then
		self:ShowEmpty(headerText, emptyText)
		return
	end
	self.data = Stock.Rows(charData, goals)
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

local function setNumber(text, value, color)
	text:SetText(value)
	text:SetTextColor(color[1], color[2], color[3])
end

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
