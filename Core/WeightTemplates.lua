-- Stat weight templates per role and the suggested template for a class and its talent points.
-- The values are design choices of this addon (a starting point the player can change), not game
-- data; see docs/DATA_SOURCES.md. Pure logic, no WoW API calls.
local _, ns = ...

local WeightTemplates = {}
ns.WeightTemplates = WeightTemplates

-- Display order of the templates; keys double as chat words in lower case.
WeightTemplates.ORDER = { "CASTER", "HEALER", "AGILITY", "STRENGTH", "TANK" }

WeightTemplates.VALUES = {
	CASTER = { STR = 0, AGI = 0, STA = 1, INT = 2, SPI = 0.5 },
	HEALER = { STR = 0, AGI = 0, STA = 1, INT = 1.5, SPI = 1.5 },
	AGILITY = { STR = 0.5, AGI = 2, STA = 1, INT = 0, SPI = 0 },
	STRENGTH = { STR = 2, AGI = 1, STA = 1, INT = 0, SPI = 0 },
	TANK = { STR = 1, AGI = 1, STA = 2, INT = 0, SPI = 0 },
}

-- Template per talent tree (Classic Era tree order) for each class file name.
local CLASS_TREES = {
	WARRIOR = { "STRENGTH", "STRENGTH", "TANK" },
	PALADIN = { "HEALER", "TANK", "STRENGTH" },
	HUNTER = { "AGILITY", "AGILITY", "AGILITY" },
	ROGUE = { "AGILITY", "AGILITY", "AGILITY" },
	PRIEST = { "HEALER", "HEALER", "CASTER" },
	SHAMAN = { "CASTER", "STRENGTH", "HEALER" },
	MAGE = { "CASTER", "CASTER", "CASTER" },
	WARLOCK = { "CASTER", "CASTER", "CASTER" },
	DRUID = { "CASTER", "TANK", "HEALER" },
}

-- Template key for a class and its points per tree (the tree with the most points; the first
-- tree without points), or nil for an unknown class.
function WeightTemplates.Suggest(classFile, points)
	local trees = CLASS_TREES[classFile]
	if not trees then
		return nil
	end
	local best, bestPoints = 1, -1
	for tree, spent in ipairs(points or {}) do
		if spent > bestPoints then
			best, bestPoints = tree, spent
		end
	end
	return trees[best]
end

-- Template key for a chat word ("healer"), or nil.
function WeightTemplates.FromWord(word)
	local key = string.upper(word or "")
	return WeightTemplates.VALUES[key] and key or nil
end

-- Sets all five weights of a character from a template. Returns true, or nil + "unknown_template".
function WeightTemplates.Apply(charData, key)
	local values = WeightTemplates.VALUES[key]
	if not values then
		return nil, "unknown_template"
	end
	for stat, value in pairs(values) do
		charData.craftEval.weights[stat] = value
	end
	return true
end
