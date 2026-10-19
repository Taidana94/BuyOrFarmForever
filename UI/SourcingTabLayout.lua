-- Widgets of the Sourcing tab: goal line with "<" ">", strategy buttons, budget line, the plan table
-- (missing, buy, cost, farm, farm time) and the summary lines. Logic: UI/SourcingTab.lua.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local Layout = {}
ns.SourcingTabLayout = Layout

Layout.VISIBLE_ROWS = 9
Layout.STRATEGIES = { "SAVE_TIME", "SAVE_GOLD", "FARM_SELF" }
local STRATEGY_LABELS = { SAVE_TIME = "STRATEGY_SAVE_TIME", SAVE_GOLD = "STRATEGY_SAVE_GOLD", FARM_SELF = "STRATEGY_FARM_SELF" }

local TABLE = Widgets.TableLayout(220, {
	{ key = "missing", header = "COL_MISSING", width = 48 },
	{ key = "buy", header = "COL_BUY", width = 56 },
	{ key = "cost", header = "COL_COST", width = 84 },
	{ key = "farm", header = "COL_FARM", width = 56 },
	{ key = "farmTime", header = "COL_FARM_TIME", width = 84 },
})

local STRATEGY_Y, STRATEGY_WIDTH, STRATEGY_GAP = -26, 120, 6
local BUDGET_GAP, BUDGET_BOX_WIDTH = 12, 80
local HEADER_Y, LIST_Y = -60, -78
local EMPTY_TEXT_Y, TEXT_WIDTH = -84, 560
-- Goal line between the arrows and the time limit box at the top right.
local GOAL_TEXT_GAP, GOAL_TEXT_WIDTH = 8, 480
local ROUTE_Y, LIMIT_Y, SUMMARY_Y, RESERVE_Y, TIME_VALUE_Y = 74, 58, 42, 26, 10

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
	-- Own budget: empty box = plan with the character's gold.
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", previous, "RIGHT", BUDGET_GAP, 0)
	label:SetText(L.SOURCING_BUDGET_LABEL)
	tab.budgetBox = ns.Inputs.CreateBox(frame, { width = BUDGET_BOX_WIDTH, onCommit = function(text)
		ns.Inputs.Run("budget " .. (ns.Util.Trim(text) == "" and "clear" or text))
	end })
	tab.budgetBox:SetPoint("LEFT", label, "RIGHT", STRATEGY_GAP, 0)
	tab.budgetText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.budgetText:SetPoint("LEFT", tab.budgetBox, "RIGHT", STRATEGY_GAP, 0)
	tab.budgetText:SetJustifyH("LEFT")
end

-- Farm time limit at the top right: empty box = no limit.
local function buildLimit(tab, frame)
	tab.limitBox = ns.Inputs.CreateBox(frame, { width = BUDGET_BOX_WIDTH, onCommit = function(text)
		ns.Inputs.Run("timelimit " .. (ns.Util.Trim(text) == "" and "clear" or text))
	end })
	tab.limitBox:SetPoint("TOPRIGHT", 0, 0)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("RIGHT", tab.limitBox, "LEFT", -STRATEGY_GAP, 0)
	label:SetText(L.SOURCING_LIMIT_LABEL)
end

local function createText(frame, font, y, anchor)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint(anchor, 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

-- Creates the widgets of a tab object and connects them to its methods (SetStrategy, StepGoal,
-- Scroll).
function Layout.Build(tab, parent)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	local next = Widgets.CreateGoalNavigation(tab, frame)
	tab.goalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.goalText:SetPoint("LEFT", next, "RIGHT", GOAL_TEXT_GAP, 0)
	tab.goalText:SetWidth(GOAL_TEXT_WIDTH)
	tab.goalText:SetJustifyH("LEFT")
	buildStrategies(tab, frame)
	buildLimit(tab, frame)
	tab.rows = Widgets.CreateTable(frame, TABLE, Layout.VISIBLE_ROWS, HEADER_Y, LIST_Y)
	for _, row in ipairs(tab.rows) do
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
	end
	tab.emptyText = createText(frame, "GameFontDisableSmall", EMPTY_TEXT_Y, "TOPLEFT")
	tab.routeText = createText(frame, "GameFontHighlightSmall", ROUTE_Y, "BOTTOMLEFT")
	tab.limitText = createText(frame, "GameFontHighlightSmall", LIMIT_Y, "BOTTOMLEFT")
	tab.summaryText = createText(frame, "GameFontHighlightSmall", SUMMARY_Y, "BOTTOMLEFT")
	tab.reserveText = createText(frame, "GameFontHighlightSmall", RESERVE_Y, "BOTTOMLEFT")
	tab.timeValueText = createText(frame, "GameFontDisableSmall", TIME_VALUE_Y, "BOTTOMLEFT")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
end
