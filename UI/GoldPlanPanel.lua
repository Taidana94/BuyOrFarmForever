-- Planner view of the Gold tab: time buttons (1, 2, 4 hours) and a duration box, three view
-- buttons, and below them either the plan for that time (summary, steps, alternatives, the farm
-- routes with gold per hour), the comparison of the strategies, or the account overview; an item
-- slot for the keep list. Same lines as /bof goldplan, /bof goldsources, /bof compare and
-- /bof account; inputs run those commands.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local GoldPlanCommands = ns.GoldPlanCommands

local Panel = {}
ns.GoldPlanPanel = Panel

local MAX_STEPS, MAX_SOURCES, MAX_LIST = 8, 4, 10
local TIME_BUTTON_WIDTH, DURATION_BOX_WIDTH, VIEW_BUTTON_WIDTH, START_BUTTON_WIDTH, GAP = 60, 70, 80, 110, 6
-- Views of the lower part, in button order; the view is not stored (the plan shows first).
local VIEWS = { "PLAN", "COMPARE", "ACCOUNT" }
-- The view buttons get their own row: the time row shares its height with the Gold tab's mode buttons.
local VIEW_ROW_Y, SUMMARY_Y, STEPS_Y, ALTERNATIVES_Y, SOURCES_HEADER_Y, SOURCES_Y = -32, -62, -92, -222, -244, -260
-- Space between the summary (one or two lines) and the steps or list below it.
local SUMMARY_GAP = 10
local LINE_GAP, SOURCE_GAP, TEXT_WIDTH, KEEP_TEXT_WIDTH = 4, 2, 700, 600
-- Kept items shown as icons next to the slot (right-click removes one); more are counted.
local MAX_KEEP_ICONS, KEEP_ICON_SIZE = 12, 20

local function createText(frame, font, y)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint("TOPLEFT", 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

local function buildTimeRow(panel, frame)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, -6)
	label:SetText(L.GOLDPLAN_TIME_LABEL)
	panel.timeButtons = {}
	local previous = label
	for _, seconds in ipairs(GoldPlanCommands.DURATIONS) do
		local button = Widgets.CreateButton(frame, Util.FormatDuration(seconds), TIME_BUTTON_WIDTH)
		button:SetPoint("LEFT", previous, "RIGHT", GAP, 0)
		button:SetScript("OnClick", function()
			Panel.SetDuration(panel, seconds)
		end)
		panel.timeButtons[seconds] = button
		previous = button
	end
	panel.durationBox = Inputs.CreateBox(frame, { width = DURATION_BOX_WIDTH, onCommit = function(text)
		local seconds = Util.ParseDuration(text)
		if seconds and seconds > 0 then
			Panel.SetDuration(panel, seconds)
		else
			ns.UIShared.PrintError("invalid_duration")
		end
	end })
	panel.durationBox:SetPoint("LEFT", previous, "RIGHT", GAP * 2, 0)
	-- Plan with or without selling on the auction house (setting planUseAuction).
	panel.auctionCheck = Widgets.CreateCheck(frame, L.GOLDPLAN_USE_AUCTION, function(checked)
		Inputs.Run("set planUseAuction " .. (checked and "on" or "off"))
	end)
	panel.auctionCheck:SetPoint("LEFT", panel.durationBox, "RIGHT", GAP * 2, 0)
end

