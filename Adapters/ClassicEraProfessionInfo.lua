-- Classic Era adapter part: which profession a window shows (ns.ClassicEraProfessionOf, used by
-- Adapters/ClassicEraProfessions.lua), profession names and icons, and the effect categories of
-- crafted items (Data/ClassicEra/). Adapters/ClassicEra.lua exposes every function of the Info table
-- as an adapter method. Classic Era only.
local _, ns = ...

local Info = {}
ns.ClassicEraProfessionInfo = Info

-- Profession recognition ------------------------------------------------------------------
-- The windows only name their skill line (localized). It is compared with the client's own names
-- for the skill line ids and profession spells of Data/ClassicEra/Professions.lua.

local professionByName = {} -- skill line name -> profession key (matches only; session cache)
local dataByKey = {}
for _, entry in ipairs(ns.ClassicEraProfessionData) do
	dataByKey[entry.key] = entry
end

-- C_TradeSkillUI.GetTradeSkillDisplayName is documented in 70003 (not used by the Vanilla UI).
local function skillLineName(entry)
	if C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillDisplayName then
		return C_TradeSkillUI.GetTradeSkillDisplayName(entry.skillLine)
	end
	return nil
end

local function matches(entry, name)
	if skillLineName(entry) == name then
		return true
	end
	for _, spellID in ipairs(entry.spells) do
		if C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) == name then
			return true
		end
	end
	return false
end

-- Profession key of a skill line name; "OTHER" if no known profession matches (not cached, the
-- spell names may still be loading).
local function professionOf(name)
	if type(name) ~= "string" or name == "" then
		return "OTHER"
	end
	if not professionByName[name] then
		for _, entry in ipairs(ns.ClassicEraProfessionData) do
			if matches(entry, name) then
				professionByName[name] = entry.key
				break
			end
		end
	end
	return professionByName[name] or "OTHER"
end

ns.ClassicEraProfessionOf = professionOf

-- Localized name and icon (file id) of a profession key, or nil for "OTHER" and unknown keys.
-- C_Spell.GetSpellTexture is documented in 70003.
function Info.GetProfessionInfo(key)
	local entry = dataByKey[key]
	if not entry then
		return nil, nil
	end
	local spellID = entry.spells[1]
	local name = skillLineName(entry) or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID))
	local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
	return name, icon
end

-- Effect category of a crafted item ("item", itemID) or an enchantment ("spell", spellID) from
-- Data/ClassicEra/EffectData.lua, or nil if the data has no entry.
function Info.GetEffectCategory(kind, id)
	local data = ns.ClassicEraEffectData
	local list = (kind == "item" and data.ITEMS) or (kind == "spell" and data.ENCHANTS) or nil
	return list and list[id]
end

-- Professions that make an item (Data/ClassicEra/CraftedBy.lua): a list of profession keys, or nil.
function Info.GetCraftedBy(itemID)
	local entry = ns.ClassicEraCraftedBy and ns.ClassicEraCraftedBy[itemID]
	if type(entry) == "string" then
		return { entry }
	end
	return entry
end

-- Item classes (the category of products without effect data) ------------------------

-- Item class id (Enum.ItemClass, e.g. 7 = trade goods) from C_Item.GetItemInfoInstant (no cache
-- needed), or nil.
local INSTANT_CLASS_ID_RETURN = 6

function Info.GetItemClassID(itemID)
	if not (C_Item and C_Item.GetItemInfoInstant) then
		return nil
	end
	return (select(INSTANT_CLASS_ID_RETURN, C_Item.GetItemInfoInstant(itemID)))
end

-- Localized name of an item class (C_Item.GetItemClassInfo, documented in 70003), or nil.
function Info.GetItemClassName(classID)
	if not (C_Item and C_Item.GetItemClassInfo) then
		return nil
	end
	return C_Item.GetItemClassInfo(classID)
end
