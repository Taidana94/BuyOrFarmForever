-- Start suggestion (setting farmSuggestStart): when the player loots a material that the selected
-- goal still misses and no farm run exists, a small bar offers to start a run with that material
-- as target ("Gegner" / "Sammeln"). Never starts by itself; each material is offered once per
-- session; the bar hides after SHOW_SECONDS.
-- Loot and bag signals are registered only while the setting is on. Before the loot, the bag
-- counts of the missing materials are noted; after it, a higher count is the looted material.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Events = ns.Events
local UIShared = ns.UIShared

local FarmSuggest = {}
ns.FarmSuggest = FarmSuggest

FarmSuggest.SHOW_SECONDS = 30
local LOOT_GRACE_SECONDS = 2
local BAR_Y = -140

local before = {} -- itemID -> bag count when the loot window opened
local offered = {} -- itemID -> true once offered in this session
local lootOpen, lootClosedAt = false, nil
local bar

local function charData()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey]
end

-- Missing materials of the selected goal.
local function missingItems(data)
	local goal = ns.Materials.GetActiveGoal(data)
	local list = {}
	for _, row in ipairs(goal and ns.Stock.Rows(data, { goal }) or {}) do
		if row.missing > 0 then
			list[#list + 1] = row.itemID
		end
	end
	return list
end

local function start(itemID)
	return function()
		ns.Slash.Handle("farm start " .. itemID)
	end
end

local function offer(itemID)
	offered[itemID] = true
	bar = bar or ns.PromptBar.Create(BAR_Y)
	ns.PromptBar.Show(bar, Util.Format(L.FARM_SUGGEST, UIShared.ItemText(itemID)), {
		{ L.FARM_BTN_START, start(itemID) },
		{ L.INPUT_NO },
	}, FarmSuggest.SHOW_SECONDS)
end

local function onLootOpened()
	lootOpen = true
	local data = charData()
	for itemID in pairs(before) do
		before[itemID] = nil
	end
	if not data or data.currentRun then
		return
	end
	for _, itemID in ipairs(missingItems(data)) do
		before[itemID] = ns.Client:GetBagCount(itemID)
	end
end

local function onLootClosed()
	lootOpen = false
	lootClosedAt = ns.Client:GetUptime()
end

local function onBagsChanged()
	local recent = lootOpen or (lootClosedAt and ns.Client:GetUptime() - lootClosedAt <= LOOT_GRACE_SECONDS)
	local data = charData()
	if not recent or not data or data.currentRun then
		return
	end
	for itemID, count in pairs(before) do
		if not offered[itemID] and ns.Client:GetBagCount(itemID) > count then
			offer(itemID)
			return
		end
	end
end

local HANDLERS = { LOOT_OPENED = onLootOpened, LOOT_CLOSED = onLootClosed, BAGS_CHANGED = onBagsChanged }
local active = false

-- Registers the loot and bag handlers while the setting is on.
local function sync()
	local wanted = ns.db ~= nil and not ns.readOnly and ns.db.settings.farmSuggestStart
	if wanted == active then
		return
	end
	active = wanted
	for signal, handler in pairs(HANDLERS) do
		if wanted then
			Events.OnSignal(signal, handler)
		else
			Events.OffSignal(signal, handler)
		end
	end
end

-- The bar frame, or nil before the first suggestion (for tests).
function FarmSuggest.GetBar()
	return bar
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", sync)
	Events.OnSignal("SETTINGS_CHANGED", sync)
end
