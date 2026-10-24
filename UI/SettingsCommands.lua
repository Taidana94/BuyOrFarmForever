-- /bof set [setting value]: lists or changes a setting of the schema (Core/Settings.lua). The
-- settings tab uses the same command. Raises SETTINGS_CHANGED after a change.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Settings = ns.Settings
local Slash = ns.Slash
local UIShared = ns.UIShared

local SettingsCommands = {}
ns.SettingsCommands = SettingsCommands

-- "an" / "aus", the name of a choice or the number.
function SettingsCommands.ValueText(entry, value)
	if entry.type == "boolean" then
		return value and L.SET_ON or L.SET_OFF
	elseif entry.type == "choice" then
		return L["SET_CHOICE_" .. value]
	end
	return tostring(value)
end

-- A new language applies to new texts at once; open windows keep theirs until the next /reload.
local function applyLanguage()
	ns.Locale.SetActive(ns.Locale.Resolve(ns.db.settings.language, ns.Client:GetLocale()))
	ns.Events.Emit("LOCALE_CHANGED")
	Log.Print(L.SET_LANGUAGE_RELOAD)
end

local function listSettings()
	for _, entry in ipairs(Settings.SCHEMA) do
		Log.Print(Util.Format(L.SET_LIST_LINE, entry.key, SettingsCommands.ValueText(entry, ns.db.settings[entry.key]),
			L[entry.label]))
	end
end

local function invalidMessage(entry)
	if entry.type == "boolean" then
		return L.SET_INVALID_BOOLEAN
	elseif entry.type == "choice" then
		return L.SET_INVALID_CHOICE
	end
	return Util.Format(L.SET_INVALID_NUMBER, entry.min, entry.max)
end

local function setCommand(argument)
	local key, rest = Slash.SplitCommand(argument)
	if key == "" then
		if UIShared.Character() then
			listSettings()
		end
		return
	end
	local entry = Settings.Find(key)
	if not entry then
		Log.Print(Util.Format(L.SET_UNKNOWN, key))
		return
	end
	if not UIShared.WritableCharacter() then
		return
	end
	local value = Settings.ParseValue(entry, rest)
	if value == nil or not Settings.Set(ns.db.settings, entry.key, value) then
		Log.Print(invalidMessage(entry))
		return
	end
	if entry.key == "language" then
		applyLanguage()
	end
	Log.Print(Util.Format(L.SET_CHANGED, L[entry.label], SettingsCommands.ValueText(entry, value)))
	ns.Events.Emit("SETTINGS_CHANGED", entry.key)
end

if ns.Client then
	Slash.AddCommand("set", setCommand, "HELP_LINE_SET")
end
