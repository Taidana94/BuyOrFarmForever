-- Item tooltip lines (setting tooltipEnabled): for materials of the character's goals the missing
-- amount, for items that a goal crafts the score against the equipped gear. The hook only reads a
-- cache; the cache is rebuilt once after goals, bags, bank or equipment changed (dirty flag), not
-- on every tooltip. The hook is installed once at login through the adapter.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Events = ns.Events
local Materials = ns.Materials
local Stock = ns.Stock
local CraftEval = ns.CraftEval

local TooltipLines = {}
ns.TooltipLines = TooltipLines

local LINE_COLOR = { 0.4, 0.9, 1 }
local cache, dirty = {}, true

local function charData()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey]
end

local function addLine(itemID, text)
	local lines = cache[itemID]
	if not lines then
		lines = {}
		cache[itemID] = lines
	end
	lines[#lines + 1] = text
end

local function gainText(gain)
	local decimals = gain == math.floor(gain) and 0 or 1
	return (gain > 0 and "+" or "") .. Util.FormatDecimal(gain, decimals)
end

local function addCraftLines(data, goals)
	for _, goal in ipairs(goals) do
		local itemID = CraftEval.GoalItemID(goal)
		local comparison = itemID and CraftEval.CompareWithEquipped(itemID, data.craftEval.weights)
		if comparison then
			addLine(itemID, Util.Format(L.TOOLTIP_CRAFT, gainText(comparison.gain)))
		end
	end
end

local function rebuild()
	for itemID in pairs(cache) do
		cache[itemID] = nil
	end
	dirty = false
	local data = charData()
	if not data then
		return
	end
	local goals = Materials.AllGoals(data)
	for _, row in ipairs(Stock.Rows(data, goals)) do
		local template = row.missing > 0 and L.TOOLTIP_MISSING or L.TOOLTIP_COMPLETE
		addLine(row.itemID, Util.Format(template, row.missing, row.need))
	end
	addCraftLines(data, goals)
end

-- Lines for an item (rebuilds the cache if needed); nil if the addon has nothing to say.
function TooltipLines.For(itemID)
	if dirty then
		rebuild()
	end
	return cache[itemID]
end

local function onTooltip(tooltip, itemID)
	if not (ns.db and not ns.readOnly and ns.db.settings.tooltipEnabled) then
		return
	end
	local lines = TooltipLines.For(itemID)
	for _, text in ipairs(lines or {}) do
		tooltip:AddLine(text, LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3])
	end
end

local function markDirty()
	dirty = true
end

if ns.Client then
	for _, signal in ipairs({ "DATA_CHANGED", "BAGS_CHANGED", "BANK_CLOSED", "EQUIPMENT_CHANGED", "SETTINGS_CHANGED" }) do
		Events.OnSignal(signal, markDirty)
	end
	Events.OnSignal("CHARACTER_READY", function()
		ns.Client:HookItemTooltips(onTooltip)
	end)
end
