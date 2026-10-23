-- Cache for the route lists (Core/GoldRoutes.lua, Core/Conversion.lua). Building them walks up to
-- FarmRuns.MAX_RUNS saved runs and every learned recipe, and the advisor, the gold tab and the wants
-- plan ask after every bag or gold change, which does not change them. An entry is rebuilt when a
-- signal that can change routes arrives, when the saved runs, the character or the settings it was
-- built with differ, or after MAX_AGE_SECONDS (live Auctionator prices raise no signal).
-- Callers get a shallow copy of the list, so adding to it does not change the cache.
local _, ns = ...

local RouteCache = {}
ns.RouteCache = RouteCache

local MAX_AGE_SECONDS = 60
local INVALIDATING_SIGNALS = { "DATA_CHANGED", "PRICES_CHANGED", "RECIPES_CHANGED", "SETTINGS_CHANGED" }

local entries = {}

local function fingerprint()
	local runs, settings = ns.db.farmRuns, ns.db.settings
	local last = runs[#runs]
	return table.concat({ tostring(ns.db), ns.charKey or "", #runs, last and last.endedAt or 0,
		settings.farmEstimateScope, settings.ahDiscountPercent }, "|")
end

local function copy(list)
	local out = {}
	for i, value in ipairs(list) do
		out[i] = value
	end
	return out
end

-- The list `name` from the cache, or built by build() and stored.
function RouteCache.Get(name, build)
	local now, key = ns.Client:GetServerTime(), fingerprint()
	local entry = entries[name]
	if not entry or entry.key ~= key or now - entry.at >= MAX_AGE_SECONDS then
		entry = { key = key, at = now, list = build() }
		entries[name] = entry
	end
	return copy(entry.list)
end

function RouteCache.Invalidate()
	entries = {}
end

if ns.Client then
	for _, signal in ipairs(INVALIDATING_SIGNALS) do
		ns.Events.OnSignal(signal, RouteCache.Invalidate)
	end
end
