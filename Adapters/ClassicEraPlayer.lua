-- Classic Era adapter part: the player's state for the farm automation (AFK, resting in a city
-- or inn, on a flight path) and class/talents for weight templates.
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- UnitIsAFK, UnitClass and C_SpecializationInfo.GetSpecializationInfo are documented in Classic
-- Era 70003; IsResting (PlayerFrame.lua) and UnitOnTaxi (action bar code) are legacy globals used
-- by Blizzard's Classic Era UI. GetTalentTabInfo is only a deprecation wrapper there (loaded with
-- a CVar) and is not used. Exact returns in 1.15.9: unverified in game.
local _, ns = ...

local Player = {}
ns.ClassicEraPlayer = Player

-- Legacy globals may return 1/nil instead of true/false; any true value counts.
local function truthy(value)
	return value and true or false
end

function Player.IsAFK()
	return UnitIsAFK ~= nil and truthy(UnitIsAFK("player"))
end

function Player.IsResting()
	return IsResting ~= nil and truthy(IsResting())
end

function Player.IsOnTaxi()
	return UnitOnTaxi ~= nil and truthy(UnitOnTaxi("player"))
end

-- Class file name ("PRIEST", "WARRIOR", …), or nil.
-- Character level (UnitLevel, used by the Classic Era UI), or nil.
function Player.GetLevel()
	if not UnitLevel then
		return nil
	end
	return UnitLevel("player")
end

function Player.GetClass()
	if not UnitClass then
		return nil
	end
	local _, classFile = UnitClass("player")
	return classFile
end

-- Points spent per talent tree: { tree 1, tree 2, tree 3 }, or nil if unavailable. Classic Era
-- classes have three trees; pointsSpent is the 7th return of GetSpecializationInfo (docs 70003).
local TALENT_TREES = 3
local POINTS_RETURN = 7

function Player.GetTalentPoints()
	local info = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
	if not info then
		return nil
	end
	local points = {}
	for tree = 1, TALENT_TREES do
		local spent = select(POINTS_RETURN, info(tree))
		points[tree] = type(spent) == "number" and spent or 0
	end
	return points
end
