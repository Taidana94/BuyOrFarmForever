-- Weekly review: the last seven days against the seven before (net gold, online time, gold per
-- hour), where the gold came from (Core/Income.lua sources), the finished plans ("Jetzt tun") with
-- their result against the plan, and the farm runs. Pure logic; finished plans are stored in
-- characters[charKey].planResults = { { endedAt, seconds, earned, planned } }, at most MAX_PLANS.
local _, ns = ...

local WeekReview = {}
ns.WeekReview = WeekReview

WeekReview.DAYS = 7
WeekReview.MAX_PLANS = 30
local SECONDS_PER_DAY = 86400

-- Stores the result of a plan that ends now.
function WeekReview.RecordPlan(charData, active, earned, now)
	local results = charData.planResults
	results[#results + 1] = { endedAt = now, seconds = now - active.startedAt, earned = earned,
		planned = active.plannedSure + active.plannedAuction }
	while #results > WeekReview.MAX_PLANS do
		table.remove(results, 1)
	end
end

local function planTotals(charData, since)
	local totals = { count = 0, earned = 0, planned = 0 }
	for _, result in ipairs(charData.planResults) do
		if result.endedAt >= since then
			totals.count = totals.count + 1
			totals.earned, totals.planned = totals.earned + result.earned, totals.planned + result.planned
		end
	end
	return totals
end

local function runTotals(since)
	local totals = { count = 0, seconds = 0 }
	for _, run in ipairs(ns.db.farmRuns) do
		if run.charKey == ns.charKey and run.endedAt >= since then
			totals.count, totals.seconds = totals.count + 1, totals.seconds + run.activeSeconds + run.travelSeconds
		end
	end
	return totals
end

-- { week, before (Income.Summary of this and the previous seven days), plans = { count, earned,
-- planned }, runs = { count, seconds } }.
function WeekReview.Build(charData, now)
	local span = WeekReview.DAYS * SECONDS_PER_DAY
	return {
		week = ns.Income.Summary(charData, now, WeekReview.DAYS),
		before = ns.Income.Summary(charData, now - span, WeekReview.DAYS),
		plans = planTotals(charData, now - span),
		runs = runTotals(now - span),
	}
end

local function validResult(result)
	return type(result) == "table" and type(result.endedAt) == "number" and type(result.seconds) == "number"
		and type(result.earned) == "number" and type(result.planned) == "number"
end

-- Validation (registered with DB.VALIDATORS): broken plan results are dropped.
function WeekReview.Sanitize(charData, path, repairs)
	if type(charData.planResults) ~= "table" then
		charData.planResults = {}
		repairs[#repairs + 1] = path .. ".planResults"
		return
	end
	for i = #charData.planResults, 1, -1 do
		if not validResult(charData.planResults[i]) then
			table.remove(charData.planResults, i)
			repairs[#repairs + 1] = path .. ".planResults"
		end
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = WeekReview.Sanitize
