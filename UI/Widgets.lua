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

-- Content area of a window tab, inside the window's border and below the tab buttons.
local TAB_MARGIN_X, TAB_MARGIN_TOP, TAB_MARGIN_BOTTOM = 22, 72, 20

function Widgets.CreateTabFrame(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", TAB_MARGIN_X, -TAB_MARGIN_TOP)
	frame:SetPoint("BOTTOMRIGHT", -TAB_MARGIN_X, TAB_MARGIN_BOTTOM)
	return frame
end

-- Check box with a label; onClick(checked) after each click.
local CHECK_SIZE = 24

function Widgets.CreateCheck(parent, label, onClick)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(CHECK_SIZE, CHECK_SIZE)
	check.Text:SetText(label)
	check:SetScript("OnClick", function(self)
		onClick(self:GetChecked() and true or false)
	end)
	return check
end

function Widgets.CreateButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, Widgets.BUTTON_HEIGHT)
	button:SetText(text)
	return button
end

-- Table layout from columns = { { key, header (locale key), width } } after the name column, whose
-- header is the locale key nameHeader (default COL_MATERIAL).
-- Returns { nameWidth, nameHeader, columns, columnX, rowWidth, rowHeight }.
function Widgets.TableLayout(nameWidth, columns, nameHeader)
	local layout = { nameWidth = nameWidth, nameHeader = nameHeader or "COL_MATERIAL", columns = columns, columnX = {},
		rowHeight = ROW_HEIGHT }
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
	name:SetText(L[layout.nameHeader])
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

-- Left-aligned text lines below each other, starting at opts.y (from the top of `parent`).
-- Each line hangs below the previous one, so a line that wraps pushes the following lines
-- down instead of overlapping them. opts = { count, font, y, width, gap }. Returns the lines.
function Widgets.CreateTextStack(parent, opts)
	local lines = {}
	for i = 1, opts.count do
		local text = parent:CreateFontString(nil, "OVERLAY", opts.font)
		if i == 1 then
			text:SetPoint("TOPLEFT", 0, opts.y)
		else
			text:SetPoint("TOPLEFT", lines[i - 1], "BOTTOMLEFT", 0, -opts.gap)
		end
		text:SetWidth(opts.width)
		text:SetJustifyH("LEFT")
		lines[i] = text
	end
	return lines
end

function Widgets.SetShown(widget, shown)
	if shown then
		widget:Show()
	else
		widget:Hide()
	end
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

-- Refresh behavior shared by the tabs: signal handlers only while the tab is shown, and any
-- number of refresh requests in one frame lead to one Refresh on the next frame (only if the
-- tab is still visible). A tab class gets the methods with Widgets.MixRefresh(Tab); each tab
-- object calls Widgets.InitRefresh(tab, signals) and provides tab.frame and tab:Refresh().
local RefreshMixin = {}

function RefreshMixin:Activate()
	for _, signal in ipairs(self.refreshSignals) do
		ns.Events.OnSignal(signal, self.refreshHandler)
	end
	self:Refresh()
end

function RefreshMixin:Deactivate()
	for _, signal in ipairs(self.refreshSignals) do
		ns.Events.OffSignal(signal, self.refreshHandler)
	end
end

function RefreshMixin:RequestRefresh()
	if self.refreshPending then
		return
	end
	self.refreshPending = true
	C_Timer.After(0, self.runRefresh)
end

function Widgets.MixRefresh(class)
	for name, fn in pairs(RefreshMixin) do
		class[name] = fn
	end
end

-- One handler and one timer callback per tab object, so OffSignal removes exactly what
-- Activate added and no closure is created per request.
function Widgets.InitRefresh(tab, signals)
	tab.refreshSignals = signals
	tab.refreshHandler = function()
		tab:RequestRefresh()
	end
	tab.runRefresh = function()
		tab.refreshPending = false
		if tab.frame:IsVisible() then
			tab:Refresh()
		end
	end
end
