-- Short texts of a plan step for the "Jetzt tun" window (UI/PlanWindow.lua): a title ("Herstellen:
-- 2× [Leinenumhang]"), the gold value for the right edge and one grey detail line (time, sale chance,
-- what to buy first, alt, progress). The long one-line texts of the chat stay in UI/GoldPlanCommands.lua.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local UIShared = ns.UIShared

local PlanStepText = {}
ns.PlanStepText = PlanStepText

local PERCENT = 100

local function buyList(task)
	local parts = {}
	for i, entry in ipairs(task.toBuy or {}) do
		parts[i] = Util.Format(L.GOLDPLAN_BUY_PART, entry.units, UIShared.ItemText(entry.itemID))
	end
	return #parts > 0 and Util.Format(L.STEP_BUY, table.concat(parts, L.PLAN_SEPARATOR)) or nil
end

local function taskDetails(task, details)
	if task.chance and task.chance < 1 then
		details[#details + 1] = Util.Format(L.STEP_CHANCE, math.floor(task.chance * PERCENT + 0.5))
	end
	details[#details + 1] = task.untested and L.STEP_UNTESTED or nil
	if task.charKey then
		details[#details + 1] = Util.Format(L.STEP_ON_ALT, (ns.Stock.SplitKey(task.charKey)))
	end
	details[#details + 1] = buyList(task)
end

local TASK_TITLES = {
	CRAFT = function(task)
		return Util.Format(L.STEP_CRAFT, task.crafts, UIShared.ItemText(task.itemID))
	end,
	COOLDOWN = function(task)
		return Util.Format(L.STEP_COOLDOWN, task.crafts, UIShared.ItemText(task.itemID))
	end,
	FLIP = function(task)
		return Util.Format(L.STEP_FLIP, task.units, UIShared.ItemText(task.itemID), Money.Format(task.buy))
	end,
	SELL_VENDOR = function(task)
		return Util.Format(L.STEP_SELL_VENDOR, task.units)
	end,
	SELL_AUCTION = function(task)
		return Util.Format(L.STEP_SELL_AUCTION, task.units)
	end,
	DISENCHANT = function(task)
		return Util.Format(L.STEP_DISENCHANT, task.units)
	end,
}

local function taskParts(step, details)
	local task = step.task
	taskDetails(task, details)
	local value = task.sure + task.auction
	return TASK_TITLES[task.kind](task), value > 0 and Money.Format(value) or ""
end

-- title, value (text for the right edge, "" for none), detail line ("" for none) of a step; the
-- progress of a sell step (gone, total) is added to the details.
function PlanStepText.Parts(step, gone, total)
	local details = { Util.Format(L.STEP_TIME, Util.FormatDuration(step.seconds)) }
	local title, value
	if step.kind == "TASK" then
		title, value = taskParts(step, details)
	elseif step.kind == "TRAVEL" then
		title, value = Util.Format(L.STEP_TRAVEL, ns.FarmCommands.RouteName(step.method)), ""
	else
		title, value = Util.Format(L.STEP_FARM, ns.FarmCommands.RouteName(step.method)), Money.Format(step.sure)
		if step.auction > 0 then
			details[#details + 1] = Util.Format(L.STEP_AUCTION_EXTRA, Money.Format(step.auction))
		end
	end
	if gone then
		details[#details + 1] = Util.Format(L.STEP_PROGRESS, gone, total)
	end
	return title, value, table.concat(details, L.STEP_SEPARATOR)
end
