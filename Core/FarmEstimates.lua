-- Farm time estimates from saved runs, with their data basis. Pure logic on db.farmRuns.
-- A run counts for an item if the item was its target or it yielded the item; runs with the
-- item as target and no yield are included (they lower the rate). Travel time is reported
-- separately as the average per run.
local _, ns = ...

local FarmEstimates = {}
ns.FarmEstimates = FarmEstimates

local function counts(run, itemID, scope, charKey)
	if scope == "CHARACTER" and run.charKey ~= charKey then
		return false
	end
	if run.activeSeconds <= 0 then
		return false
	end
	return run.items[itemID] ~= nil or run.targetItemID == itemID
end

-- Data basis for an item: { runs, seconds (farm time), amount, travelSeconds (average per run),
-- minRate, maxRate (per second, over runs with yield; nil with fewer than two such runs) }, or nil
-- if no run counts. scope = "CHARACTER" (only charKey's runs) or "ACCOUNT".
function FarmEstimates.ForItem(db, itemID, scope, charKey)
	local basis = { runs = 0, seconds = 0, amount = 0, travelSeconds = 0 }
	local rates = {}
	for _, run in ipairs(db.farmRuns) do
		if counts(run, itemID, scope, charKey) then
			local amount = run.items[itemID] or 0
			basis.runs = basis.runs + 1
			basis.seconds = basis.seconds + run.activeSeconds
			basis.amount = basis.amount + amount
			basis.travelSeconds = basis.travelSeconds + run.travelSeconds
			if amount > 0 then
				rates[#rates + 1] = amount / run.activeSeconds
			end
		end
	end
	if basis.runs == 0 then
		return nil
	end
	basis.travelSeconds = basis.travelSeconds / basis.runs
	if #rates >= 2 then
		table.sort(rates)
		basis.minRate, basis.maxRate = rates[1], rates[#rates]
	end
	return basis
end

-- Farm seconds for `amount` items: point estimate from the overall rate, and the range from the
-- slowest and fastest run. Returns seconds, low, high (low/high nil without a range), or nil if
-- nothing of the item was ever farmed.
function FarmEstimates.TimeFor(basis, amount)
	if not basis or basis.amount <= 0 then
		return nil
	end
	local seconds = amount * basis.seconds / basis.amount
	if not basis.minRate then
		return seconds
	end
	return seconds, amount / basis.maxRate, amount / basis.minRate
end
