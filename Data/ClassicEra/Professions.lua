-- Professions of Classic Era with recipes: neutral key (Core/ProfessionView.lua) -> skill line id
-- and profession spell ids. The adapter recognizes a profession window by comparing its skill line
-- name with the client's names for these ids (all localized by the client at runtime), and takes the
-- icon from the first spell. Mining's recipe window is Smelting (2656): `open` names the spell that opens
-- the recipe window when it is not the first one.
-- Source: Wowhead Classic skill pages and tooltips, 2026-10-23 (community, see docs/DATA_SOURCES.md).
-- Classic Era only; never reuse for Forever without verification.
local _, ns = ...

ns.ClassicEraProfessionData = {
	{ key = "ALCHEMY", skillLine = 171, spells = { 2259 } },
	{ key = "BLACKSMITHING", skillLine = 164, spells = { 2018 } },
	{ key = "ENCHANTING", skillLine = 333, spells = { 7411 } },
	{ key = "ENGINEERING", skillLine = 202, spells = { 4036 } },
	{ key = "LEATHERWORKING", skillLine = 165, spells = { 2108 } },
	{ key = "TAILORING", skillLine = 197, spells = { 3908 } },
	{ key = "MINING", skillLine = 186, spells = { 2575, 2656 }, open = 2656 },
	{ key = "COOKING", skillLine = 185, spells = { 2550 } },
	{ key = "FIRST_AID", skillLine = 129, spells = { 3273 } },
	{ key = "POISONS", skillLine = 40, spells = { 2842 } },
}
