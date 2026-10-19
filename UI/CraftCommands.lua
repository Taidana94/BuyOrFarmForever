-- /bof craft, /bof weights: craft evaluation of the selected goal (or of any item) and stat
-- weights. CraftCommands.EvaluationLines is shared with the Craft tab; KindName and DetailLine are
-- shared with /bof alt (UI/AltCommands.lua).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local CraftEval = ns.CraftEval
local Slash = ns.Slash
local UIShared = ns.UIShared

local CraftCommands = {}
ns.CraftCommands = CraftCommands

local STAT_WORDS = { str = "STR", agi = "AGI", sta = "STA", int = "INT", spi = "SPI", armor = "ARMOR", dps = "DPS" }
local KIND_NAMES = { PLANNED = "ALT_KIND_PLANNED", POSSIBLE = "ALT_KIND_POSSIBLE" }
local ERROR_TEXTS = { not_equippable = "CRAFT_NOT_EQUIPPABLE", loading = "CRAFT_LOADING" }

function CraftCommands.KindName(kind)
	return L[KIND_NAMES[kind]]
end

-- Scores are whole numbers unless a weight has decimals.
local function scoreText(score)
	local decimals = score == math.floor(score) and 0 or 1
	return Util.FormatDecimal(score, decimals)
end

local function gainText(gain)
	return (gain > 0 and "+" or "") .. scoreText(gain)
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

local function sourcingPlan(charData, goal)
	return (ns.Sourcing.CurrentPlan(charData, { goal }))
end

