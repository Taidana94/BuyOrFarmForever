-- Craft tab of the main window: the craft evaluation of the selected goal as text lines (the
-- same lines as /bof craft), the stat weights and a hint to the commands. Same refresh rules as
-- the other tabs: events only while shown, refreshes coalesced to one per frame.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local UIShared = ns.UIShared
local CraftCommands = ns.CraftCommands

local CraftTab = {}
ns.CraftTab = CraftTab

local MAX_LINES = 12
local LINE_HEIGHT = 18
local MARGIN_X, MARGIN_TOP, MARGIN_BOTTOM = 22, 46, 20
local LINES_Y, TEXT_WIDTH = -26, 590
local WEIGHTS_Y, HINT_Y = 40, 22
local NAV_BUTTON_WIDTH, NAV_GAP, GOAL_TEXT_GAP = 26, 4, 8
local REFRESH_SIGNALS = {
	"EQUIPMENT_CHANGED", "BAGS_CHANGED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED", "MONEY_CHANGED",
}

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local function createText(frame, font, y, anchor)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint(anchor, 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

function CraftTab.Create(parent)
	local tab = setmetatable({ lines = {} }, Tab)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", MARGIN_X, -MARGIN_TOP)
	frame:SetPoint("BOTTOMRIGHT", -MARGIN_X, MARGIN_BOTTOM)
	tab.frame = frame
	-- Goal navigation as in the Material tab (the selection is shared).
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
	for i = 1, MAX_LINES do
		tab.lines[i] = createText(frame, "GameFontHighlightSmall", LINES_Y - (i - 1) * LINE_HEIGHT, "TOPLEFT")
	end
	tab.weightsText = createText(frame, "GameFontHighlightSmall", WEIGHTS_Y, "BOTTOMLEFT")
	tab.hintText = createText(frame, "GameFontDisableSmall", HINT_Y, "BOTTOMLEFT")
	tab.hintText:SetText(L.CRAFT_TAB_WEIGHTS_HINT)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
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

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	if not charData then
		self.goalText:SetText("")
		self:ShowLines({ L.NOT_READY })
		return
	end
	self.weightsText:SetText(CraftCommands.WeightsLine(charData.craftEval.weights))
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
	self.goalText:SetText(ns.Util.Format(L.CRAFT_HEADER, id, UIShared.GoalName(goal)))
	self:ShowLines(CraftCommands.EvaluationLines(charData, goal))
end
