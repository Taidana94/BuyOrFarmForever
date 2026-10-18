-- Shared widgets of the window tabs: buttons and item tables (column header plus a fixed pool
-- of rows with icon, item name and right-aligned number columns). Frames are created once per
-- tab and reused; only stable frame APIs and Blizzard_SharedXML templates are used.
local _, ns = ...

local L = ns.L

local Widgets = {}
ns.Widgets = Widgets

Widgets.BUTTON_HEIGHT = 22
local ROW_HEIGHT = 22
local ICON_SIZE = 18
local ICON_GAP = 6
local NAME_X = ICON_SIZE + ICON_GAP

function Widgets.CreateButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, Widgets.BUTTON_HEIGHT)
	button:SetText(text)
	return button
end

-- Table layout from columns = { { key, header (locale key), width } } after the name column.
-- Returns { nameWidth, columns, columnX, rowWidth, rowHeight }.
function Widgets.TableLayout(nameWidth, columns)
	local layout = { nameWidth = nameWidth, columns = columns, columnX = {}, rowHeight = ROW_HEIGHT }
	local x = NAME_X + nameWidth
	for i, column in ipairs(columns) do
		layout.columnX[i] = x
		x = x + column.width
	end
	layout.rowWidth = x
	return layout
end

function Widgets.CreateHeader(parent, layout)
	local name = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("TOPLEFT", NAME_X, 0)
	name:SetText(L.COL_MATERIAL)
	for i, column in ipairs(layout.columns) do
		local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", layout.columnX[i], 0)
		text:SetWidth(column.width)
		text:SetJustifyH("RIGHT")
		text:SetText(L[column.header])
	end
end

-- Row number `index` with row.icon, row.name and row.numbers[column.key]. The caller sets
-- OnEnter/OnLeave and fills the texts.
function Widgets.CreateRow(parent, index, layout)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(layout.rowWidth, layout.rowHeight)
	row:SetPoint("TOPLEFT", 0, -(index - 1) * layout.rowHeight)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", 0, 0)
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", NAME_X, 0)
	row.name:SetWidth(layout.nameWidth - ICON_GAP)
	row.name:SetJustifyH("LEFT")
	row.numbers = {}
	for i, column in ipairs(layout.columns) do
		local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("LEFT", layout.columnX[i], 0)
		text:SetWidth(column.width)
		text:SetJustifyH("RIGHT")
		row.numbers[column.key] = text
	end
	return row
end

-- Header at headerY and `count` rows below it (listY), inside `parent`. Returns the rows.
function Widgets.CreateTable(parent, layout, count, headerY, listY)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("TOPLEFT", 0, headerY)
	header:SetSize(1, layout.rowHeight)
	Widgets.CreateHeader(header, layout)
	local list = CreateFrame("Frame", nil, parent)
	list:SetPoint("TOPLEFT", 0, listY)
	list:SetSize(1, count * layout.rowHeight)
	local rows = {}
	for i = 1, count do
		rows[i] = Widgets.CreateRow(list, i, layout)
	end
	return rows
end

function Widgets.SetEnabled(widget, enabled)
	if enabled then
		widget:Enable()
	else
		widget:Disable()
	end
end

function Widgets.SetText(text, value, color)
	text:SetText(value)
	text:SetTextColor(color[1], color[2], color[3])
end

Widgets.COLOR_NORMAL = { 1, 1, 1 }
Widgets.COLOR_MISSING = { 1, 0.35, 0.35 }
Widgets.COLOR_DONE = { 0.4, 1, 0.4 }
Widgets.COLOR_GRAY = { 0.6, 0.6, 0.6 }
