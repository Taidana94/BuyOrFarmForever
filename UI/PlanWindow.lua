-- Plan window ("Jetzt tun"): a small movable window with the steps of the active plan as a checklist
-- (UI/PlanCommands.lua, Core/ActivePlan.lua). A click on a step ticks or unticks it by hand; the
-- addon ticks steps itself when the game shows them done. Header: progress and gold since the start.
-- Buttons: "Beenden" ends the plan with its result. Created on first open, refreshed only while shown.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets

local PlanWindow = {}
ns.PlanWindow = PlanWindow

PlanWindow.SCALE = 0.85
local WIDTH, PADDING, HEADER_HEIGHT, ROW_HEIGHT, FOOTER_HEIGHT = 520, 14, 56, 16, 44
-- Space between two steps; the detail line below a title gets the height of its wrapped text.
local ROW_GAP, CHECK_SIZE, VALUE_WIDTH, TEXT_X, DETAIL_GAP = 8, 16, 120, 22, 2
local BUTTON_WIDTH = 100
local CHECK_ON = "Interface\\Buttons\\UI-CheckBox-Check"
local CHECK_OFF = "Interface\\Buttons\\UI-CheckBox-Up"
local DONE_COLOR, COLOR_END = "|cff808080", "|r"
local REFRESH_SIGNALS = { "PLAN_CHANGED", "MONEY_CHANGED", "ITEM_LOADED", "DATA_CHANGED", "BAGS_CHANGED" }

local Window = {}
Window.__index = Window
Widgets.MixRefresh(Window)

local window

local function savePosition(frame)
	frame:StopMovingOrSizing()
	local point, _, _, x, y = frame:GetPoint()
	local position = ns.db.settings.planWindow
	position.point, position.x, position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
end

local function buildFrame()
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, HEADER_HEIGHT + FOOTER_HEIGHT + ROW_HEIGHT)
	frame:SetScale(PlanWindow.SCALE)
	frame:SetFrameStrata("MEDIUM")
	-- Own frame level band before any child is created, so the small windows never interleave.
	frame:SetFrameLevel(Widgets.WINDOW_LEVELS.PLAN)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", savePosition)
	local position = ns.db.settings.planWindow
	frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(L.PLAN_WINDOW_TITLE)
	return frame
end

local function buildRow(win, frame, index)
	local row = CreateFrame("Button", nil, frame)
	row:SetSize(WIDTH - 2 * PADDING, ROW_HEIGHT)
	if index == 1 then
		row:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT)
	else
		row:SetPoint("TOPLEFT", win.rows[index - 1], "BOTTOMLEFT", 0, -ROW_GAP)
	end
	row.check = row:CreateTexture(nil, "ARTWORK")
	row.check:SetSize(CHECK_SIZE, CHECK_SIZE)
	row.check:SetPoint("TOPLEFT", 0, 1)
	row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.value:SetPoint("TOPRIGHT")
	row.value:SetWidth(VALUE_WIDTH)
	row.value:SetJustifyH("RIGHT")
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.text:SetPoint("TOPLEFT", TEXT_X, 0)
	row.text:SetWidth(WIDTH - 2 * PADDING - TEXT_X - VALUE_WIDTH)
	row.text:SetJustifyH("LEFT")
	row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.detail:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -DETAIL_GAP)
	row.detail:SetWidth(WIDTH - 2 * PADDING - TEXT_X)
	row.detail:SetJustifyH("LEFT")
	row:SetScript("OnClick", function()
		ns.Inputs.Run("plan " .. index)
	end)
	win.rows[index] = row
end

local function create()
	local win = setmetatable({ rows = {} }, Window)
	local frame = buildFrame()
	win.frame = frame
	win.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	win.status:SetPoint("TOPLEFT", PADDING, -PADDING - ROW_HEIGHT)
	win.status:SetWidth(WIDTH - 2 * PADDING)
	win.status:SetJustifyH("LEFT")
	for i = 1, ns.ActivePlan.MAX_STEPS do
		buildRow(win, frame, i)
	end
	win.stop = Widgets.CreateButton(frame, L.PLAN_BTN_STOP, BUTTON_WIDTH)
	win.stop:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
	win.stop:SetScript("OnClick", function()
		ns.Inputs.Run("plan stop")
	end)
	win.start = Widgets.CreateButton(frame, L.PLAN_BTN_START, BUTTON_WIDTH)
	win.start:SetPoint("BOTTOMLEFT", PADDING, PADDING)
	win.start:SetScript("OnClick", function()
		ns.Inputs.Run("plan start")
	end)
	Widgets.InitRefresh(win, REFRESH_SIGNALS)
	frame:SetScript("OnShow", function()
		win:Activate()
	end)
	frame:SetScript("OnHide", function()
		win:Deactivate()
	end)
	return win
end

-- Fills a row with step `index` (tick, title, gold, grey details); returns its height.
local function drawRow(row, index, step, ctx)
	local gone, total = ns.ActivePlan.ItemProgress(step, ctx)
	local title, value, detail = ns.PlanStepText.Parts(step, not step.done and gone or nil, total)
	title = Util.Format(L.GOLD_SOURCE_NUMBERED, index, title)
	row.check:SetTexture(step.done and CHECK_ON or CHECK_OFF)
	row.text:SetText(step.done and DONE_COLOR .. title .. COLOR_END or title)
	row.value:SetText(value)
	row.detail:SetText(detail)
	return (row.text:GetStringHeight() or ROW_HEIGHT) + DETAIL_GAP + (row.detail:GetStringHeight() or ROW_HEIGHT)
end

function Window:Refresh()
	local active = ns.PlanCommands.Active()
	local steps = active and active.steps or {}
	local ctx = ns.PlanCommands.Context()
	local listHeight = 0
	for i, row in ipairs(self.rows) do
		Widgets.SetShown(row, steps[i] ~= nil)
		if steps[i] then
			local height = math.max(ROW_HEIGHT, drawRow(row, i, steps[i], ctx))
			row:SetHeight(height)
			listHeight = listHeight + height + ROW_GAP
		end
	end
	if active then
		local done, total = ns.ActivePlan.Progress(active)
		local earned = (ns.Client:GetMoney() or 0) - active.startMoney
		self.status:SetText(Util.Format(L.PLAN_STATUS, done, total, Money.Format(earned)))
	else
		self.status:SetText(L.PLAN_NONE)
	end
	Widgets.SetEnabled(self.stop, active ~= nil)
	Widgets.SetEnabled(self.start, active == nil)
	self.frame:SetHeight(HEADER_HEIGHT + FOOTER_HEIGHT + math.max(ROW_HEIGHT, listHeight))
end

function PlanWindow.Toggle()
	if not (ns.db and ns.charKey) or ns.readOnly then
		ns.Log.Print(ns.readOnly and L.READ_ONLY_NO_ACCESS or L.NOT_READY)
		return
	end
	window = window or create()
	Widgets.SetShown(window.frame, not window.frame:IsShown())
end

function PlanWindow.Show()
	if not (window and window.frame:IsShown()) then
		PlanWindow.Toggle()
	end
end

-- The window object, or nil before the first open (for tests).
function PlanWindow.Get()
	return window
end
