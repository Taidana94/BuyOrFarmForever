-- /bof week: weekly review in the chat (Core/WeekReview.lua).
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log
local Money = ns.Money
local UIShared = ns.UIShared

local WeekCommand = {}
ns.WeekCommand = WeekCommand

local PERCENT = 100

local function planLine(plans)
	if plans.count == 0 then
		return L.WEEK_PLANS_NONE
	end
	local share = plans.planned > 0 and math.floor(plans.earned * PERCENT / plans.planned + 0.5) or 0
	return Util.Format(L.WEEK_PLANS, plans.count, Money.Format(plans.earned), Money.Format(plans.planned), share)
end

-- The lines of the review.
function WeekCommand.Lines(charData)
	local review = ns.WeekReview.Build(charData, ns.Client:GetServerTime())
	local week, before = review.week, review.before
	local lines = {
		Util.Format(L.WEEK_HEADER, ns.WeekReview.DAYS),
		Util.Format(L.WEEK_NET, Money.Format(week.net), Money.Format(week.gained), Money.Format(week.spent),
			Money.Format(before.net)),
		Util.Format(L.WEEK_TIME, Util.FormatDuration(week.seconds),
			week.perHour and Money.Format(math.floor(week.perHour)) or L.WEEK_TOO_LITTLE),
	}
	lines[#lines + 1] = ns.GoldCommands.SourcesLine(charData, ns.WeekReview.DAYS)
	lines[#lines + 1] = planLine(review.plans)
	lines[#lines + 1] = Util.Format(L.WEEK_RUNS, review.runs.count, Util.FormatDuration(review.runs.seconds))
	return lines
end

local function weekCommand()
	local charData = UIShared.Character()
	if charData then
		for _, line in ipairs(WeekCommand.Lines(charData)) do
			Log.Print(line)
		end
	end
end

if ns.Client then
	ns.Slash.AddCommand("week", weekCommand, L.HELP_LINE_WEEK)
end
