-- Profession tools the gold planner must never suggest selling (item id -> true). Classic Era only.
-- Enchanting rods and engineering tools: crafted items of the Wowhead Classic skill pages
-- (work/research/wowhead-crafted.json, 2026-10-24). Flint and Tinder, Mining Pick, Skinning Knife,
-- Blacksmith Hammer and Fishing Pole: ids from general knowledge, NOT verified (docs/DATA_SOURCES.md).
local _, ns = ...

ns.ClassicEraTools = {
	[6218] = true, -- Runed Copper Rod
	[6339] = true, -- Runed Silver Rod
	[11130] = true, -- Runed Golden Rod
	[11145] = true, -- Runed Truesilver Rod
	[16207] = true, -- Runed Arcanite Rod
	[6219] = true, -- Arclight Spanner
	[10498] = true, -- Gyromatic Micro-Adjustor
	[4471] = true, -- Flint and Tinder (unverified id)
	[2901] = true, -- Mining Pick (unverified id)
	[7005] = true, -- Skinning Knife (unverified id)
	[5956] = true, -- Blacksmith Hammer (unverified id)
	[6256] = true, -- Fishing Pole (unverified id)
}
