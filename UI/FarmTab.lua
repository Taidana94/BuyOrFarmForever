-- Farm tab of the main window: buttons for the farm run (start, pause/resume, travel, stop, keep
-- unclear gains, save, discard), the run's status and items, and the farm time estimates for the
-- selected goal. The buttons run the same /bof farm commands as the chat, so there is one code
-- path. While the tab is visible and a run is running, a 1-second ticker updates the time line.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local FarmRuns = ns.FarmRuns
local FarmCommands = ns.FarmCommands

local FarmTab = {}
ns.FarmTab = FarmTab

local MAX_ITEM_LINES = 6
local MAX_ESTIMATE_LINES = 4
local LINE_HEIGHT = 16
local MARGIN_X, MARGIN_TOP, MARGIN_BOTTOM = 22, 46, 20
local BUTTON_WIDTH, BUTTON_GAP = 120, 6
local START_Y, CONTROL_Y, STATUS_Y = 0, -28, -60
local ITEMS_Y = -80
local ESTIMATE_HEADER_Y = -186
local TEXT_WIDTH = 590
local TIMER_SECONDS = 1
local REFRESH_SIGNALS = { "FARM_CHANGED", "DATA_CHANGED", "ITEM_LOADED", "BAGS_CHANGED" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)
local baseDeactivate = Tab.Deactivate

local function run(command)
	ns.Slash.Handle("farm " .. command)
end

local function createText(frame, font, y)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint("TOPLEFT", 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

-- A row of buttons at y: { { key, label, command } }; returns { [key] = button }.
local function createButtonRow(frame, y, specs)
	local buttons, previous = {}, nil
	for _, spec in ipairs(specs) do
		local button = Widgets.CreateButton(frame, L[spec.label], BUTTON_WIDTH)
		if previous then
			button:SetPoint("LEFT", previous, "RIGHT", BUTTON_GAP, 0)
		else
			button:SetPoint("TOPLEFT", 0, y)
		end
		button:SetScript("OnClick", function()
			run(spec.command)
		end)
		buttons[spec.key] = button
		previous = button
	end
	return buttons
end

local function createLines(frame, count, y)
	local lines = {}
	for i = 1, count do
		lines[i] = createText(frame, "GameFontHighlightSmall", y - (i - 1) * LINE_HEIGHT)
	end
	return lines
end

function FarmTab.Create(parent)
	local tab = setmetatable({}, Tab)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", MARGIN_X, -MARGIN_TOP)
	frame:SetPoint("BOTTOMRIGHT", -MARGIN_X, MARGIN_BOTTOM)
	tab.frame = frame
	tab.startButtons = createButtonRow(frame, START_Y, {
		{ key = "gather", label = "FARM_BTN_GATHER", command = "start gather" },
		{ key = "mobs", label = "FARM_BTN_MOBS", command = "start mobs" },
		{ key = "other", label = "FARM_BTN_OTHER", command = "start other" },
	})
	tab.controls = createButtonRow(frame, CONTROL_Y, {
		{ key = "pause", label = "FARM_BTN_PAUSE", command = "pause" },
		{ key = "resume", label = "FARM_BTN_RESUME", command = "resume" },
		{ key = "travel", label = "FARM_BTN_TRAVEL", command = "travel" },
		{ key = "stop", label = "FARM_BTN_STOP", command = "stop" },
	})
	-- In review the second row offers keep/save/discard at the same place.
	tab.review = createButtonRow(frame, CONTROL_Y, {
		{ key = "keep", label = "FARM_BTN_KEEP", command = "keep all" },
		{ key = "save", label = "FARM_BTN_SAVE", command = "save" },
		{ key = "discard", label = "FARM_BTN_DISCARD", command = "discard" },
	})
	tab.statusText = createText(frame, "GameFontHighlight", STATUS_Y)
	tab.itemLines = createLines(frame, MAX_ITEM_LINES, ITEMS_Y)
	tab.estimateHeader = createText(frame, "GameFontNormalSmall", ESTIMATE_HEADER_Y)
	tab.estimateLines = createLines(frame, MAX_ESTIMATE_LINES, ESTIMATE_HEADER_Y - LINE_HEIGHT)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	tab.tick = function()
		tab:UpdateStatus()
	end
	return tab
end

local function setTexts(texts, lines)
	for i, text in ipairs(texts) do
		text:SetText(lines[i] or "")
	end
end

local function setShown(buttons, shown)
	for _, button in pairs(buttons) do
		if shown then
			button:Show()
		else
			button:Hide()
		end
	end
end

local function currentRun()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	return charData, charData and FarmRuns.Current(charData)
end

-- Only the status line changes every second; everything else waits for events.
function Tab:UpdateStatus()
	local _, farmRun = currentRun()
	self.statusText:SetText(farmRun and FarmCommands.StatusLine(farmRun, ns.Client:GetServerTime()) or L.FARM_NONE)
end

-- Starts or cancels the ticker that updates the shown farm time.
function Tab:UpdateTicker(running)
	if running and not self.ticker then
		-- PERF-OK: 1 s ticker only while this tab is visible and a run is running (no event for passing
		-- time); it only rewrites one text and is cancelled when the run stops or the tab hides.
		self.ticker = C_Timer.NewTicker(TIMER_SECONDS, self.tick)
	elseif not running and self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
end

function Tab:Deactivate()
	baseDeactivate(self)
	self:UpdateTicker(false)
end

function Tab:UpdateButtons(farmRun, canWrite)
	local state = farmRun and farmRun.state
	local inReview = state == "REVIEW"
	setShown(self.controls, not inReview)
	setShown(self.review, inReview)
	for _, button in pairs(self.startButtons) do
		Widgets.SetEnabled(button, canWrite and not farmRun)
	end
	local running = FarmRuns.IsRunning(farmRun)
	Widgets.SetEnabled(self.controls.pause, canWrite and running)
	Widgets.SetEnabled(self.controls.resume, canWrite and state == "PAUSED")
	Widgets.SetEnabled(self.controls.travel, canWrite and running)
	Widgets.SetEnabled(self.controls.stop, canWrite and farmRun ~= nil and not inReview)
	self.controls.travel:SetText(state == "TRAVEL" and L.FARM_BTN_ARRIVED or L.FARM_BTN_TRAVEL)
	for _, button in pairs(self.review) do
		Widgets.SetEnabled(button, canWrite and inReview)
	end
end

function Tab:Refresh()
	local charData, farmRun = currentRun()
	local canWrite = charData ~= nil and not ns.readOnly
	self:UpdateButtons(farmRun, canWrite)
	self:UpdateStatus()
	setTexts(self.itemLines, farmRun and FarmCommands.ItemLines(farmRun) or {})
	self:UpdateTicker(FarmRuns.IsRunning(farmRun) and self.frame:IsVisible())
	local goal = charData and ns.Materials.GetActiveGoal(charData)
	self.estimateHeader:SetText(goal and L.FARM_TAB_ESTIMATES or "")
	setTexts(self.estimateLines, goal and FarmCommands.EstimateLines(charData, goal) or {})
end
