-- Item tooltip lines (setting tooltipEnabled): for items the plan of the character's wants needs the
-- missing amount, for wanted gear the score against the equipped gear; at the bottom the recipe lines
-- (UI/TooltipRecipe.lua, setting tooltipRecipes). The hook only reads a cache;
-- the cache is rebuilt once after wants, bags, bank, prices or equipment changed (dirty flag), not on
-- every tooltip. The hook is installed once at login through the adapter.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Events = ns.Events
local Stock = ns.Stock
local CraftEval = ns.CraftEval

local TooltipLines = {}
ns.TooltipLines = TooltipLines

local LINE_COLOR = { 0.4, 0.9, 1 }
local cache, dirty = {}, true
-- itemID -> recipe lines, or false when the addon knows no recipe; filled on demand.
local recipeCache, recipeIndex = {}, nil

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

local function addGearLines(data)
	for _, want in ipairs(data.wants) do
		local comparison = CraftEval.CompareWithEquipped(want.itemID, data.craftEval.weights)
		if comparison then
			addLine(want.itemID, Util.Format(L.TOOLTIP_CRAFT, gainText(comparison.gain)))
		end
	end
end

local function rebuild()
	for itemID in pairs(cache) do
		cache[itemID] = nil
	end
	for itemID in pairs(recipeCache) do
		recipeCache[itemID] = nil
	end
	recipeIndex = nil
	dirty = false
	local data = charData()
	if not data then
		return
	end
	local plan = ns.WantPlan.Current()
	for _, row in ipairs(plan and Stock.Rows(data, ns.WantPlan.Requirements(plan)) or {}) do
		local template = row.missing > 0 and L.TOOLTIP_MISSING or L.TOOLTIP_COMPLETE
		addLine(row.itemID, Util.Format(template, row.missing, row.need))
	end
	addGearLines(data)
end

-- Lines for an item (rebuilds the cache if needed); nil if the addon has nothing to say.
function TooltipLines.For(itemID)
	if dirty then
		rebuild()
	end
	return cache[itemID]
end

-- Recipe lines for an item (cached until the data changes), or nil.
function TooltipLines.RecipeFor(itemID)
	if dirty then
		rebuild()
	end
	if recipeCache[itemID] == nil then
		recipeIndex = recipeIndex or ns.TooltipRecipe.Index(ns.db)
		recipeCache[itemID] = ns.TooltipRecipe.Lines(itemID, recipeIndex, ns.Client:GetServerTime()) or false
	end
	return recipeCache[itemID] or nil
end

-- A line is a text, or { left, right } shown left and right-aligned (right side white).
local function addLines(tooltip, lines)
	for _, line in ipairs(lines or {}) do
		if type(line) == "table" then
			tooltip:AddDoubleLine(line[1], line[2], LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], 1, 1, 1)
		else
			tooltip:AddLine(line, LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3])
		end
	end
end

local PERCENT = 100

-- "AH-Absatz: 75 % – 3 von 4 deiner Auktionen verkauft" for items with an auction price, or nil.
function TooltipLines.SaleLine(itemID)
	local now = ns.Client:GetServerTime()
	if not (ns.db.settings.useSaleChance and ns.GoldRoutes.AuctionNet(itemID, now)) then
		return nil
	end
	local estimate = ns.SaleEstimate.For(itemID, now)
	local percent = math.floor(estimate.chance * PERCENT + 0.5)
	if estimate.source == "OWN" then
		return Util.Format(L.TOOLTIP_SALE_OWN, percent, estimate.sold, estimate.sold + estimate.expired)
	elseif estimate.source == "MARKET" then
		return Util.Format(L.TOOLTIP_SALE_MARKET, percent, estimate.supply)
	end
	return Util.Format(L.TOOLTIP_SALE_NONE, percent)
end

local function onTooltip(tooltip, itemID)
	if not (ns.db and not ns.readOnly) then
		return
	end
	if ns.db.settings.tooltipEnabled then
		addLines(tooltip, TooltipLines.For(itemID))
		addLines(tooltip, { TooltipLines.SaleLine(itemID) })
	end
	if ns.db.settings.tooltipRecipes then
		addLines(tooltip, TooltipLines.RecipeFor(itemID))
	end
end

local function markDirty()
	dirty = true
end

if ns.Client then
	for _, signal in ipairs({ "DATA_CHANGED", "BAGS_CHANGED", "BANK_CLOSED", "EQUIPMENT_CHANGED", "SETTINGS_CHANGED",
		"PRICES_CHANGED", "RECIPES_CHANGED" }) do
		Events.OnSignal(signal, markDirty)
	end
	Events.OnSignal("CHARACTER_READY", function()
		ns.Client:HookItemTooltips(onTooltip)
	end)
end
