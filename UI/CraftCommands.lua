-- /bof craft, /bof weights, /bof alt: craft evaluation of the selected goal (or of any item),
-- stat weights and alternatives. CraftCommands.EvaluationLines is shared with the Craft tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local CraftEval = ns.CraftEval
local Sourcing = ns.Sourcing
local Slash = ns.Slash
local UIShared = ns.UIShared

local CraftCommands = {}
ns.CraftCommands = CraftCommands

local STAT_WORDS = { str = "STR", agi = "AGI", sta = "STA", int = "INT", spi = "SPI" }
local KIND_WORDS = { planned = "PLANNED", drop = "POSSIBLE" }
local KIND_NAMES = { PLANNED = "ALT_KIND_PLANNED", POSSIBLE = "ALT_KIND_POSSIBLE" }
local ERROR_TEXTS = { not_equippable = "CRAFT_NOT_EQUIPPABLE", loading = "CRAFT_LOADING" }

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
		parts[#parts + 1] = Util.Format(L.CRAFT_EQUIPPED_PART, name, scoreText(entry.score))
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

local function sourcingLines(lines, charData, goal, comparison)
	local strategy = ns.db.settings.strategy
	local plan = Sourcing.Plan(Sourcing.Inputs(charData, { goal }), strategy, (Sourcing.Budget()))
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

local function alternativeLines(lines, charData, comparison)
	local weights = charData.craftEval.weights
	for index, alt in ipairs(charData.craftEval.alternatives) do
		local altComparison, err = CraftEval.CompareWithEquipped(alt.itemID, weights)
		local kind = L[KIND_NAMES[alt.kind]]
		local note = alt.note ~= "" and Util.Format(L.ALT_NOTE, alt.note) or ""
		if altComparison and comparison then
			lines[#lines + 1] = Util.Format(L.ALT_LINE, index, kind, UIShared.ItemText(alt.itemID),
				scoreText(altComparison.score), gainText(comparison.score - altComparison.score), note)
		else
			lines[#lines + 1] = Util.Format(L.ALT_LINE_NO_COMPARE, index, kind,
				CraftCommands.CompareLine(alt.itemID, altComparison, err), note)
		end
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
	sourcingLines(lines, charData, goal, comparison)
	ownedLine(lines, charData, goal)
	alternativeLines(lines, charData, comparison)
	lines[#lines + 1] = L.CRAFT_LIMITS
	return lines
end

function CraftCommands.WeightsLine(weights)
	return Util.Format(L.WEIGHTS_LINE, scoreText(weights.STR), scoreText(weights.AGI), scoreText(weights.STA),
		scoreText(weights.INT), scoreText(weights.SPI))
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

local function weightsCommand(argument)
	local word, rest = Slash.SplitCommand(argument)
	if word == "" then
		local charData = UIShared.Character()
		if charData then
			Log.Print(CraftCommands.WeightsLine(charData.craftEval.weights))
		end
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

-- /bof alt [add <item> planned|drop [note] | remove <nr>] ------------------------------------

local function listAlternatives(charData)
	if #charData.craftEval.alternatives == 0 then
		Log.Print(L.ALT_LIST_EMPTY)
		return
	end
	for index, alt in ipairs(charData.craftEval.alternatives) do
		local note = alt.note ~= "" and Util.Format(L.ALT_NOTE, alt.note) or ""
		Log.Print(Util.Format(L.ALT_LIST_LINE, index, L[KIND_NAMES[alt.kind]], UIShared.ItemText(alt.itemID), note))
	end
end

local function addAlternative(charData, argument)
	local itemID, rest = Util.ParseItemArg(argument)
	local kindWord, note = Slash.SplitCommand(rest or "")
	local index, err = CraftEval.AddAlternative(charData, itemID, KIND_WORDS[kindWord], note, ns.Client:GetServerTime())
	if not index then
		Log.Print(err == "too_many_alternatives" and Util.Format(L.ALT_TOO_MANY, CraftEval.MAX_ALTERNATIVES) or L.ALT_USAGE)
		return
	end
	Log.Print(Util.Format(L.ALT_ADDED, index, UIShared.ItemText(itemID)))
end

local function altCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if sub == "" or sub == "list" then
		local charData = UIShared.Character()
		if charData then
			listAlternatives(charData)
		end
		return
	end
	if sub ~= "add" and sub ~= "remove" then
		Log.Print(L.ALT_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if not charData then
		return
	end
	if sub == "add" then
		addAlternative(charData, rest)
	elseif CraftEval.RemoveAlternative(charData, Util.ParseInteger(Util.Trim(rest))) then
		Log.Print(L.ALT_REMOVED)
	else
		Log.Print(Util.Format(L.ALT_NOT_FOUND, Util.Trim(rest)))
	end
end

if ns.Client then
	Slash.AddCommand("craft", craftCommand, L.HELP_LINE_CRAFT)
	Slash.AddCommand("weights", weightsCommand, L.HELP_LINE_WEIGHTS)
	Slash.AddCommand("alt", altCommand, L.HELP_LINE_ALT)
end
