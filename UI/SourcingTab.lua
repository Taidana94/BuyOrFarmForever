-- Sourcing tab of the main window: the plan for the missing materials of the selected goal (or
-- all goals) under the chosen strategy and budget. Same refresh rules as the Material tab:
-- events only while shown, refreshes coalesced to one per frame.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Sourcing = ns.Sourcing
local Widgets = ns.Widgets
local UIShared = ns.UIShared
local PlanCommands = ns.PlanCommands
local Layout = ns.SourcingTabLayout

local SourcingTab = {}
ns.SourcingTab = SourcingTab

local REFRESH_SIGNALS = {
	"BAGS_CHANGED", "BANK_OPENED", "BANK_CLOSED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED", "MONEY_CHANGED",
}

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

function SourcingTab.Create(parent)
	local tab = setmetatable({ offset = 0, lines = {} }, Tab)
	Layout.Build(tab, parent)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

-- Tooltip: price per unit, the farm time of the planned part (as in the table, split into farm
-- time and travel) and the farm time for the whole missing amount.
local function tooltipLines(line, input)
	local lines = {}
	if input.unitPrice then
		local template = input.priceOutdated and L.PLAN_TIP_PRICE_OUTDATED or L.PLAN_TIP_PRICE
		lines[#lines + 1] = Util.Format(template, Money.Format(input.unitPrice))
	else
		lines[#lines + 1] = L.PLAN_TIP_NO_PRICE
	end
	if line.byproduct > 0 then
		lines[#lines + 1] = Util.Format(L.PLAN_TIP_BYPRODUCT, line.byproduct)
	end
	if input.secondsPerUnit then
		local travel = Util.FormatDuration(input.travelSeconds)
		if line.farm > 0 then
			lines[#lines + 1] = Util.Format(L.PLAN_TIP_PLANNED, line.farm,
				Util.FormatDuration(input.secondsPerUnit * line.farm), travel)
		end
		lines[#lines + 1] = Util.Format(L.PLAN_TIP_FARM, line.missing,
			Util.FormatDuration(input.secondsPerUnit * line.missing), travel)
	else
		lines[#lines + 1] = L.FARM_ESTIMATE_NONE
	end
	return lines
end

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local canWrite = ns.db ~= nil and not ns.readOnly
	local strategy = ns.db.settings.strategy
	for key, button in pairs(self.strategyButtons) do
		Widgets.SetEnabled(button, canWrite and key ~= strategy)
	end
	-- Switching goals only matters when one goal is shown (not "all goals").
	local hasGoals = charData ~= nil and #ns.Materials.ListGoalIDs(charData) > 0
	local canStep = canWrite and hasGoals and not ns.db.settings.window.allGoals
	Widgets.SetEnabled(self.prev, canStep)
	Widgets.SetEnabled(self.next, canStep)
	local budget, isOwn = Sourcing.Budget()
	self.budgetText:SetText(PlanCommands.BudgetText(budget, isOwn))
	ns.Inputs.SetValue(self.budgetBox, isOwn and Money.Format(budget) or "")
	ns.Inputs.SetValue(self.limitBox, Util.DurationInput(Sourcing.TimeLimit()))
	local goals, headerText, emptyText = nil, "", L.NOT_READY
	if charData then
		goals, headerText, emptyText = UIShared.GoalSelection(charData)
	end
	self.goalText:SetText(headerText)
	self.limitText:SetText("")
	self.routeText:SetText("")
	if not goals then
		self:Show({}, emptyText, "", {})
		return
	end
	local plan, inputs = PlanCommands.CurrentPlan(charData, goals)
	for i, line in ipairs(plan.lines) do
		line.tooltipLines = tooltipLines(line, inputs[i])
	end
	if #plan.lines == 0 then
		self:Show({}, L.FARM_NOTHING_MISSING, "", {})
		return
	end
	self.limitText:SetText(PlanCommands.LimitText(plan))
	self.routeText:SetText(PlanCommands.RouteText(inputs))
	self:Show(plan.lines, "", PlanCommands.SummaryText(plan), PlanCommands.CostNotes(charData, plan))
end

-- notes = { reserve text, time value text } (PlanCommands.CostNotes), may be empty.
function Tab:Show(lines, emptyText, summary, notes)
	self.lines = lines
	self.emptyText:SetText(emptyText)
	self.summaryText:SetText(summary)
	self.reserveText:SetText(notes[1] or "")
	self.timeValueText:SetText(notes[2] or "")
	self:Scroll(0)
end

function Tab:Scroll(delta)
	local maxOffset = math.max(0, #self.lines - Layout.VISIBLE_ROWS)
	self.offset = math.min(maxOffset, math.max(0, self.offset + delta))
	for i, row in ipairs(self.rows) do
		self:DrawRow(row, self.lines[self.offset + i])
	end
end

local function count(text, value)
	if value > 0 then
		Widgets.SetText(text, tostring(value), Widgets.COLOR_NORMAL)
	else
		Widgets.SetText(text, L.WINDOW_OFF, Widgets.COLOR_GRAY)
	end
end

function Tab:DrawRow(row, line)
	row.data = line
	if not line then
		row:Hide()
		return
	end
	row.icon:SetTexture(ns.Client:GetItemIcon(line.itemID))
	row.name:SetText(UIShared.ItemText(line.itemID))
	Widgets.SetText(row.numbers.missing, tostring(line.missing), line.open > 0 and Widgets.COLOR_MISSING or Widgets.COLOR_NORMAL)
	count(row.numbers.buy, line.buy)
	Widgets.SetText(row.numbers.cost, line.buy > 0 and Money.Format(line.cost) or L.WINDOW_OFF,
		line.priceOutdated and Widgets.COLOR_GRAY or Widgets.COLOR_NORMAL)
	count(row.numbers.farm, line.farm)
	Widgets.SetText(row.numbers.farmTime, line.farm > 0 and Util.FormatDuration(line.farmSeconds) or L.WINDOW_OFF,
		Widgets.COLOR_NORMAL)
	row:Show()
end

function Tab:StepGoal(step)
	if UIShared.StepGoal(step) then
		self.offset = 0
		self:Refresh()
	end
end

function Tab:SetStrategy(strategy)
	if not (ns.db and not ns.readOnly and Sourcing.STRATEGIES[strategy]) then
		return
	end
	ns.db.settings.strategy = strategy
	self.offset = 0
	self:Refresh()
end
