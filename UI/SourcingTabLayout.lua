-- Widgets of the Sourcing tab: goal line, strategy buttons, budget line, the plan table
-- (missing, buy, cost, farm, farm time) and the summary lines. Logic: UI/SourcingTab.lua.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local Layout = {}
ns.SourcingTabLayout = Layout

Layout.VISIBLE_ROWS = 10
Layout.STRATEGIES = { "SAVE_TIME", "SAVE_GOLD", "FARM_SELF" }
local STRATEGY_LABELS = { SAVE_TIME = "STRATEGY_SAVE_TIME", SAVE_GOLD = "STRATEGY_SAVE_GOLD", FARM_SELF = "STRATEGY_FARM_SELF" }

local TABLE = Widgets.TableLayout(220, {
	{ key = "missing", header = "COL_MISSING", width = 48 },
	{ key = "buy", header = "COL_BUY", width = 56 },
	{ key = "cost", header = "COL_COST", width = 84 },
	{ key = "farm", header = "COL_FARM", width = 56 },
	{ key = "farmTime", header = "COL_FARM_TIME", width = 84 },
})

local MARGIN_X, MARGIN_TOP, MARGIN_BOTTOM = 22, 46, 20
local STRATEGY_Y, STRATEGY_WIDTH, STRATEGY_GAP = -26, 120, 6
local BUDGET_GAP = 12
local HEADER_Y, LIST_Y = -60, -78
local EMPTY_TEXT_Y, TEXT_WIDTH = -84, 560
local SUMMARY_Y, TIME_VALUE_Y = 40, 22

local function showTooltip(row)
	local line = row.data
	if not line then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("item:" .. line.itemID)
	for _, text in ipairs(line.tooltipLines or {}) do
		GameTooltip:AddLine(text)
	end
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function buildStrategies(tab, frame)
	tab.strategyButtons = {}
	local previous
	for _, strategy in ipairs(Layout.STRATEGIES) do
		local button = Widgets.CreateButton(frame, L[STRATEGY_LABELS[strategy]], STRATEGY_WIDTH)
		if previous then
			button:SetPoint("LEFT", previous, "RIGHT", STRATEGY_GAP, 0)
		else
			button:SetPoint("TOPLEFT", 0, STRATEGY_Y)
		end
		button:SetScript("OnClick", function()
			tab:SetStrategy(strategy)
		end)
		tab.strategyButtons[strategy] = button
		previous = button
	end
	tab.budgetText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.budgetText:SetPoint("LEFT", previous, "RIGHT", BUDGET_GAP, 0)
	tab.budgetText:SetJustifyH("LEFT")
end

local function createText(frame, font, y, anchor)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint(anchor, 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

-- Creates the widgets of a tab object and connects them to its methods (SetStrategy, Scroll).
function Layout.Build(tab, parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", MARGIN_X, -MARGIN_TOP)
	frame:SetPoint("BOTTOMRIGHT", -MARGIN_X, MARGIN_BOTTOM)
	tab.frame = frame
	tab.goalText = createText(frame, "GameFontHighlight", 0, "TOPLEFT")
	buildStrategies(tab, frame)
	tab.rows = Widgets.CreateTable(frame, TABLE, Layout.VISIBLE_ROWS, HEADER_Y, LIST_Y)
	for _, row in ipairs(tab.rows) do
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
	end
	tab.emptyText = createText(frame, "GameFontDisableSmall", EMPTY_TEXT_Y, "TOPLEFT")
	tab.summaryText = createText(frame, "GameFontHighlightSmall", SUMMARY_Y, "BOTTOMLEFT")
	tab.timeValueText = createText(frame, "GameFontDisableSmall", TIME_VALUE_Y, "BOTTOMLEFT")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
end
