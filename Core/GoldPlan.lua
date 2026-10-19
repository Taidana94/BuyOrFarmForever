-- Gold plan: what to do in a given time to make the most gold. Pure logic.
--
-- Inputs: one-off tasks (sell bag items, disenchant, craft; each { kind, seconds, sure, auction })
-- and repeatable methods (farm routes from GoldRoutes.List: surePerHour, auctionPerHour,
-- ratingPerHour, travelSeconds per trip). Sure gold is certain (vendor, coins); auction gold is
-- not guaranteed and counts with the discount (GoldRoutes.Rating) when choosing.
--
-- Choice: tasks in order of rating per second, each taken if it beats what the best method would
-- make in the same time; the rest of the time goes to the one method with the highest value
-- rating x (rest - travel). With linear rates and travel paid once per trip, one method is best for
-- the rest; switching would only add travel.
local _, ns = ...

local GoldPlan = {}
ns.GoldPlan = GoldPlan

local SECONDS_PER_HOUR = 3600
-- Other methods shown as alternatives to the chosen one.
GoldPlan.MAX_ALTERNATIVES = 2

local function methodValue(method, seconds)
	return math.max(0, seconds - method.travelSeconds) * method.ratingPerHour / SECONDS_PER_HOUR
end

local function bestMethod(methods, seconds)
	local best, bestValue = nil, 0
	for _, method in ipairs(methods) do
		local value = methodValue(method, seconds)
		if value > bestValue then
			best, bestValue = method, value
		end
	end
	return best, bestValue
end

local function sortedTasks(tasks, discount)
	local list = {}
	for _, task in ipairs(tasks) do
		task.rating = ns.GoldRoutes.Rating(task.sure, task.auction, discount)
		if task.rating > 0 and task.seconds > 0 then
			list[#list + 1] = task
		end
	end
	table.sort(list, function(a, b)
		return a.rating / a.seconds > b.rating / b.seconds
	end)
	return list
end

local function addStep(plan, step)
	plan.steps[#plan.steps + 1] = step
	plan.seconds = plan.seconds + step.seconds
	plan.sure = plan.sure + (step.sure or 0)
	plan.auction = plan.auction + (step.auction or 0)
end

local function addMethod(plan, method, rest)
	local farmSeconds = rest - method.travelSeconds
	if method.travelSeconds > 0 then
		addStep(plan, { kind = "TRAVEL", method = method, seconds = method.travelSeconds })
	end
	addStep(plan, { kind = "METHOD", method = method, seconds = farmSeconds,
		sure = method.surePerHour * farmSeconds / SECONDS_PER_HOUR,
		auction = method.auctionPerHour * farmSeconds / SECONDS_PER_HOUR })
end

-- Other methods with their value for the same time, best first (to explain the choice).
local function alternatives(methods, chosen, seconds)
	local list = {}
	for _, method in ipairs(methods) do
		local value = methodValue(method, seconds)
		if method ~= chosen and value > 0 then
			list[#list + 1] = { method = method, rating = value }
		end
	end
	table.sort(list, function(a, b)
		return a.rating > b.rating
	end)
	while #list > GoldPlan.MAX_ALTERNATIVES do
		table.remove(list)
	end
	return list
end

-- Plan for opts = { seconds, tasks, methods, discountPercent }.
-- Returns { steps = { { kind = "TASK" | "TRAVEL" | "METHOD", task | method, seconds, sure, auction } },
-- seconds, sure, auction, rating, alternatives = { { method, rating } } }.
function GoldPlan.Plan(opts)
	local plan = { steps = {}, seconds = 0, sure = 0, auction = 0 }
	local rest, methods = opts.seconds, opts.methods
	for _, task in ipairs(sortedTasks(opts.tasks, opts.discountPercent)) do
		local fits = task.seconds <= rest
		if fits and task.rating + select(2, bestMethod(methods, rest - task.seconds)) >= select(2, bestMethod(methods, rest)) then
			addStep(plan, { kind = "TASK", task = task, seconds = task.seconds, sure = task.sure, auction = task.auction })
			rest = rest - task.seconds
		end
	end
	local method = bestMethod(methods, rest)
	if method then
		addMethod(plan, method, rest)
	end
	plan.alternatives = method and alternatives(methods, method, rest) or {}
	plan.rating = ns.GoldRoutes.Rating(plan.sure, plan.auction, opts.discountPercent)
	return plan
end
