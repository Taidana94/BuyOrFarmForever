-- Widgets of the Material tab: goal line (navigation, name and crafts boxes, new and delete), the
-- check boxes, column header, a fixed pool of rows (count per craft box, clickable price cell,
-- remove button, tooltip) and the bottom bar (item slot with count and "add", recipe import with
-- count, auction scan). Logic: UI/MaterialTab.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Inputs = ns.Inputs

local Layout = {}
ns.MaterialTabLayout = Layout

Layout.VISIBLE_ROWS = 10
local VISIBLE_ROWS = Layout.VISIBLE_ROWS
-- Right-aligned columns after the name: row.numbers[key], header text L[header].
local TABLE = Widgets.TableLayout(190, {
	{ key = "perCraft", header = "COL_PER_CRAFT", width = 52 },
	{ key = "need", header = "COL_NEED", width = 48 },
	{ key = "bags", header = "COL_BAGS", width = 48 },
	{ key = "bank", header = "COL_BANK", width = 44 },
	{ key = "others", header = "COL_OTHERS", width = 48 },
	{ key = "missing", header = "COL_MISSING", width = 48 },
	{ key = "price", header = "COL_PRICE", width = 84 },
})
local PER_CRAFT_COLUMN, PRICE_COLUMN = 1, 7

-- Vertical layout inside the tab (pixels from the top) and fixed sizes.
local GAP, WIDE_GAP = 4, 10
local NAME_BOX_WIDTH, COUNT_BOX_WIDTH, GOAL_BUTTON_WIDTH = 190, 44, 80
local CHECK_Y, OTHERS_CHECK_X = -28, 230
local HEADER_Y, LIST_Y = -60, -78
local EMPTY_TEXT_Y, EMPTY_TEXT_WIDTH = -84, 500
local BOX_INSET, REMOVE_WIDTH = 4, 22
local ADD_BUTTON_WIDTH, IMPORT_BUTTON_WIDTH, SCAN_BUTTON_WIDTH = 90, 150, 100

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
	GameTooltip:AddLine(L.MATERIAL_ROW_HINT)
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function button(frame, label, width, onClick)
	local b = Widgets.CreateButton(frame, label, width)
	b:SetScript("OnClick", onClick)
	return b
end

-- Goal line: < > "Ziel 2 von 5:" [name] Herstellungen [n] [Neu] [Löschen].
local function buildGoalLine(tab, frame)
	local next = Widgets.CreateGoalNavigation(tab, frame)
	tab.goalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.goalText:SetPoint("LEFT", next, "RIGHT", WIDE_GAP, 0)
	tab.nameBox = Inputs.CreateBox(frame, { width = NAME_BOX_WIDTH, onCommit = function(text)
		tab:Rename(text)
	end })
	tab.nameBox:SetPoint("LEFT", tab.goalText, "RIGHT", WIDE_GAP, 0)
	tab.craftsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.craftsLabel:SetPoint("LEFT", tab.nameBox, "RIGHT", WIDE_GAP, 0)
	tab.craftsLabel:SetText(L.MATERIAL_CRAFTS_LABEL)
	tab.craftsBox = Inputs.CreateBox(frame, { width = COUNT_BOX_WIDTH, numeric = true, onCommit = function(text)
		tab:SetCrafts(text)
	end })
	tab.craftsBox:SetPoint("LEFT", tab.craftsLabel, "RIGHT", WIDE_GAP, 0)
	tab.newGoal = button(frame, L.MATERIAL_NEW_GOAL, GOAL_BUTTON_WIDTH, function()
		tab:NewGoal()
	end)
	tab.newGoal:SetPoint("TOPRIGHT", -(GOAL_BUTTON_WIDTH + GAP), 0)
	tab.deleteGoal = button(frame, L.MATERIAL_DELETE_GOAL, GOAL_BUTTON_WIDTH, function()
		tab:DeleteGoal()
	end)
	tab.deleteGoal:SetPoint("TOPRIGHT", 0, 0)
end

local function buildChecks(tab, frame)
	tab.allGoals = Widgets.CreateCheck(frame, L.WINDOW_ALL_GOALS, function(checked)
		tab:SetAllGoals(checked)
	end)
	tab.allGoals:SetPoint("TOPLEFT", 0, CHECK_Y)
	tab.countOthers = Widgets.CreateCheck(frame, L.MATERIAL_COUNT_OTHERS, function()
		tab:ToggleOthers()
	end)
	tab.countOthers:SetPoint("TOPLEFT", OTHERS_CHECK_X, CHECK_Y)
