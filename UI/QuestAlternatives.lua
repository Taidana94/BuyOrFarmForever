-- Quest rewards as craft alternatives (setting questAlternatives): when the quest frame shows a
-- reward that fits the same equipment slot as an item one of the goals crafts, a bar offers to
-- keep it as a planned alternative. Never added without a click; each item is offered once per
-- session. The quest signals are registered at login and cost nothing between quest frames.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Events = ns.Events
local CraftEval = ns.CraftEval
local UIShared = ns.UIShared

local QuestAlternatives = {}
ns.QuestAlternatives = QuestAlternatives

QuestAlternatives.SHOW_SECONDS = 30
local BAR_Y = -210

local offered = {}
local bar

local function charData()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey]
end

-- Equipment slots of the items the goals craft: { [slotKey] = true }.
local function goalSlots(data)
	local slots = {}
	for _, goal in ipairs(ns.Materials.AllGoals(data)) do
		local itemID = CraftEval.GoalItemID(goal)
		for _, slot in ipairs(itemID and ns.Client:GetEquipSlots(itemID) or {}) do
			slots[slot] = true
		end
	end
	return slots
end

local function isAlternative(data, itemID)
	for _, alt in ipairs(data.craftEval.alternatives) do
		if alt.itemID == itemID then
			return true
		end
	end
	return false
end

local function sharesSlot(itemID, slots)
	for _, slot in ipairs(ns.Client:GetEquipSlots(itemID) or {}) do
		if slots[slot] then
			return true
		end
	end
	return false
end

-- First reward that shares a slot with a crafted goal item and is not offered or kept yet.
function QuestAlternatives.Candidate(data, items)
	local slots = goalSlots(data)
	for _, itemID in ipairs(items) do
		if not offered[itemID] and not isAlternative(data, itemID) and sharesSlot(itemID, slots) then
			return itemID
		end
	end
	return nil
end

local function onQuestFrame()
	local data = charData()
	local rewards = data and ns.db.settings.questAlternatives and ns.Client:GetQuestRewards()
	local itemID = rewards and QuestAlternatives.Candidate(data, rewards.items)
	if not itemID then
		return
	end
	offered[itemID] = true
	bar = bar or ns.PromptBar.Create(BAR_Y)
	local note = Util.Format(L.QUEST_ALT_NOTE, rewards.title)
	ns.PromptBar.Show(bar, Util.Format(L.QUEST_ALT_OFFER, UIShared.ItemText(itemID)), {
		{ L.QUEST_ALT_KEEP, function()
			ns.Slash.Handle("alt add " .. itemID .. " planned " .. note)
		end },
		{ L.INPUT_NO },
	}, QuestAlternatives.SHOW_SECONDS)
end

-- The bar, or nil before the first offer (for tests).
function QuestAlternatives.GetBar()
	return bar
end

if ns.Client then
	Events.OnSignal("QUEST_OFFERED", onQuestFrame)
	Events.OnSignal("QUEST_REWARDS", onQuestFrame)
end
