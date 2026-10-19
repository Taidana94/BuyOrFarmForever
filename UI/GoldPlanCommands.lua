-- Gold planner commands: /bof goldsources (the character's farm routes with gold per hour) and
-- the text lines shared with the planner view of the Gold buffer tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Slash = ns.Slash
local UIShared = ns.UIShared

local GoldPlanCommands = {}
ns.GoldPlanCommands = GoldPlanCommands

-- "Gegner in Westfall: 2g pro Std. sicher + 1g im AH, Anreise 3 Min. (2 Runden, 40 Min.)"
function GoldPlanCommands.RouteLine(route)
	local line = Util.Format(L.GOLD_SOURCE_LINE, ns.FarmCommands.RouteName(route), Money.Format(route.surePerHour),
		Money.Format(route.auctionPerHour), Util.FormatDuration(route.travelSeconds), route.runs,
		Util.FormatDuration(route.activeSeconds))
	if route.runsWithoutCoins > 0 then
		line = line .. Util.Format(L.GOLD_SOURCE_NO_COINS, route.runsWithoutCoins)
	end
	return line
end

-- Lines of all routes (best first), or one line explaining that data is missing.
function GoldPlanCommands.SourceLines()
	local routes = ns.GoldRoutes.Current()
	if #routes == 0 then
		return { Util.Format(L.GOLD_SOURCES_NONE, Util.FormatDuration(ns.GoldRoutes.MIN_SECONDS)) }
	end
	local lines = {}
	for i, route in ipairs(routes) do
		lines[i] = Util.Format(L.GOLD_SOURCE_NUMBERED, i, GoldPlanCommands.RouteLine(route))
	end
	return lines
end

local function sourcesCommand()
	if not UIShared.Character() then
		return
	end
	Log.Print(Util.Format(L.GOLD_SOURCES_HEADER, ns.db.settings.ahDiscountPercent))
	for _, line in ipairs(GoldPlanCommands.SourceLines()) do
		Log.Print(line)
	end
end

if ns.Client then
	Slash.AddCommand("goldsources", sourcesCommand, L.HELP_LINE_GOLDSOURCES)
end
