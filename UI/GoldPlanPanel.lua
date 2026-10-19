-- Planner view of the Gold buffer tab: time buttons (1, 2, 4 hours) and a duration box, the plan
-- for that time (summary, steps, alternatives), the farm routes with gold per hour and an item slot
-- for the keep list. Same lines as /bof goldplan and /bof goldsources; inputs run those commands.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local GoldPlanCommands = ns.GoldPlanCommands

local Panel = {}
ns.GoldPlanPanel = Panel

local MAX_STEPS, MAX_SOURCES = 8, 4
local TIME_BUTTON_WIDTH, DURATION_BOX_WIDTH, GAP = 60, 70, 6
local SUMMARY_Y, STEPS_Y, ALTERNATIVES_Y, SOURCES_HEADER_Y, SOURCES_Y = -30, -52, -186, -208, -224
local LINE_GAP, SOURCE_GAP, TEXT_WIDTH, KEEP_TEXT_WIDTH = 4, 2, 700, 600

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
end

local function buildKeepRow(panel, frame)
	panel.keepSlot = Inputs.CreateItemSlot(frame, function(itemID)
		Inputs.Run("goldkeep " .. itemID)
	end)
	panel.keepSlot:SetPoint("BOTTOMLEFT", 0, 0)
	panel.keepText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	panel.keepText:SetPoint("LEFT", panel.keepSlot, "RIGHT", GAP, 0)
	panel.keepText:SetWidth(KEEP_TEXT_WIDTH)
	panel.keepText:SetJustifyH("LEFT")
end

-- Builds the view inside `parent` (hidden until the tab shows it). Returns the panel object.
function Panel.Build(parent)
	local panel = { seconds = GoldPlanCommands.DURATIONS[1] }
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:Hide()
	panel.frame = frame
	buildTimeRow(panel, frame)
	panel.summary = createText(frame, "GameFontHighlight", SUMMARY_Y)
	panel.steps = Widgets.CreateTextStack(frame, {
		count = MAX_STEPS, font = "GameFontHighlightSmall", y = STEPS_Y, width = TEXT_WIDTH, gap = LINE_GAP,
	})
	panel.alternatives = createText(frame, "GameFontDisableSmall", ALTERNATIVES_Y)
	panel.sourcesHeader = createText(frame, "GameFontNormalSmall", SOURCES_HEADER_Y)
	panel.sources = Widgets.CreateTextStack(frame, {
		count = MAX_SOURCES, font = "GameFontHighlightSmall", y = SOURCES_Y, width = TEXT_WIDTH, gap = SOURCE_GAP,
	})
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

function Panel.Refresh(panel)
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	for seconds, button in pairs(panel.timeButtons) do
		Widgets.SetEnabled(button, seconds ~= panel.seconds)
	end
	if not charData or ns.readOnly then
		panel.summary:SetText(L.NOT_READY)
		showLines(panel.steps, {})
		return
	end
	local isButton = panel.timeButtons[panel.seconds] ~= nil
	Inputs.SetValue(panel.durationBox, isButton and "" or Util.DurationInput(panel.seconds))
	local steps, summary, alternatives = GoldPlanCommands.PlanTexts(GoldPlanCommands.Plan(charData, panel.seconds), panel.seconds)
	panel.summary:SetText(summary)
	showLines(panel.steps, steps)
	panel.alternatives:SetText(alternatives)
	panel.sourcesHeader:SetText(Util.Format(L.GOLD_SOURCES_HEADER, ns.db.settings.ahDiscountPercent))
	showLines(panel.sources, GoldPlanCommands.SourceLines())
	local kept = 0
	for _ in pairs(charData.goldKeep) do
		kept = kept + 1
	end
	panel.keepText:SetText(Util.Format(L.GOLDPLAN_KEEP_HINT, kept))
end