local function sourcingLines(lines, plan, comparison)
	local strategy = ns.db.settings.strategy
	lines[#lines + 1] = Util.Format(L.CRAFT_COST, L[ns.PlanCommands.STRATEGY_NAMES[strategy]],
		Money.Format(plan.cost), Util.FormatDuration(plan.farmSeconds))
	if plan.open > 0 then
		lines[#lines + 1] = Util.Format(L.CRAFT_COST_OPEN, plan.open)
	end
	if comparison and comparison.gain > 0 then
		lines[#lines + 1] = Util.Format(L.CRAFT_PER_POINT, Money.Format(plan.cost / comparison.gain),
			Util.FormatDuration(plan.farmSeconds / comparison.gain))
	elseif comparison then
		lines[#lines + 1] = L.CRAFT_NO_GAIN
	end
end

local function ownedLine(lines, charData, goal)
	local now = ns.Client:GetServerTime()
	local owned = CraftEval.OwnedValue(charData, goal, ns.PriceCapture.CurrentRealmKey(), now)
	if owned.owned == 0 then
		return
	end
	local template = owned.complete and L.CRAFT_OWNED or L.CRAFT_OWNED_INCOMPLETE
	lines[#lines + 1] = Util.Format(template, owned.owned, Money.Format(owned.vendor), Money.Format(owned.market))
end

local function detailText(value, format)
	return value and format(value) or L.ALT_UNKNOWN
end

-- Extra line with the user's cost, time and requirements of an alternative (nil without details),
-- next to the craft's sourcing cost and farm time when a plan is given.
function CraftCommands.DetailLine(alt, plan)
	if not (alt.copper or alt.seconds or alt.requires) then
		return nil
	end
	local requires = alt.requires and Util.Format(L.ALT_REQUIRES_PART, alt.requires) or ""
	local cost, time = detailText(alt.copper, Money.Format), detailText(alt.seconds, Util.FormatDuration)
	if not plan then
		return Util.Format(L.ALT_DETAILS, cost, time, requires)
	end
	return Util.Format(L.ALT_DETAILS_VS_CRAFT, cost, time, Money.Format(plan.cost),
		Util.FormatDuration(plan.farmSeconds), requires)
end

-- Immediate benefit vs. a planned replacement: does the craft stay better, or does it only bridge
-- the time until the alternative arrives? nil unless the alternative is planned and the craft
-- improves the gear now.
function CraftCommands.VerdictLine(index, alt, comparison, altComparison)
	if alt.kind ~= "PLANNED" or not (comparison and altComparison) or comparison.gain <= 0 then
		return nil
	end
	local difference = comparison.score - altComparison.score
	if difference >= 0 then
		return Util.Format(L.ALT_VERDICT_STAYS, index, gainText(difference))
	end
	if alt.seconds then
		return Util.Format(L.ALT_VERDICT_BRIDGE_TIME, index, gainText(comparison.gain), scoreText(-difference),
			Util.FormatDuration(alt.seconds))
	end
	return Util.Format(L.ALT_VERDICT_BRIDGE, index, gainText(comparison.gain), scoreText(-difference))
end

local function altNote(alt)
	local note = alt.note ~= "" and Util.Format(L.ALT_NOTE, alt.note) or ""
	local level = CraftEval.LevelLock(alt.itemID)
	return level and note .. Util.Format(L.ALT_LEVEL_PART, level) or note
end

local function alternativeLines(lines, charData, comparison, plan)
	local weights = charData.craftEval.weights
	for index, alt in ipairs(charData.craftEval.alternatives) do
		local altComparison, err = CraftEval.CompareWithEquipped(alt.itemID, weights)
		local kind = CraftCommands.KindName(alt.kind)
		local note = altNote(alt)
		if altComparison and comparison then
			lines[#lines + 1] = Util.Format(L.ALT_LINE, index, kind, UIShared.ItemText(alt.itemID),
				scoreText(altComparison.score), gainText(comparison.score - altComparison.score), note)
		else
			lines[#lines + 1] = Util.Format(L.ALT_LINE_NO_COMPARE, index, kind,
				CraftCommands.CompareLine(alt.itemID, altComparison, err), note)
		end
		lines[#lines + 1] = CraftCommands.DetailLine(alt, plan)
		lines[#lines + 1] = CraftCommands.VerdictLine(index, alt, comparison, altComparison)
	end
end

-- All lines of the evaluation of a goal (chat and window).
function CraftCommands.EvaluationLines(charData, goal)
	local itemID = CraftEval.GoalItemID(goal)
	if not itemID then
		return { L.CRAFT_NO_ITEM }
	end
	local comparison, err = CraftEval.CompareWithEquipped(itemID, charData.craftEval.weights)
	local lines = { CraftCommands.CompareLine(itemID, comparison, err) }
	local level = CraftEval.LevelLock(itemID)
	if level then
		lines[#lines + 1] = Util.Format(L.CRAFT_LEVEL_LOCKED, level, ns.Client:GetLevel())
	end
	local plan = sourcingPlan(charData, goal)
	sourcingLines(lines, plan, comparison)
	ownedLine(lines, charData, goal)
	alternativeLines(lines, charData, comparison, plan)
	lines[#lines + 1] = L.CRAFT_LIMITS
	return lines
end

function CraftCommands.WeightsLine(weights)
	local F = Util.FormatCompact
	return Util.Format(L.WEIGHTS_LINE, F(weights.STR), F(weights.AGI), F(weights.STA), F(weights.INT), F(weights.SPI),
		F(weights.ARMOR), F(weights.DPS))
end

-- /bof craft [item] -----------------------------------------------------------------------

local function craftCommand(argument)
	local charData = UIShared.Character()
	if not charData then
		return
	end
	if Util.Trim(argument) ~= "" then
		local itemID = Util.ParseItemArg(argument)
		if not itemID then
			UIShared.PrintError("invalid_item")
			return
		end
		local comparison, err = CraftEval.CompareWithEquipped(itemID, charData.craftEval.weights)
		Log.Print(CraftCommands.CompareLine(itemID, comparison, err))
		return
	end
	local goal, id = UIShared.ActiveGoal(charData)
	if not goal then
		return
	end
	Log.Print(Util.Format(L.CRAFT_HEADER, id, UIShared.GoalName(goal)))
	for _, line in ipairs(CraftCommands.EvaluationLines(charData, goal)) do
		Log.Print(line)
	end
	Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
end

-- /bof weights [stat value] -----------------------------------------------------------------

-- The suggested template for the player's class and talents, or nil.
function CraftCommands.SuggestedTemplate()
	return ns.WeightTemplates.Suggest(ns.Client:GetClass(), ns.Client:GetTalentPoints())
end

-- /bof weights template <name> | suggest
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
	Slash.AddCommand("craft", craftCommand, L.HELP_LINE_CRAFT)
	Slash.AddCommand("weights", weightsCommand, L.HELP_LINE_WEIGHTS)
end
