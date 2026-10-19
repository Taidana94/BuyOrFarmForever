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
		ITEM_DATA_LOAD_RESULT = "ITEM_LOADED",
		MERCHANT_SHOW = "MERCHANT_OPENED",
		MERCHANT_UPDATE = "MERCHANT_CHANGED",
		MERCHANT_CLOSED = "MERCHANT_CLOSED",
		AUCTION_HOUSE_SHOW = "AUCTION_OPENED",
		AUCTION_HOUSE_CLOSED = "AUCTION_CLOSED",
		AUCTION_ITEM_LIST_UPDATE = "AUCTION_RESULTS",
		LOOT_OPENED = "LOOT_OPENED",
		LOOT_CLOSED = "LOOT_CLOSED",
		-- Only used to note the time of a running farm run; item counts are not read at logout.
		PLAYER_LOGOUT = "LOGOUT",
		PLAYER_MONEY = "MONEY_CHANGED",
		PLAYER_EQUIPMENT_CHANGED = "EQUIPMENT_CHANGED",
		-- Windows whose bag gains are not farm yield (purchases, mail, trade).
		MAIL_SHOW = "MAIL_OPENED",
		MAIL_CLOSED = "MAIL_CLOSED",
		TRADE_SHOW = "TRADE_OPENED",
		TRADE_CLOSED = "TRADE_CLOSED",
		-- Combat start counts as farm activity (idle time detection).
		PLAYER_REGEN_DISABLED = "COMBAT_STARTED",
		-- Player state for automatic pause and travel.
		PLAYER_FLAGS_CHANGED = "PLAYER_FLAGS_CHANGED",
		PLAYER_UPDATE_RESTING = "RESTING_CHANGED",
		PLAYER_CONTROL_LOST = "CONTROL_LOST",
		PLAYER_CONTROL_GAINED = "CONTROL_GAINED",
		-- Quest frame with rewards (offered quest, quest ready to turn in).
		QUEST_DETAIL = "QUEST_OFFERED",
		QUEST_COMPLETE = "QUEST_REWARDS",
		QUEST_FINISHED = "QUEST_CLOSED",
		-- Trainer window (gold spent on training).
		TRAINER_SHOW = "TRAINER_OPENED",
		TRAINER_CLOSED = "TRAINER_CLOSED",
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

-- includeBank = true. Correct also while the bank is closed (confirmed in game, 70003).
function ClassicEra:GetBagAndBankCount(itemID)
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemID, true)
	end
	return nil
end

-- C_Spell.GetSpellName is documented in Classic Era 70003 (MayReturnNothing).
function ClassicEra:GetSpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return plain(C_Spell.GetSpellName(spellID))
	end
	return nil
end

-- File id of the item icon, or nil (C_Item.GetItemIconByID, documented in 70003).
function ClassicEra:GetItemIcon(itemID)
	if C_Item and C_Item.GetItemIconByID then
		return C_Item.GetItemIconByID(itemID)
	end
	return nil
end

-- Performance --------------------------------------------------------------------------
-- All documented in Classic Era 70003 and used by Blizzard_AddOnList.

-- Memory of the addon in KB. refresh = true first updates the numbers (walks all addons).
function ClassicEra:GetMemoryKB(addonName, refresh)
	if not GetAddOnMemoryUsage then
		return nil
	end
	if refresh and UpdateAddOnMemoryUsage then
		UpdateAddOnMemoryUsage()
	end
	return GetAddOnMemoryUsage(addonName)
end

local function metric(addonName, which)
	return {
		addon = C_AddOnProfiler.GetAddOnMetric(addonName, which),
		app = C_AddOnProfiler.GetApplicationMetric(which),
		overall = C_AddOnProfiler.GetOverallMetric(which),
	}
end

-- { recent, average, peak } with { addon, app, overall } each, or nil if the profiler is off.
function ClassicEra:GetCPUMetrics(addonName)
	local profiler = C_AddOnProfiler
	local metrics = Enum and Enum.AddOnProfilerMetric
	if not (profiler and profiler.IsEnabled and metrics and profiler.IsEnabled()) then
		return nil
	end
	return {
		recent = metric(addonName, metrics.RecentAverageTime),
		average = metric(addonName, metrics.SessionAverageTime),
		peak = metric(addonName, metrics.PeakTime),
	}
end

-- High-resolution time in milliseconds (debugprofilestop), or nil.
function ClassicEra:GetTimeMs()
	return debugprofilestop and debugprofilestop() or nil
end

-- Merchant and auction house: Adapters/ClassicEraTrade.lua.
function ClassicEra:ReadMerchantPrices()
	return ns.ClassicEraTrade.ReadMerchantPrices()
end

function ClassicEra:ReadAuctionResults()
	return ns.ClassicEraTrade.ReadAuctionResults()
end

function ClassicEra:CanQueryAuction()
	return ns.ClassicEraTrade.CanQueryAuction()
end

function ClassicEra:QueryAuction(itemName)
	return ns.ClassicEraTrade.QueryAuction(itemName)
end

-- Item name if cached; otherwise requests the item data and returns nil.
function ClassicEra:GetItemName(itemID)
	local name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(itemID)
	if not name and C_Item and C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return name
end

-- Copper the character carries (GetMoney, used by Blizzard_AuctionUI in 70003), or nil.
function ClassicEra:GetMoney()
	return GetMoney and GetMoney() or nil
end

-- Item stats and equipment: Adapters/ClassicEraGear.lua.
function ClassicEra:GetItemStats(itemID)
	return ns.ClassicEraGear.GetItemStats(itemID)
end

function ClassicEra:GetEquipSlots(itemID)
	return ns.ClassicEraGear.GetEquipSlots(itemID)
end

function ClassicEra:GetEquippedItemID(slot)
	return ns.ClassicEraGear.GetEquippedItemID(slot)
end

function ClassicEra:GetSellPrice(itemID)
	return ns.ClassicEraGear.GetSellPrice(itemID)
end

function ClassicEra:GetItemMinLevel(itemID)
	return ns.ClassicEraGear.GetItemMinLevel(itemID)
end

-- Bags and map: Adapters/ClassicEraBags.lua.
function ClassicEra:ScanBags(counts)
	return ns.ClassicEraBags.ScanBags(counts)
end

function ClassicEra:GetCurrentMapID()
	return ns.ClassicEraBags.GetCurrentMapID()
end

function ClassicEra:GetMapName(uiMapID)
	return ns.ClassicEraBags.GetMapName(uiMapID)
end

-- Profession windows: Adapters/ClassicEraProfessions.lua.
function ClassicEra:ReadSelectedRecipe()
	return ns.ClassicEraProfessions.ReadSelectedRecipe()
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

-- Parts whose functions need no adapter state are exposed as methods unchanged:
-- Adapters/ClassicEraUI.lua (cursor and window helpers), Adapters/ClassicEraPlayer.lua (player state),
-- Adapters/ClassicEraQuest.lua (quest rewards), Adapters/ClassicEraExternal.lua (other addons).
for _, part in ipairs({ ns.ClassicEraUI, ns.ClassicEraPlayer, ns.ClassicEraQuest, ns.ClassicEraExternal }) do
	for name, fn in pairs(part) do
		ClassicEra[name] = function(_, ...)
			return fn(...)
		end
	end
end

ns.Adapter.Register(ClassicEra)
