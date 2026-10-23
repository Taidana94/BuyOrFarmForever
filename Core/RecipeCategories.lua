-- Categories of the professions view: what a recipe's product is good for ("STR" = strength food,
-- strength elixir or strength gear). Decided in this order:
-- 1. the client's effect data (consumables and enchantments, Data/<client>/EffectData.lua),
-- 2. gear: its largest primary stat; without one WEAPON (has damage per second) or ARMOR,
-- 3. other items: their item class ("CLASS_<classID>", named by the client),
-- 4. an enchantment without data: UTILITY.
-- FromFacts is pure; ForRecipe collects the facts through the adapter and caches the result per
-- recipe key for the session (item data does not change). Results of items still loading are not
-- cached.
local _, ns = ...

local RecipeCategories = {}
ns.RecipeCategories = RecipeCategories

-- Display order of the effect categories; item classes follow in class id order, LOADING last.
RecipeCategories.ORDER = {
	"STR", "AGI", "STA", "INT", "SPI", "STA_SPI", "ALL_STATS", "ATTACK_POWER", "SPELL_POWER", "MP5", "HP5", "ARMOR",
	"RESIST", "PROTECTION", "WEAPON", "SPEED", "FISHING", "SKILL", "HEAL", "MANA", "UTILITY",
}
RecipeCategories.LOADING = "LOADING"
local CLASS_PREFIX = "CLASS_"
local PRIMARY_STATS = { "STR", "AGI", "STA", "INT", "SPI" }

local RANK = {}
for index, key in ipairs(RecipeCategories.ORDER) do
	RANK[key] = index
end

local function gearCategory(stats)
	local best, bestValue = nil, 0
	for _, stat in ipairs(PRIMARY_STATS) do
		if (stats[stat] or 0) > bestValue then
			best, bestValue = stat, stats[stat]
		end
	end
	if best then
		return best
	end
	return (stats.DPS or 0) > 0 and "WEAPON" or "ARMOR"
end

-- facts = { effect = category key or nil, isEnchant = bool, slots = equip slots or nil,
--           stats = item stats or nil (nil while loading), classID = item class id or nil }.
-- Returns the category key, or nil if the facts are not complete yet (gear stats loading).
function RecipeCategories.FromFacts(facts)
	if facts.effect and RANK[facts.effect] then
		return facts.effect
	end
	if facts.isEnchant then
		return "UTILITY"
	end
	if facts.slots then
		return facts.stats and gearCategory(facts.stats) or nil
	end
	if facts.classID then
		return CLASS_PREFIX .. facts.classID
	end
	return nil
end

-- Item class id of a "CLASS_<id>" category, or nil for effect categories.
function RecipeCategories.ClassID(category)
	return tonumber(string.match(category, "^" .. CLASS_PREFIX .. "(%d+)$"))
end

-- Sort position of a category: effect categories first, then item classes, LOADING last.
function RecipeCategories.SortKey(category)
	if RANK[category] then
		return RANK[category]
	end
	local classID = RecipeCategories.ClassID(category)
	if classID then
		return #RecipeCategories.ORDER + 1 + classID
	end
	return math.huge
end

local function factsFor(key, recipe)
	local client = ns.Client
	local itemID = recipe.outputItemID
	if itemID == 0 then
		local keyType, spellID = ns.Recipes.SplitKey(key)
		return { isEnchant = true, effect = keyType == "spell" and client:GetEffectCategory("spell", spellID) or nil }
	end
	local slots = client:GetEquipSlots(itemID)
	return {
		effect = client:GetEffectCategory("item", itemID),
		slots = slots,
		stats = slots and client:GetItemStats(itemID) or nil,
		classID = client:GetItemClassID(itemID),
	}
end

local cache = {}

-- Category key of a recipe from the book (stored recipe data), LOADING while item data loads.
function RecipeCategories.ForRecipe(key, recipe)
	if not cache[key] then
		cache[key] = RecipeCategories.FromFacts(factsFor(key, recipe))
	end
	return cache[key] or RecipeCategories.LOADING
end
