-- Classic Era adapter part: item stats, equip slots and equipped items for the craft evaluation.
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- GetItemStats is a global function in Classic Era 1.15.9 (confirmed in game; C_Item.GetItemStats
-- does not exist there). GetInventoryItemLink is used by the Vanilla PaperDollFrame,
-- C_Item.GetItemInfoInstant / C_Item.GetItemInfo are documented (70003).
local _, ns = ...

local Gear = {}
ns.ClassicEraGear = Gear

-- GetItemStats keys (Blizzard global-string names) -> neutral stat keys used by the core.
local STAT_KEYS = {
	ITEM_MOD_STRENGTH_SHORT = "STR",
	ITEM_MOD_AGILITY_SHORT = "AGI",
	ITEM_MOD_STAMINA_SHORT = "STA",
	ITEM_MOD_INTELLECT_SHORT = "INT",
	ITEM_MOD_SPIRIT_SHORT = "SPI",
	RESISTANCE0_NAME = "ARMOR",
}

-- Inventory slots (INVSLOT_* in Blizzard_FrameXMLBase/Classic/Constants.lua) per equip location.
-- With several slots the item replaces the weaker one (rings, trinkets); with sum = true it replaces
-- all of them together (a two-handed weapon replaces main and off hand). One-handed weapons are
-- compared with the main hand only.
local INVSLOT = {
	HEAD = 1, NECK = 2, SHOULDER = 3, BODY = 4, CHEST = 5, WAIST = 6, LEGS = 7, FEET = 8, WRIST = 9, HAND = 10,
	FINGER1 = 11, FINGER2 = 12, TRINKET1 = 13, TRINKET2 = 14, BACK = 15,
	MAINHAND = 16, OFFHAND = 17, RANGED = 18, TABARD = 19,
}
local SLOTS = {
	INVTYPE_HEAD = { INVSLOT.HEAD },
	INVTYPE_NECK = { INVSLOT.NECK },
	INVTYPE_SHOULDER = { INVSLOT.SHOULDER },
	INVTYPE_BODY = { INVSLOT.BODY },
	INVTYPE_CHEST = { INVSLOT.CHEST },
	INVTYPE_ROBE = { INVSLOT.CHEST },
	INVTYPE_WAIST = { INVSLOT.WAIST },
	INVTYPE_LEGS = { INVSLOT.LEGS },
	INVTYPE_FEET = { INVSLOT.FEET },
	INVTYPE_WRIST = { INVSLOT.WRIST },
	INVTYPE_HAND = { INVSLOT.HAND },
	INVTYPE_FINGER = { INVSLOT.FINGER1, INVSLOT.FINGER2 },
	INVTYPE_TRINKET = { INVSLOT.TRINKET1, INVSLOT.TRINKET2 },
	INVTYPE_CLOAK = { INVSLOT.BACK },
	INVTYPE_WEAPON = { INVSLOT.MAINHAND },
	INVTYPE_WEAPONMAINHAND = { INVSLOT.MAINHAND },
	INVTYPE_2HWEAPON = { INVSLOT.MAINHAND, INVSLOT.OFFHAND, sum = true },
	INVTYPE_WEAPONOFFHAND = { INVSLOT.OFFHAND },
	INVTYPE_SHIELD = { INVSLOT.OFFHAND },
	INVTYPE_HOLDABLE = { INVSLOT.OFFHAND },
	INVTYPE_RANGED = { INVSLOT.RANGED },
	INVTYPE_RANGEDRIGHT = { INVSLOT.RANGED },
	INVTYPE_THROWN = { INVSLOT.RANGED },
	INVTYPE_RELIC = { INVSLOT.RANGED },
	INVTYPE_TABARD = { INVSLOT.TABARD },
}

-- Position of sellPrice in the returns of C_Item.GetItemInfo (generated docs, 70003).
local SELL_PRICE_RETURN = 11

local function itemLink(itemID)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	local _, link = C_Item.GetItemInfo(itemID)
	if not link and C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return link
end

-- { STR, AGI, STA, INT, SPI, ARMOR } (missing stats are 0), or nil while the item data loads.
function Gear.GetItemStats(itemID)
	local link = itemLink(itemID)
	if not (link and GetItemStats) then
		return nil
	end
	local stats = { STR = 0, AGI = 0, STA = 0, INT = 0, SPI = 0, ARMOR = 0 }
	for key, value in pairs(GetItemStats(link) or {}) do
		local stat = STAT_KEYS[key]
		if stat and type(value) == "number" then
			stats[stat] = value
		end
	end
	return stats
end

-- Inventory slots the item goes into: { slot, ... } with .sum = true when it replaces all of
-- them together; nil if the item cannot be equipped.
function Gear.GetEquipSlots(itemID)
	if not (C_Item and C_Item.GetItemInfoInstant) then
		return nil
	end
	local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
	return equipLoc and SLOTS[equipLoc] or nil
end

-- Item id in an inventory slot of the player, or nil if the slot is empty.
function Gear.GetEquippedItemID(slot)
	if not GetInventoryItemLink then
		return nil
	end
	local _, itemID = ns.Util.ParseLink(GetInventoryItemLink("player", slot))
	return itemID
end

-- Vendor sell price per unit in copper, or nil while the item data loads.
function Gear.GetSellPrice(itemID)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	local sellPrice = select(SELL_PRICE_RETURN, C_Item.GetItemInfo(itemID))
	if sellPrice == nil and C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return sellPrice
end
