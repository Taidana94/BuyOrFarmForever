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
}

-- WoW API and Blizzard UI globals the addon is allowed to read.
read_globals = {
	-- Classic Era: confirmed (build data 70003); GetBuildInfo also confirmed in game
	"GetBuildInfo",
	"GetLocale",
	"WOW_PROJECT_ID",
	"WOW_PROJECT_CLASSIC",
	"DEFAULT_CHAT_FRAME",
}

exclude_files = {
	".git/",
	"docs/",
}
