-- Farm time estimates as text: one line per missing material of a goal, with the data basis
-- (shared by /bof farm estimate and the Farm tab).
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Stock = ns.Stock
local FarmEstimates = ns.FarmEstimates
local UIShared = ns.UIShared

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

-- Estimate lines for the missing materials of a goal (shared with the Farm tab).
function FarmReports.EstimateLines(charData, goal)
	local lines = {}
	for _, row in ipairs(Stock.Rows(charData, { goal })) do
		if row.missing > 0 then
			lines[#lines + 1] = Util.Format(L.FARM_ESTIMATE_LINE, UIShared.ItemText(row.itemID), row.missing,
				FarmReports.EstimateText(row.itemID, row.missing))
		end
	end
	if #lines == 0 then
		lines[1] = L.FARM_NOTHING_MISSING
	end
	return lines
end
