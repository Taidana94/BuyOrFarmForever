-- /bof make <recipe> [count | all]: crafts a learned recipe from the recipe book (used by the craft
-- buttons of the professions tab). If the profession's recipe window is not open, the command opens it
-- and asks for a second click: crafting right after the window opened would run outside the click,
-- and whether the client allows that is not verified. The count is capped at what the bags allow.
-- Enchantments cannot be made here (they need a target item).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Slash = ns.Slash
local UIShared = ns.UIShared
local ProfessionView = ns.ProfessionView

local MakeCommand = {}
ns.MakeCommand = MakeCommand

local ALL_WORD = "all"

local CRAFT_ERRORS = {
	combat = "MAKE_ERR_COMBAT",
	no_window = "MAKE_ERR_OPEN",
	not_listed = "MAKE_ERR_NOT_LISTED",
}

local function bagCount(itemID)
	return ns.Client:GetBagCount(itemID)
end

-- Requested crafts: "" = 1, "all" = what the bags allow, else a whole number; nil if invalid.
local function parseCount(text, possible)
	text = Util.Trim(text or "")
	if text == "" then
		return 1
	end
	if string.lower(text) == ALL_WORD then
		return possible
	end
	local count = Util.ParseInteger(text)
	return ns.Materials.IsValidCrafts(count) and count or nil
end

-- The learned recipe and its book entry, or nil plus the locale key of the reason.
local function learnedRecipe(charData, key)
	local entry = charData.recipeBook[key]
	local recipe = entry and ns.Recipes.Get(ns.db, key)
	if not recipe then
		return nil, nil, "MAKE_ERR_UNKNOWN"
	end
	if recipe.outputItemID == 0 or entry.profession == "ENCHANTING" then
		return nil, nil, "MAKE_ERR_ENCHANT"
	end
	return recipe, entry
end

-- Crafts in the open window, or opens it (second click needed).
local function craftOrOpen(key, recipe, profession, count)
	local name = ProfessionView.ProductName(key, recipe) or Util.Format(L.ITEM_UNKNOWN, recipe.outputItemID)
	if ns.Client:GetOpenTradeProfession() ~= profession then
		Log.Print(ns.Client:OpenProfession(profession) and L.MAKE_OPENING or L.MAKE_ERR_OPEN)
		return
	end
	local ok, err = ns.Client:CraftRecipe(key, count)
	Log.Print(ok and Util.Format(L.MAKE_STARTED, count, name) or L[CRAFT_ERRORS[err] or "MAKE_ERR_NOT_LISTED"])
end

local function makeCommand(argument)
	local charData = UIShared.Character()
	local key, rest = Slash.SplitCommand(argument)
	if not (charData and key ~= "") then
		Log.Print(L.MAKE_USAGE)
		return
	end
	local recipe, entry, reason = learnedRecipe(charData, key)
	if not recipe then
		Log.Print(L[reason])
		return
	end
	local possible = ProfessionView.ReagentState(recipe, bagCount).crafts
	local count = parseCount(rest, possible)
	if not count then
		Log.Print(Util.Format(L.ERR_INVALID_CRAFTS, ns.Materials.MAX_CRAFTS))
	elseif possible == 0 then
		Log.Print(L.MAKE_ERR_NO_REAGENTS)
	elseif ns.Client:IsInCombat() then
		Log.Print(L.MAKE_ERR_COMBAT)
	else
		craftOrOpen(key, recipe, entry.profession or "OTHER", math.min(count, possible))
	end
end

-- Runs the command from a window button (same path as the chat, so the messages are the same).
function MakeCommand.Run(key, count)
	ns.Inputs.Run("make " .. key .. " " .. tostring(count))
end

if ns.Client then
	Slash.AddCommand("make", makeCommand, "HELP_LINE_MAKE")
end
