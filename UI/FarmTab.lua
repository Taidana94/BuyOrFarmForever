-- Farm tab of the main window: buttons for the farm run (start, pause/resume, travel, stop, keep
-- unclear gains, save, discard), the target material (preselected: first missing material of the
-- selected goal, changeable with < >), the run's status and items (with "mitzählen" per unclear
-- item in review), and the farm time estimates for the selected goal. The buttons run the same
-- /bof farm commands as the chat, so there is one code path. While the tab is visible and a run
-- is running, a 1-second ticker updates the time line.
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
local BUTTON_WIDTH, BUTTON_GAP = 120, 6
local NAV_WIDTH, TARGET_X, KEEP_WIDTH, KEEP_X = 26, 390, 90, 600
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

-- A row of buttons at y: { { key, label, command } }; returns { [key] = button }. Commands may be
-- functions (evaluated on click).
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
			run(type(spec.command) == "function" and spec.command() or spec.command)
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

-- "Zielmaterial: < > [Item]" next to the start buttons.
local function buildTarget(tab, frame)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", TARGET_X, -BUTTON_GAP)
	label:SetText(L.FARM_TARGET_LABEL)
	tab.targetPrev = Widgets.CreateButton(frame, L.WINDOW_PREV, NAV_WIDTH)
	tab.targetPrev:SetPoint("LEFT", label, "RIGHT", BUTTON_GAP, 0)
	tab.targetPrev:SetScript("OnClick", function()
		tab:StepTarget(-1)
	end)
	tab.targetNext = Widgets.CreateButton(frame, L.WINDOW_NEXT, NAV_WIDTH)
	tab.targetNext:SetPoint("LEFT", tab.targetPrev, "RIGHT", BUTTON_GAP, 0)
	tab.targetNext:SetScript("OnClick", function()
		tab:StepTarget(1)
	end)
	tab.targetText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.targetText:SetPoint("LEFT", tab.targetNext, "RIGHT", BUTTON_GAP, 0)
end

-- One "mitzählen" button per item line, shown in review for items with unclear gains.
local function buildKeepButtons(tab, frame)
	tab.keepButtons = {}
	for i, line in ipairs(tab.itemLines) do
		local button = Widgets.CreateButton(frame, L.FARM_KEEP_ITEM, KEEP_WIDTH)
		button:SetPoint("LEFT", line, "LEFT", KEEP_X, 0)
		button:SetScript("OnClick", function()
			if button.itemID then
				run("keep " .. button.itemID)
			end
		end)
		tab.keepButtons[i] = button
	end
end

function FarmTab.Create(parent)
	local tab = setmetatable({}, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	local function startCommand(kind)
		return function()
			return "start " .. kind .. (tab.targetItemID and (" " .. tab.targetItemID) or "")
		end
	end
	tab.startButtons = createButtonRow(frame, START_Y, {
		{ key = "gather", label = "FARM_BTN_GATHER", command = startCommand("gather") },
		{ key = "mobs", label = "FARM_BTN_MOBS", command = startCommand("mobs") },
		{ key = "other", label = "FARM_BTN_OTHER", command = startCommand("other") },
	})
	buildTarget(tab, frame)
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
	buildKeepButtons(tab, frame)
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

-- Missing materials of the selected goal: the target choices.
local function missingItems(charData)
	local goal = charData and ns.Materials.GetActiveGoal(charData)
	local list = {}
	for _, row in ipairs(goal and ns.Stock.Rows(charData, { goal }) or {}) do
		if row.missing > 0 then
			list[#list + 1] = row.itemID
		end
	end
	return list
end

-- Target index 0 = no target, 1..n = missing item; the first missing item is preselected.
function Tab:UpdateTarget(charData, farmRun)
	self.targets = missingItems(charData)
	if not self.targetIndex or self.targetIndex > #self.targets then
		self.targetIndex = #self.targets > 0 and 1 or 0
	end
	self.targetItemID = self.targets[self.targetIndex]
	local shownID = farmRun and farmRun.targetItemID > 0 and farmRun.targetItemID or (not farmRun and self.targetItemID)
	self.targetText:SetText(shownID and ns.UIShared.ItemText(shownID) or L.FARM_NO_TARGET)
	local canChoose = not farmRun and #self.targets > 0
	Widgets.SetEnabled(self.targetPrev, canChoose)
	Widgets.SetEnabled(self.targetNext, canChoose)
end

function Tab:StepTarget(step)
	local count = #(self.targets or {})
	if count > 0 then
		self.targetIndex = (self.targetIndex + step) % (count + 1)
		self:Refresh()
	end
end

-- Item lines with a "mitzählen" button for unclear gains during review.
function Tab:UpdateItems(farmRun)
	local entries = farmRun and FarmCommands.ItemEntries(farmRun) or {}
	local inReview = farmRun ~= nil and farmRun.state == "REVIEW"
	for i, text in ipairs(self.itemLines) do
		local entry = entries[i]
		text:SetText(entry and entry.line or "")
		local button = self.keepButtons[i]
		button.itemID = entry and entry.itemID
		if inReview and entry and entry.unclear > 0 then
			button:Show()
		else
			button:Hide()
		end
	end
end

function Tab:Refresh()
	local charData, farmRun = currentRun()
	local canWrite = charData ~= nil and not ns.readOnly
	self:UpdateButtons(farmRun, canWrite)
	self:UpdateStatus()
	self:UpdateTarget(charData, farmRun)
	self:UpdateItems(farmRun)
	self:UpdateTicker(FarmRuns.IsRunning(farmRun) and self.frame:IsVisible())
	local goal = charData and ns.Materials.GetActiveGoal(charData)
	self.estimateHeader:SetText(goal and L.FARM_TAB_ESTIMATES or "")
	setTexts(self.estimateLines, goal and ns.FarmReports.EstimateLines(charData, goal) or {})
end