end

-- Count per craft box over its column, an invisible button over the price cell, remove button.
local function buildRowInputs(tab, row)
	row.countBox = Inputs.CreateBox(row, { width = COUNT_BOX_WIDTH, numeric = true, onCommit = function(text)
		tab:SetCount(row, text)
	end })
	row.countBox:SetPoint("LEFT", TABLE.columnX[PER_CRAFT_COLUMN] + BOX_INSET, 0)
	row.priceButton = CreateFrame("Button", nil, row)
	row.priceButton:SetSize(TABLE.columns[PRICE_COLUMN].width, TABLE.rowHeight)
	row.priceButton:SetPoint("LEFT", TABLE.columnX[PRICE_COLUMN], 0)
	row.priceButton:SetScript("OnClick", function()
		tab:EditPrice(row)
	end)
	row.priceButton:SetScript("OnEnter", function()
		showTooltip(row)
	end)
	row.priceButton:SetScript("OnLeave", hideTooltip)
	row.remove = button(row, L.INPUT_REMOVE, REMOVE_WIDTH, function()
		tab:RemoveItem(row)
	end)
	row.remove:SetPoint("LEFT", TABLE.rowWidth + BOX_INSET, 0)
end

-- Column header, the row pool, the shared price box, the empty-state text and wheel scrolling.
local function buildList(tab, frame)
	tab.rows = Widgets.CreateTable(frame, TABLE, VISIBLE_ROWS, HEADER_Y, LIST_Y)
	for _, row in ipairs(tab.rows) do
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
		buildRowInputs(tab, row)
	end
	tab.priceBox = Inputs.CreateBox(frame, { width = TABLE.columns[PRICE_COLUMN].width, onCommit = function(text)
		tab:CommitPrice(text)
	end })
	tab.priceBox:Hide()
	tab.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.emptyText:SetPoint("TOPLEFT", 0, EMPTY_TEXT_Y)
	tab.emptyText:SetWidth(EMPTY_TEXT_WIDTH)
	tab.emptyText:SetJustifyH("LEFT")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
end

-- Places the shared price box over the price cell of a row.
function Layout.PlacePriceBox(tab, row)
	tab.priceBox:ClearAllPoints()
	tab.priceBox:SetPoint("LEFT", row, "LEFT", TABLE.columnX[PRICE_COLUMN] + BOX_INSET, 0)
end

-- Bottom bar: [slot] [n] [Hinzufügen]  [n] [Rezept übernehmen]  [AH-Scan].
local function buildBottom(tab, frame)
	tab.slot = Inputs.CreateItemSlot(frame, function(itemID)
		tab:SetPendingItem(itemID)
	end)
	tab.slot:SetPoint("BOTTOMLEFT", 0, 0)
	tab.addCount = Inputs.CreateBox(frame, { width = COUNT_BOX_WIDTH, numeric = true, draft = true, onCommit = function()
		tab:AddPendingItem()
	end })
	tab.addCount:SetPoint("LEFT", tab.slot, "RIGHT", WIDE_GAP, 0)
	tab.add = button(frame, L.MATERIAL_ADD_ITEM, ADD_BUTTON_WIDTH, function()
		tab:AddPendingItem()
	end)
	tab.add:SetPoint("LEFT", tab.addCount, "RIGHT", GAP, 0)
	tab.importCount = Inputs.CreateBox(frame, { width = COUNT_BOX_WIDTH, numeric = true, draft = true, onCommit = function()
		tab:ImportRecipe()
	end })
	tab.importCount:SetPoint("LEFT", tab.add, "RIGHT", WIDE_GAP * 2, 0)
	tab.import = button(frame, L.WINDOW_IMPORT_RECIPE, IMPORT_BUTTON_WIDTH, function()
		tab:ImportRecipe()
	end)
	tab.import:SetPoint("LEFT", tab.importCount, "RIGHT", GAP, 0)
	tab.scan = button(frame, L.WINDOW_SCAN, SCAN_BUTTON_WIDTH, function()
		tab:ScanAuction()
	end)
	tab.scan:SetPoint("LEFT", tab.import, "RIGHT", WIDE_GAP * 2, 0)
end

-- Creates the widgets of a tab object and connects them to its methods (see UI/MaterialTab.lua).
function Layout.Build(tab, parent)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildGoalLine(tab, frame)
	buildChecks(tab, frame)
	buildList(tab, frame)
	buildBottom(tab, frame)
end
