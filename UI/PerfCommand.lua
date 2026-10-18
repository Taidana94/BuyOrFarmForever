-- /bof perf: memory, share of frame time and the duration of a stock refresh, for docs/TESTING.md.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Perf = ns.Perf
local Materials = ns.Materials
local Stock = ns.Stock
local UIShared = ns.UIShared

local PERCENT_DECIMALS = 2
local KB_DECIMALS = 0
local MS_DECIMALS = 3

local function percent(metric)
	local share = metric and Perf.Share(metric)
	if not share then
		return L.PERF_UNAVAILABLE
	end
	return Util.FormatDecimal(share * 100, PERCENT_DECIMALS)
end

local function printCPU()
	local metrics = ns.Client:GetCPUMetrics(ns.ADDON_NAME)
	if not metrics then
		Log.Print(L.PERF_CPU_OFF)
		return
	end
	Log.Print(Util.Format(L.PERF_CPU, percent(metrics.recent), percent(metrics.average), percent(metrics.peak)))
end

-- Times one recount of all goals of the character (what the window does on a bag change).
local function printTiming()
	local charData = UIShared.Character()
	if not charData then
		return
	end
	local goals = Materials.AllGoals(charData)
	local rows
	local ms = Perf.Measure(function()
		rows = Stock.Rows(charData, goals)
	end)
	local msText = ms and Util.FormatDecimal(ms, MS_DECIMALS) or L.PERF_UNAVAILABLE
	Log.Print(Util.Format(L.PERF_TIMING, msText, #rows))
end

local function perfCommand()
	Log.Print(L.PERF_HEADER)
	local kb = Perf.MemoryKB(ns.ADDON_NAME)
	Log.Print(Util.Format(L.PERF_MEMORY, kb and Util.FormatDecimal(kb, KB_DECIMALS) or L.PERF_UNAVAILABLE))
	printCPU()
	printTiming()
end

if ns.Client then
	ns.Slash.AddCommand("perf", perfCommand, L.HELP_LINE_PERF)
end
