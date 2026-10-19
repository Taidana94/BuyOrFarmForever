-- Classic Era adapter part: contents of the carried bags and the player's map.
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- C_Container, C_Map and Enum.BagIndex are documented in Classic Era 70003; NUM_BAG_SLOTS is
-- defined by Blizzard_FrameXMLBase/Classic/Constants.lua.
local _, ns = ...

local Bags = {}
ns.ClassicEraBags = Bags

-- Fallbacks with the documented values, in case the constants are missing.
local BACKPACK = Enum and Enum.BagIndex and Enum.BagIndex.Backpack or 0
local DEFAULT_BAG_SLOTS = 4

-- Fills counts with { [itemID] = total count } over the backpack and the equipped bags.
-- The table is cleared and reused, so a bag update creates no new count table.
function Bags.ScanBags(counts)
	for itemID in pairs(counts) do
		counts[itemID] = nil
	end
	if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
		return counts
	end
	local lastBag = BACKPACK + (NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS)
	for bag = BACKPACK, lastBag do
		for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID and info.stackCount then
				counts[info.itemID] = (counts[info.itemID] or 0) + info.stackCount
			end
		end
	end
	return counts
end

-- Every stack in the backpack and the equipped bags: { { itemID, count, isBound, hasNoValue, bag,
-- slot } } (fields of ContainerItemInfo, documented in 70003). Built on demand, not per event.
function Bags.ListBagStacks()
	local stacks = {}
	if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
		return stacks
	end
	for bag = BACKPACK, BACKPACK + (NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS) do
		for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID and info.stackCount then
				stacks[#stacks + 1] = { itemID = info.itemID, count = info.stackCount, isBound = info.isBound == true,
					hasNoValue = info.hasNoValue == true, bag = bag, slot = slot }
			end
		end
	end
	return stacks
end

-- Free slots over the backpack and the equipped bags (all bag types), or nil without the API.
function Bags.GetFreeBagSlots()
	if not (C_Container and C_Container.GetContainerNumFreeSlots) then
		return nil
	end
	local free = 0
	for bag = BACKPACK, BACKPACK + (NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS) do
		free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0)
	end
	return free
end

-- Sells the stack in bag/slot to the open merchant (C_Container.UseContainerItem, documented in
-- 70003 without restrictions; with a merchant open it sells). Only if the slot still holds itemID,
-- so a moved stack is never sold by mistake. Returns true if the sale was sent.
function Bags.SellStack(bag, slot, itemID)
	local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
	if not (info and info.itemID == itemID and C_Container.UseContainerItem) then
		return false
	end
	C_Container.UseContainerItem(bag, slot)
	return true
end

function Bags.GetCurrentMapID()
	return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or 0
end

function Bags.GetMapName(uiMapID)
	local info = C_Map and C_Map.GetMapInfo and uiMapID and uiMapID > 0 and C_Map.GetMapInfo(uiMapID)
	return info and info.name or nil
end
