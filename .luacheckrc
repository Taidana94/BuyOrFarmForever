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
	C_Item = { fields = { "GetItemCount", "GetItemIconByID", "GetItemInfo", "RequestLoadItemDataByID" } },
	C_Spell = { fields = { "GetSpellName" } },
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
	"UISpecialFrames",
	"BACKDROP_DIALOG_32_32",
	C_Timer = { fields = { "After" } },
	-- performance (/bof perf; documented in 70003, used by Blizzard_AddOnList)
	"UpdateAddOnMemoryUsage",
	"GetAddOnMemoryUsage",
	"debugprofilestop",
	C_AddOnProfiler = { fields = { "IsEnabled", "GetAddOnMetric", "GetApplicationMetric", "GetOverallMetric" } },
	Enum = { fields = { AddOnProfilerMetric = { fields = { "RecentAverageTime", "SessionAverageTime", "PeakTime" } } } },
	"DEFAULT_CHAT_FRAME",
	"geterrorhandler",
}

-- Locale strings are full sentences on one line (required by the localization check).
files["Locales/"] = { max_line_length = false }

exclude_files = {
	".git/",
	"docs/",
}
