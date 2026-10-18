-- Slash commands /bof and /kof: help, version, debug, reset.
-- Subcommands are language-neutral; all output is localized.
local addonName, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util

local Slash = {}
ns.Slash = Slash

Slash.RESET_CONFIRM_SECONDS = 30

local resetPendingUntil = nil

local function printHelp()
	Log.Print(L.HELP_HEADER)
	Log.Print(L.HELP_LINE_HELP)
	Log.Print(L.HELP_LINE_VERSION)
	Log.Print(L.HELP_LINE_DEBUG)
	Log.Print(L.HELP_LINE_RESET)
end

local function clientName(client)
	if client.id == "classic_era" then
		return L.CLIENT_CLASSIC_ERA
	end
	return client.id
end

local function printVersion()
	local client = ns.Client
	local info = client:GetBuildInfo()
	local unknown = L.UNKNOWN_VALUE
	Log.Print(Util.Format(
		L.VERSION_LINE,
		client:GetAddOnVersion(addonName) or unknown,
		info.interface or unknown,
		info.build or unknown,
		info.version or unknown,
		clientName(client)
	))
end

-- Returns true if the database may be changed; prints the reason otherwise.
local function canWrite()
	if not ns.db then
		Log.Print(L.NOT_READY)
		return false
	end
	if ns.readOnly then
		Log.Print(L.READ_ONLY_REFUSED)
		return false
	end
	return true
end

local function toggleDebug()
	if not canWrite() then
		return
	end
	local settings = ns.db.settings
	settings.debug = not settings.debug
	if settings.debug then
		Log.Print(L.DEBUG_ON)
	else
		Log.Print(L.DEBUG_OFF)
	end
	Log.Info("debug mode set to " .. tostring(settings.debug))
end

local function reset(argument)
	if not canWrite() then
		return
	end
	local uptime = ns.Client:GetUptime()
	if argument == "confirm" then
		if resetPendingUntil and uptime <= resetPendingUntil then
			resetPendingUntil = nil
			ns.DB.ResetSettings(ns.db)
			Log.Print(L.RESET_DONE)
			Log.Info("settings reset")
		else
			resetPendingUntil = nil
			Log.Print(L.RESET_NOT_PENDING)
		end
		return
	end
	resetPendingUntil = uptime + Slash.RESET_CONFIRM_SECONDS
	Log.Print(Util.Format(L.RESET_CONFIRM_PROMPT, Slash.RESET_CONFIRM_SECONDS))
end

function Slash.Handle(message)
	local input = Util.Trim(string.lower(message or ""))
	local command, argument = input:match("^(%S*)%s*(.-)$")
	if command == "" or command == "help" then
		printHelp()
	elseif command == "version" then
		printVersion()
	elseif command == "debug" then
		toggleDebug()
	elseif command == "reset" then
		reset(argument)
	else
		Log.Print(Util.Format(L.UNKNOWN_COMMAND, command))
	end
end

function Slash.Register()
	SLASH_BUYORFARMFOREVER1 = "/bof"
	SLASH_BUYORFARMFOREVER2 = "/kof"
	SlashCmdList.BUYORFARMFOREVER = Slash.Handle
end
