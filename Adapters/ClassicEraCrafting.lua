-- Classic Era adapter part: crafting from the professions tab. Opens a profession window and crafts a
-- recipe of the open trade skill window. Loaded after Adapters/ClassicEraProfessions.lua and before
-- Adapters/ClassicEra.lua, which exposes every function of this table as an adapter method.
-- Call these only from a click or a slash command (a hardware event).
-- Sources (community, warcraft.wiki.gg, 2026-10-23; to be confirmed in game):
-- DoTradeSkill(index, repeat) is not marked protected and crafts from the open trade skill window;
-- CastSpellByName is protected, but "can still open trade skill windows ... even from a tainted
-- execution path". Classic Era only.
local _, ns = ...

local Crafting = {}
ns.ClassicEraCrafting = Crafting

-- Position of itemStackCount in the returns of C_Item.GetItemInfo (generated docs, 70003).
local STACK_COUNT_RETURN = 8

local openSpellByKey = {}
for _, entry in ipairs(ns.ClassicEraProfessionData) do
	openSpellByKey[entry.key] = entry.open or entry.spells[1]
end

-- InCombatLockdown is used by Blizzard's SecureTemplates (70003).
function Crafting.IsInCombat()
	return InCombatLockdown ~= nil and InCombatLockdown() == true
end

-- Opens the recipe window of a profession by casting its spell (client name). Returns true if the
-- cast was sent; false for unknown keys, Enchanting (craft window) or a missing spell name.
function Crafting.OpenProfession(professionKey)
	local spellID = professionKey ~= "ENCHANTING" and openSpellByKey[professionKey]
	local name = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
	if not (name and CastSpellByName) then
		return false
	end
	CastSpellByName(name)
	return true
end

-- Profession key of the open trade skill window, or nil.
function Crafting.GetOpenTradeProfession()
	return ns.ClassicEraProfessions.TradeWindowProfession()
end

-- Crafts a recipe of the open trade skill window `count` times (the client stops early when the
-- reagents run out). Returns true, or false plus "combat" | "no_window" | "not_listed".
function Crafting.CraftRecipe(recipeKey, count)
	if Crafting.IsInCombat() then
		return false, "combat"
	end
	if not Crafting.GetOpenTradeProfession() then
		return false, "no_window"
	end
	local index = ns.ClassicEraProfessions.FindTradeRecipe(recipeKey)
	if not (index and DoTradeSkill) then
		return false, "not_listed"
	end
	if SelectTradeSkill then
		SelectTradeSkill(index)
	end
	DoTradeSkill(index, count)
	return true
end

-- How many units of an item fit in one stack, or nil while the item data loads.
function Crafting.GetItemStackSize(itemID)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	return (select(STACK_COUNT_RETURN, C_Item.GetItemInfo(itemID)))
end
