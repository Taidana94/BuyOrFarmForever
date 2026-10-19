-- luacheck configuration for BuyOrFarmForever.
-- Lua 5.1 semantics. read_globals is an allowlist: only WoW APIs that were checked for the
-- target client (see work/notes/BuyOrFarmForever-plan.md and work/notes/forever-facts.md).
-- Add an API here only after it has been verified.

std = "lua51"
max_line_length = 140

-- Adapter functions are methods (Client:GetLocale()) so that every adapter has the same
-- call shape; many of them do not need self. Only the implicit self is exempt.
self = false

-- Globals the addon is allowed to create.
globals = {
	"BuyOrFarmForever", -- addon namespace (debugging)
	"BuyOrFarmForeverDB", -- SavedVariables
	"SLASH_BUYORFARMFOREVER1", -- /bof
	"SLASH_BUYORFARMFOREVER2", -- /kof
	SlashCmdList = { fields = { BUYORFARMFOREVER = { read_only = false } } },
	-- key binding names (Bindings.xml)
	"BINDING_HEADER_BUYORFARMFOREVER",
	"BINDING_NAME_BUYORFARMFOREVER_TOGGLE",
	"BINDING_NAME_BUYORFARMFOREVER_FARM",
}

-- WoW API and Blizzard UI globals the addon is allowed to read.
-- Status for Classic Era 1.15.9 (70003): documented in Blizzard_APIDocumentationGenerated
-- and/or used by Blizzard's own UI code in that build. GetBuildInfo is confirmed in game.
read_globals = {
	-- client identity
	"GetBuildInfo",
	"GetLocale",
	"WOW_PROJECT_ID",
	"WOW_PROJECT_CLASSIC",
	C_AddOns = { fields = { "GetAddOnMetadata" } },
	-- items and bags (GetItemCount with includeBank: correct with closed bank, confirmed in game)
	C_Item = { fields = { "GetItemCount", "GetItemIconByID", "GetItemInfo", "GetItemInfoInstant", "RequestLoadItemDataByID" } },
	-- equipment and item stats (GetItemStats confirmed in game 70003; GetInventoryItemLink used by PaperDollFrame)
	"GetItemStats",
	"GetInventoryItemLink",
	C_Spell = { fields = { "GetSpellName" } },
	-- bags and map (documented in 70003; NUM_BAG_SLOTS from Blizzard_FrameXMLBase/Classic/Constants.lua)
	C_Container = { fields = { "GetContainerNumSlots", "GetContainerItemInfo" } },
	C_Map = { fields = { "GetBestMapForUnit", "GetMapInfo" } },
	"NUM_BAG_SLOTS",
	"GetMoney", -- used by Blizzard_AuctionUI (Classic) in 70003
	-- cursor (documented in 70003; item id return unverified, see Adapters/ClassicEraUI.lua)
	"GetCursorInfo",
	"ClearCursor",
	-- player state (UnitIsAFK, UnitClass, C_SpecializationInfo documented in 70003; IsResting and
	-- UnitOnTaxi, UnitLevel used by Blizzard's Classic Era UI; see Adapters/ClassicEraPlayer.lua)
	"UnitIsAFK",
	"IsResting",
	"UnitOnTaxi",
	"UnitClass",
	"UnitLevel",
	C_SpellBook = { fields = { "IsSpellKnown" } },
	C_SpecializationInfo = { fields = { "GetSpecializationInfo" } },
	-- quest frame rewards (Blizzard_UIPanels_Game/Classic/QuestFrame.lua, Vanilla/QuestInfo.lua, 70003)
	"GetNumQuestChoices",
	"GetNumQuestRewards",
	"GetQuestItemLink",
	"GetTitleText",
	-- profession windows (called by Blizzard_TradeSkillUI / Blizzard_CraftUI, Vanilla, 70003)
	"GetTradeSkillSelectionIndex",
	"GetTradeSkillInfo",
	"GetTradeSkillItemLink",
	"GetTradeSkillRecipeLink",
	"GetTradeSkillNumMade",
	"GetTradeSkillNumReagents",
	"GetTradeSkillReagentInfo",
	"GetTradeSkillReagentItemLink",
	"GetCraftSelectionIndex",
	"GetCraftInfo",
	"GetCraftItemLink",
	"GetCraftNumReagents",
	"GetCraftReagentInfo",
	"GetCraftReagentItemLink",
	"SelectTradeSkill", -- hooked only (hooksecurefunc), to know where a recipe was selected last
	"SelectCraft",
	"hooksecurefunc", -- used by Blizzard UI code in 70003 (e.g. Blizzard_EditMode)
	ChatFrameUtil = { fields = { "InsertLink", "GetActiveWindow" } }, -- Blizzard_ChatFrameBase (70003), post-hook only
	-- character, time
	"UnitName",
	"GetRealmName",
	"GetNormalizedRealmName",
	"UnitFactionGroup",
	"GetServerTime",
	"GetTime",
	"issecretvalue",
	-- frames, chat, errors (templates and constants: Blizzard_SharedXML, Vanilla, 70003)
	"CreateFrame",
	"UIParent",
	"GameTooltip",
	"ItemRefTooltip", -- Blizzard_UIPanels_Game/Classic/ItemRef.xml (70003)
	"MerchantFrame", -- Blizzard_UIPanels_Game/Vanilla/MerchantFrame.xml (70003)
	"Minimap", -- Blizzard_Minimap/Classic/Minimap.xml (70003)
	-- optional price addon (Source/API/v1 of Auctionator; work/notes/price-addons.md)
	Auctionator = { fields = { API = { fields = { v1 = { fields = {
		"GetAuctionPriceByItemID", "GetAuctionAgeByItemID",
	} } } } } },
	"UISpecialFrames",
	"BACKDROP_DIALOG_32_32",
	C_Timer = { fields = { "After", "NewTicker" } },
	-- merchant and auction house (called by MerchantFrame.lua / Blizzard_AuctionUI, Vanilla, 70003)
	"GetMerchantNumItems",
	"GetMerchantItemInfo",
	"GetMerchantItemLink",
	"GetNumAuctionItems",
	"GetAuctionItemInfo",
	"CanSendAuctionQuery",
	"QueryAuctionItems",
	-- performance (/bof perf; documented in 70003, used by Blizzard_AddOnList)
	"UpdateAddOnMemoryUsage",
	"GetAddOnMemoryUsage",
	"debugprofilestop",
	C_AddOnProfiler = { fields = { "IsEnabled", "GetAddOnMetric", "GetApplicationMetric", "GetOverallMetric" } },
	Enum = { fields = {
		AddOnProfilerMetric = { fields = { "RecentAverageTime", "SessionAverageTime", "PeakTime" } },
		BagIndex = { fields = { "Backpack" } },
		ItemClass = { fields = { "Weapon", "Armor" } },
	} },
	"DEFAULT_CHAT_FRAME",
	"geterrorhandler",
}

-- Locale strings are full sentences on one line (required by the localization check).
files["Locales/"] = { max_line_length = false }

exclude_files = {
	".git/",
	"docs/",
}
