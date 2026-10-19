-- Gold buffer tab of the main window: budget overview (gold, reserves, free, uncovered), the
-- savings goals as editable rows (name, amount, reserved, up, reached, delete), a row to create a
-- goal, a purchase check, the net income and buttons to distribute the gold and to switch whether
-- the sourcing plan may use reserves. Every input runs the same /bof gold command as the chat.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local GoldCommands = ns.GoldCommands

local GoldTab = {}
ns.GoldTab = GoldTab

local VISIBLE_ROWS = 8
local ROW_HEIGHT, ROWS_Y, HEADER_Y, NEW_ROW_GAP = 24, -74, -56, 6
local BUTTON_WIDTH, BUTTON_GAP = 150, 6
local OVERVIEW_Y, INCOME_Y, RESERVES_Y = -32, 26, 8
local TEXT_WIDTH = 690
-- Row columns: number, name box, amount box, status text, up, reached, delete.
local NUMBER_WIDTH, NAME_WIDTH, AMOUNT_WIDTH, STATUS_WIDTH = 24, 180, 90, 200
local UP_WIDTH, DONE_WIDTH, REMOVE_WIDTH, CHECK_BOX_WIDTH = 50, 80, 22, 90
local PERCENT = 100
local REFRESH_SIGNALS = { "MONEY_CHANGED", "DATA_CHANGED" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local run = Inputs.Run

local function createText(frame, font, y, anchor)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint(anchor, 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

local function button(parent, label, width, onClick)
	local b = Widgets.CreateButton(parent, label, width)
	b:SetScript("OnClick", onClick)
	return b
end

-- Places widgets one after another from the left edge of `row`.
local function chain(row, widgets)
	local previous
	for _, widget in ipairs(widgets) do
		if previous then
			widget:SetPoint("LEFT", previous, "RIGHT", BUTTON_GAP, 0)
		else
			widget:SetPoint("LEFT", row, "LEFT", 0, 0)
		end
		previous = widget
	end
end

local function buildRow(tab, frame, i)
	local row = CreateFrame("Frame", nil, frame)
	row:SetSize(TEXT_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, ROWS_Y - (i - 1) * ROW_HEIGHT)
	row.number = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.number:SetWidth(NUMBER_WIDTH)
	row.name = Inputs.CreateBox(row, { width = NAME_WIDTH, onCommit = function(text)
		run("gold name " .. row.index .. " " .. text)
	end })
	row.amount = Inputs.CreateBox(row, { width = AMOUNT_WIDTH, onCommit = function(text)
		run("gold set " .. row.index .. " " .. text)
	end })
	row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.status:SetWidth(STATUS_WIDTH)
	row.status:SetJustifyH("LEFT")
	row.up = button(row, L.GOLD_BTN_UP, UP_WIDTH, function()
		run("gold up " .. row.index)
	end)
	row.done = button(row, L.GOLD_BTN_DONE, DONE_WIDTH, function()
		run("gold done " .. row.index)
	end)
	row.remove = button(row, L.INPUT_REMOVE, REMOVE_WIDTH, function()
		Inputs.Confirm(Util.Format(L.GOLD_DELETE_CONFIRM, row.index), function()
			run("gold delete " .. row.index)
		end)
	end)
	chain(row, { row.number, row.name, row.amount, row.status, row.up, row.done, row.remove })
	tab.rows[i] = row
end

-- "Neu: [Name] [Betrag] [Anlegen]" below the rows.
local function buildNewRow(tab, frame)
	local row = CreateFrame("Frame", nil, frame)
	row:SetSize(TEXT_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, ROWS_Y - VISIBLE_ROWS * ROW_HEIGHT - NEW_ROW_GAP)
	local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetWidth(NUMBER_WIDTH)
	label:SetText(L.GOLD_NEW_LABEL)
	tab.newName = Inputs.CreateBox(row, { width = NAME_WIDTH, onCommit = function()
		tab:CreateGoal()
	end })
	tab.newAmount = Inputs.CreateBox(row, { width = AMOUNT_WIDTH, onCommit = function()
		tab:CreateGoal()
	end })
	tab.create = button(row, L.GOLD_BTN_CREATE, DONE_WIDTH, function()
		tab:CreateGoal()
	end)
	chain(row, { label, tab.newName, tab.newAmount, tab.create })
end

local function buildTop(tab, frame)
	tab.distribute = button(frame, L.GOLD_BTN_DISTRIBUTE, BUTTON_WIDTH, function()
		run("gold distribute")
	end)
	tab.distribute:SetPoint("TOPLEFT", 0, 0)
	tab.reserves = button(frame, L.GOLD_BTN_RESERVES, BUTTON_WIDTH, function()
		run("gold reserves")
	end)
	tab.reserves:SetPoint("LEFT", tab.distribute, "RIGHT", BUTTON_GAP, 0)
	tab.checkButton = button(frame, L.GOLD_BTN_CHECK, CHECK_BOX_WIDTH, function()
		tab:CheckPurchase()
	end)
	tab.checkButton:SetPoint("TOPRIGHT", 0, 0)
	tab.checkAmount = Inputs.CreateBox(frame, { width = CHECK_BOX_WIDTH, onCommit = function()
		tab:CheckPurchase()
	end })
	tab.checkAmount:SetPoint("RIGHT", tab.checkButton, "LEFT", -BUTTON_GAP, 0)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("RIGHT", tab.checkAmount, "LEFT", -BUTTON_GAP, 0)
	label:SetText(L.GOLD_CHECK_LABEL)
end

function GoldTab.Create(parent)
	local tab = setmetatable({ rows = {} }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildTop(tab, frame)
	tab.overviewText = createText(frame, "GameFontHighlight", OVERVIEW_Y, "TOPLEFT")
	tab.header = createText(frame, "GameFontNormalSmall", HEADER_Y, "TOPLEFT")
	for i = 1, VISIBLE_ROWS do
		buildRow(tab, frame, i)
	end
	buildNewRow(tab, frame)
	tab.incomeText = createText(frame, "GameFontHighlightSmall", INCOME_Y, "BOTTOMLEFT")
	tab.reservesText = createText(frame, "GameFontHighlightSmall", RESERVES_Y, "BOTTOMLEFT")
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

-- "5g zurückgelegt (100 %)" or "erreicht".
local function statusText(goal)
	if goal.done then
		return L.GOLD_ROW_DONE
	end
	return Util.Format(L.GOLD_ROW_STATUS, Money.Format(goal.reserved), math.floor(goal.reserved * PERCENT / goal.copper))
end

local function drawRow(row, index, goal, canWrite)
	row.index = index
	if not goal then
		row:Hide()
		return
	end
	row.number:SetText(index .. ".")
	Inputs.SetValue(row.name, goal.label)
	Inputs.SetValue(row.amount, Money.Format(goal.copper))
	row.status:SetText(statusText(goal))
	Widgets.SetEnabled(row.up, canWrite and index > 1)
	Widgets.SetEnabled(row.done, canWrite and not goal.done)
	Widgets.SetEnabled(row.remove, canWrite)
	row:Show()
end

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local canWrite = charData ~= nil and not ns.readOnly
	Widgets.SetEnabled(self.distribute, canWrite)
	Widgets.SetEnabled(self.reserves, canWrite)
	Widgets.SetEnabled(self.create, canWrite)
	if not charData then
		self.overviewText:SetText(L.NOT_READY)
		return
	end
	self.overviewText:SetText(GoldCommands.OverviewLine(charData))
	local goals = charData.savingsGoals
	for i, row in ipairs(self.rows) do
		drawRow(row, i, goals[i], canWrite)
	end
	self.header:SetText(#goals > 0 and L.GOLD_ROWS_HEADER or L.GOLD_NO_GOALS_WINDOW)
	self.incomeText:SetText(GoldCommands.IncomeLine(charData))
	self.reservesText:SetText(ns.db.settings.useReservesInSourcing and L.GOLD_RESERVES_USED or L.GOLD_RESERVES_KEPT)
end

function Tab:CreateGoal()
	local amount = Util.Trim(self.newAmount:GetText() or "")
	if amount == "" then
		self.newAmount:SetFocus()
		return
	end
	run("gold add " .. amount .. " " .. (self.newName:GetText() or ""))
	Inputs.SetValue(self.newName, "")
	Inputs.SetValue(self.newAmount, "")
end

function Tab:CheckPurchase()
	run("gold check " .. (self.checkAmount:GetText() or ""))
end
