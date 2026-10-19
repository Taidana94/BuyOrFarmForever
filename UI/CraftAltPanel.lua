-- Alternatives editor of the Craft tab: one row per alternative with its item, a planned/drop
-- toggle, cost, time effort and requirements boxes and a remove button; below, an item slot with
-- a kind toggle to add an alternative. Every input runs /bof alt (Inputs.Run).
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local UIShared = ns.UIShared

local Panel = {}
ns.CraftAltPanel = Panel

local VISIBLE_ROWS = 8
local ROW_HEIGHT, HEADER_Y, ROWS_Y = 24, -30, -50
-- Column x positions and widths.
local ITEM_X, ITEM_WIDTH = 0, 205
local KIND_X, KIND_WIDTH = 210, 120
local COST_X, COST_WIDTH = 335, 80
local TIME_X, TIME_WIDTH = 420, 70
local REQ_X, REQ_WIDTH = 495, 180
local REMOVE_X, REMOVE_WIDTH = 680, 22
local GAP = 8
local KIND_LABELS = { PLANNED = "ALT_KIND_PLANNED", POSSIBLE = "ALT_KIND_POSSIBLE" }
local KIND_WORDS = { PLANNED = "planned", POSSIBLE = "drop" }
local OTHER_KIND = { PLANNED = "POSSIBLE", POSSIBLE = "PLANNED" }

local run = Inputs.Run

local function header(frame, x, label)
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("TOPLEFT", x, HEADER_Y)
	text:SetText(label)
end

-- Runs "alt <sub> <index> <value>", with "clear" for an empty box.
local function setDetail(row, sub, text)
	if row.index then
		run("alt " .. sub .. " " .. row.index .. " " .. (Util.Trim(text) == "" and "clear" or text))
	end
end

local function buildRow(panel, frame, i)
	local row = CreateFrame("Frame", nil, frame)
	row:SetSize(REMOVE_X + REMOVE_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, ROWS_Y - (i - 1) * ROW_HEIGHT)
	row.item = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.item:SetPoint("LEFT", ITEM_X, 0)
	row.item:SetWidth(ITEM_WIDTH)
	row.item:SetJustifyH("LEFT")
	row.kind = Widgets.CreateButton(row, "", KIND_WIDTH)
	row.kind:SetPoint("LEFT", KIND_X, 0)
	row.kind:SetScript("OnClick", function()
		run("alt kind " .. row.index .. " " .. KIND_WORDS[OTHER_KIND[row.alt.kind]])
	end)
	local boxes = { { "cost", COST_X, COST_WIDTH }, { "time", TIME_X, TIME_WIDTH }, { "req", REQ_X, REQ_WIDTH } }
	for _, spec in ipairs(boxes) do
		local box = Inputs.CreateBox(row, { width = spec[3], onCommit = function(text)
			setDetail(row, spec[1], text)
		end })
		box:SetPoint("LEFT", spec[2], 0)
		row[spec[1]] = box
	end
	row.remove = Widgets.CreateButton(row, L.INPUT_REMOVE, REMOVE_WIDTH)
	row.remove:SetPoint("LEFT", REMOVE_X, 0)
	row.remove:SetScript("OnClick", function()
		run("alt remove " .. row.index)
	end)
	panel.rows[i] = row
end

local function buildAddRow(panel, frame)
	panel.newKind = "PLANNED"
	panel.slot = Inputs.CreateItemSlot(frame, function(itemID)
		panel.pendingItemID = itemID
		Inputs.SetSlotItem(panel.slot, itemID)
		Panel.UpdateAddRow(panel)
	end)
	panel.slot:SetPoint("BOTTOMLEFT", 0, 0)
	panel.kindToggle = Widgets.CreateButton(frame, "", KIND_WIDTH)
	panel.kindToggle:SetPoint("LEFT", panel.slot, "RIGHT", GAP, 0)
	panel.kindToggle:SetScript("OnClick", function()
		panel.newKind = OTHER_KIND[panel.newKind]
		Panel.UpdateAddRow(panel)
	end)
	panel.add = Widgets.CreateButton(frame, L.ALT_ADD, KIND_WIDTH)
	panel.add:SetPoint("LEFT", panel.kindToggle, "RIGHT", GAP, 0)
	panel.add:SetScript("OnClick", function()
		Panel.AddPending(panel)
	end)
end

-- Creates the panel inside `parent` (the Craft tab frame) and returns it; hidden by default.
function Panel.Build(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:Hide()
	local panel = { frame = frame, rows = {}, offset = 0 }
	header(frame, ITEM_X, L.ALT_COL_ITEM)
	header(frame, KIND_X, L.ALT_COL_KIND)
	header(frame, COST_X, L.ALT_COL_COST)
	header(frame, TIME_X, L.ALT_COL_TIME)
	header(frame, REQ_X, L.ALT_COL_REQ)
	for i = 1, VISIBLE_ROWS do
		buildRow(panel, frame, i)
	end
	panel.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	panel.emptyText:SetPoint("TOPLEFT", 0, ROWS_Y)
	panel.emptyText:SetText(L.ALT_PANEL_EMPTY)
	buildAddRow(panel, frame)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		panel.offset = math.max(0, panel.offset - delta)
		Panel.Refresh(panel)
	end)
	Panel.UpdateAddRow(panel)
	return panel
end

function Panel.UpdateAddRow(panel)
	panel.kindToggle:SetText(L[KIND_LABELS[panel.newKind]])
	Widgets.SetEnabled(panel.add, panel.pendingItemID ~= nil and not ns.readOnly)
end

function Panel.AddPending(panel)
	if not panel.pendingItemID then
		return
	end
	run("alt add " .. panel.pendingItemID .. " " .. KIND_WORDS[panel.newKind])
	panel.pendingItemID = nil
	Inputs.SetSlotItem(panel.slot, nil)
	Panel.UpdateAddRow(panel)
end

local function drawRow(row, index, alt)
	row.index, row.alt = index, alt
	if not alt then
		row:Hide()
		return
	end
	row.item:SetText(UIShared.ItemText(alt.itemID))
	row.kind:SetText(L[KIND_LABELS[alt.kind]])
	Inputs.SetValue(row.cost, alt.copper and Money.Format(alt.copper) or "")
	Inputs.SetValue(row.time, Util.DurationInput(alt.seconds))
	Inputs.SetValue(row.req, alt.requires or "")
	row:Show()
end

function Panel.Refresh(panel)
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local list = charData and charData.craftEval.alternatives or {}
	panel.offset = math.min(panel.offset, math.max(0, #list - VISIBLE_ROWS))
	for i, row in ipairs(panel.rows) do
		local index = panel.offset + i
		drawRow(row, index, list[index])
	end
	Widgets.SetShown(panel.emptyText, #list == 0)
	Panel.UpdateAddRow(panel)
end
