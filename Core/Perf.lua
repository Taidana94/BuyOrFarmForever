-- Performance numbers for /gc perf: the addon's share of frame time (same formula as Blizzard's
-- addon list in Classic Era 70003) and the duration of key operations. Pure logic except for the
-- client calls through ns.Client.
local _, ns = ...

local Perf = {}
ns.Perf = Perf

-- Blizzard throttles UpdateAddOnMemoryUsage to once per 15 s because it walks all addons.
Perf.MEMORY_UPDATE_SECONDS = 15

local lastMemoryUpdate

-- Share (0..1) of this addon in the frame time, or nil if there is nothing to compare with.
-- metric = { addon, app, overall } as returned by the adapter.
function Perf.Share(metric)
	local relativeTotal = metric.app - metric.overall + metric.addon
	if relativeTotal <= 0 then
		return nil
	end
	return metric.addon / relativeTotal
end

-- Memory of the addon in KB, refreshed at most every MEMORY_UPDATE_SECONDS.
function Perf.MemoryKB(addonName)
	local now = ns.Client:GetUptime()
	local refresh = not lastMemoryUpdate or now >= lastMemoryUpdate + Perf.MEMORY_UPDATE_SECONDS
	if refresh then
		lastMemoryUpdate = now
	end
	return ns.Client:GetMemoryKB(addonName, refresh)
end

-- Milliseconds of one run of fn, or nil if the client has no high-resolution timer.
function Perf.Measure(fn)
	local start = ns.Client:GetTimeMs()
	if not start then
		fn()
		return nil
	end
	fn()
	return ns.Client:GetTimeMs() - start
end
