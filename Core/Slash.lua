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

-- Subcommands registered by other modules: name -> { handler = fn(argument), helpLine = text }
local commands = {}
local commandOrder = {}

function Slash.AddCommand(name, handler, helpLine)
	if not commands[name] then
		commandOrder[#commandOrder + 1] = name
	end
	commands[name] = { handler = handler, helpLine = helpLine }
end

-- The help lines of the base commands and all registered commands (chat help and Help tab).
function Slash.HelpLines()
	local lines = { L.HELP_LINE_HELP, L.HELP_LINE_VERSION, L.HELP_LINE_DEBUG, L.HELP_LINE_RESET }
	for _, name in ipairs(commandOrder) do
		if commands[name].helpLine then
			lines[#lines + 1] = commands[name].helpLine
		end
	end
	return lines
end

local function printHelp()
	Log.Print(L.HELP_HEADER)
	for _, line in ipairs(Slash.HelpLines()) do
		Log.Print(line)
	end
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
function Slash.CanWrite()
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

local canWrite = Slash.CanWrite

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

-- Splits "word rest" and lowercases only the word, so item links and names keep their case.
function Slash.SplitCommand(text)
	local word, rest = Util.Trim(text or ""):match("^(%S*)%s*(.-)$")
	return string.lower(word), rest
end

function Slash.Handle(message)
	local command, argument = Slash.SplitCommand(message)
	if command == "" or command == "help" then
		printHelp()
	elseif command == "version" then
		printVersion()
	elseif command == "debug" then
		toggleDebug()
	elseif command == "reset" then
		reset(string.lower(argument))
	elseif commands[command] then
		commands[command].handler(argument)
		-- Lets open windows refresh after commands that changed goals or settings.
		ns.Events.Emit("DATA_CHANGED")
	else
		Log.Print(Util.Format(L.UNKNOWN_COMMAND, command))
	end
end

function Slash.Register()
	SLASH_BUYORFARMFOREVER1 = "/bof"
	SLASH_BUYORFARMFOREVER2 = "/kof"
	SlashCmdList.BUYORFARMFOREVER = Slash.Handle
end
