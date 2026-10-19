-- Gold buffer tab of the main window: budget overview (gold, reserves, free, uncovered), the
-- savings goals, the net income and buttons to distribute the gold and to switch whether the
-- sourcing plan may use reserves. The buttons run the same /bof gold commands as the chat.
-- Creating and editing savings goals stays in the chat (/bof gold add …), shown as a hint.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local GoldCommands = ns.GoldCommands

local GoldTab = {}
ns.GoldTab = GoldTab

local MAX_GOAL_LINES = 10
local LINE_GAP = 6
local BUTTON_WIDTH, BUTTON_GAP = 150, 6
local OVERVIEW_Y, GOALS_Y = -30, -56
local INCOME_Y, RESERVES_Y, HINT_Y = 44, 26, 8
local TEXT_WIDTH = 590
local REFRESH_SIGNALS = { "MONEY_CHANGED", "DATA_CHANGED" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local function createText(frame, font, y, anchor)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint(anchor, 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

local function createCommandButton(frame, label, command)
	local button = Widgets.CreateButton(frame, L[label], BUTTON_WIDTH)
	button:SetScript("OnClick", function()
		ns.Slash.Handle("gold " .. command)
	end)
	return button
end

function GoldTab.Create(parent)
	local tab = setmetatable({}, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	tab.distribute = createCommandButton(frame, "GOLD_BTN_DISTRIBUTE", "distribute")
	tab.distribute:SetPoint("TOPLEFT", 0, 0)
	tab.reserves = createCommandButton(frame, "GOLD_BTN_RESERVES", "reserves")
	tab.reserves:SetPoint("LEFT", tab.distribute, "RIGHT", BUTTON_GAP, 0)
	tab.overviewText = createText(frame, "GameFontHighlight", OVERVIEW_Y, "TOPLEFT")
	tab.goalLines = Widgets.CreateTextStack(frame, {
		count = MAX_GOAL_LINES, font = "GameFontHighlightSmall", y = GOALS_Y, width = TEXT_WIDTH, gap = LINE_GAP,
	})
	tab.incomeText = createText(frame, "GameFontHighlightSmall", INCOME_Y, "BOTTOMLEFT")
	tab.reservesText = createText(frame, "GameFontHighlightSmall", RESERVES_Y, "BOTTOMLEFT")
	tab.hintText = createText(frame, "GameFontDisableSmall", HINT_Y, "BOTTOMLEFT")
	tab.hintText:SetText(L.GOLD_TAB_HINT)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local canWrite = charData ~= nil and not ns.readOnly
	Widgets.SetEnabled(self.distribute, canWrite)
	Widgets.SetEnabled(self.reserves, canWrite)
	if not charData then
		self.overviewText:SetText(L.NOT_READY)
		return
	end
	self.overviewText:SetText(GoldCommands.OverviewLine(charData))
	local lines = GoldCommands.GoalLines(charData)
	for i, text in ipairs(self.goalLines) do
		text:SetText(lines[i] or "")
	end
	self.incomeText:SetText(GoldCommands.IncomeLine(charData))
	self.reservesText:SetText(ns.db.settings.useReservesInSourcing and L.GOLD_RESERVES_USED or L.GOLD_RESERVES_KEPT)
end
