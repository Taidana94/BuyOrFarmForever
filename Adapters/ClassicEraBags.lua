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

function Bags.GetCurrentMapID()
	return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or 0
end

function Bags.GetMapName(uiMapID)
	local info = C_Map and C_Map.GetMapInfo and uiMapID and uiMapID > 0 and C_Map.GetMapInfo(uiMapID)
	return info and info.name or nil
end
