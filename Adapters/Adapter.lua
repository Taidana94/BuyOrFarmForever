-- Adapter interface: the only place where client-specific code meets the core.
-- Each client TOC loads exactly one adapter file, which calls Adapter.Register.
-- Core code uses ns.Client and never calls WoW APIs directly.
local _, ns = ...

local L = ns.L

local Adapter = {}
ns.Adapter = Adapter

-- Fields every adapter must provide. This list grows with each stage of the plan
-- (see work/notes/BuyOrFarmForever-plan.md, section 6).
Adapter.REQUIRED = {
	"IsCurrentClient", -- () -> bool: true if this adapter matches the running client
	"GetBuildInfo", -- () -> { version, build, date, interface }
	"GetLocale", -- () -> locale code, e.g. "deDE"
	"GetAddOnVersion", -- (addonName) -> version string from the TOC, or nil
	"GetCharacterKey", -- () -> { key, name, realm, normalizedRealm, faction } or nil before login
	"GetServerTime", -- () -> server time in seconds since the epoch
	"GetUptime", -- () -> client uptime in seconds (for durations within a session)
	"GetBagCount", -- (itemID) -> count in the bags
	"GetBagAndBankCount", -- (itemID) -> count in bags and bank, or nil if not available
	"GetItemLink", -- (itemID) -> item link, or nil while item data is loading (load is requested)
	"GetItemIcon", -- (itemID) -> icon file id, or nil
	"GetSpellName", -- (spellID) -> localized name, or nil
	"ReadSelectedRecipe", -- () -> recipe of the open profession window, or nil + "no_window" | "no_selection" | "loading"
}

-- Every adapter also has an `events` table: WoW event name -> client-neutral signal.
-- Signals used so far: BANK_OPENED, BANK_CLOSED, BAGS_CHANGED, ITEM_LOADED (itemID, success).
-- Internal signal (no WoW event): DATA_CHANGED, raised after every registered slash command.

-- Returns true, or false plus a list of missing field names.
function Adapter.Validate(adapter)
	local missing = {}
	if type(adapter) ~= "table" then
		return false, { "<adapter table>" }
	end
	if type(adapter.id) ~= "string" or adapter.id == "" then
		missing[#missing + 1] = "id"
	end
	for _, name in ipairs(Adapter.REQUIRED) do
		if type(adapter[name]) ~= "function" then
			missing[#missing + 1] = name
		end
	end
	if type(adapter.events) ~= "table" then
		missing[#missing + 1] = "events"
	end
	return #missing == 0, missing
end

local function printMessage(text)
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage("|cff33ff99" .. L.ADDON_TITLE .. "|r: " .. text)
	end
end

-- Registers the client adapter. A structurally incomplete adapter is a programming
-- error and raises. An adapter for a different client leaves ns.Client unset.
function Adapter.Register(adapter)
	local ok, missing = Adapter.Validate(adapter)
	if not ok then
		error("Adapter is missing required fields: " .. table.concat(missing, ", "), 2)
	end
	if ns.Client then
		error("An adapter is already registered: " .. tostring(ns.Client.id), 2)
	end
	if not adapter:IsCurrentClient() then
		ns.clientMismatch = adapter.id
		printMessage(L.CLIENT_MISMATCH)
		return false
	end
	ns.Client = adapter
	ns.Locale.SetActive(adapter:GetLocale())
	return true
end
