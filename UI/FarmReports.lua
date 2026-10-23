-- Farm time estimate of a material as text, with its data basis.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local FarmEstimates = ns.FarmEstimates

local FarmReports = {}
ns.FarmReports = FarmReports

-- Estimate line for one missing material.
function FarmReports.EstimateText(itemID, missing)
	local scope = ns.db.settings.farmEstimateScope
	local basis = FarmEstimates.ForItem(ns.db, itemID, scope, ns.charKey)
	if not basis then
		return L.FARM_ESTIMATE_NONE
	end
	local seconds, low, high = FarmEstimates.TimeFor(basis, missing)
	local source = Util.Format(L.FARM_ESTIMATE_BASIS, basis.runs, Util.FormatDuration(basis.seconds))
	if not seconds then
		return Util.Format(L.FARM_ESTIMATE_NO_YIELD, source)
	end
	local travel = Util.FormatDuration(basis.travelSeconds)
	if low then
		return Util.Format(L.FARM_ESTIMATE_RANGE, Util.FormatDuration(seconds), Util.FormatDuration(low),
			Util.FormatDuration(high), travel, source)
	end
	return Util.Format(L.FARM_ESTIMATE, Util.FormatDuration(seconds), travel, source)
end
