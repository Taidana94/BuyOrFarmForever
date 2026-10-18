-- Net income of a character: every change of the carried gold while online counts as a gain or a
-- spending (loot, quests, sales, purchases, repairs, mail and trade alike), together with the time
-- online. Stored per day (server time / 86400) in characters[charKey].income, at most MAX_DAYS
-- days. From this the net gold per hour online gives the time value of a purchase.
local _, ns = ...

local Income = {}
ns.Income = Income

Income.MAX_DAYS = 60
-- Rates from less than this much online time are not shown (too little data).
Income.MIN_SECONDS = 3600
local SECONDS_PER_DAY = 86400
local SECONDS_PER_HOUR = 3600
-- Online time between two checkpoints longer than this counts only up to it (sleeping clients,
-- missing logout after a crash).
local MAX_GAP_SECONDS = 1800

local function dayOf(serverTime)
	return math.floor(serverTime / SECONDS_PER_DAY)
end

local function dayRecord(charData, day)
	local record = charData.income[day]
	if not record then
		record = { gained = 0, spent = 0, seconds = 0 }
		charData.income[day] = record
	end
	return record
end

-- Drops the oldest days beyond MAX_DAYS.
local function prune(charData)
	local days = {}
	for day in pairs(charData.income) do
		days[#days + 1] = day
	end
	if #days <= Income.MAX_DAYS then
		return
	end
	table.sort(days)
	for i = 1, #days - Income.MAX_DAYS do
		charData.income[days[i]] = nil
	end
end

-- Records a change of the carried gold (positive = gained, negative = spent).
function Income.RecordChange(charData, delta, now)
	if delta == 0 then
		return
	end
	local record = dayRecord(charData, dayOf(now))
	if delta > 0 then
		record.gained = record.gained + delta
	else
		record.spent = record.spent - delta
	end
	prune(charData)
end

-- Adds online time between two checkpoints (capped, see MAX_GAP_SECONDS).
function Income.RecordTime(charData, fromTime, toTime)
	local seconds = math.min(MAX_GAP_SECONDS, math.max(0, toTime - fromTime))
	if seconds > 0 then
		local record = dayRecord(charData, dayOf(toTime))
		record.seconds = record.seconds + seconds
	end
end

-- Totals over the last `days` days up to `now`: { gained, spent, net, seconds, perHour (nil with
-- less than MIN_SECONDS online) }.
function Income.Summary(charData, now, days)
	local first = dayOf(now) - (days - 1)
	local summary = { gained = 0, spent = 0, seconds = 0 }
	for day, record in pairs(charData.income) do
		if day >= first then
			summary.gained = summary.gained + record.gained
			summary.spent = summary.spent + record.spent
			summary.seconds = summary.seconds + record.seconds
		end
	end
	summary.net = summary.gained - summary.spent
	if summary.seconds >= Income.MIN_SECONDS then
		summary.perHour = summary.net * SECONDS_PER_HOUR / summary.seconds
	end
	return summary
end

-- Online seconds needed to earn `cost` again at the net rate, or nil (no data or no net gain).
function Income.TimeToEarn(summary, cost)
	if not summary.perHour or summary.perHour <= 0 then
		return nil
	end
	return cost / summary.perHour * SECONDS_PER_HOUR
end

-- Validation of stored income (registered with DB.VALIDATORS).
local function validRecord(record)
	return type(record) == "table" and type(record.gained) == "number" and record.gained >= 0
		and type(record.spent) == "number" and record.spent >= 0 and type(record.seconds) == "number"
		and record.seconds >= 0
end

function Income.Sanitize(charData, path, repairs)
	local changed = false
	for day, record in pairs(charData.income) do
		if type(day) ~= "number" or not validRecord(record) then
			charData.income[day] = nil
			changed = true
		end
	end
	if changed then
		repairs[#repairs + 1] = path .. ".income"
	end
	prune(charData)
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Income.Sanitize
