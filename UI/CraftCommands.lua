-- /gc craft <item>, /gc weights: an item rated against the equipped gear with the stat weights, and
-- the weights themselves. CompareLine is shared with the professions detail.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local CraftEval = ns.CraftEval
local Slash = ns.Slash
local UIShared = ns.UIShared

local CraftCommands = {}
ns.CraftCommands = CraftCommands

local STAT_WORDS = { str = "STR", agi = "AGI", sta = "STA", int = "INT", spi = "SPI", armor = "ARMOR", dps = "DPS" }
local ERROR_TEXTS = { not_equippable = "CRAFT_NOT_EQUIPPABLE", loading = "CRAFT_LOADING" }

-- Scores are whole numbers unless a weight has decimals.
local function scoreText(score)
	local decimals = score == math.floor(score) and 0 or 1
	return Util.FormatDecimal(score, decimals)
end

local function gainText(gain)
	return (gain > 0 and "+" or "") .. scoreText(gain)
end

-- "Ausrüstung: +6 Wertung ..." for an item the character can wear, or nil (not equippable, loading).
function CraftCommands.GearLine(charData, itemID)
	local comparison = CraftEval.CompareWithEquipped(itemID, charData.craftEval.weights)
	return comparison and Util.Format(L.PROF_GEAR, gainText(comparison.gain)) or nil
end

local function equippedText(comparison)
	local parts = {}
	for _, entry in ipairs(comparison.equipped) do
		local name = entry.itemID and UIShared.ItemText(entry.itemID) or L.CRAFT_SLOT_EMPTY
		parts[#parts + 1] = Util.Format(L.CRAFT_EQUIPPED_PART, L["SLOT_" .. entry.slot] or entry.slot, name,
			scoreText(entry.score))
	end
	return table.concat(parts, L.PLAN_SEPARATOR)
end

-- "[Item]: Wertung 15 – angelegt: [Alt] (9) → +6", or the reason why there is no comparison.
function CraftCommands.CompareLine(itemID, comparison, err)
	if not comparison then
		return Util.Format(L[ERROR_TEXTS[err]], UIShared.ItemText(itemID))
	end
	return Util.Format(L.CRAFT_COMPARE, UIShared.ItemText(itemID), scoreText(comparison.score),
		equippedText(comparison), gainText(comparison.gain))
end

function CraftCommands.WeightsLine(weights)
	local F = Util.FormatCompact
	return Util.Format(L.WEIGHTS_LINE, F(weights.STR), F(weights.AGI), F(weights.STA), F(weights.INT), F(weights.SPI),
		F(weights.ARMOR), F(weights.DPS))
end

-- /gc craft <item> ------------------------------------------------------------------------

local function craftCommand(argument)
	local charData = UIShared.Character()
	if not charData then
		return
	end
	local itemID = Util.ParseItemArg(argument)
	if not itemID then
		Log.Print(L.CRAFT_USAGE)
		return
	end
	local comparison, err = CraftEval.CompareWithEquipped(itemID, charData.craftEval.weights)
	Log.Print(CraftCommands.CompareLine(itemID, comparison, err))
	local level = CraftEval.LevelLock(itemID)
	if level then
		Log.Print(Util.Format(L.CRAFT_LEVEL_LOCKED, level, ns.Client:GetLevel()))
	end
	Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
end

-- /gc weights [stat value] -----------------------------------------------------------------

-- The suggested template for the player's class and talents, or nil.
function CraftCommands.SuggestedTemplate()
	return ns.WeightTemplates.Suggest(ns.Client:GetClass(), ns.Client:GetTalentPoints())
end

-- /gc weights template <name> | suggest
local function applyTemplate(key)
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	if not (key and ns.WeightTemplates.Apply(charData, key)) then
		Log.Print(L.WEIGHTS_USAGE)
		return
	end
	Log.Print(Util.Format(L.WEIGHTS_TEMPLATE_SET, L["TEMPLATE_" .. key]))
	Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
end

local function weightsCommand(argument)
	local word, rest = Slash.SplitCommand(argument)
	if word == "" then
		local charData = UIShared.Character()
		if charData then
			Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
		end
		return
	end
	if word == "template" or word == "suggest" then
		applyTemplate(word == "suggest" and CraftCommands.SuggestedTemplate() or ns.WeightTemplates.FromWord(Util.Trim(rest)))
		return
	end
	local stat = STAT_WORDS[word]
	local value = tonumber((Util.Trim(rest):gsub(",", ".")))
	if not stat then
		Log.Print(L.WEIGHTS_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	if not CraftEval.SetWeight(charData, stat, value) then
		Log.Print(Util.Format(L.ERR_INVALID_WEIGHT, CraftEval.MAX_WEIGHT))
		return
	end
	Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
end

if ns.Client then
	Slash.AddCommand("craft", craftCommand, "HELP_LINE_CRAFT")
	Slash.AddCommand("weights", weightsCommand, "HELP_LINE_WEIGHTS")
end
