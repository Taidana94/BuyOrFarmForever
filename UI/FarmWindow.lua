-- Farm window: a small movable window with the run's status line and four buttons (Start,
-- Pause/Fortsetzen, Anreise/Angekommen, Beenden) that run the /bof farm commands (user request
-- 0.10.0: farm runs are controlled here, the Farm tab only lists the routes). Created on first open,
-- refreshed only while shown; a 1-second ticker updates the times while shown and a run is running.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local FarmRuns = ns.FarmRuns

local FarmWindow = {}
ns.FarmWindow = FarmWindow

FarmWindow.SCALE = 0.85
local WIDTH, HEIGHT, PADDING = 340, 104, 14
local BUTTON_WIDTH, BUTTON_GAP = 74, 4
local STATUS_Y = -38
local TIMER_SECONDS = 1
local REFRESH_SIGNALS = { "FARM_CHANGED", "DATA_CHANGED", "ITEM_LOADED" }

local Window = {}
Window.__index = Window
Widgets.MixRefresh(Window)
local baseDeactivate = Window.Deactivate

local window

local function savePosition(frame)
	frame:StopMovingOrSizing()
	local point, _, _, x, y = frame:GetPoint()
	local position = ns.db.settings.farmWindow
	position.point, position.x, position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
end

local function buildFrame()
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetScale(FarmWindow.SCALE)
	frame:SetFrameStrata("MEDIUM")
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", savePosition)
	local position = ns.db.settings.farmWindow
	frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(L.FARM_WINDOW_TITLE)
	return frame
end

local function run(command)
	ns.Inputs.Run("farm " .. command)
end

-- Start, Pause/Fortsetzen, Anreise/Angekommen, Beenden in one row at the bottom.
local function buildButtons(win, frame)
	local specs = {
		{ key = "start", label = L.FARM_BTN_START, click = function()
			run("start")
		end },
		{ key = "pause", label = L.FARM_BTN_PAUSE, click = function()
			run(win.paused and "resume" or "pause")
		end },
		{ key = "travel", label = L.FARM_BTN_TRAVEL, click = function()
			run("travel")
		end },
		{ key = "stop", label = L.FARM_BTN_STOP, click = function()
			run("stop")
		end },
	}
	win.buttons = {}
	for i, spec in ipairs(specs) do
		local button = Widgets.CreateButton(frame, spec.label, BUTTON_WIDTH)
		button:SetPoint("BOTTOMLEFT", PADDING + (i - 1) * (BUTTON_WIDTH + BUTTON_GAP), PADDING)
		button:SetScript("OnClick", spec.click)
		win.buttons[spec.key] = button
	end
end

local function create()
	local win = setmetatable({}, Window)
	local frame = buildFrame()
	win.frame = frame
	win.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	win.statusText:SetPoint("TOPLEFT", PADDING, STATUS_Y)
	win.statusText:SetWidth(WIDTH - 2 * PADDING)
	win.statusText:SetJustifyH("LEFT")
	buildButtons(win, frame)
	Widgets.InitRefresh(win, REFRESH_SIGNALS)
	win.tick = function()
		win:UpdateStatus()
	end
	frame:SetScript("OnShow", function()
		win:Activate()
	end)
	frame:SetScript("OnHide", function()
		win:Deactivate()
	end)
	return win
end

local function currentRun()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	return charData, charData and FarmRuns.Current(charData)
end

function Window:UpdateStatus()
	local _, farmRun = currentRun()
	self.statusText:SetText(farmRun and ns.FarmCommands.StatusLine(farmRun, ns.Client:GetServerTime()) or L.FARM_WINDOW_IDLE)
end

-- Starts or cancels the ticker that updates the shown times.
function Window:UpdateTicker(running)
	if running and not self.ticker then
		-- PERF-OK: 1 s ticker only while this window is shown and a run is running (no event for passing
		-- time); it only rewrites one text and is cancelled when the run stops or the window hides.
		self.ticker = C_Timer.NewTicker(TIMER_SECONDS, self.tick)
	elseif not running and self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
end

function Window:Deactivate()
	baseDeactivate(self)
	self:UpdateTicker(false)
end

function Window:Refresh()
	local charData, farmRun = currentRun()
	local canWrite = charData ~= nil and not ns.readOnly
	local state = farmRun and farmRun.state
	local running = FarmRuns.IsRunning(farmRun)
	self.paused = state == "PAUSED"
	Widgets.SetEnabled(self.buttons.start, canWrite and not farmRun)
	Widgets.SetEnabled(self.buttons.pause, canWrite and (running or self.paused))
	Widgets.SetEnabled(self.buttons.travel, canWrite and running)
	Widgets.SetEnabled(self.buttons.stop, canWrite and farmRun ~= nil)
	self.buttons.pause:SetText(self.paused and L.FARM_BTN_RESUME or L.FARM_BTN_PAUSE)
	self.buttons.travel:SetText(state == "TRAVEL" and L.FARM_BTN_ARRIVED or L.FARM_BTN_TRAVEL)
	self:UpdateStatus()
	self:UpdateTicker(running and self.frame:IsVisible())
end

function FarmWindow.Toggle()
	if not (ns.db and ns.charKey) or ns.readOnly then
		ns.Log.Print(ns.readOnly and L.READ_ONLY_NO_ACCESS or L.NOT_READY)
		return
	end
	window = window or create()
	Widgets.SetShown(window.frame, not window.frame:IsShown())
end

function FarmWindow.Show()
	if not (window and window.frame:IsShown()) then
		FarmWindow.Toggle()
	end
end

-- The window object, or nil before the first open (for tests).
function FarmWindow.Get()
	return window
end
