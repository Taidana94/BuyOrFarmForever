-- Widgets of the Material tab: goal line, navigation, "all goals" check box, column header,
-- a fixed pool of rows with tooltip, and the recipe import and auction scan buttons.
-- Logic: UI/MaterialTab.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util

local Layout = {}
ns.MaterialTabLayout = Layout

local Widgets = ns.Widgets

Layout.VISIBLE_ROWS = 10
local VISIBLE_ROWS = Layout.VISIBLE_ROWS
local NAME_WIDTH = 230
-- Right-aligned columns after the name: row.numbers[key], header text L[header].
local TABLE = Widgets.TableLayout(NAME_WIDTH, {
	{ key = "need", header = "COL_NEED", width = 48 },
	{ key = "bags", header = "COL_BAGS", width = 48 },
	{ key = "bank", header = "COL_BANK", width = 48 },
	{ key = "others", header = "COL_OTHERS", width = 48 },
	{ key = "missing", header = "COL_MISSING", width = 48 },
	{ key = "price", header = "COL_PRICE", width = 84 },
})
Layout.ROW_WIDTH = TABLE.rowWidth

local function showTooltip(row)
	if not row.data then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("item:" .. row.data.itemID)
	local now = ns.Client:GetServerTime()
	for _, d in ipairs(row.data.details) do
		local template = d.sameFaction and L.STOCK_ALT_DETAIL or L.STOCK_ALT_OTHER_FACTION
		GameTooltip:AddLine(Util.Format(template, d.name, d.total, d.bags, d.bank, Util.FormatAge(now - d.at)))
	end
	for _, line in ipairs(row.data.priceLines or {}) do
		GameTooltip:AddLine(line)
	end
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local createButton = Widgets.CreateButton

-- Vertical layout inside the tab (pixels from the top) and fixed sizes.
local MARGIN_X, MARGIN_TOP, MARGIN_BOTTOM = 22, 46, 20
local NAV_BUTTON_WIDTH, NAV_GAP, GOAL_TEXT_GAP = 26, 4, 8
local CHECK_SIZE, CHECK_Y = 24, -28
local HEADER_Y = -60
local LIST_Y, EMPTY_TEXT_Y, EMPTY_TEXT_WIDTH = -78, -84, 500
local IMPORT_BUTTON_WIDTH = 160
local SCAN_BUTTON_WIDTH = 120
local BUTTON_GAP = 8

-- Goal line with previous/next buttons and the "all goals" check box.
local function buildNavigation(tab, frame)
	tab.prev = createButton(frame, L.WINDOW_PREV, NAV_BUTTON_WIDTH)
	tab.prev:SetPoint("TOPLEFT", 0, 0)
	tab.next = createButton(frame, L.WINDOW_NEXT, NAV_BUTTON_WIDTH)
	tab.next:SetPoint("LEFT", tab.prev, "RIGHT", NAV_GAP, 0)
	tab.goalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.goalText:SetPoint("LEFT", tab.next, "RIGHT", GOAL_TEXT_GAP, 0)
	tab.goalText:SetJustifyH("LEFT")
	tab.prev:SetScript("OnClick", function()
		tab:StepGoal(-1)
	end)
	tab.next:SetScript("OnClick", function()
		tab:StepGoal(1)
	end)
	tab.allGoals = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	tab.allGoals:SetSize(CHECK_SIZE, CHECK_SIZE)
	tab.allGoals:SetPoint("TOPLEFT", 0, CHECK_Y)
	tab.allGoals.Text:SetText(L.WINDOW_ALL_GOALS)
	tab.allGoals:SetScript("OnClick", function(self)
		tab:SetAllGoals(self:GetChecked() and true or false)
	end)
end

-- Column header, the row pool, the empty-state text and mouse wheel scrolling.
local function buildList(tab, frame)
	tab.rows = Widgets.CreateTable(frame, TABLE, VISIBLE_ROWS, HEADER_Y, LIST_Y)
	for _, row in ipairs(tab.rows) do
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
	end
	tab.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.emptyText:SetPoint("TOPLEFT", 0, EMPTY_TEXT_Y)
	tab.emptyText:SetWidth(EMPTY_TEXT_WIDTH)
	tab.emptyText:SetJustifyH("LEFT")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
end

-- Creates the widgets of a tab object and connects them to its methods
-- (StepGoal, SetAllGoals, Scroll, ImportRecipe, ScanAuction).
function Layout.Build(tab, parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", MARGIN_X, -MARGIN_TOP)
	frame:SetPoint("BOTTOMRIGHT", -MARGIN_X, MARGIN_BOTTOM)
	tab.frame = frame
	buildNavigation(tab, frame)
	buildList(tab, frame)
	tab.import = createButton(frame, L.WINDOW_IMPORT_RECIPE, IMPORT_BUTTON_WIDTH)
	tab.import:SetPoint("BOTTOMLEFT", 0, 0)
	tab.import:SetScript("OnClick", function()
		tab:ImportRecipe()
	end)
	tab.scan = createButton(frame, L.WINDOW_SCAN, SCAN_BUTTON_WIDTH)
	tab.scan:SetPoint("LEFT", tab.import, "RIGHT", BUTTON_GAP, 0)
	tab.scan:SetScript("OnClick", function()
		tab:ScanAuction()
	end)
end
