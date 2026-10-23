-- Recipe lines at the bottom of item tooltips (setting tooltipRecipes): which profession makes the
-- item (Data/ClassicEra/CraftedBy.lua through the adapter, or the recipe book), which of the player's
-- characters know the recipe, and, when the recipe was seen in a profession window, one line per
-- reagent with its count and its cost right-aligned in coins, and the total. Lines are texts or
-- { left, right } pairs (UI/TooltipLines.lua). Prices are planning prices (Core/PriceCapture.lua);
-- a reagent without one is marked and the total becomes "at least". Built on demand per item and
-- cached by UI/TooltipLines.lua until the data changes. Setting tooltipReagents off: only the
-- profession lines.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local UIShared = ns.UIShared

local TooltipRecipe = {}
ns.TooltipRecipe = TooltipRecipe

local HEADING_COLOR = "|cffffd100"
local DIM_COLOR = "|cff9d9d9d"
local COLOR_END = "|r"
-- Characters named as knowing the recipe; more are counted.
local MAX_NAMES = 3

-- Recipe keys by product over db.recipes; built once per cache generation.
function TooltipRecipe.Index(db)
	return ns.Wants.RecipesByProduct(db)
end

-- Character names (realm left out) that learned recipeKey, and the profession from their book.
local function knownBy(recipeKey)
	local names, profession = {}, nil
	for charKey, charData in pairs(ns.db.characters) do
		local entry = charData.recipeBook[recipeKey]
		if entry then
			names[#names + 1] = (ns.Stock.SplitKey(charKey)) or charKey
			profession = profession or entry.profession
		end
	end
	table.sort(names)
	return names, profession
end

local function professionNames(keys)
	local names = {}
	for _, key in ipairs(keys) do
		names[#names + 1] = (ns.Client:GetProfessionInfo(key)) or key
	end
	return table.concat(names, L.PLAN_SEPARATOR)
end

local function knownText(names)
	if #names == 0 then
		return ""
	end
	local shown = {}
	for i = 1, math.min(#names, MAX_NAMES) do
		shown[i] = names[i]
	end
	local text = table.concat(shown, L.PLAN_SEPARATOR)
	if #names > MAX_NAMES then
		text = text .. Util.Format(L.TOOLTIP_RECIPE_MORE, #names - MAX_NAMES)
	end
	return Util.Format(L.TOOLTIP_RECIPE_KNOWN, text)
end

-- Copper with coin icons where the client has them, else as text (e.g. 8s 48k).
local function coins(copper)
	return ns.Client:FormatCoins(copper) or Money.Format(math.floor(copper))
end

local function reagentLines(lines, recipe, now)
	local total, missing = 0, 0
	for _, reagent in ipairs(recipe.reagents) do
		local price = ns.PriceCapture.Best(reagent.itemID, now)
		local left = Util.Format(L.TOOLTIP_RECIPE_REAGENT, UIShared.ItemText(reagent.itemID), reagent.count)
		if price then
			total = total + price * reagent.count
			lines[#lines + 1] = { left, coins(price * reagent.count) }
		else
			missing = missing + 1
			lines[#lines + 1] = { left, DIM_COLOR .. L.TOOLTIP_RECIPE_NO_PRICE .. COLOR_END }
		end
	end
	return total, missing
end

local function costLines(lines, recipe, total, missing)
	local label = missing > 0 and L.TOOLTIP_RECIPE_COST_MIN or L.TOOLTIP_RECIPE_COST
	lines[#lines + 1] = { HEADING_COLOR .. label .. COLOR_END, coins(total) }
	local made = (recipe.outputMin + recipe.outputMax) / 2
	if made > 1 then
		local amount = Util.FormatDecimal(made, made == math.floor(made) and 0 or 1)
		lines[#lines + 1] = { Util.Format(L.TOOLTIP_RECIPE_PER_UNIT, amount), coins(total / made) }
	end
end

-- Tooltip lines for itemID (index from TooltipRecipe.Index), or nil if nobody makes it as far as the
-- addon knows.
function TooltipRecipe.Lines(itemID, index, now)
	local recipeKey = index[itemID] and index[itemID][1]
	local recipe = recipeKey and ns.Recipes.Get(ns.db, recipeKey)
	local names, bookProfession = {}, nil
	if recipe then
		names, bookProfession = knownBy(recipeKey)
	end
	local professions = ns.Client:GetCraftedBy(itemID) or (bookProfession and { bookProfession })
	if not (professions or recipe) then
		return nil
	end
	local lines = { " ", HEADING_COLOR .. L.TOOLTIP_RECIPE_HEAD .. COLOR_END,
		Util.Format(L.TOOLTIP_RECIPE_BY, professions and professionNames(professions) or L.PROF_OTHER, knownText(names)) }
	if not ns.db.settings.tooltipReagents then
		return lines
	end
	if not recipe then
		lines[4] = DIM_COLOR .. L.TOOLTIP_RECIPE_UNKNOWN .. COLOR_END
		return lines
	end
	local total, missing = reagentLines(lines, recipe, now)
	costLines(lines, recipe, total, missing)
	return lines
end
