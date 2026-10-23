-- Widgets of the Wants tab ("Ziele"): the add line (item slot, count, "Hinzufügen", AH scan), the
-- list of wants on the left (count box, "Alle"/"Neu" stock mode, remove button), the plan tree of the selected want on the
-- right (indented rows with a "Herstellen" or "Farmen" button) and the summary lines at the bottom.
-- Logic: UI/WantsTab.lua.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local Inputs = ns.Inputs

local Layout = {}
ns.WantsTabLayout = Layout

Layout.WANT_ROWS = 10
Layout.TREE_ROWS = 11
Layout.SUMMARY_LINES = 4
Layout.INDENT = 14
local GAP, WIDE_GAP = 4, 10
local COUNT_WIDTH, ADD_WIDTH, SCAN_WIDTH = 44, 100, 120
local HEADER_Y, LIST_Y = -34, -52
local WANT_WIDTH, WANT_ROW_HEIGHT, WANT_NAME_WIDTH, REMOVE_WIDTH, MODE_WIDTH = 236, 24, 114, 22, 34
local TREE_X, TREE_WIDTH, TREE_ROW_HEIGHT, TREE_TEXT_WIDTH, ACTION_WIDTH = 252, 484, 22, 384, 86
local ICON_SIZE = 16
local SUMMARY_LINE_HEIGHT, SUMMARY_BOTTOM, TEXT_WIDTH = 17, 4, 736

local function button(frame, label, width, onClick)
	local b = Widgets.CreateButton(frame, label, width)
	b:SetScript("OnClick", onClick)
	return b
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function showItemTooltip(row)
	if not row.itemID then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("item:" .. row.itemID)
	for _, line in ipairs(row.tooltipLines or {}) do
		GameTooltip:AddLine(line, 1, 1, 1)
	end
	GameTooltip:Show()
end

-- [slot] [count] [Hinzufügen]  hint ...  [AH-Scan]
local function buildAddLine(tab, frame)
	tab.slot = Inputs.CreateItemSlot(frame, function(itemID)
		tab:SetPendingItem(itemID)
	end)
	tab.slot:SetPoint("TOPLEFT", 0, 0)
	tab.addCount = Inputs.CreateBox(frame, { width = COUNT_WIDTH, numeric = true, draft = true, onCommit = function()
		tab:AddPending()
	end })
	tab.addCount:SetPoint("LEFT", tab.slot, "RIGHT", WIDE_GAP, 0)
	tab.add = button(frame, L.WANT_ADD, ADD_WIDTH, function()
		tab:AddPending()
	end)
	tab.add:SetPoint("LEFT", tab.addCount, "RIGHT", GAP, 0)
	tab.addHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.addHint:SetPoint("LEFT", tab.add, "RIGHT", WIDE_GAP, 0)
	tab.addHint:SetText(L.WANT_ADD_HINT)
	tab.scan = button(frame, L.WINDOW_SCAN, SCAN_WIDTH, function()
		ns.PriceCommands.Scan()
	end)
	tab.scan:SetPoint("TOPRIGHT", 0, 0)
end

local function header(frame, x, text)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", x, HEADER_Y)
	label:SetText(text)
	return label
end

local function buildWantRow(tab, list, index)
	local row = CreateFrame("Button", nil, list)
	row:SetSize(WANT_WIDTH, WANT_ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(index - 1) * WANT_ROW_HEIGHT)
	row.highlight = row:CreateTexture(nil, "BACKGROUND")
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(1, 1, 1, 0.12)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", 0, 0)
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", ICON_SIZE + GAP, 0)
	row.name:SetWidth(WANT_NAME_WIDTH)
	row.name:SetJustifyH("LEFT")
	row.countBox = Inputs.CreateBox(row, { width = COUNT_WIDTH, numeric = true, onCommit = function(text)
		tab:SetCount(row, text)
	end })
	row.countBox:SetPoint("LEFT", ICON_SIZE + GAP + WANT_NAME_WIDTH + GAP, 0)
	row.remove = button(row, L.INPUT_REMOVE, REMOVE_WIDTH, function()
		tab:RemoveWant(row)
	end)
	row.remove:SetPoint("RIGHT", 0, 0)
	row.mode = button(row, L.WANT_BTN_ALL, MODE_WIDTH, function()
		tab:ToggleOnlyNew(row)
	end)
	row.mode:SetPoint("RIGHT", row.remove, "LEFT", -GAP / 2, 0)
	row.mode:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tip, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	row.mode:SetScript("OnLeave", hideTooltip)
	row:SetScript("OnClick", function()
		tab:SelectWant(row.index)
	end)
	row:SetScript("OnEnter", showItemTooltip)
	row:SetScript("OnLeave", hideTooltip)
	return row
end

local function buildTreeRow(tab, frame, index)
	local row = CreateFrame("Button", nil, frame)
	row:SetSize(TREE_WIDTH, TREE_ROW_HEIGHT)
	row:SetPoint("TOPLEFT", TREE_X, LIST_Y - (index - 1) * TREE_ROW_HEIGHT)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row.action = button(row, "", ACTION_WIDTH, function()
		tab:RunAction(row)
	end)
	row.action:SetPoint("RIGHT", 0, 0)
	row:SetScript("OnEnter", showItemTooltip)
	row:SetScript("OnLeave", hideTooltip)
	return row
end

-- Indents a tree row: icon and text move right by depth steps.
function Layout.Indent(row, depth)
	local x = depth * Layout.INDENT
	row.icon:ClearAllPoints()
	row.icon:SetPoint("LEFT", x, 0)
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", x + ICON_SIZE + GAP, 0)
	row.text:SetWidth(TREE_TEXT_WIDTH - x)
end

-- Creates the widgets of a tab object and connects them to its methods (see UI/WantsTab.lua).
function Layout.Build(tab, parent)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildAddLine(tab, frame)
	header(frame, 0, L.WANT_LIST_HEADER)
	tab.treeHeader = header(frame, TREE_X, L.WANT_TREE_HEADER)
	tab.wantRows, tab.treeRows, tab.summary = {}, {}, {}
	-- The wants list scrolls on its own; the wheel anywhere else scrolls the tree.
	tab.wantList = CreateFrame("Frame", nil, frame)
	tab.wantList:SetPoint("TOPLEFT", 0, LIST_Y)
	tab.wantList:SetSize(WANT_WIDTH, Layout.WANT_ROWS * WANT_ROW_HEIGHT)
	tab.wantList:EnableMouseWheel(true)
	tab.wantList:SetScript("OnMouseWheel", function(_, delta)
		tab:ScrollWants(-delta)
	end)
	for i = 1, Layout.WANT_ROWS do
		tab.wantRows[i] = buildWantRow(tab, tab.wantList, i)
	end
	for i = 1, Layout.TREE_ROWS do
		tab.treeRows[i] = buildTreeRow(tab, frame, i)
	end
	tab.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.emptyText:SetPoint("TOPLEFT", 0, LIST_Y)
	tab.emptyText:SetWidth(TEXT_WIDTH)
	tab.emptyText:SetJustifyH("LEFT")
	for i = 1, Layout.SUMMARY_LINES do
		local text = frame:CreateFontString(nil, "OVERLAY", i == 1 and "GameFontHighlight" or "GameFontHighlightSmall")
		text:SetPoint("BOTTOMLEFT", 0, SUMMARY_BOTTOM + (Layout.SUMMARY_LINES - i) * SUMMARY_LINE_HEIGHT)
		text:SetWidth(TEXT_WIDTH)
		text:SetJustifyH("LEFT")
		tab.summary[i] = text
	end
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
end
