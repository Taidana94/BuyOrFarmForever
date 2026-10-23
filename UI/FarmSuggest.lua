-- Start suggestion (setting farmSuggestStart): when the player loots an item the plan of the wants
-- still has to get and no farm run exists, a small bar offers to start a run with that item as
-- target. Each material is offered once per session; the bar hides after SHOW_SECONDS.
-- Automatic start (setting farmAutoStart, wins over the suggestion): any loot outside a city or inn
-- with no farm run starts one, with a looted missing material as target. The loot that started it
-- is not counted (the run begins after it). The idle time ends such a run like any other.
-- Loot and bag signals are registered only while one of the settings is on. Before the loot, the bag
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

-- Items the plan still has to get (buy, farm or open).
local function missingItems()
	local plan = ns.WantPlan.Current()
	local list = {}
	for itemID in pairs(plan and ns.WantPlan.ToGet(plan) or {}) do
		list[#list + 1] = itemID
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
	for _, itemID in ipairs(missingItems()) do
		before[itemID] = ns.Client:GetBagCount(itemID)
	end
end

local function onLootClosed()
	lootOpen = false
	lootClosedAt = ns.Client:GetUptime()
end

-- A missing material whose bag count rose since the loot window opened, or nil.
local function lootedMissing(skipOffered)
	for itemID, count in pairs(before) do
		if not (skipOffered and offered[itemID]) and ns.Client:GetBagCount(itemID) > count then
			return itemID
		end
	end
	return nil
end

local function autoStart()
	if ns.Client:IsResting() then
		return
	end
	local itemID = lootedMissing(false)
	ns.Slash.Handle("farm start" .. (itemID and " " .. itemID or ""))
end

local function onBagsChanged()
	local recent = lootOpen or (lootClosedAt and ns.Client:GetUptime() - lootClosedAt <= LOOT_GRACE_SECONDS)
	local data = charData()
	if not recent or not data or data.currentRun then
		return
	end
	if ns.db.settings.farmAutoStart then
		autoStart()
		return
	end
	local itemID = ns.db.settings.farmSuggestStart and lootedMissing(true)
	if itemID then
		offer(itemID)
	end
end

local HANDLERS = { LOOT_OPENED = onLootOpened, LOOT_CLOSED = onLootClosed, BAGS_CHANGED = onBagsChanged }
local active = false

-- Registers the loot and bag handlers while the setting is on.
local function sync()
	local settings = ns.db and ns.db.settings
	local wanted = settings ~= nil and not ns.readOnly and (settings.farmSuggestStart or settings.farmAutoStart)
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
