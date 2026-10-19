-- Craft tab of the main window, two views (buttons at the top right): the craft evaluation of the
-- selected goal as text lines (the same lines as /bof craft) with the stat weights as boxes, and
-- the alternatives editor (UI/CraftAltPanel.lua). Same refresh rules as the other tabs: events only
-- while shown, refreshes coalesced to one per frame.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local UIShared = ns.UIShared
local CraftEval = ns.CraftEval
local CraftCommands = ns.CraftCommands
local AltPanel = ns.CraftAltPanel

local CraftTab = {}
ns.CraftTab = CraftTab

local MAX_LINES = 12
local LINE_GAP = 6
local LINES_Y, TEXT_WIDTH = -30, 690
local WEIGHTS_Y, HINT_Y, WEIGHT_BOX_WIDTH, WEIGHT_GAP = 30, 8, 36, 6
local NAV_BUTTON_WIDTH, NAV_GAP, GOAL_TEXT_GAP, MODE_WIDTH = 26, 4, 8, 110
local STAT_WORDS = { STR = "str", AGI = "agi", STA = "sta", INT = "int", SPI = "spi" }
local REFRESH_SIGNALS = {
	"EQUIPMENT_CHANGED", "BAGS_CHANGED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED", "MONEY_CHANGED",
}

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local function buildNavigation(tab, frame)
	tab.prev = Widgets.CreateButton(frame, L.WINDOW_PREV, NAV_BUTTON_WIDTH)
	tab.prev:SetPoint("TOPLEFT", 0, 0)
	tab.next = Widgets.CreateButton(frame, L.WINDOW_NEXT, NAV_BUTTON_WIDTH)
	tab.next:SetPoint("LEFT", tab.prev, "RIGHT", NAV_GAP, 0)
	tab.prev:SetScript("OnClick", function()
		tab:StepGoal(-1)
	end)
	tab.next:SetScript("OnClick", function()
		tab:StepGoal(1)
	end)
	tab.goalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.goalText:SetPoint("LEFT", tab.next, "RIGHT", GOAL_TEXT_GAP, 0)
	tab.goalText:SetJustifyH("LEFT")
	tab.altMode = Widgets.CreateButton(frame, L.CRAFT_MODE_ALTERNATIVES, MODE_WIDTH)
	tab.altMode:SetPoint("TOPRIGHT", 0, 0)
	tab.altMode:SetScript("OnClick", function()
		tab:SetMode("ALTERNATIVES")
	end)
	tab.evalMode = Widgets.CreateButton(frame, L.CRAFT_MODE_EVALUATION, MODE_WIDTH)
	tab.evalMode:SetPoint("RIGHT", tab.altMode, "LEFT", -NAV_GAP, 0)
	tab.evalMode:SetScript("OnClick", function()
		tab:SetMode("EVALUATION")
	end)
end

-- "Gewichte: Stärke [1] Beweglichkeit [1] …" at the bottom of the evaluation view.
local function buildWeights(tab, frame)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("BOTTOMLEFT", 0, WEIGHTS_Y)
	label:SetText(L.CRAFT_WEIGHTS_LABEL)
	tab.weightBoxes = {}
	local previous = label
	for _, stat in ipairs(CraftEval.STATS) do
		local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		name:SetPoint("LEFT", previous, "RIGHT", WEIGHT_GAP * 2, 0)
		name:SetText(L["STAT_" .. stat])
		local box = Inputs.CreateBox(frame, { width = WEIGHT_BOX_WIDTH, onCommit = function(text)
			Inputs.Run("weights " .. STAT_WORDS[stat] .. " " .. text)
		end })
		box:SetPoint("LEFT", name, "RIGHT", WEIGHT_GAP, 0)
		tab.weightBoxes[stat] = box
		previous = box
	end
	tab.hintText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.hintText:SetPoint("BOTTOMLEFT", 0, HINT_Y)
	tab.hintText:SetText(L.CRAFT_TAB_WEIGHTS_HINT)
end

function CraftTab.Create(parent)
	local tab = setmetatable({ mode = "EVALUATION" }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildNavigation(tab, frame)
	tab.evaluation = CreateFrame("Frame", nil, frame)
	tab.evaluation:SetAllPoints()
	tab.lines = Widgets.CreateTextStack(tab.evaluation, {
		count = MAX_LINES, font = "GameFontHighlightSmall", y = LINES_Y, width = TEXT_WIDTH, gap = LINE_GAP,
	})
	buildWeights(tab, tab.evaluation)
	tab.alternatives = AltPanel.Build(frame)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

function Tab:SetMode(mode)
	self.mode = mode
	self:Refresh()
end

function Tab:StepGoal(step)
	if UIShared.StepGoal(step) then
		self:Refresh()
	end
end

function Tab:ShowLines(lines)
	for i, text in ipairs(self.lines) do
		text:SetText(lines[i] or "")
	end
end

-- Weight boxes show "1" or "1,5".
local function weightText(value)
	return Util.FormatDecimal(value, value == math.floor(value) and 0 or 1)
end

function Tab:UpdateWeights(weights)
	for stat, box in pairs(self.weightBoxes) do
		Inputs.SetValue(box, weightText(weights[stat]))
	end
end

function Tab:Refresh()
	local isAlt = self.mode == "ALTERNATIVES"
	Widgets.SetShown(self.evaluation, not isAlt)
	Widgets.SetShown(self.alternatives.frame, isAlt)
	Widgets.SetEnabled(self.altMode, not isAlt)
	Widgets.SetEnabled(self.evalMode, isAlt)
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	if not charData then
		self.goalText:SetText("")
		self:ShowLines({ L.NOT_READY })
		return
	end
	if isAlt then
		self.goalText:SetText(L.CRAFT_ALT_HEADER)
		AltPanel.Refresh(self.alternatives)
		return
	end
	self:RefreshEvaluation(charData)
end

function Tab:RefreshEvaluation(charData)
	self:UpdateWeights(charData.craftEval.weights)
	local hasGoals = #ns.Materials.ListGoalIDs(charData) > 0
	Widgets.SetEnabled(self.prev, hasGoals and not ns.readOnly)
	Widgets.SetEnabled(self.next, hasGoals and not ns.readOnly)
	-- The craft evaluation is per goal; with "all goals" the selected goal is evaluated.
	local goal, id = ns.Materials.GetActiveGoal(charData)
	if not goal then
		self.goalText:SetText("")
		self:ShowLines({ #ns.Materials.ListGoalIDs(charData) == 0 and L.GOAL_LIST_EMPTY or L.WINDOW_NO_GOAL_SELECTED })
		return
	end
	self.goalText:SetText(Util.Format(L.CRAFT_HEADER, id, UIShared.GoalName(goal)))
	self:ShowLines(CraftCommands.EvaluationLines(charData, goal))
end