local function buildViewButtons(panel, frame)
	panel.viewButtons = {}
	for i, view in ipairs(VIEWS) do
		local button = Widgets.CreateButton(frame, L["GOLDPLAN_VIEW_" .. view], VIEW_BUTTON_WIDTH)
		button:SetPoint("TOPLEFT", (i - 1) * (VIEW_BUTTON_WIDTH + GAP), VIEW_ROW_Y)
		button:SetScript("OnClick", function()
			panel.view = view
			Panel.Refresh(panel)
		end)
		panel.viewButtons[view] = button
	end
	-- Starts the shown plan as a checklist (UI/PlanWindow.lua).
	panel.startButton = Widgets.CreateButton(frame, L.PLAN_BTN_START, START_BUTTON_WIDTH)
	panel.startButton:SetPoint("TOPLEFT", #VIEWS * (VIEW_BUTTON_WIDTH + GAP) + GAP, VIEW_ROW_Y)
	panel.startButton:SetScript("OnClick", function()
		Inputs.Run("plan start " .. Util.DurationInput(panel.seconds))
	end)
end

-- "Behalten: [slot] Kupfererz, Ruhestein …" at the bottom.
local function buildKeepRow(panel, frame)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("BOTTOMLEFT", 0, Inputs.SLOT_SIZE / 2 - LINE_GAP)
	label:SetText(L.GOLDPLAN_KEEP_LABEL)
	panel.keepSlot = Inputs.CreateItemSlot(frame, function(itemID)
		Inputs.Run("goldkeep " .. itemID)
	end)
	panel.keepSlot:SetPoint("LEFT", label, "RIGHT", GAP, 0)
	panel.keepIcons = {}
	for i = 1, MAX_KEEP_ICONS do
		local icon = Inputs.CreateItemIcon(frame, KEEP_ICON_SIZE, L.GOLDPLAN_KEEP_REMOVE_HINT, function(itemID)
			Inputs.Run("goldkeep " .. itemID)
		end)
		icon:SetPoint("LEFT", i == 1 and panel.keepSlot or panel.keepIcons[i - 1], "RIGHT", GAP / 2, 0)
		panel.keepIcons[i] = icon
	end
	panel.keepText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	panel.keepText:SetWidth(KEEP_TEXT_WIDTH)
	panel.keepText:SetJustifyH("LEFT")
end

-- Builds the view inside `parent` (hidden until the tab shows it). Returns the panel object.
function Panel.Build(parent)
	local panel = { seconds = GoldPlanCommands.DURATIONS[1], view = "PLAN" }
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:Hide()
	panel.frame = frame
	buildTimeRow(panel, frame)
	buildViewButtons(panel, frame)
	panel.summary = createText(frame, "GameFontHighlight", SUMMARY_Y)
	panel.steps = Widgets.CreateTextStack(frame, {
		count = MAX_STEPS, font = "GameFontHighlightSmall", y = STEPS_Y, width = TEXT_WIDTH, gap = LINE_GAP,
	})
	panel.alternatives = createText(frame, "GameFontDisableSmall", ALTERNATIVES_Y)
	panel.sourcesHeader = createText(frame, "GameFontNormalSmall", SOURCES_HEADER_Y)
	panel.sources = Widgets.CreateTextStack(frame, {
		count = MAX_SOURCES, font = "GameFontHighlightSmall", y = SOURCES_Y, width = TEXT_WIDTH, gap = SOURCE_GAP,
	})
	panel.list = Widgets.CreateTextStack(frame, {
		count = MAX_LIST, font = "GameFontHighlightSmall", y = STEPS_Y, width = TEXT_WIDTH, gap = LINE_GAP,
	})
	-- The steps and lists follow the summary, however many lines it wraps to.
	for _, stack in ipairs({ panel.steps, panel.list }) do
		stack[1]:ClearAllPoints()
		stack[1]:SetPoint("TOPLEFT", panel.summary, "BOTTOMLEFT", 0, -SUMMARY_GAP)
	end
	buildKeepRow(panel, frame)
	return panel
end

function Panel.SetDuration(panel, seconds)
	panel.seconds = seconds
	Panel.Refresh(panel)
end

local function showLines(texts, lines)
	for i, text in ipairs(texts) do
		text:SetText(lines[i] or "")
	end
end

local function setShownAll(texts, shown)
	for _, text in ipairs(texts) do
		Widgets.SetShown(text, shown)
	end
end

-- Shows the widgets of the plan view or the list of the other views.
local function showView(panel)
	local isPlan = panel.view == "PLAN"
	setShownAll(panel.steps, isPlan)
	setShownAll(panel.sources, isPlan)
	setShownAll(panel.list, not isPlan)
	Widgets.SetShown(panel.alternatives, isPlan)
	Widgets.SetShown(panel.sourcesHeader, isPlan)
	for view, button in pairs(panel.viewButtons) do
		Widgets.SetEnabled(button, view ~= panel.view)
	end
end

-- Comparison and account view: the first line as the summary, the rest as the list.
local function refreshList(panel, charData)
	local lines = panel.view == "COMPARE" and GoldPlanCommands.CompareLines(charData, panel.seconds)
		or ns.AccountCommands.Lines()
	panel.summary:SetText(table.remove(lines, 1))
	showLines(panel.list, lines)
end

local function refreshPlan(panel, charData)
	local steps, summary, alternatives = GoldPlanCommands.PlanTexts(GoldPlanCommands.Plan(charData, panel.seconds), panel.seconds)
	panel.summary:SetText(summary)
	showLines(panel.steps, steps)
	panel.alternatives:SetText(alternatives)
	panel.sourcesHeader:SetText(Util.Format(L.GOLD_SOURCES_HEADER, ns.db.settings.ahDiscountPercent))
	showLines(panel.sources, GoldPlanCommands.SourceLines())
end

function Panel.Refresh(panel)
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	for seconds, button in pairs(panel.timeButtons) do
		Widgets.SetEnabled(button, seconds ~= panel.seconds)
	end
	showView(panel)
	panel.auctionCheck:SetChecked(ns.db ~= nil and ns.db.settings.planUseAuction)
	if not charData or ns.readOnly then
		panel.summary:SetText(L.NOT_READY)
		showLines(panel.steps, {})
		showLines(panel.list, {})
		return
	end
	local isButton = panel.timeButtons[panel.seconds] ~= nil
	Inputs.SetValue(panel.durationBox, isButton and "" or Util.DurationInput(panel.seconds))
	if panel.view == "PLAN" then
		refreshPlan(panel, charData)
	else
		refreshList(panel, charData)
	end
	Panel.RefreshKeep(panel, charData)
end

local function keptIDs(charData)
	local ids = {}
	for itemID in pairs(charData.goldKeep) do
		ids[#ids + 1] = itemID
	end
	table.sort(ids)
	return ids
end

-- One icon per kept item (at most MAX_KEEP_ICONS), then the hint for an empty list or "+n".
function Panel.RefreshKeep(panel, charData)
	local ids = keptIDs(charData)
	local anchor = panel.keepSlot
	for i, icon in ipairs(panel.keepIcons) do
		Inputs.SetSlotItem(icon, ids[i])
		Widgets.SetShown(icon, ids[i] ~= nil)
		anchor = ids[i] and icon or anchor
	end
	panel.keepText:ClearAllPoints()
	panel.keepText:SetPoint("LEFT", anchor, "RIGHT", GAP, 0)
	local more = #ids - MAX_KEEP_ICONS
	panel.keepText:SetText(#ids == 0 and L.GOLDPLAN_KEEP_EMPTY or more > 0 and Util.Format(L.GOLDPLAN_KEEP_MORE, more) or "")
end
