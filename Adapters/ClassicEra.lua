-- Client adapter for WoW Classic Era (1.15.9, interface 11509).
-- APIs used here are listed with their verification status in work/notes/BuyOrFarmForever-plan.md.
local _, ns = ...

local ClassicEra = {
	id = "classic_era",
	caps = {},
	-- WoW event -> client-neutral signal (all documented in Classic Era 70003)
	events = {
		BANKFRAME_OPENED = "BANK_OPENED",
		BANKFRAME_CLOSED = "BANK_CLOSED",
		BAG_UPDATE_DELAYED = "BAGS_CHANGED",
	},
}

-- WOW_PROJECT_CLASSIC (2) and WOW_PROJECT_ID are defined by Blizzard's
-- Blizzard_FrameXMLBase/Vanilla/Constants.lua in Classic Era.
function ClassicEra:IsCurrentClient()
	return WOW_PROJECT_ID ~= nil and WOW_PROJECT_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function ClassicEra:GetBuildInfo()
	local version, build, date, interface = GetBuildInfo()
	return {
		version = version,
		build = build,
		date = date,
		interface = interface,
	}
end

function ClassicEra:GetLocale()
	return GetLocale()
end

function ClassicEra:GetAddOnVersion(addonName)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(addonName, "Version")
	end
	return nil
end

-- Returns the value, or nil if it is missing or a secret value.
local function plain(value)
	if value == nil then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

-- Returns nil until name and realm are known. Call it on or after PLAYER_LOGIN.
function ClassicEra:GetCharacterKey()
	local name = plain(UnitName("player"))
	local normalizedRealm = plain(GetNormalizedRealmName())
	if type(name) ~= "string" or name == "" or type(normalizedRealm) ~= "string" or normalizedRealm == "" then
		return nil
	end
	return {
		key = name .. "-" .. normalizedRealm,
		name = name,
		realm = plain(GetRealmName()),
		normalizedRealm = normalizedRealm,
		faction = plain(UnitFactionGroup("player")),
	}
end

function ClassicEra:GetServerTime()
	return GetServerTime()
end

function ClassicEra:GetUptime()
	return GetTime()
end

function ClassicEra:GetBagCount(itemID)
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemID, false)
	end
	return 0
end

-- includeBank = true. Whether this is correct while the bank is closed is unverified (Q-T6).
function ClassicEra:GetBagAndBankCount(itemID)
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemID, true)
	end
	return nil
end

-- C_Item.GetItemInfo returns nil until the item is in the client cache.
function ClassicEra:GetItemLink(itemID)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	local _, link = C_Item.GetItemInfo(itemID)
	if link then
		return link
	end
	if C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return nil
end

ns.Adapter.Register(ClassicEra)
