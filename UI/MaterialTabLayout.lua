-- Widgets of the Material tab: goal line, navigation, "all goals" check box, column header,
-- a fixed pool of rows with tooltip, and the recipe import button. Logic: UI/MaterialTab.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util

local Layout = {}
ns.MaterialTabLayout = Layout

Layout.VISIBLE_ROWS = 10
local VISIBLE_ROWS = Layout.VISIBLE_ROWS
local ROW_HEIGHT = 22
local ICON_SIZE = 18
local NAME_WIDTH = 230
local NUMBER_WIDTH = 48
local NUMBER_COLUMNS = { "need", "bags", "bank", "others", "missing" }
local HEADER_KEYS = {
	need = "COL_NEED", bags = "COL_BAGS", bank = "COL_BANK", others = "COL_OTHERS", missing = "COL_MISSING",
}

local function numberX(index)
	return ICON_SIZE + 6 + NAME_WIDTH + (index - 1) * NUMBER_WIDTH
end

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
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function createRow(parent, index)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(ICON_SIZE + 6 + NAME_WIDTH + #NUMBER_COLUMNS * NUMBER_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", 0, 0)
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", ICON_SIZE + 6, 0)
	row.name:SetWidth(NAME_WIDTH - 6)
	row.name:SetJustifyH("LEFT")
	row.numbers = {}
	for i, key in ipairs(NUMBER_COLUMNS) do
		local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("LEFT", numberX(i), 0)
		text:SetWidth(NUMBER_WIDTH)
		text:SetJustifyH("RIGHT")
		row.numbers[key] = text
	end
	row:SetScript("OnEnter", showTooltip)
	row:SetScript("OnLeave", hideTooltip)
	return row
end

local function createHeader(parent)
	local name = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("TOPLEFT", ICON_SIZE + 6, 0)
	name:SetText(L.COL_MATERIAL)
	for i, key in ipairs(NUMBER_COLUMNS) do
		local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", numberX(i), 0)
		text:SetWidth(NUMBER_WIDTH)
		text:SetJustifyH("RIGHT")
		text:SetText(L[HEADER_KEYS[key]])
	end
end

local function createButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 22)
	button:SetText(text)
	return button
end

-- Vertical layout inside the tab (pixels from the top) and fixed sizes.
local MARGIN_X, MARGIN_TOP, MARGIN_BOTTOM = 22, 46, 20
local NAV_BUTTON_WIDTH, NAV_GAP, GOAL_TEXT_GAP = 26, 4, 8
local CHECK_SIZE, CHECK_Y = 24, -28
local HEADER_Y, HEADER_HEIGHT = -60, 16
local LIST_Y, EMPTY_TEXT_Y, EMPTY_TEXT_WIDTH = -78, -84, 500
local IMPORT_BUTTON_WIDTH = 160

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
	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", 0, HEADER_Y)
	header:SetSize(1, HEADER_HEIGHT)
	createHeader(header)
	local list = CreateFrame("Frame", nil, frame)
	list:SetPoint("TOPLEFT", 0, LIST_Y)
	list:SetSize(1, VISIBLE_ROWS * ROW_HEIGHT)
	for i = 1, VISIBLE_ROWS do
		tab.rows[i] = createRow(list, i)
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
-- (StepGoal, SetAllGoals, Scroll, ImportRecipe).
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
end
