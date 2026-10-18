-- Client adapter for WoW Classic Era (1.15.9, interface 11509).
-- APIs used here are listed with their verification status in work/notes/BuyOrFarmForever-plan.md.
local _, ns = ...

local ClassicEra = {
	id = "classic_era",
	caps = {},
}

-- WOW_PROJECT_CLASSIC (2) and WOW_PROJECT_ID are defined by Blizzard's
-- Blizzard_FrameXMLBase/Vanilla/Constants.lua in Classic Era.
function ClassicEra:IsCurrentClient()
	return WOW_PROJECT_ID ~= nil and WOW_PROJECT_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function ClassicEra:GetBuildInfo()
	local version, build, date, interface = GetBuildInfo()
	return {
		version = version,
		build = build,
		date = date,
		interface = interface,
	}
end

function ClassicEra:GetLocale()
	return GetLocale()
end

ns.Adapter.Register(ClassicEra)
