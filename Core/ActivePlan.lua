-- Active plan ("Jetzt tun"): a gold plan (Core/GoldPlan.lua) the player started, stored per character
-- as a checklist, whose steps tick themselves off when the game shows they are done. Pure logic: the
-- game state comes from a context of functions. Stored: plain fields of each step's task or method
-- (no localized text) and the bag counts at the start, so the step texts are rebuilt for display.
--
-- Done when (otherwise the player ticks the step by hand):
--   SELL_VENDOR, SELL_AUCTION, DISENCHANT  the planned units of every item left the bags
--   CRAFT, COOLDOWN                        the bags hold the planned crafts more of the product
--   FLIP                                   the bags hold the planned units more of the item
--   TRAVEL                                 the player is in the route's zone
--   METHOD (farm route)                    a farm run in that zone was saved after the start
-- Crafts on another character are ticked by hand only.
--
-- ctx = { bagCount(itemID), mapID(), runsSince(uiMapID, fishing, time) -> count, money, now, charKey }
local _, ns = ...

local ActivePlan = {}
ns.ActivePlan = ActivePlan

ActivePlan.MAX_STEPS = 12
local TASK_FIELDS = { "kind", "itemID", "crafts", "units", "seconds", "sure", "auction", "buy", "sell", "charKey", "spend", "chance",
	"untested" }
local METHOD_FIELDS = { "uiMapID", "fishing", "crafted", "productItemID", "travelSeconds" }

local function copyFields(source, fields)
	if not source then
		return nil
	end
	local copy = {}
	for _, field in ipairs(fields) do
		copy[field] = source[field]
	end
	return copy
end

local function baselineOf(task, ctx)
	local baseline = {}
	for itemID in pairs(task and task.items or {}) do
		baseline[itemID] = ctx.bagCount(itemID)
	end
	if task and task.itemID then
		baseline[task.itemID] = ctx.bagCount(task.itemID)
	end
	return baseline
end

local function stepOf(step, ctx)
	local task = copyFields(step.task, TASK_FIELDS)
	if task then
		task.items = step.task.items and ns.Util.CopyTable(step.task.items)
		task.toBuy = step.task.toBuy and ns.Util.CopyTable(step.task.toBuy)
	end
	return { kind = step.kind, seconds = step.seconds, sure = step.sure or 0, auction = step.auction or 0, task = task,
		method = copyFields(step.method, METHOD_FIELDS), baseline = baselineOf(step.task, ctx), done = false }
end

-- Stores `plan` as the character's active plan. Returns it, or nil plus "empty".
function ActivePlan.Start(charData, plan, ctx)
	if #plan.steps == 0 then
		return nil, "empty"
	end
	local active = { startedAt = ctx.now, startMoney = ctx.money, plannedSure = plan.sure, plannedAuction = plan.auction,
		seconds = plan.seconds, steps = {} }
	for i = 1, math.min(#plan.steps, ActivePlan.MAX_STEPS) do
		active.steps[i] = stepOf(plan.steps[i], ctx)
	end
	charData.activePlan = active
	return active
end

local function itemsGone(step, ctx)
	for itemID, count in pairs(step.task.items or {}) do
		if ctx.bagCount(itemID) > (step.baseline[itemID] or 0) - count then
			return false
		end
	end
	return true
end

local function gained(step, ctx, amount)
	local itemID = step.task.itemID
	return ctx.bagCount(itemID) >= (step.baseline[itemID] or 0) + amount
end

local TASK_CHECKS = {
	SELL_VENDOR = itemsGone,
	SELL_AUCTION = itemsGone,
	DISENCHANT = itemsGone,
	CRAFT = function(step, ctx)
		return gained(step, ctx, step.task.crafts or 1)
	end,
	FLIP = function(step, ctx)
		return gained(step, ctx, step.task.units or 1)
	end,
}
TASK_CHECKS.COOLDOWN = TASK_CHECKS.CRAFT

local function isDone(step, active, ctx)
	if step.kind == "TRAVEL" then
		return step.method ~= nil and ctx.mapID() == step.method.uiMapID
	elseif step.kind == "METHOD" then
		return step.method ~= nil and ctx.runsSince(step.method.uiMapID, step.method.fishing, active.startedAt) > 0
	end
	local check = TASK_CHECKS[step.task.kind]
	local own = not step.task.charKey or step.task.charKey == ctx.charKey
	return check ~= nil and own and check(step, ctx)
end

-- Ticks off the steps the game shows as done (a ticked step stays ticked; a step the player set by
-- hand is left alone). Returns the number of steps that changed.
function ActivePlan.Update(active, ctx)
	local changed = 0
	for _, step in ipairs(active.steps) do
		if not (step.done or step.manual) and isDone(step, active, ctx) then
			step.done, changed = true, changed + 1
		end
	end
	return changed
end

-- Progress of a step with items to get rid of (sell, post, disenchant): units gone and planned units,
-- or nil for other steps.
function ActivePlan.ItemProgress(step, ctx)
	if not (step.task and step.task.items and TASK_CHECKS[step.task.kind] == itemsGone) then
		return nil
	end
	local gone, total = 0, 0
	for itemID, count in pairs(step.task.items) do
		local left = ctx.bagCount(itemID) - ((step.baseline[itemID] or 0) - count)
		gone, total = gone + math.min(count, math.max(0, count - left)), total + count
	end
	return gone, total
end

-- Ticks a step by hand or unticks it. Returns the new state, or nil for an unknown index.
function ActivePlan.Toggle(active, index)
	local step = active.steps[index]
	if not step then
		return nil
	end
	step.done, step.manual = not step.done, true
	return step.done
end

-- Done steps and all steps.
function ActivePlan.Progress(active)
	local done = 0
	for _, step in ipairs(active.steps) do
		done = done + (step.done and 1 or 0)
	end
	return done, #active.steps
end

-- Validation (registered with DB.VALIDATORS): a broken active plan is dropped.
function ActivePlan.Sanitize(charData, path, repairs)
	local active = charData.activePlan
	if active == nil then
		return
	end
	local ok = type(active) == "table" and type(active.steps) == "table" and type(active.startedAt) == "number"
		and type(active.startMoney) == "number"
	for _, step in ipairs(ok and active.steps or {}) do
		ok = ok and type(step) == "table" and type(step.kind) == "string" and type(step.baseline) == "table"
	end
	if not ok then
		charData.activePlan = nil
		repairs[#repairs + 1] = path .. ".activePlan"
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = ActivePlan.Sanitize
